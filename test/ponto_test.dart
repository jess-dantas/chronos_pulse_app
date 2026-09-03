import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/ponto/data/models/registro_ponto_model.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_local_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_remote_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/repositories/ponto_repository.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/providers/ponto_provider.dart';

class MockPontoLocalDataSource extends PontoLocalDataSource {
  final List<RegistroPontoModel> _banco = [];

  @override
  Future<void> salvarPontoLocal(RegistroPontoModel registro) async {
    _banco.add(registro);
  }

  @override
  Future<List<RegistroPontoModel>> obterPontosNaoSincronizados({String? colaboradorId}) async {
    return _banco
        .where((p) =>
            !p.sincronizadoOffline &&
            (colaboradorId == null || p.colaboradorId == colaboradorId))
        .toList();
  }

  @override
  Future<List<RegistroPontoModel>> obterHistoricoHoje({String? colaboradorId}) async {
    final filtrados = (colaboradorId == null)
        ? _banco
        : _banco.where((p) => p.colaboradorId == colaboradorId).toList();
    return List.from(filtrados);
  }

  @override
  Future<void> marcarComoSincronizado(String idLocal) async {
    final idx = _banco.indexWhere((p) => p.idLocal == idLocal);
    if (idx != -1) {
      final antigo = _banco[idx];
      _banco[idx] = RegistroPontoModel(
        idLocal: antigo.idLocal,
        colaboradorId: antigo.colaboradorId,
        dataHoraDispositivo: antigo.dataHoraDispositivo,
        tipoRegistro: antigo.tipoRegistro,
        latitude: antigo.latitude,
        longitude: antigo.longitude,
        precisaoGps: antigo.precisaoGps,
        fotoUrl: antigo.fotoUrl,
        hashLocal: antigo.hashLocal,
        sincronizadoOffline: true,
      );
    }
  }
}

class MockPontoRemoteDataSource extends PontoRemoteDataSource {
  bool online = true;
  List<RegistroPontoModel> ultimosSincronizados = [];

  MockPontoRemoteDataSource() : super(DioClient());

  @override
  Future<bool> verificarConexao() async {
    return online;
  }

  @override
  Future<List<String>> sincronizarPontos(List<RegistroPontoModel> registros) async {
    if (!online) {
      throw Exception('Servidor indisponível');
    }
    ultimosSincronizados = List.from(registros);
    return registros.map((r) => r.idLocal).toList();
  }
}

void main() {
  group('PontoProvider & Sensor de Conectividade', () {
    late MockPontoLocalDataSource localDataSource;
    late MockPontoRemoteDataSource remoteDataSource;
    late PontoRepository repository;
    late PontoProvider provider;

    setUp(() {
      localDataSource = MockPontoLocalDataSource();
      remoteDataSource = MockPontoRemoteDataSource();
      repository = PontoRepository(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
      );
      provider = PontoProvider(repository);
    });

    tearDown(() {
      provider.dispose();
    });

    test('Deve salvar localmente como pendente quando offline e sincronizar ao ficar online', () async {
      // 1. Simula servidor offline
      remoteDataSource.online = false;
      await provider.checarConexao();
      expect(provider.isOnline, isFalse);

      final ponto1 = RegistroPontoModel(
        idLocal: 'uuid-1',
        dataHoraDispositivo: DateTime.now().toUtc(),
        tipoRegistro: 'ENTRADA',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'hash1',
        sincronizadoOffline: false,
      );

      final salvoOnline = await provider.registrarPonto(ponto1);
      expect(salvoOnline, isFalse);
      expect(provider.pendentesCount, equals(1));
      expect(provider.historico.length, equals(1));
      expect(provider.historico.first.sincronizadoOffline, isFalse);

      // 2. Servidor volta a ficar online e executa auto-sync
      remoteDataSource.online = true;
      await provider.checarConexao(autoSync: true);

      expect(provider.isOnline, isTrue);
      expect(provider.pendentesCount, equals(0));
      expect(provider.historico.first.sincronizadoOffline, isTrue);
      expect(remoteDataSource.ultimosSincronizados.length, equals(1));
    });

    test('Sincronização manual deve processar lote acumulado', () async {
      remoteDataSource.online = false;

      final p1 = RegistroPontoModel(
        idLocal: 'uuid-a',
        dataHoraDispositivo: DateTime.now().toUtc(),
        tipoRegistro: 'ENTRADA',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'hashA',
        sincronizadoOffline: false,
      );

      final p2 = RegistroPontoModel(
        idLocal: 'uuid-b',
        dataHoraDispositivo: DateTime.now().toUtc(),
        tipoRegistro: 'INTERVALO',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'hashB',
        sincronizadoOffline: false,
      );

      await provider.registrarPonto(p1);
      await provider.registrarPonto(p2);
      expect(provider.pendentesCount, equals(2));

      // Volta a ficar online e dispara sincronização manual
      remoteDataSource.online = true;
      final totalSincronizados = await provider.sincronizar();

      expect(totalSincronizados, equals(2));
      expect(provider.pendentesCount, equals(0));
      expect(provider.isOnline, isTrue);
    });
  });
}
