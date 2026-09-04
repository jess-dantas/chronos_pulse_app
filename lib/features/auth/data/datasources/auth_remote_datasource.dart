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
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Não foi possível conectar ao servidor. Verifique sua conexão com a internet ou tente novamente mais tarde.',
        );
      }
      final msg = (e.response?.data is Map ? e.response?.data['message'] : null) ?? e.message;
      throw Exception(msg ?? 'Erro de rede ao autenticar.');
    } catch (e) {
      throw Exception(
        e.toString().startsWith('Exception: ')
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Erro ao realizar login: ${e.toString()}',
      );
    }
  }

  Future<UsuarioModel> cadastrarEmpresa({
    required String cnpj,
    required String nomeEmpresa,
    required String responsavelNome,
    required String responsavelCpf,
    required String responsavelEmail,
    String? responsavelCelular,
    required String responsavelSenha,
  }) async {
    try {
      final cleanCnpj = cnpj
          .replaceAll(RegExp(r'[^0-9A-Za-z]'), '')
          .toUpperCase();
      final cleanCpf = responsavelCpf.replaceAll(RegExp(r'\D'), '');
      final response = await _dioClient.dio.post(
        ApiConstants.cadastrarEmpresaEndpoint,
        data: {
          'cnpj': cleanCnpj,
          'nomeEmpresa': nomeEmpresa,
          'responsavelNome': responsavelNome,
          'responsavelCpf': cleanCpf,
          'responsavelEmail': responsavelEmail,
          'responsavelCelular': responsavelCelular,
          'responsavelSenha': responsavelSenha,
        },
      );

      if (response.statusCode == 200) {
        return UsuarioModel.fromJson(response.data);
      } else {
        throw Exception('Erro ao cadastrar empresa.');
      }
    } on DioException catch (e) {
      final msg = (e.response?.data is Map ? e.response?.data['message'] : null) ?? e.message;
      throw Exception(msg ?? 'Erro ao cadastrar empresa.');
    }
  }

  Future<UsuarioModel> refreshToken(String refreshToken) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.refreshTokenEndpoint,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        return UsuarioModel.fromJson(response.data);
      } else {
        throw Exception('Refresh token inválido.');
      }
    } on DioException catch (e) {
      final msg = (e.response?.data is Map ? e.response?.data['message'] : null) ?? e.message;
      throw Exception(msg ?? 'Erro ao renovar sessão.');
    }
  }
}
