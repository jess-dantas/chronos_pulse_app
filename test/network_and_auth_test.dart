import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/constants/api_constants.dart';
import 'package:chronos_pulse_app/core/errors/mensagens_erro.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';

void main() {
  group('ApiConstants Tests', () {
    test('baseUrl deve retornar uma URL válida', () {
      final url = ApiConstants.baseUrl;
      expect(url, isNotEmpty);
      expect(url.startsWith('http://') || url.startsWith('https://'), isTrue);
      expect(url.endsWith('/api/v1'), isTrue);
    });

    test('Endpoints devem ser construídos corretamente', () {
      expect(ApiConstants.loginEndpoint, '/auth/login');
      expect(ApiConstants.pontosEndpoint, '/pontos/sincronizar');
      expect(ApiConstants.estoqueMateriaisEndpoint, '/estoque/materiais');
    });
  });

  group('DioClient & AuthRemoteDataSource Error Handling Tests', () {
    test('DioClient intercepta falhas de timeout com mensagem amigável', () async {
      final dioClient = DioClient();
      dioClient.dio.httpClientAdapter = _MockTimeoutAdapter();

      expect(
        () => dioClient.dio.get('/test-timeout'),
        throwsA(isA<DioException>().having(
          (e) => e.message,
          'message',
          contains('Tempo limite de conexão excedido'),
        )),
      );
    });

    test('DioClient intercepta falhas de conexão com mensagem amigável', () async {
      final dioClient = DioClient();
      dioClient.dio.httpClientAdapter = _MockConnectionErrorAdapter();

      expect(
        () => dioClient.dio.get('/test-connection-error'),
        throwsA(isA<DioException>().having(
          (e) => e.message,
          'message',
          contains('Não foi possível conectar ao servidor'),
        )),
      );
    });

    test('AuthRemoteDataSource repassa erro de conexão amigável ao usuário', () async {
      final dioClient = DioClient();
      dioClient.dio.httpClientAdapter = _MockConnectionErrorAdapter();
      final authDataSource = AuthRemoteDataSource(dioClient);

      expect(
        () => authDataSource.login(cpf: '12345678901', senha: '123'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'toString',
          contains('Não foi possível conectar ao servidor'),
        )),
      );
    });

    test('AuthRemoteDataSource trata credenciais inválidas (401)', () async {
      final dioClient = DioClient();
      dioClient.dio.httpClientAdapter = _Mock401Adapter();
      final authDataSource = AuthRemoteDataSource(dioClient);

      expect(
        () => authDataSource.login(cpf: '12345678901', senha: 'wrong'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'toString',
          contains('Revise suas credenciais'),
        )),
      );
    });

    test('AuthRemoteDataSource mostra mensagem amigável para usuário/senha inválidos (400)', () async {
      final dioClient = DioClient();
      dioClient.dio.httpClientAdapter = _Mock400Adapter();
      final authDataSource = AuthRemoteDataSource(dioClient);

      expect(
        () => authDataSource.login(cpf: '11111111111', senha: 'errada'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'toString',
          contains('Revise os dados informados.'),
        )),
      );
    });

    // D1: identidade offline — falha de rede no refresh NÃO pode ser tratada
    // como rejeição de credenciais (senão a sessão local se perderia offline).
    test('refreshToken lança FalhaDeRedeException quando a rede falha (D1)', () async {
      final dioClient = DioClient();
      dioClient.dio.httpClientAdapter = _MockConnectionErrorAdapter();
      final authDataSource = AuthRemoteDataSource(dioClient);

      expect(
        () => authDataSource.refreshToken('refresh-x'),
        throwsA(isA<FalhaDeRedeException>()),
      );
    });

    test('refreshToken com timeout também sinaliza falha de rede (D1)', () async {
      final dioClient = DioClient();
      dioClient.dio.httpClientAdapter = _MockTimeoutAdapter();
      final authDataSource = AuthRemoteDataSource(dioClient);

      expect(
        () => authDataSource.refreshToken('refresh-x'),
        throwsA(isA<FalhaDeRedeException>()),
      );
    });

    test('refreshToken rejeitado pelo servidor (401) NÃO é falha de rede (D1)', () async {
      final dioClient = DioClient();
      dioClient.dio.httpClientAdapter = _Mock401Adapter();
      final authDataSource = AuthRemoteDataSource(dioClient);

      // O chamador (AuthProvider) usa essa distinção para encerrar a sessão
      // apenas quando o servidor rejeita — nunca por problema de conexão.
      expect(
        () => authDataSource.refreshToken('refresh-x'),
        throwsA(isA<Exception>().having(
          (e) => e is FalhaDeRedeException,
          'naoEhFalhaDeRede',
          isFalse,
        )),
      );
    });
  });
}

class _MockTimeoutAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionTimeout,
      error: 'Timeout error',
    );
  }
}

class _MockConnectionErrorAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      error: 'Connection refused / CORS blocked',
    );
  }
}

class _Mock401Adapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"message": "Unauthorized"}',
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _Mock400Adapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"status": 400, "mensagem": "Credenciais inválidas", "campos": null}',
      400,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
