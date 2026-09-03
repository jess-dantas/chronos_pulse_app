import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/usuario_model.dart';

class AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSource(this._dioClient);

  Future<UsuarioModel> login({
    required String cpf,
    required String senha,
  }) async {
    try {
      final cleanCpf = cpf.replaceAll(RegExp(r'\D'), '');
      final response = await _dioClient.dio.post(
        ApiConstants.loginEndpoint,
        data: {
          'cpf': cleanCpf,
          'senha': senha,
        },
      );

      if (response.statusCode == 200) {
        return UsuarioModel.fromJson(response.data);
      } else {
        throw Exception('Credenciais inválidas.');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('CPF ou senha incorretos.');
      }
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Erro de rede ao autenticar.');
    } catch (e) {
      throw Exception('Erro ao realizar login: ${e.toString()}');
    }
  }
}
