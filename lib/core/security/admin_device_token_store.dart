import 'session_storage.dart';

/// Credencial de dispositivo confiável do admin (biometria-first): o
/// `deviceToken` emitido por `POST /admin/auth/dispositivo` + o username
/// logado, guardados no armazenamento seguro. Com ela (e a biometria do
/// aparelho confirmada), o login pula senha e 2FA.
///
/// - Gravada ao ativar "Confiar neste dispositivo" (`/perfil/seguranca`);
/// - Sobrevive ao logout (é para isso que serve — reentregar sem senha);
/// - Sai ao revogar (DELETE `/admin/auth/dispositivo`), quando o servidor
///   recusa o token no login biométrico ou na expiração local (30 dias).
///
/// As funções de leitura/gravação são injetáveis para permitir testes
/// unitários sem os plugins de plataforma (mesmo padrão do
/// `DeviceTokenStore`/`LoginBiometricoStore`).
class AdminDeviceTokenStore {
  AdminDeviceTokenStore({
    Future<String?> Function(String key)? ler,
    Future<void> Function(String key, String value)? gravar,
    Future<void> Function(String key)? remover,
  })  : _ler = ler ?? SessionStorage.readToken,
        _gravar = gravar ?? SessionStorage.writeToken,
        _remover = remover ?? SessionStorage.removeToken;

  static final AdminDeviceTokenStore instancia = AdminDeviceTokenStore();

  static const String chaveToken = 'chronos_admin_device_token';
  static const String chaveUsername = 'chronos_admin_device_username';
  static const String chaveExpiraEm = 'chronos_admin_device_expira_em';

  final Future<String?> Function(String key) _ler;
  final Future<void> Function(String key, String value) _gravar;
  final Future<void> Function(String key) _remover;

  Future<void> salvar({
    required String token,
    required String username,
    required DateTime expiraEm,
  }) async {
    await _gravar(chaveToken, token);
    await _gravar(chaveUsername, username);
    await _gravar(
        chaveExpiraEm, expiraEm.toUtc().millisecondsSinceEpoch.toString());
  }

  /// Credencial vigente, ou `null` quando não existe/expirou (a expiração
  /// local também limpa os resíduos — um token vencido não fica no aparelho).
  Future<AdminDeviceCredencial?> lerAtiva() async {
    try {
      final token = await _ler(chaveToken);
      if (token == null || token.isEmpty) return null;

      final username = await _ler(chaveUsername);
      final expiraRaw = await _ler(chaveExpiraEm);
      final expiraMs = int.tryParse(expiraRaw ?? '');
      if (username == null || username.isEmpty || expiraMs == null) {
        await limpar();
        return null;
      }

      final expiraEm = DateTime.fromMillisecondsSinceEpoch(expiraMs,
          isUtc: true);
      if (!expiraEm.isAfter(DateTime.now().toUtc())) {
        await limpar();
        return null;
      }

      return AdminDeviceCredencial(
        token: token,
        username: username,
        expiraEm: expiraEm,
      );
    } catch (_) {
      // Armazenamento inacessível: sem credencial utilizável (fail-safe).
      return null;
    }
  }

  Future<bool> possuiCredencial() async => (await lerAtiva()) != null;

  Future<void> limpar() async {
    await _remover(chaveToken);
    await _remover(chaveUsername);
    await _remover(chaveExpiraEm);
  }
}

class AdminDeviceCredencial {
  final String token;
  final String username;
  final DateTime expiraEm;

  const AdminDeviceCredencial({
    required this.token,
    required this.username,
    required this.expiraEm,
  });
}
