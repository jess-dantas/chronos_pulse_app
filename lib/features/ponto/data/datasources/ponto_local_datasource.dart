import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../models/registro_ponto_model.dart';

class PontoLocalDataSource {
  // Cache em memória para o modo Web (evita conflitos com SQLite nativo no browser)
  static final List<RegistroPontoModel> _webStorage = [];

  Future<void> salvarPontoLocal(RegistroPontoModel registro) async {
    if (kIsWeb) {
      _webStorage.add(registro);
      return;
    }

    final db = await DatabaseHelper.instance.database;
    await db.insert('pontos', registro.toJson());
  }

  Future<List<RegistroPontoModel>> obterPontosNaoSincronizados({String? colaboradorId}) async {
    if (kIsWeb) {
      return _webStorage
          .where((p) =>
              !p.sincronizadoOffline &&
              (colaboradorId == null || p.colaboradorId == colaboradorId))
          .toList();
    }

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
    if (kIsWeb) {
      final filtrados = (colaboradorId == null)
          ? _webStorage
          : _webStorage.where((p) => p.colaboradorId == colaboradorId).toList();
      return List.from(filtrados.reversed);
    }

    final db = await DatabaseHelper.instance.database;
    final whereClause = colaboradorId != null ? 'colaboradorId = ?' : null;
    final whereArgs = colaboradorId != null ? [colaboradorId] : null;

    final result = await db.query(
      'pontos',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'dataHoraDispositivo DESC',
    );

    return result.map((json) => RegistroPontoModel.fromJson(json)).toList();
  }

  Future<void> marcarComoSincronizado(String idLocal) async {
    if (kIsWeb) {
      final index = _webStorage.indexWhere((p) => p.idLocal == idLocal);
      if (index != -1) {
        final item = _webStorage[index];
        _webStorage[index] = RegistroPontoModel(
          idLocal: item.idLocal,
          colaboradorId: item.colaboradorId,
          dataHoraDispositivo: item.dataHoraDispositivo,
          tipoRegistro: item.tipoRegistro,
          latitude: item.latitude,
          longitude: item.longitude,
          precisaoGps: item.precisaoGps,
          fotoUrl: item.fotoUrl,
          hashLocal: item.hashLocal,
          sincronizadoOffline: true,
        );
      }
      return;
    }

    final db = await DatabaseHelper.instance.database;
    await db.update(
      'pontos',
      {'sincronizadoOffline': 1},
      where: 'idLocal = ?',
      whereArgs: [idLocal],
    );
  }
}
