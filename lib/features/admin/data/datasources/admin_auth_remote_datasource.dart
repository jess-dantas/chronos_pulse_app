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

  Future<Map<String, dynamic>> login(String username, String senha) async {
    try {
      final response = await _dioClient.dio.post(
        '$_adminBaseUrl/admin/auth/login',
        data: {
          'username': username,
          'senha': senha,
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

  /// POST /admin/auth/2fa/recover — login com código de recuperação.
  Future<Map<String, dynamic>> recover({
    required String username,
    required String senha,
    required String recoveryCode,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '$_adminBaseUrl/admin/auth/2fa/recover',
        data: {
          'username': username,
          'senha': senha,
          'recoveryCode': recoveryCode,
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

  /// POST /admin/auth/alterar-senha { senhaAtual, novaSenha }
  Future<void> alterarSenha(String senhaAtual, String novaSenha) async {
    try {
      await _dioClient.dio.post(
        '$_adminBaseUrl/admin/auth/alterar-senha',
        data: {
          'senhaAtual': senhaAtual,
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