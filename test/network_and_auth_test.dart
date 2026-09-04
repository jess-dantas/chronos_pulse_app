import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/constants/api_constants.dart';
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
          contains('CPF ou senha incorretos'),
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
