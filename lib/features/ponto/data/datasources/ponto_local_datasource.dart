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

  Future<List<RegistroPontoModel>> obterPontosNaoSincronizados() async {
    if (kIsWeb) {
      return _webStorage.where((p) => !p.sincronizadoOffline).toList();
    }

    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'pontos',
      where: 'sincronizadoOffline = ?',
      whereArgs: [0],
    );

    return result.map((json) => RegistroPontoModel.fromJson(json)).toList();
  }

  Future<List<RegistroPontoModel>> obterHistoricoHoje() async {
    if (kIsWeb) {
      return List.from(_webStorage.reversed);
    }

    final db = await DatabaseHelper.instance.database;
    final result =
        await db.query('pontos', orderBy: 'dataHoraDispositivo DESC');

    return result.map((json) => RegistroPontoModel.fromJson(json)).toList();
  }

  Future<void> marcarComoSincronizado(String dataHoraDispositivo) async {
    if (kIsWeb) {
      final index = _webStorage.indexWhere(
        (p) => p.dataHoraDispositivo.toIso8601String() == dataHoraDispositivo,
      );
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
          sincronizadoOffline: true,
        );
      }
      return;
    }

    final db = await DatabaseHelper.instance.database;
    await db.update(
      'pontos',
      {'sincronizadoOffline': 1},
      where: 'dataHoraDispositivo = ?',
      whereArgs: [dataHoraDispositivo],
    );
  }
}
