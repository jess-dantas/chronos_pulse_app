import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/database/database_helper.dart';
import '../models/registro_ponto_model.dart';

/// Persistência local via SQLite (nativo: Android/iOS).
class PontoLocalDataSource {
  // O armazenamento local preciso durável para offline-first usa SQLite no
  // nativo e uma implementação dedicada (PontoLocalDataSourceWeb) na Web —
  // ver R12/offline.

  Future<void> salvarPontoLocal(RegistroPontoModel registro) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('pontos', registro.toJson());
  }

  Future<List<RegistroPontoModel>> obterPontosNaoSincronizados(
      {String? colaboradorId}) async {
    final db = await DatabaseHelper.instance.database;
    final whereClause = colaboradorId != null
        ? 'sincronizadoOffline = ? AND colaboradorId = ?'
        : 'sincronizadoOffline = ?';
    final whereArgs = colaboradorId != null ? [0, colaboradorId] : [0];

    final result = await db.query(
      'pontos',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return result.map((json) => RegistroPontoModel.fromJson(json)).toList();
  }

  Future<List<RegistroPontoModel>> obterHistoricoHoje(
      {String? colaboradorId}) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59, 999);

    final db = await DatabaseHelper.instance.database;
    final whereClause = colaboradorId != null ? 'colaboradorId = ?' : null;
    final whereArgs = colaboradorId != null ? [colaboradorId] : [];

    final result = await db.query(
      'pontos',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'dataHoraDispositivo ASC',
    );

    return result.map((json) => RegistroPontoModel.fromJson(json)).where((p) {
      final data = p.dataHoraDispositivo.toLocal();
      return !data.isBefore(inicioDia) && !data.isAfter(fimDia);
    }).toList();
  }

  Future<List<RegistroPontoModel>> obterPorMesAno({
    String? colaboradorId,
    int? mes,
    int? ano,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final whereClause = colaboradorId != null ? 'colaboradorId = ?' : null;
    final whereArgs = colaboradorId != null ? [colaboradorId] : [];

    final result = await db.query(
      'pontos',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'dataHoraDispositivo ASC',
    );

    return result.map((json) => RegistroPontoModel.fromJson(json)).where((p) {
      final data = p.dataHoraDispositivo.toLocal();
      final mesOk = mes == null || data.month == mes;
      final anoOk = ano == null || data.year == ano;
      return mesOk && anoOk;
    }).toList();
  }

  Future<void> marcarComoSincronizado(String idLocal) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'pontos',
      {'sincronizadoOffline': 1},
      where: 'idLocal = ?',
      whereArgs: [idLocal],
    );
  }

  /// Reconcilia o dia local com o espelho do servidor (offline-first).
  ///
  /// Upsert por instante exato: o registro do servidor vence (tipo/nsr/hash
  /// do servidor passam a valer localmente — resolve a divergência de tipo
  /// que fazia a mesma batida aparecer duas vezes na mesclagem). Locais já
  /// sincronizados do dia ausentes no servidor são removidos (o servidor é a
  /// fonte da verdade para dado sincronizado); pendentes nunca são tocados.
  /// O chamador só deve invocar quando o espelho do dia foi obtido com
  /// sucesso — falha aqui não apaga nada.
  Future<void> reconciliarDia({
    required String? colaboradorId,
    required DateTime inicioDia,
    required DateTime fimDia,
    required List<RegistroPontoModel> remotos,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final whereClause = colaboradorId != null ? 'colaboradorId = ?' : null;
      final whereArgs = colaboradorId != null
          ? <dynamic>[colaboradorId]
          : <dynamic>[];
      final result = await txn.query(
        'pontos',
        where: whereClause,
        whereArgs: whereArgs,
      );

      final remotosPorInstante = <int, RegistroPontoModel>{
        for (final r in remotos) r.dataHoraDispositivo.millisecondsSinceEpoch: r,
      };
      final instantesGravados = <int>{};

      for (final linha in result) {
        final local = RegistroPontoModel.fromJson(linha);
        final data = local.dataHoraDispositivo.toLocal();
        if (data.isBefore(inicioDia) || data.isAfter(fimDia)) continue;

        final instante = local.dataHoraDispositivo.millisecondsSinceEpoch;
        if (remotosPorInstante.containsKey(instante)) {
          // Mesma batida no servidor: servidor vence — e desenfileira
          // pendentes já aceitos lá (evita reenvio duplicado).
          await txn.delete('pontos', where: 'id = ?', whereArgs: [linha['id']]);
          if (instantesGravados.add(instante)) {
            await txn.insert('pontos', remotosPorInstante[instante]!.toJson());
          }
        } else if (local.sincronizadoOffline && !local.ajusteManual) {
          // Órfão: sincronizado localmente mas não existe mais no servidor
          // do dia (ex.: histórico de teste limpo no deploy).
          await txn.delete('pontos', where: 'id = ?', whereArgs: [linha['id']]);
        }
      }

      // Registros do servidor ainda não copiados localmente entram agora.
      for (final r in remotos) {
        final instante = r.dataHoraDispositivo.millisecondsSinceEpoch;
        if (instantesGravados.add(instante)) {
          await txn.insert('pontos', r.toJson());
        }
      }
    });
  }

  /// Limpa todos os registros locais de ponto (fila offline).
  Future<void> limparPontosLocais() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('pontos');
  }
}

