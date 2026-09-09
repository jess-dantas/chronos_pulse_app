import 'dart:convert';

import 'package:chronos_pulse_app/core/constants/api_constants.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/telemetry/telemetry_interceptor.dart';
import 'package:chronos_pulse_app/core/telemetry/telemetry_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TelemetryService', () {
    test('envia eventos em lote e limpa a fila após sucesso', () async {
      final adapter = _RegistroAdapter();
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final service = TelemetryService(
        dioClient: dioClient,
        flushInterval: const Duration(hours: 1),
      );

      service.registrarLoginSucesso();
      service.registrar(
        tipo: TipoEventoTelemetria.apiRequest,
        modulo: 'ESTOQUE',
        endpoint: '/estoque/materiais',
        statusHttp: 200,
        latencyMs: 42,
      );

      await service.flush();

      expect(adapter.requisicoes, hasLength(1));
      final envio = adapter.requisicoes.single;
      expect(envio.corpo, isNotNull);
      final eventos =
          (envio.corpo!['eventos'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(eventos, hasLength(2));
      expect(eventos[0]['tipo'], 'LOGIN_SUCESSO');
      expect(eventos[0]['modulo'], 'AUTH');
      expect(eventos[0]['endpoint'], '/auth/login');
      expect(eventos[0]['statusHttp'], 200);
      expect(eventos[0]['plataforma'], isNotNull);
      expect(eventos[1]['tipo'], 'API_REQUEST');
      expect(eventos[1]['modulo'], 'ESTOQUE');
      expect(eventos[1]['endpoint'], '/estoque/materiais');
      expect(eventos[1]['statusHttp'], 200);
      expect(eventos[1]['latencyMs'], 42);

      await service.flush();
      expect(adapter.requisicoes, hasLength(1));
    });

    test('descarta eventos silenciosamente sem sessão autenticada', () async {
      final adapter = _RegistroAdapter();
      final dioClient = DioClient()..dio.httpClientAdapter = adapter;
      final service = TelemetryService(
        dioClient: dioClient,
        flushInterval: const Duration(hours: 1),
      );

      service.registrarErroDeUi('Falha ao carregar tela', StackTrace.current);
      await service.flush();

      expect(adapter.requisicoes, isEmpty);
      expect(service.isEmpty, isTrue);
    });

    test('reenfileira o lote em falha de envio e tenta novamente', () async {
      final adapter = _RegistroAdapter(falhasRestantes: 1);
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final service = TelemetryService(
        dioClient: dioClient,
        flushInterval: const Duration(hours: 1),
      );

      service.registrarErroDeUi('Erro de UI simulado', StackTrace.current);

      await service.flush();
      expect(adapter.requisicoes, hasLength(1));

      await service.flush();
      expect(adapter.requisicoes, hasLength(2));
      expect(service.isEmpty, isTrue);

      final eventos = (adapter.requisicoes.last.corpo!['eventos'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(eventos, hasLength(1));
      expect(eventos[0]['tipo'], 'UI_ERRO');
      expect(eventos[0]['modulo'], 'APP');
    });

    test('dispara flush automático ao atingir o limite do lote', () async {
      final adapter = _RegistroAdapter();
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final service = TelemetryService(
        dioClient: dioClient,
        maxBatchSize: 2,
        flushInterval: const Duration(hours: 1),
      );

      service.registrarErroDeUi('Erro 1', StackTrace.current);
      await pumpEventQueue();
      expect(adapter.requisicoes, isEmpty);

      service.registrarErroDeUi('Erro 2', StackTrace.current);
      await pumpEventQueue();
      await Future<void>.delayed(Duration.zero);
      expect(adapter.requisicoes, hasLength(1));
      expect(service.isEmpty, isTrue);
    });

    test('registrarErroDeUi cria evento UI_ERRO com mensagem e stack', () async {
      final adapter = _RegistroAdapter();
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final service = TelemetryService(
        dioClient: dioClient,
        flushInterval: const Duration(hours: 1),
      );

      try {
        throw StateError('tela quebrou');
      } catch (e, s) {
        service.registrarErroDeUi(e, s);
      }

      await service.flush();

      final eventos = (adapter.requisicoes.single.corpo!['eventos'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(eventos, hasLength(1));
      expect(eventos[0]['tipo'], 'UI_ERRO');
      expect(eventos[0]['modulo'], 'APP');
      expect(eventos[0]['mensagem'], contains('tela quebrou'));
      // Stack resumido não deve conter dados sensíveis, somente frames.
      expect(eventos[0]['detalhe'], isNotNull);
    });
  });

  group('TelemetryInterceptor', () {
    test('mede latência e status de respostas de sucesso', () async {
      final adapter = _RegistroAdapter();
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final service = TelemetryService(
        dioClient: dioClient,
        flushInterval: const Duration(hours: 1),
      );
      dioClient.dio.interceptors.add(
        TelemetryInterceptor(telemetryService: service),
      );

      await dioClient.dio.get('/estoque/materiais');

      await service.flush();
      final eventos = (adapter.requisicoes
              .lastWhere((r) => r.corpo != null)
              .corpo!['eventos'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(eventos, hasLength(1));
      expect(eventos[0]['tipo'], 'API_REQUEST');
      expect(eventos[0]['modulo'], 'ESTOQUE');
      expect(eventos[0]['endpoint'], '/estoque/materiais');
      expect(eventos[0]['statusHttp'], 200);
      expect(eventos[0]['latencyMs'], isA<int>());
    });

    test('registra API_ERRO quando a requisição falha com status HTTP', () async {
      final adapter = _RegistroAdapter(statusCode: 503);
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final service = TelemetryService(
        dioClient: dioClient,
        flushInterval: const Duration(hours: 1),
      );
      dioClient.dio.interceptors.add(
        TelemetryInterceptor(telemetryService: service),
      );

      await expectLater(
        dioClient.dio.get('/compras/fornecedores'),
        throwsA(isA<DioException>()),
      );

      await service.flush();
      final eventos = (adapter.requisicoes
              .lastWhere((r) => r.corpo != null)
              .corpo!['eventos'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(eventos, hasLength(1));
      expect(eventos[0]['tipo'], 'API_ERRO');
      expect(eventos[0]['modulo'], 'COMPRAS');
      expect(eventos[0]['endpoint'], '/compras/fornecedores');
      expect(eventos[0]['statusHttp'], 503);
      expect(eventos[0]['mensagem'], isNotNull);
    });

    test('registra API_ERRO para falhas de conexão sem status HTTP', () async {
      final adapter = _RegistroAdapter(falhaConexao: true);
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final service = TelemetryService(
        dioClient: dioClient,
        flushInterval: const Duration(hours: 1),
      );
      dioClient.dio.interceptors.add(
        TelemetryInterceptor(telemetryService: service),
      );

      await expectLater(
        dioClient.dio.get('/auth/me'),
        throwsA(isA<DioException>()),
      );

      await service.flush();
      final eventos = (adapter.requisicoes
              .lastWhere((r) => r.corpo != null)
              .corpo!['eventos'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(eventos, hasLength(1));
      expect(eventos[0]['tipo'], 'API_ERRO');
      expect(eventos[0]['modulo'], 'AUTH');
      expect(eventos[0]['statusHttp'], isNull);
    });

    test('ignora o endpoint de telemetria para evitar recursão', () async {
      final adapter = _RegistroAdapter();
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final service = TelemetryService(
        dioClient: dioClient,
        flushInterval: const Duration(hours: 1),
      );
      dioClient.dio.interceptors.add(
        TelemetryInterceptor(telemetryService: service),
      );

      await dioClient.dio.post(
        ApiConstants.telemetriaEventosEndpoint,
        data: {'eventos': <Map<String, dynamic>>[]},
      );

      await service.flush();
      expect(adapter.requisicoes, hasLength(1));
      expect(service.isEmpty, isTrue);
    });
  });
}

/// Adaptador que registra as requisições recebidas e responde em JSON.
/// Se `falhasRestantes > 0`, lança `DioException` de `badResponse` e decrementa.
class _RegistroAdapter implements HttpClientAdapter {
  _RegistroAdapter({
    this.statusCode = 200,
    this.falhasRestantes = 0,
    this.falhaConexao = false,
  });

  final int statusCode;
  int falhasRestantes;

  /// Se verdadeiro, lança `connectionError` em rotas que não sejam telemetria
  /// (a ingestão do próprio serviço precisa conseguir falhar/completar).
  final bool falhaConexao;

  final List<Req> requisicoes = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    await requestStream?.forEach(bytes.addAll);
    Map<String, dynamic>? corpo;
    if (bytes.isNotEmpty) {
      corpo = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    }
    requisicoes.add((options: options, corpo: corpo));

    if (falhaConexao && !options.path.contains('/telemetria/')) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'Connection refused',
      );
    }

    if (falhasRestantes > 0) {
      falhasRestantes--;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: statusCode,
          data: {'message': 'Erro simulado'},
          headers: Headers(),
        ),
      );
    }

    return ResponseBody.fromString(
      '{"ok":true}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

typedef Req = ({RequestOptions options, Map<String, dynamic>? corpo});