import 'session_storage.dart';

/// Credencial de login (CPF + senha) guardada no armazenamento seguro para
/// o login por biometria (mobile only — a web nunca guarda).
///
/// - Gravada automaticamente após um login por senha bem-sucedido;
/// - Atualizada em `alterar-senha`;
/// - Sobrevive ao logout (é para isso que serve: reentregar sem digitar);
///   só sai em "apagar meus dados" (LGPD) ou quando o login por senha de
///   OUTRO CPF troca a credencial.
///
/// As funções de leitura/gravação são injetáveis para permitir testes
/// unitários sem os plugins de plataforma (mesmo padrão do
/// `DeviceTokenStore`).
class LoginBiometricoStore {
  LoginBiometricoStore({
    Future<String?> Function(String key)? ler,
    Future<void> Function(String key, String value)? gravar,
    Future<void> Function(String key)? remover,
  })  : _ler = ler ?? SessionStorage.readToken,
        _gravar = gravar ?? SessionStorage.writeToken,
        _remover = remover ?? SessionStorage.removeToken;

  static final LoginBiometricoStore instancia = LoginBiometricoStore();

  static const String chaveCpf = 'chronos_login_cpf';
  static const String chaveSenha = 'chronos_login_senha';

  final Future<String?> Function(String key) _ler;
  final Future<void> Function(String key, String value) _gravar;
  final Future<void> Function(String key) _remover;

  Future<void> salvar({required String cpf, required String senha}) async {
    await _gravar(chaveCpf, cpf);
    await _gravar(chaveSenha, senha);
  }

  Future<String?> lerCpf() => _ler(chaveCpf);

  Future<String?> lerSenha() => _ler(chaveSenha);

  Future<bool> possuiCredencial() async {
    try {
      final cpf = await lerCpf();
      final senha = await lerSenha();
      return cpf != null &&
          cpf.isNotEmpty &&
          senha != null &&
          senha.isNotEmpty;
    } catch (_) {
      // Armazenamento inacessível: sem credencial utilizável (fail-safe).
      return false;
    }
  }

  Future<void> limpar() async {
    await _remover(chaveCpf);
    await _remover(chaveSenha);
  }
}
