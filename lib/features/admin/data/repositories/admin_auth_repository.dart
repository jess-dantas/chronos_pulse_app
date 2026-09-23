abstract class AdminAuthRepository {
  Future<Map<String, dynamic>> login(String username, String senha);
  Future<Map<String, dynamic>> verifyTwoFactor(String tempToken, String codigo);
  Future<Map<String, dynamic>> twoFactorStatus();
  Future<Map<String, dynamic>> twoFactorSetup({String? bearerToken});
  Future<Map<String, dynamic>> twoFactorConfirm(String codigo,
      {String? bearerToken});
  Future<void> alterarSenha(String senhaAtual, String novaSenha);
  Future<Map<String, dynamic>> bootstrapStatus();
  Future<Map<String, dynamic>> bootstrap({
    required String username,
    required String senha,
    required String nomeCompleto,
    required String email,
  });
  Future<Map<String, dynamic>> recover({
    required String username,
    required String senha,
    required String recoveryCode,
  });
  Future<void> logout(String refreshToken);
}