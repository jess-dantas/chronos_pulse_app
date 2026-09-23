import '../datasources/admin_auth_remote_datasource.dart';
import '../repositories/admin_auth_repository.dart';

class AdminAuthRepositoryImpl implements AdminAuthRepository {
  final AdminAuthRemoteDataSource _remoteDataSource;

  AdminAuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Map<String, dynamic>> login(String username, String senha) async {
    return _remoteDataSource.login(username, senha);
  }

  @override
  Future<Map<String, dynamic>> verifyTwoFactor(
    String tempToken,
    String codigo,
  ) {
    return _remoteDataSource.verifyTwoFactor(tempToken, codigo);
  }

  @override
  Future<Map<String, dynamic>> twoFactorStatus() {
    return _remoteDataSource.twoFactorStatus();
  }

  @override
  Future<Map<String, dynamic>> twoFactorSetup({String? bearerToken}) {
    return _remoteDataSource.twoFactorSetup(bearerToken: bearerToken);
  }

  @override
  Future<Map<String, dynamic>> twoFactorConfirm(String codigo,
      {String? bearerToken}) {
    return _remoteDataSource.twoFactorConfirm(codigo,
        bearerToken: bearerToken);
  }

  @override
  Future<void> alterarSenha(String senhaAtual, String novaSenha) {
    return _remoteDataSource.alterarSenha(senhaAtual, novaSenha);
  }

  @override
  Future<Map<String, dynamic>> bootstrapStatus() {
    return _remoteDataSource.bootstrapStatus();
  }

  @override
  Future<Map<String, dynamic>> bootstrap({
    required String username,
    required String senha,
    required String nomeCompleto,
    required String email,
  }) {
    return _remoteDataSource.bootstrap(
      username: username,
      senha: senha,
      nomeCompleto: nomeCompleto,
      email: email,
    );
  }

  @override
  Future<Map<String, dynamic>> recover({
    required String username,
    required String senha,
    required String recoveryCode,
  }) {
    return _remoteDataSource.recover(
      username: username,
      senha: senha,
      recoveryCode: recoveryCode,
    );
  }

  @override
  Future<void> logout(String refreshToken) async {
    return _remoteDataSource.logout(refreshToken);
  }
}