/// Persistência local na Web via SharedPreferences (localStorage).
///
/// Determinística e durável entre recarregamentos (F5), navegação e troca de
/// portas do dev server — diferente do SQLite/WASM em IndexedDB, que não
/// persistiu de forma confiável para batidas offline. Mantém a mesma interface
/// do [PontoLocalDataSource] para o app se comportar identicamente em
/// web & mobile.
class PontoLocalDataSourceWeb implements PontoLocalDataSource {
  static const String _chave = 'ponto_offline_registros_v1';

  Future<List<RegistroPontoModel>> _lerTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chave);
    if (raw == null || raw.isEmpty) return [];
    try {
      final lista = jsonDecode(raw) as List<dynamic>;
      return lista
          .map((e) => RegistroPontoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persistir(List<RegistroPontoModel> registros) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chave,
      jsonEncode(registros.map((r) => r.toJson()).toList()),
    );
  }

  @override
  Future<void> salvarPontoLocal(RegistroPontoModel registro) async {
    final lista = await _lerTodos();
    lista.add(registro);
    await _persistir(lista);
  }

  @override
  Future<void> marcarComoSincronizado(String idLocal) async {
    final lista = await _lerTodos();
    final idx = lista.indexWhere((r) => r.idLocal == idLocal);
    if (idx >= 0) {
      lista[idx] = lista[idx].copyWith(sincronizadoOffline: true);
      await _persistir(lista);
    }
  }

  @override
  Future<void> reconciliarDia({
    required String? colaboradorId,
    required DateTime inicioDia,
    required DateTime fimDia,
    required List<RegistroPontoModel> remotos,
  }) async {
    final todos = await _lerTodos();
    final remotosPorInstante = <int, RegistroPontoModel>{
      for (final r in remotos) r.dataHoraDispositivo.millisecondsSinceEpoch: r,
    };
    final mantidos = <RegistroPontoModel>[];
    final instantesGravados = <int>{};

    for (final local in todos) {
      final noColaborador =
          colaboradorId == null || local.colaboradorId == colaboradorId;
      final data = local.dataHoraDispositivo.toLocal();
      final noDia = !data.isBefore(inicioDia) && !data.isAfter(fimDia);
      if (!noColaborador || !noDia) {
        mantidos.add(local);
        continue;
      }

      final instante = local.dataHoraDispositivo.millisecondsSinceEpoch;
      final remoto = remotosPorInstante[instante];
      if (remoto != null) {
        mantidos.add(remoto);
        instantesGravados.add(instante);
      } else if (!(local.sincronizadoOffline && !local.ajusteManual)) {
        // Pendente (ou ajuste local): preservado.
        mantidos.add(local);
      }
      // Órfão sincronizado ausente do servidor do dia: removido.
    }

    for (final r in remotos) {
      final instante = r.dataHoraDispositivo.millisecondsSinceEpoch;
      if (instantesGravados.add(instante)) {
        mantidos.add(r);
      }
    }

    await _persistir(mantidos);
  }

  @override
  Future<List<RegistroPontoModel>> obterPontosNaoSincronizados({
    String? colaboradorId,
  }) async {
    final lista = await _lerTodos();
    return lista
        .where((r) =>
            !r.sincronizadoOffline &&
            (colaboradorId == null || r.colaboradorId == colaboradorId))
        .toList();
  }

  @override
  Future<List<RegistroPontoModel>> obterHistoricoHoje({
    String? colaboradorId,
  }) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59, 999);

    final lista = await _lerTodos();
    return lista.where((r) {
      final okColaborador =
          colaboradorId == null || r.colaboradorId == colaboradorId;
      final data = r.dataHoraDispositivo.toLocal();
      return okColaborador &&
          !data.isBefore(inicioDia) &&
          !data.isAfter(fimDia);
    }).toList()
      ..sort((a, b) => a.dataHoraDispositivo.compareTo(b.dataHoraDispositivo));
  }

  @override
  Future<List<RegistroPontoModel>> obterPorMesAno({
    String? colaboradorId,
    int? mes,
    int? ano,
  }) async {
    final lista = await _lerTodos();
    return lista.where((r) {
      final okColaborador =
          colaboradorId == null || r.colaboradorId == colaboradorId;
      final data = r.dataHoraDispositivo.toLocal();
      final mesOk = mes == null || data.month == mes;
      final anoOk = ano == null || data.year == ano;
      return okColaborador && mesOk && anoOk;
    }).toList()
      ..sort((a, b) => a.dataHoraDispositivo.compareTo(b.dataHoraDispositivo));
  }

  @override
  Future<void> limparPontosLocais() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave);
  }
}
