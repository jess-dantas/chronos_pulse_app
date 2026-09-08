import '../../../../core/database/database_helper.dart';
import '../models/registro_ponto_model.dart';

class PontoLocalDataSource {
  // Persistência única via SQLite: nativo usa o SQLite local; na Web o
  // DatabaseHelper usa sqflite_common_ffi_web, que grava em IndexedDB,
  // preservando os registros offline entre sessões do navegador (R12).

  Future<void> salvarPontoLocal(RegistroPontoModel registro) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('pontos', registro.toJson());
  }

  Future<List<RegistroPontoModel>> obterPontosNaoSincronizados({String? colaboradorId}) async {
    final db = await DatabaseHelper.instance.database;
    final whereClause = colaboradorId != null
        ? 'sincronizadoOffline = ? AND colaboradorId = ?'
        : 'sincronizadoOffline = ?';
    final whereArgs =
        colaboradorId != null ? [0, colaboradorId] : [0];

    final result = await db.query(
      'pontos',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return result.map((json) => RegistroPontoModel.fromJson(json)).toList();
  }

  Future<List<RegistroPontoModel>> obterHistoricoHoje({String? colaboradorId}) async {
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
      orderBy: 'dataHoraDispositivo DESC',
    );

    return result
        .map((json) => RegistroPontoModel.fromJson(json))
        .where((p) {
          final data = p.dataHoraDispositivo.toLocal();
          return !data.isBefore(inicioDia) && !data.isAfter(fimDia);
        })
        .toList();
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
      orderBy: 'dataHoraDispositivo DESC',
    );

    return result
        .map((json) => RegistroPontoModel.fromJson(json))
        .where((p) {
          final data = p.dataHoraDispositivo.toLocal();
          final mesOk = mes == null || data.month == mes;
          final anoOk = ano == null || data.year == ano;
          return mesOk && anoOk;
        })
        .toList();
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
}