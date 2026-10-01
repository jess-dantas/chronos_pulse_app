import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/mensagens_erro.dart';
import '../../../../core/network/dio_client.dart';
import '../models/device_token_model.dart';
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
        throw Exception('Revise suas credenciais.');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Revise os dados informados.');
      }
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Revise suas credenciais.');
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Não foi possível conectar ao servidor. Verifique sua conexão com a internet ou tente novamente mais tarde.',
        );
      }
      final msg =
          (e.response?.data is Map ? e.response?.data['message'] : null) ??
              e.message;
      throw Exception(msg ?? 'Erro de rede ao autenticar.');
    } catch (e) {
      throw Exception(
        mensagemErroAmigavel(e, fallback: 'Não foi possível realizar o login.'),
      );
    }
  }

  Future<UsuarioModel> cadastrarEmpresa({
    required String cnpj,
    required String nomeEmpresa,
    required String responsavelNome,
    required String responsavelCpf,
    required String responsavelEmail,
    String? responsavelTelefone,
    String? responsavelCelular,
    required String responsavelSenha,
    String? enderecoLogradouro,
    String? enderecoNumero,
    String? enderecoComplemento,
    String? enderecoBairro,
    String? enderecoCidade,
    String? enderecoUf,
    String? enderecoCep,
  }) async {
    try {
      final cleanCnpj =
          cnpj.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase();
      final cleanCpf = responsavelCpf.replaceAll(RegExp(r'\D'), '');
      final response = await _dioClient.dio.post(
        ApiConstants.cadastrarEmpresaEndpoint,
        data: {
          'cnpj': cleanCnpj,
          'nomeEmpresa': nomeEmpresa,
          'responsavelNome': responsavelNome,
          'responsavelCpf': cleanCpf,
          'responsavelEmail': responsavelEmail,
          'responsavelTelefone': responsavelTelefone,
          'responsavelCelular': responsavelCelular,
          'responsavelSenha': responsavelSenha,
          'enderecoLogradouro': enderecoLogradouro,
          'enderecoNumero': enderecoNumero,
          'enderecoComplemento': enderecoComplemento,
          'enderecoBairro': enderecoBairro,
          'enderecoCidade': enderecoCidade,
          'enderecoUf': enderecoUf,
          'enderecoCep': enderecoCep,
        },
      );

      if (response.statusCode == 200) {
        return UsuarioModel.fromJson(response.data);
      } else {
        throw Exception('Erro ao cadastrar empresa.');
      }
    } on DioException catch (e) {
      throw Exception(
        mensagemErroAmigavel(e, fallback: 'Erro ao cadastrar empresa.'),
      );
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
      // Rede fora: sinaliza separadamente para o chamador manter a sessão
      // local (identidade offline não pode se perder por falha de conexão).
      if (ehFalhaDeRede(e)) {
        throw const FalhaDeRedeException(
          'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.',
        );
      }
      throw Exception(
        mensagemErroAmigavel(e, fallback: 'Erro ao renovar sessão.'),
      );
    }
  }

  Future<String> alterarSenha({
    required String novaSenha,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.alterarSenhaEndpoint,
        data: {'novaSenha': novaSenha},
      );
      final msg = (response.data is Map ? response.data['mensagem'] : null);
      return msg ?? 'Senha alterada com sucesso.';
    } on DioException catch (e) {
      throw Exception(
        mensagemErroAmigavel(e, fallback: 'Erro ao alterar senha.'),
      );
    }
  }

  Future<String> esqueciSenha({required String cpf}) async {
    try {
      final cleanCpf = cpf.replaceAll(RegExp(r'\D'), '');
      final response = await _dioClient.dio.post(
        ApiConstants.esqueciSenhaEndpoint,
        data: {'cpf': cleanCpf},
      );
      final msg = (response.data is Map ? response.data['mensagem'] : null);
      return msg ?? 'Código de recuperação enviado para o e-mail cadastrado.';
    } on DioException catch (e) {
      throw Exception(
        mensagemErroAmigavel(e,
            fallback: 'Erro ao solicitar recuperação de senha.'),
      );
    }
  }

  Future<String> redefinirSenha({
    required String cpf,
    required String codigo,
    required String novaSenha,
  }) async {
    try {
      final cleanCpf = cpf.replaceAll(RegExp(r'\D'), '');
      final response = await _dioClient.dio.post(
        ApiConstants.redefinirSenhaEndpoint,
        data: {
          'cpf': cleanCpf,
          'codigo': codigo.trim(),
          'novaSenha': novaSenha,
        },
      );
      final msg = (response.data is Map ? response.data['mensagem'] : null);
      return msg ?? 'Senha redefinida com sucesso.';
    } on DioException catch (e) {
      throw Exception(
        mensagemErroAmigavel(e, fallback: 'Erro ao redefinir senha.'),
      );
    }
  }

  Future<String> enviarFoto(List<int> bytes, String nomeArquivo) async {
    try {
      final formData = FormData.fromMap({
        'foto': MultipartFile.fromBytes(bytes, filename: nomeArquivo),
      });
      final response = await _dioClient.dio.post(
        ApiConstants.meFotoEndpoint,
        data: formData,
      );
      final foto =
          (response.data is Map ? response.data['foto'] : null) as String?;
      if (foto == null || foto.isEmpty) {
        throw Exception('Não foi possível salvar a foto.');
      }
      return 'data:image;base64,$foto';
    } on DioException catch (e) {
      throw Exception(
        mensagemErroAmigavel(e, fallback: 'Erro ao enviar foto.'),
      );
    }
  }

  /// Emite um device token opaco de 7 dias para "bater ponto sem login".
  /// Exige sessão ativa (Bearer) e aceite vigente do termo de privacidade
  /// — o backend recusa com 403 se o consentimento não estiver ativo.
  Future<DeviceTokenModel> vincularDevice({String? deviceName}) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.deviceVincularEndpoint,
        data: {if (deviceName != null) 'deviceName': deviceName},
      );
      if (response.statusCode == 200 && response.data is Map) {
        return DeviceTokenModel.fromJson(response.data);
      }
      throw Exception('Resposta inesperada ao vincular o dispositivo.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception(
            'Aceite o termo de ciência de privacidade antes de ativar.');
      }
      throw Exception(
        mensagemErroAmigavel(e, fallback: 'Erro ao vincular o dispositivo.'),
      );
    }
  }

  /// Revoga TODOS os vínculos de dispositivo da conta (remota).
  Future<void> revogarDevice() async {
    try {
      await _dioClient.dio.post(ApiConstants.deviceRevogarEndpoint);
    } on DioException catch (e) {
      throw Exception(
        mensagemErroAmigavel(e, fallback: 'Erro ao desativar o dispositivo.'),
      );
    }
  }
}
