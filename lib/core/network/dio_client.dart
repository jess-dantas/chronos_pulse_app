import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class DioClient {
  late final Dio dio;
  String? _authToken;

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
        onError: (DioException error, ErrorInterceptorHandler handler) {
          String userFriendlyMessage;
          if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
            userFriendlyMessage = 'Acesso não autorizado ou credenciais inválidas.';
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

  void updateToken(String? token) {
    _authToken = token;
  }

  String? get token => _authToken;
}
