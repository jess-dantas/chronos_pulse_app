import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_local_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/models/registro_ponto_model.dart';

class _RepoFake extends AuthRepository {
  _RepoFake()
      : super(
          remoteDataSource: AuthRemoteDataSource(DioClient()),
          dioClient: DioClient(),
        );
}

RegistroPontoModel _registro(String id, {required bool sincronizado}) {
  return RegistroPontoModel(
    idLocal: id,
    dataHoraDispositivo: DateTime.now().toUtc(),
    tipoRegistro: 'ENTRADA',
    latitude: 0,
    longitude: 0,
    precisaoGps: 5,
    fotoUrl: '',
    hashLocal: 'h-$id',
    sincronizadoOffline: sincronizado,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorage, (call) async {
    switch (call.method) {
      case 'readAll':
        return <String, String>{};
      case 'read':
        return null;
      default:
        return null;
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Sessão x fila offline de pontos', () {
    late PontoLocalDataSourceWeb ds;
    late AuthProvider auth;

    setUp(() {
      ds = PontoLocalDataSourceWeb();
      auth = AuthProvider(_RepoFake(), pontoLocalDataSource: ds);
    });

    test('logout preserva a fila não sincronizada e limpa o histórico',
        () async {
      await ds.salvarPontoLocal(_registro('pendente', sincronizado: false));
      await ds.salvarPontoLocal(_registro('sincronizado', sincronizado: true));

      await auth.logout();

      final pendentes = await ds.obterPontosNaoSincronizados();
      expect(pendentes.map((r) => r.idLocal), equals(['pendente']),
          reason: 'batida offline deve sobreviver ao logout (replay no login)');
      final historico = await ds.obterHistoricoHoje();
      expect(historico.map((r) => r.idLocal), equals(['pendente']),
          reason: 'histórico já sincronizado sai do dispositivo no logout');
    });

    test('limparDadosLocais (LGPD) remove fila e histórico', () async {
      await ds.salvarPontoLocal(_registro('pendente', sincronizado: false));
      await ds.salvarPontoLocal(_registro('sincronizado', sincronizado: true));

      await auth.limparDadosLocais();

      expect(await ds.obterPontosNaoSincronizados(), isEmpty);
      expect(await ds.obterHistoricoHoje(), isEmpty);
    });
  });
}
