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

  /// Etapa 2 do login 2FA-first (TOTP): troca o tempToken pelos tokens finais.
  Future<UsuarioModel> twoFactorVerify({
    required String tempToken,
    required String codigo,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.twoFactorVerifyEndpoint,
        data: {'tempToken': tempToken, 'codigo': codigo.trim()},
      );
      if (response.statusCode == 200) {
        return UsuarioModel.fromJson(response.data);
      }
      throw Exception('Código inválido.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(_mensagemServidor(e) ?? 'Código inválido.');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Sessão expirada. Refaça o login.');
      }
      if (e.response?.statusCode == 403) {
        throw Exception(
            'Conta temporariamente bloqueada por excesso de tentativas.');
      }
      throw Exception(
        mensagemErroAmigavel(e, fallback: 'Erro ao verificar o código.'),
      );
    } catch (e) {
      throw Exception(mensagemErroAmigavel(
          e, fallback: 'Erro ao verificar o código.'));
    }
  }

  /// Envia o OTP de 8 dígitos por e-mail (etapa alternativa do 2FA).
  Future<void> twoFactorEmailSend({required String tempToken}) async {
    try {
      await _dioClient.dio.post(
        ApiConstants.twoFactorEmailSendEndpoint,
        data: {'tempToken': tempToken},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Sessão expirada. Refaça o login.');
      }
      throw Exception(mensagemErroAmigavel(
          e, fallback: 'Erro ao enviar o código por e-mail.'));
    }
  }

  /// Etapa 2 do login 2FA-first (OTP por e-mail): 8 dígitos.
  Future<UsuarioModel> twoFactorEmailVerify({
    required String tempToken,
    required String codigo,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.twoFactorEmailVerifyEndpoint,
        data: {'tempToken': tempToken, 'codigo': codigo.trim()},
      );
      if (response.statusCode == 200) {
        return UsuarioModel.fromJson(response.data);
      }
      throw Exception('Código inválido.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(_mensagemServidor(e) ?? 'Código inválido.');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Sessão expirada. Refaça o login.');
      }
      if (e.response?.statusCode == 403) {
        throw Exception(
            'Conta temporariamente bloqueada por excesso de tentativas.');
      }
      throw Exception(mensagemErroAmigavel(
          e, fallback: 'Erro ao verificar o código.'));
    } catch (e) {
      throw Exception(mensagemErroAmigavel(
          e, fallback: 'Erro ao verificar o código.'));
    }
  }

  /// Gestão do 2FA do colaborador (sessão autenticada com Bearer).
  Future<bool> twoFactorStatus() async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.twoFactorStatusEndpoint,
      );
      return response.data is Map && response.data['enabled'] == true;
    } on DioException catch (e) {
      throw Exception(
        mensagemErroAmigavel(e, fallback: 'Erro ao consultar o 2FA.'),
      );
    }
  }

  /// Gera o segredo TOTP pendente (ainda não habilitado).
  Future<Map<String, String>> twoFactorSetup() async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.twoFactorSetupEndpoint,
      );
      final data = response.data is Map ? response.data : const {};
      return {
        'secret': (data['secret'] ?? '') as String,
        'otpauthUri': (data['otpauthUri'] ?? '') as String,
      };
    } on DioException catch (e) {
      throw Exception(
        mensagemErroAmigavel(e, fallback: 'Erro na configuração do 2FA.'),
      );
    }
  }

  Future<void> twoFactorConfirm({required String codigo}) async {
    try {
      await _dioClient.dio.post(
        ApiConstants.twoFactorConfirmEndpoint,
        data: {'codigo': codigo.trim()},
      );
    } on DioException catch (e) {
      throw Exception(_mensagemServidor(e) ??
          mensagemErroAmigavel(e, fallback: 'Erro ao ativar o 2FA.'));
    }
  }

  Future<void> twoFactorDisable({required String codigo}) async {
    try {
      await _dioClient.dio.post(
        ApiConstants.twoFactorDisableEndpoint,
        data: {'codigo': codigo.trim()},
      );
    } on DioException catch (e) {
      throw Exception(_mensagemServidor(e) ??
          mensagemErroAmigavel(e, fallback: 'Erro ao desativar o 2FA.'));
    }
  }

  String? _mensagemServidor(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.trim().isNotEmpty) return msg;
    }
    return null;
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

  static bool _semRede(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout;

  /// Status do vínculo + 2FA no modo sem login (`GET /device/status`,
  /// header `X-Device-Token`, sem sessão).
  ///
  /// - [offline]: sem conexão — o chamador decide o fallback local;
  /// - [revogado]: 401 — o vínculo não vale mais no servidor.
  Future<({bool offline, bool revogado, bool twoFactorEnabled})>
      deviceStatus({required String token}) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.deviceStatusEndpoint,
        options: Options(headers: {'X-Device-Token': token}),
      );
      final data = response.data is Map ? response.data as Map : const {};
      return (
        offline: false,
        revogado: false,
        twoFactorEnabled: data['twoFactorEnabled'] == true,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return (offline: false, revogado: true, twoFactorEnabled: false);
      }
      if (_semRede(e)) {
        return (offline: true, revogado: false, twoFactorEnabled: false);
      }
      throw Exception(
        mensagemErroAmigavel(e, fallback: 'Erro ao confirmar o vínculo.'),
      );
    }
  }

  /// Verificação do 2FA no modo sem login (`POST /device/verificar`,
  /// header `X-Device-Token`) — etapa 2 da ordem biometria → 2FA → vínculo.
  ///
  /// [codigo] nulo + [porEmail] gera e envia o OTP de 8 dígitos
  /// (`enviado: true`); com código, `verificado: true` quando confere.
  /// Código inválido lança exceção; [offline] = sem conexão.
  Future<({bool offline, bool verificado, bool enviado, DateTime? expiraEm})>
      deviceVerificar({
    required String token,
    String? codigo,
    bool porEmail = false,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.deviceVerificarEndpoint,
        options: Options(headers: {'X-Device-Token': token}),
        data: {
          'metodo': porEmail ? 'EMAIL' : 'TOTP',
          if (codigo != null) 'codigo': codigo,
        },
      );
      final data = response.data is Map ? response.data as Map : const {};
      final expiraRaw = data['expiraEm'];
      return (
        offline: false,
        verificado: data['verificado'] == true,
        enviado: data['enviado'] == true,
        expiraEm: expiraRaw is String ? DateTime.tryParse(expiraRaw) : null,
      );
    } on DioException catch (e) {
      if (_semRede(e)) {
        return (offline: true, verificado: false, enviado: false, expiraEm: null);
      }
      if (e.response?.statusCode == 401) {
        throw Exception(
            'O vínculo deste aparelho não é mais válido. Faça login e '
            'ative "Bater ponto sem login" novamente.');
      }
      if (e.response?.statusCode == 400 || e.response?.statusCode == 403) {
        throw Exception(_mensagemServidor(e) ?? 'Código inválido.');
      }
      throw Exception(mensagemErroAmigavel(
          e, fallback: 'Erro ao verificar o código.'));
    }
  }
}
