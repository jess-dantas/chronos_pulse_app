import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/security/device_token_store.dart';
import 'package:chronos_pulse_app/core/telemetry/telemetry_service.dart';
import 'package:chronos_pulse_app/features/ponto/data/models/registro_ponto_model.dart';
import 'package:chronos_pulse_app/features/ponto/data/repositories/ponto_repository.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/providers/ponto_provider.dart';

import 'ponto_test.dart' show MockPontoLocalDataSource, MockPontoRemoteDataSource;

/// Adapter que captura a requisição (espelha o padrão de modo_dispositivo_test).
class _CapturaAdapter implements HttpClientAdapter {
  RequestOptions? ultima;
  int chamadas = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    chamadas++;
    ultima = options;
    return ResponseBody.fromString(
      '{"registrados":1}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Telemetria que apenas captura os eventos registrados (sem rede).
class _TelemetriaCaptura extends TelemetryService {
  _TelemetriaCaptura() : super(dioClient: DioClient());

  final List<TipoEventoTelemetria> tipos = [];
  final List<String> mensagens = [];

  @override
  void registrar({
    required TipoEventoTelemetria tipo,
    required String modulo,
    String? endpoint,
    int? statusHttp,
    int? latencyMs,
    String? mensagem,
    String? detalhe,
  }) {
    tipos.add(tipo);
    mensagens.add(mensagem ?? '');
  }
}

DeviceTokenStore _store(Map<String, String> memoria) => DeviceTokenStore(
      ler: (k) async => memoria[k],
      gravar: (k, v) async {
        memoria[k] = v;
      },
      remover: (k) async {
        memoria.remove(k);
      },
    );

RegistroPontoModel _registro(String idLocal) => RegistroPontoModel(
      idLocal: idLocal,
      colaboradorId: 'cpc-dono',
      dataHoraDispositivo: DateTime.now().toUtc(),
      tipoRegistro: 'ENTRADA',
      latitude: -23.5,
      longitude: -46.6,
      precisaoGps: 5.0,
      hashLocal: 'hash1',
      sincronizadoOffline: false,
    );

void main() {
  group('TelemetryService — credencial para a ingestão', () {
    test('sem sessão e com vínculo: envia a fila com X-Device-Token', () async {
      final memoria = <String, String>{};
      await _store(memoria).salvar(
        token: 'dt-abc',
        cpcId: 'cpc-dono',
        nome: 'Aparelho',
        expiraEm: DateTime.now().toUtc().add(const Duration(days: 7)),
      );

      final dioClient = DioClient();
      final adapter = _CapturaAdapter();
      dioClient.dio.httpClientAdapter = adapter;
      final svc =
          TelemetryService(dioClient: dioClient, deviceStore: _store(memoria));

      svc.registrar(
        tipo: TipoEventoTelemetria.conexaoOffline,
        modulo: 'HOME',
        mensagem: 'Sem conexão na abertura do app',
      );
      expect(svc.isEmpty, isFalse);

      await svc.flush();

      expect(svc.isEmpty, isTrue);
      expect(adapter.chamadas, 1);
      expect(adapter.ultima!.headers['X-Device-Token'], 'dt-abc');
      expect(adapter.ultima!.headers.containsKey('Authorization'), isFalse);
      final payload = adapter.ultima!.data as Map<String, dynamic>;
      expect(payload['eventos'], hasLength(1));
      svc.dispose();
    });

    test('sem sessão e sem vínculo: descarta a fila (backend recusaria)',
        () async {
      final dioClient = DioClient();
      final adapter = _CapturaAdapter();
      dioClient.dio.httpClientAdapter = adapter;
      final svc = TelemetryService(
        dioClient: dioClient,
        deviceStore: _store(<String, String>{}),
      );

      svc.registrar(tipo: TipoEventoTelemetria.uiErro, modulo: 'APP');
      await svc.flush();

      expect(adapter.chamadas, 0);
      expect(svc.isEmpty, isTrue);
      svc.dispose();
    });

    test('com sessão ativa: envia sem X-Device-Token (Bearer do DioClient)',
        () async {
      final dioClient = DioClient()..updateToken('jwt-da-sessao');
      final adapter = _CapturaAdapter();
      dioClient.dio.httpClientAdapter = adapter;
      final svc = TelemetryService(dioClient: dioClient);

      svc.registrar(tipo: TipoEventoTelemetria.loginSucesso, modulo: 'AUTH');
      await svc.flush();

      expect(adapter.chamadas, 1);
      expect(adapter.ultima!.headers.containsKey('X-Device-Token'), isFalse);
      expect(adapter.ultima!.headers['Authorization'], 'Bearer jwt-da-sessao');
      svc.dispose();
    });
  });

  group('DioClient — X-Trace-Id (correlação com o backend)', () {
    test('envia um traceId novo e válido por requisição', () async {
      final dioClient = DioClient();
      final adapter = _CapturaAdapter();
      dioClient.dio.httpClientAdapter = adapter;

      await dioClient.dio.get('/api/v1/auth/ping');
      final primeiro = adapter.ultima!.headers['X-Trace-Id'] as String;
      await dioClient.dio.get('/api/v1/auth/ping');
      final segundo = adapter.ultima!.headers['X-Trace-Id'] as String;

      expect(primeiro, isNotEmpty);
      expect(primeiro.length, lessThanOrEqualTo(64));
      expect(
        RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(primeiro),
        isTrue,
        reason: 'traceId deve ser um UUID',
      );
      expect(primeiro, isNot(segundo), reason: 'trace novo por requisição');
    });
  });

  group('PontoProvider — telemetria de batida offline', () {
    late MockPontoLocalDataSource local;
    late MockPontoRemoteDataSource remote;
    late PontoRepository repository;
    late _TelemetriaCaptura telemetria;

    setUp(() {
      local = MockPontoLocalDataSource();
      remote = MockPontoRemoteDataSource();
      repository = PontoRepository(
        localDataSource: local,
        remoteDataSource: remote,
      );
      telemetria = _TelemetriaCaptura();
    });

    test('ponto offline registra CONEXAO_OFFLINE', () async {
      remote.online = false;
      final provider =
          PontoProvider(repository, telemetria: telemetria);
      addTearDown(provider.dispose);

      final salvo = await provider.registrarPonto(_registro('off-1'));

      expect(salvo, isFalse);
      expect(telemetria.tipos, contains(TipoEventoTelemetria.conexaoOffline));
      expect(telemetria.mensagens.first, 'Batida enfileirada offline');
    });

    test('rejeição explícita do servidor NÃO vira evento de offline', () async {
      remote.rejeitar = true;
      final provider =
          PontoProvider(repository, telemetria: telemetria);
      addTearDown(provider.dispose);

      final salvo = await provider.registrarPonto(_registro('rej-1'));

      expect(salvo, isFalse);
      expect(repository.ultimaFalhaServidor, isNotNull);
      expect(telemetria.tipos, isEmpty);
    });
  });
}
