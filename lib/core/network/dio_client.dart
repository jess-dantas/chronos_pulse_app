import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class DioClient {
  late final Dio dio;
  String? _authToken;

  /// Chamado quando uma requisição autenticada recebe 401.
  /// Deve renovar o token (e persistir) e retornar `true` se teve sucesso.
  Future<bool> Function()? onRefreshToken;

  Future<bool>? _refreshing;

  DioClient({String? initialToken}) {
    _authToken = initialToken;
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          // Apenas requisições autenticadas que ainda não tentaram refresh.
          final jaRetentou = error.requestOptions.extra['_retry'] == true;
          final ehEndpointRefresh = _ehEndpointRefresh(error.requestOptions.path);
          final temToken =
              (_authToken != null && _authToken!.isNotEmpty);

          if (error.response?.statusCode == 401 && !jaRetentou && !ehEndpointRefresh && temToken) {
            final renovado = await (_refreshing ??= _renovarToken());
            if (renovado) {
              try {
                final opcoes = error.requestOptions;
                opcoes.headers['Authorization'] = 'Bearer $_authToken';
                opcoes.extra['_retry'] = true;
                final resposta = await dio.fetch(opcoes);
                return handler.resolve(resposta);
              } catch (_) {
                // segue para o tratamento de erro abaixo
              }
            }
          }

          String userFriendlyMessage;
          if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
            userFriendlyMessage =
                'Acesso não autorizado ou credenciais inválidas.';
          } else if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            userFriendlyMessage =
                'Tempo limite de conexão excedido. Verifique sua conexão com a internet.';
          } else if (error.type == DioExceptionType.connectionError) {
            userFriendlyMessage =
                'Não foi possível conectar ao servidor. Verifique sua conexão ou se a API está online.';
          } else if (error.type == DioExceptionType.badResponse) {
            final dynamic data = error.response?.data;
            if (data is Map && data['message'] != null) {
              userFriendlyMessage = data['message'].toString();
            } else {
              userFriendlyMessage = 'Erro no servidor (${error.response?.statusCode}).';
            }
          } else {
            userFriendlyMessage =
                error.message ?? 'Erro inesperado na comunicação com o servidor.';
          }

          return handler.next(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: error.error,
              message: userFriendlyMessage,
            ),
          );
        },
      ),
    );
  }

  Future<bool> _renovarToken() async {
    try {
      final callback = onRefreshToken;
      if (callback == null) return false;
      return await callback();
    } catch (_) {
      return false;
    } finally {
      _refreshing = null;
    }
  }

  bool _ehEndpointRefresh(String path) {
    final endpoint = ApiConstants.refreshTokenEndpoint;
    return path.endsWith(endpoint) || path.endsWith('$endpoint/');
  }

  void updateToken(String? token) {
    _authToken = token;
  }

  String? get token => _authToken;
}