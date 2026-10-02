import '../security/session_storage.dart';

/// Vínculo de dispositivo ativo (bater ponto sem login por 7 dias).
class VinculoDispositivo {
  final String token;
  final String cpcId;
  final String nome;
  final DateTime expiraEm;

  /// CPF do dono do vínculo (vazio em vínculos antigos, gravados antes do
  /// campo). Serve para detectar troca de dono no aparelho: outro CPF no
  /// login invalida o vínculo.
  final String cpf;

  const VinculoDispositivo({
    required this.token,
    required this.cpcId,
    required this.nome,
    required this.expiraEm,
    this.cpf = '',
  });
}

/// Persiste o `deviceToken` emitido por `POST /auth/device/vincular`.
///
/// O vínculo é INDEPENDENTE da sessão: o logout de usuário não o remove (é
/// exatamente para isso que ele serve — bater ponto sem login). A remoção
/// acontece em três casos: desativação explícita no perfil, expiração local
/// (7 dias) ou token inválido no servidor.
///
/// Usa o mesmo armazenamento seguro do resto da sessão (Keystore/Keychain no
/// nativo; SharedPreferences na Web). As funções de leitura/gravação são
/// injetáveis para permitir testes unitários sem os plugins de plataforma.
class DeviceTokenStore {
  DeviceTokenStore({
    Future<String?> Function(String key)? ler,
    Future<void> Function(String key, String value)? gravar,
    Future<void> Function(String key)? remover,
  })  : _ler = ler ?? SessionStorage.readToken,
        _gravar = gravar ?? SessionStorage.writeToken,
        _remover = remover ?? SessionStorage.removeToken;

  static final DeviceTokenStore instancia = DeviceTokenStore();

  static const String chaveToken = 'chronos_device_token';
  static const String chaveCpcId = 'chronos_device_cpc_id';
  static const String chaveNome = 'chronos_device_nome';
  static const String chaveExpiraEm = 'chronos_device_expira_em';

  /// CPF do dono do vínculo — sobrevive ao logout junto com o vínculo.
  static const String chaveCpf = 'chronos_device_cpf';

  /// Se o DONO do vínculo tem o 2FA habilitado (gravado na ativação e
  /// sincronizado pelo `device/status`). Define se o modo sem login cobra o
  /// código na etapa 2 (ordem: biometria → 2FA → vínculo).
  static const String chaveTwoFactor = 'chronos_device_2fa';

  final Future<String?> Function(String key) _ler;
  final Future<void> Function(String key, String value) _gravar;
  final Future<void> Function(String key) _remover;

  Future<void> salvar({
    required String token,
    required String cpcId,
    required String nome,
    required DateTime expiraEm,
    String cpf = '',
  }) async {
    await _gravar(chaveToken, token);
    await _gravar(chaveCpcId, cpcId);
    await _gravar(chaveNome, nome);
    await _gravar(chaveExpiraEm, expiraEm.toUtc().millisecondsSinceEpoch.toString());
    await _gravar(chaveCpf, cpf);
  }

  /// Vínculo vigente, ou `null` quando não existe/expirou (a expiração local
  /// também limpa os resíduos — um token vencido não fica no dispositivo).
  Future<VinculoDispositivo?> lerAtivo() async {
    try {
      final token = await _ler(chaveToken);
      if (token == null || token.isEmpty) return null;

      final cpcId = await _ler(chaveCpcId);
      final expiraRaw = await _ler(chaveExpiraEm);
      final expiraMs = int.tryParse(expiraRaw ?? '');
      if (cpcId == null || cpcId.isEmpty || expiraMs == null) {
        await limpar();
        return null;
      }

      final expiraEm = DateTime.fromMillisecondsSinceEpoch(expiraMs, isUtc: true);
      if (!expiraEm.isAfter(DateTime.now().toUtc())) {
        await limpar();
        return null;
      }

      return VinculoDispositivo(
        token: token,
        cpcId: cpcId,
        nome: await _ler(chaveNome) ?? '',
        expiraEm: expiraEm,
        cpf: await _ler(chaveCpf) ?? '',
      );
    } catch (_) {
      // Armazenamento inacessível: sem vínculo utilizável (fail-safe).
      return null;
    }
  }

  Future<bool> vinculoAtivo() async => (await lerAtivo()) != null;

  /// Persiste se o modo sem login deve exigir o código do 2FA a cada uso.
  Future<void> salvarTwoFactor(bool ativo) =>
      _gravar(chaveTwoFactor, ativo ? 'true' : 'false');

  /// `true` quando o dono do vínculo atual tem o 2FA habilitado
  /// (padrão `false`: só cobra o código se a ativação/servidor disser).
  Future<bool> lerTwoFactor() async {
    try {
      return await _ler(chaveTwoFactor) == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> limpar() async {
    await _remover(chaveToken);
    await _remover(chaveCpcId);
    await _remover(chaveNome);
    await _remover(chaveExpiraEm);
    await _remover(chaveCpf);
    await _remover(chaveTwoFactor);
  }
}
