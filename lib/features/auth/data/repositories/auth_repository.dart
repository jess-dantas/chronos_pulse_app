import '../datasources/auth_remote_datasource.dart';
import '../models/device_token_model.dart';
import '../models/usuario_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/device_token_store.dart';

class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final DioClient _dioClient;

  AuthRepository({
    required AuthRemoteDataSource remoteDataSource,
    required DioClient dioClient,
  })  : _remoteDataSource = remoteDataSource,
        _dioClient = dioClient;

  Future<UsuarioModel> login({
    required String cpf,
    required String senha,
  }) async {
    final usuario = await _remoteDataSource.login(cpf: cpf, senha: senha);
    if (!usuario.requiresTwoFactor) {
      _dioClient.updateToken(usuario.token);
    }
    return usuario;
  }

  /// 2FA-first: troca o tempToken pelos tokens finais (TOTP ou OTP e-mail).
  Future<UsuarioModel> twoFactorVerify({
    required String tempToken,
    required String codigo,
    bool porEmail = false,
  }) async {
    final usuario = porEmail
        ? await _remoteDataSource.twoFactorEmailVerify(
            tempToken: tempToken, codigo: codigo)
        : await _remoteDataSource.twoFactorVerify(
            tempToken: tempToken, codigo: codigo);
    _dioClient.updateToken(usuario.token);
    return usuario;
  }

  Future<void> twoFactorEmailSend({required String tempToken}) {
    return _remoteDataSource.twoFactorEmailSend(tempToken: tempToken);
  }

  Future<bool> twoFactorStatus() => _remoteDataSource.twoFactorStatus();

  Future<Map<String, String>> twoFactorSetup() =>
      _remoteDataSource.twoFactorSetup();

  Future<void> twoFactorConfirm({required String codigo}) =>
      _remoteDataSource.twoFactorConfirm(codigo: codigo);

  Future<void> twoFactorDisable({required String codigo}) =>
      _remoteDataSource.twoFactorDisable(codigo: codigo);

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
    final usuario = await _remoteDataSource.cadastrarEmpresa(
      cnpj: cnpj,
      nomeEmpresa: nomeEmpresa,
      responsavelNome: responsavelNome,
      responsavelCpf: responsavelCpf,
      responsavelEmail: responsavelEmail,
      responsavelTelefone: responsavelTelefone,
      responsavelCelular: responsavelCelular,
      responsavelSenha: responsavelSenha,
      enderecoLogradouro: enderecoLogradouro,
      enderecoNumero: enderecoNumero,
      enderecoComplemento: enderecoComplemento,
      enderecoBairro: enderecoBairro,
      enderecoCidade: enderecoCidade,
      enderecoUf: enderecoUf,
      enderecoCep: enderecoCep,
    );
    _dioClient.updateToken(usuario.token);
    return usuario;
  }

  Future<UsuarioModel> refreshToken(String refreshToken) async {
    final usuario = await _remoteDataSource.refreshToken(refreshToken);
    _dioClient.updateToken(usuario.token);
    return usuario;
  }

  Future<String> alterarSenha({
    required String novaSenha,
  }) {
    return _remoteDataSource.alterarSenha(
      novaSenha: novaSenha,
    );
  }

  Future<String> esqueciSenha({required String cpf}) {
    return _remoteDataSource.esqueciSenha(cpf: cpf);
  }

  Future<String> redefinirSenha({
    required String cpf,
    required String codigo,
    required String novaSenha,
  }) {
    return _remoteDataSource.redefinirSenha(
      cpf: cpf,
      codigo: codigo,
      novaSenha: novaSenha,
    );
  }

  Future<String> enviarFoto(List<int> bytes, String nomeArquivo) {
    return _remoteDataSource.enviarFoto(bytes, nomeArquivo);
  }

  /// Ativa o vínculo do dispositivo (7 dias) e o persiste localmente para o
  /// modo "bater ponto sem login". [cpcId]/[nome] vêm da sessão ativa.
  ///
  /// Também grava se o dono tem o 2FA habilitado: define se o modo sem
  /// login cobra o código a cada uso (ordem biometria → 2FA → vínculo).
  Future<DeviceTokenModel> vincularDevice({
    required String cpcId,
    required String nome,
    String? deviceName,
    String cpf = '',
  }) async {
    final vinculo = await _remoteDataSource.vincularDevice(deviceName: deviceName);
    await DeviceTokenStore.instancia.salvar(
      token: vinculo.deviceToken,
      cpcId: cpcId,
      nome: nome,
      expiraEm: vinculo.expiraEm,
      cpf: cpf,
    );
    try {
      await DeviceTokenStore.instancia
          .salvarTwoFactor(await _remoteDataSource.twoFactorStatus());
    } catch (_) {
      // Sem o status não dá para afirmar: assume "sem 2FA" (o modo offline
      // segue funcionando) — o `device/status` corrige na próxima entrada
      // online e cobra o código na hora se for o caso.
      await DeviceTokenStore.instancia.salvarTwoFactor(false);
    }
    return vinculo;
  }

  /// Desativa o vínculo no servidor e limpa o resíduo local.
  Future<void> revogarDevice() async {
    await _remoteDataSource.revogarDevice();
    await DeviceTokenStore.instancia.limpar();
  }

  void logout() {
    _dioClient.updateToken(null);
  }

  void updateToken(String? token) {
    _dioClient.updateToken(token);
  }
}
