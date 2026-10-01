import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class AdminAuthRemoteDataSource {
  final DioClient _dioClient;

  AdminAuthRemoteDataSource(this._dioClient);

  /// Backend admin auth fora de `/api/v1` (`/admin/auth/login`).
  String get _adminBaseUrl {
    final base = ApiConstants.baseUrl;
    return base.endsWith('/api/v1')
        ? base.substring(0, base.length - '/api/v1'.length)
        : base;
  }

  /// Login admin. [senha] opcional (2FA-first): sem senha o backend exige
  /// 2FA habilitado e devolve `requiresTwoFactor` + `tempToken` direto.
  Future<Map<String, dynamic>> login(String username, {String? senha}) async {
    try {
      final response = await _dioClient.dio.post(
        '$_adminBaseUrl/admin/auth/login',
        data: {
          'username': username,
          if (senha != null && senha.isNotEmpty) 'senha': senha,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Revise suas credenciais');
    } on DioException catch (e) {
      throw Exception(_extrairMensagem(e, 'Erro ao autenticar'));
    }
  }

  /// POST /admin/auth/2fa/verify — troca o tempToken pelos tokens finais.
  Future<Map<String, dynamic>> verifyTwoFactor(
    String tempToken,
    String codigo,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        '$_adminBaseUrl/admin/auth/2fa/verify',
        data: {
          'tempToken': tempToken,
          'codigo': codigo,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Verificação 2FA inválida');
    } on DioException catch (e) {
      throw Exception(_extrairMensagem(e, 'Código 2FA inválido'));
    }
  }

  /// POST /admin/auth/2fa/email/send { tempToken } — gera e envia por e-mail
  /// um OTP de 8 dígitos (alternativa ao TOTP quando o aparelho está fora).
  Future<void> sendEmailCode(String tempToken) async {
    try {
      await _dioClient.dio.post(
        '$_adminBaseUrl/admin/auth/2fa/email/send',
        data: {'tempToken': tempToken},
      );
    } on DioException catch (e) {
      throw Exception(_extrairMensagem(e, 'Erro ao enviar o código por e-mail'));
    }
  }

  /// POST /admin/auth/2fa/email/verify { tempToken, codigo } (8 dígitos).
  Future<Map<String, dynamic>> verifyEmailCode(
    String tempToken,
    String codigo,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        '$_adminBaseUrl/admin/auth/2fa/email/verify',
        data: {'tempToken': tempToken, 'codigo': codigo},
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Código de e-mail inválido');
    } on DioException catch (e) {
      throw Exception(_extrairMensagem(e, 'Código de e-mail inválido'));
    }
  }

  /// POST /admin/auth/refresh { refreshToken } — rotação de tokens admin.
  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    try {
      final response = await _dioClient.dio.post(
        '$_adminBaseUrl/admin/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Sessão expirada');
    } on DioException catch (e) {
      throw Exception(_extrairMensagem(e, 'Sessão expirada'));
    }
  }

  /// GET /admin/auth/2fa/status
  Future<Map<String, dynamic>> twoFactorStatus() async {
    try {
      final response =
          await _dioClient.dio.get('$_adminBaseUrl/admin/auth/2fa/status');
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Exception('Resposta inesperada do status 2FA');
    } on DioException catch (e) {
      throw Exception(_extrairMensagem(e, 'Erro ao consultar status 2FA'));
    }
  }

  /// GET /admin/auth/bootstrap/status → { bootstrapAvailable }
  Future<Map<String, dynamic>> bootstrapStatus() async {
    try {
      final response = await _dioClient.dio
          .get('$_adminBaseUrl/admin/auth/bootstrap/status');
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Exception('Resposta inesperada do status de provisionamento');
    } on DioException catch (e) {
      throw Exception(_extrairMensagem(e, 'Erro ao consultar provisionamento'));
    }
  }

  /// POST /admin/auth/bootstrap — first-run wizard (apenas com a tabela vazia).
  Future<Map<String, dynamic>> bootstrap({
    required String username,
    required String senha,
    required String nomeCompleto,
    required String email,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '$_adminBaseUrl/admin/auth/bootstrap',
        data: {
          'username': username,
          'senha': senha,
          'nomeCompleto': nomeCompleto,
          'email': email,
        },
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Resposta inesperada do provisionamento');
    } on DioException catch (e) {
      throw Exception(_extrairMensagem(e, 'Erro ao provisionar Administrator'));
    }
  }

  /// POST /admin/auth/2fa/recover — acesso com código de recuperação.
  /// [senha] opcional (o recovery code já autentica) e [novaSenha] opcional
  /// troca a senha no mesmo passo (R1).
  Future<Map<String, dynamic>> recover({
    required String username,
    String? senha,
    required String recoveryCode,
    String? novaSenha,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '$_adminBaseUrl/admin/auth/2fa/recover',
        data: {
          'username': username,
          if (senha != null && senha.isNotEmpty) 'senha': senha,
          'recoveryCode': recoveryCode,
          if (novaSenha != null && novaSenha.isNotEmpty) 'novaSenha': novaSenha,
        },
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Código de recuperação inválido');
    } on DioException catch (e) {
      throw Exception(
          _extrairMensagem(e, 'Erro ao recuperar o acesso'));
    }
  }

  /// POST /admin/auth/2fa/setup → { secret, otpauthUri }
  /// [bearerToken] explícito para o fluxo com tempToken (bootstrap/setup
  /// forçado), quando ainda não existe sessão ativa.
  Future<Map<String, dynamic>> twoFactorSetup({String? bearerToken}) async {
    try {
      final response = await _dioClient.dio.post(
        '$_adminBaseUrl/admin/auth/2fa/setup',
        options: bearerToken == null
            ? null
            : Options(headers: {'Authorization': 'Bearer $bearerToken'}),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Exception('Resposta inesperada do setup 2FA');
    } on DioException catch (e) {
      throw Exception(_extrairMensagem(e, 'Erro ao iniciar setup 2FA'));
    }
  }

  /// POST /admin/auth/2fa/confirm { codigo } → sessão + recoveryCodes.
  Future<Map<String, dynamic>> twoFactorConfirm(
    String codigo, {
    String? bearerToken,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '$_adminBaseUrl/admin/auth/2fa/confirm',
        data: {'codigo': codigo},
        options: bearerToken == null
            ? null
            : Options(headers: {'Authorization': 'Bearer $bearerToken'}),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Exception('Código de confirmação inválido');
    } on DioException catch (e) {
      throw Exception(_extrairMensagem(e, 'Código de confirmação inválido'));
    }
  }

  /// POST /admin/auth/2fa/disable { codigo } — desativa o 2FA exibindo um
  /// código TOTP válido do dispositivo atual (sempre permitido; perda do
  /// celular é coberta pelos recovery codes no próximo login).
  Future<void> twoFactorDisable(String codigo) async {
    try {
      await _dioClient.dio.post(
        '$_adminBaseUrl/admin/auth/2fa/disable',
        data: {'codigo': codigo},
      );
    } on DioException catch (e) {
      throw Exception(_extrairMensagem(e, 'Erro ao desativar o 2FA'));
    }
  }

  /// POST /admin/auth/alterar-senha { novaSenha }
  Future<void> alterarSenha(String novaSenha) async {
    try {
      await _dioClient.dio.post(
        '$_adminBaseUrl/admin/auth/alterar-senha',
        data: {
          'novaSenha': novaSenha,
        },
      );
    } on DioException catch (e) {
      throw Exception(_extrairMensagem(e, 'Erro ao alterar a senha'));
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dioClient.dio.post(
        '$_adminBaseUrl/admin/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } on DioException {
      // Ignore logout errors
    }
  }

  String _extrairMensagem(DioException e, String padrao) {
    final data = e.response?.data;
    if (data is Map) {
      return (data['mensagem'] ?? data['message'] ?? e.message ?? padrao)
          .toString();
    }
    return (e.message ?? padrao).toString();
  }
}