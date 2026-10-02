import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/mensagens_erro.dart';
import '../../../../core/security/biometria_preferences.dart';
import '../../../../core/security/session_storage.dart';
import '../../../../core/telemetry/telemetry_service.dart';
import '../../../ponto/data/datasources/ponto_local_datasource.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final TelemetryService? _telemetria;
  final PontoLocalDataSource? _pontoLocalDataSource;
  UsuarioModel? _usuario;
  bool _isLoading = false;
  String? _errorMessage;
  static const keyAccessToken = 'chronos_access_token';
  static const keyRefreshToken = 'chronos_refresh_token';
  static const _keyRole = 'chronos_role';
  static const _keyNome = 'chronos_nome';
  static const _keyEmail = 'chronos_email';
  static const _keyCpf = 'chronos_cpf';
  static const _keyTenantId = 'chronos_tenant_id';
  static const _keyTenantSlug = 'chronos_tenant_slug';
  static const _keyCpcId = 'chronos_cpc_id';
  static const _keyColaboradorId = 'chronos_colaborador_id';
  static const _keyAcessoEstoque = 'chronos_acesso_estoque';
  static const _keyModulos = 'chronos_modulos';
  static const _keySessionInicio = 'chronos_session_inicio';
  static const _keyFoto = 'chronos_foto';

  /// Tempo de inatividade antes de encerrar a sessão.
  static const Duration idleTimeout = Duration(minutes: 15);

  /// Limite absoluto de duração da sessão desde o login.
  static const Duration sessaoMaxima = Duration(hours: 8);

  Timer? _idleTimer;
  String? _motivoEncerramento;
  int _ultimaAtividade = 0;

  /// Gate biométrico de abertura (login por biometria): sessão RESTORIDA ao
  /// abrir o app exige confirmação biométrica antes de liberar o conteúdo;
  /// login explícito por senha já nasce desbloqueado. Só vive em memória —
  /// cada nova abertura do app cobra a biometria de novo.
  bool _sessaoDesbloqueada = true;

  /// 2FA-first: estado da segunda etapa entre o login e a verificação do
  /// código (TOTP ou OTP por e-mail). Vive só em memória.
  bool _requiresTwoFactor = false;
  String? _tempToken;

  AuthProvider(this._authRepository,
      {TelemetryService? telemetria,
      PontoLocalDataSource? pontoLocalDataSource})
      : _telemetria = telemetria,
        _pontoLocalDataSource = pontoLocalDataSource;

  UsuarioModel? get usuario => _usuario;
  bool get isAuthenticated => _usuario != null && _usuario!.token.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get sessaoDesbloqueada => _sessaoDesbloqueada;

  /// `true` quando o login parou na etapa de 2FA (usuário precisa digitar o
  /// código em `/login/2fa`); [tempToken] é a credencial de 5 minutos.
  bool get requiresTwoFactor => _requiresTwoFactor;
  String? get tempToken => _tempToken;

  /// Confirmação biométrica bem-sucedida (ou liberação do gate): libera o
  /// conteúdo da sessão e reavalia o roteador.
  void confirmarBiometria() {
    if (_sessaoDesbloqueada) return;
    _sessaoDesbloqueada = true;
    notifyListeners();
  }

  /// Registra atividade do usuário e rearma o timer de inatividade.
  void registrarAtividade() {
    if (!isAuthenticated) return;
    _ultimaAtividade = DateTime.now().millisecondsSinceEpoch;
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, _encerrarPorInatividade);
  }

  /// Verifica a inatividade após voltar de um background (ex.: app minimizado).
  void verificarInatividade() {
    if (!isAuthenticated) return;
    final agora = DateTime.now().millisecondsSinceEpoch;
    if (_ultimaAtividade > 0 &&
        agora - _ultimaAtividade >= idleTimeout.inMilliseconds) {
      _encerrarPorInatividade();
    } else {
      registrarAtividade();
    }
  }

  /// Consome (e limpa) o motivo de encerramento da sessão, se houver.
  String? consumirMotivoEncerramento() {
    final motivo = _motivoEncerramento;
    _motivoEncerramento = null;
    return motivo;
  }

  void _encerrarPorInatividade() {
    _motivoEncerramento =
        'Sua sessão expirou por inatividade. Por segurança, faça login novamente.';
    logout();
  }

  bool _sessaoAbsolutaExpirada(int sessionInicio) {
    final agora = DateTime.now().millisecondsSinceEpoch;
    return sessionInicio > 0 &&
        agora - sessionInicio >= sessaoMaxima.inMilliseconds;
  }

  Future<void> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await SessionStorage.readToken(keyAccessToken);
    final refreshToken = await SessionStorage.readToken(keyRefreshToken);
    final sessionInicio = prefs.getInt(_keySessionInicio) ?? 0;

    if (_sessaoAbsolutaExpirada(sessionInicio)) {
      _motivoEncerramento =
          'Sua sessão expirou. Para sua segurança, faça login novamente.';
      await _clearSession();
      notifyListeners();
      return;
    }

    if (token != null &&
        token.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty) {
      // Sessão restaurada ao abrir o app: exige biometria antes de liberar
      // o conteúdo (login por biometria — só em memória, nesta abertura),
      // salvo quando o bloqueio foi desligado em Segurança.
      _sessaoDesbloqueada = !(prefs.getBool(BiometriaPreferences.chave) ?? true);
      final nome = await _lerPerfil(_keyNome) ?? '';
      final email = await _lerPerfil(_keyEmail) ?? '';
      final cpf = await _lerPerfil(_keyCpf);
      final foto = await _lerPerfil(_keyFoto);
      final colaboradorId =
          prefs.getString(_keyColaboradorId) ?? prefs.getString(_keyCpcId);
      _usuario = UsuarioModel(
        token: token,
        refreshToken: refreshToken,
        tipo: 'Bearer',
        nome: nome,
        email: email,
        cpf: cpf,
        role: prefs.getString(_keyRole) ?? '',
        tenantId: prefs.getString(_keyTenantId),
        tenantSlug: prefs.getString(_keyTenantSlug),
        cpcId: prefs.getString(_keyCpcId),
        colaboradorId: colaboradorId,
        acessoEstoque: prefs.getBool(_keyAcessoEstoque) ?? false,
        foto: foto,
        modulos: prefs.getStringList(_keyModulos) ?? const [],
      );
      _authRepository.updateToken(token);

      try {
        final refreshed = await _authRepository.refreshToken(refreshToken);
        _usuario = UsuarioModel(
          token: refreshed.token,
          refreshToken: refreshToken,
          tipo: 'Bearer',
          nome: refreshed.nome,
          email: refreshed.email,
          cpf: refreshed.cpf ?? cpf,
          role: refreshed.role,
          tenantId: refreshed.tenantId,
          tenantSlug: refreshed.tenantSlug ?? prefs.getString(_keyTenantSlug),
          cpcId: refreshed.cpcId,
          colaboradorId:
              refreshed.colaboradorId ?? refreshed.cpcId ?? colaboradorId,
          acessoEstoque: refreshed.acessoEstoque,
          foto: refreshed.foto ?? foto,
          modulos: refreshed.modulos.isNotEmpty
              ? refreshed.modulos
              : (prefs.getStringList(_keyModulos) ?? const []),
        );
        _authRepository.updateToken(refreshed.token);
        await _saveSession(_usuario!);
      } on FalhaDeRedeException {
        // Offline: mantém a sessão local restaurada (linhas acima). A
        // identidade não pode se perder por falha de conexão — o refresh
        // será refeito pelo interceptor assim que a rede voltar.
      } catch (_) {
        // Servidor rejeitou/erro real: exige login novamente.
        await _clearSession();
      }
      notifyListeners();
      if (isAuthenticated) {
        registrarAtividade();
      }
    }
  }

  /// Atualiza a sessão em memória após um refresh de token disparado
  /// pelo interceptor do cliente HTTP (R03).
  void restaurarSessaoAposRefresh(UsuarioModel renovado) {
    final atual = _usuario;
    if (atual != null) {
      _usuario = UsuarioModel(
        token: renovado.token,
        refreshToken: renovado.refreshToken ?? atual.refreshToken,
        tipo: 'Bearer',
        nome: renovado.nome.isNotEmpty ? renovado.nome : atual.nome,
        email: renovado.email.isNotEmpty ? renovado.email : atual.email,
        cpf: renovado.cpf ?? atual.cpf,
        role: renovado.role.isNotEmpty ? renovado.role : atual.role,
        tenantId: renovado.tenantId ?? atual.tenantId,
        tenantSlug: renovado.tenantSlug ?? atual.tenantSlug,
        cpcId: renovado.cpcId ?? atual.cpcId,
        colaboradorId: renovado.colaboradorId ??
            renovado.cpcId ??
            atual.colaboradorId ??
            atual.cpcId,
        acessoEstoque: renovado.acessoEstoque,
        foto: renovado.foto ?? atual.foto,
        modulos: renovado.modulos.isNotEmpty ? renovado.modulos : atual.modulos,
      );
    }
    notifyListeners();
  }

  Future<bool> login(String cpf, String senha) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final usuario = await _authRepository.login(cpf: cpf, senha: senha);

      // 2FA-first: sem tokens finais — guarda o tempToken (5 min) e manda a
      // tela /login/2fa pedir o código (TOTP ou OTP por e-mail).
      if (usuario.requiresTwoFactor) {
        _requiresTwoFactor = true;
        _tempToken = usuario.tempToken;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      return await _concluirLogin(usuario, cpfFallback: cpf);
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Etapa 2 do 2FA-first por TOTP (6 dígitos).
  Future<bool> verificarTwoFactor(String codigo) {
    return _verificarCodigoTwoFactor(codigo, porEmail: false);
  }

  /// Etapa 2 do 2FA-first por OTP de e-mail (8 dígitos).
  Future<bool> verificarCodigoEmailTwoFactor(String codigo) {
    return _verificarCodigoTwoFactor(codigo, porEmail: true);
  }

  Future<bool> _verificarCodigoTwoFactor(String codigo,
      {required bool porEmail}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final tempToken = _tempToken;
    if (tempToken == null || tempToken.isEmpty) {
      _requiresTwoFactor = false;
      _isLoading = false;
      _errorMessage = 'Sessão expirada. Refaça o login.';
      notifyListeners();
      return false;
    }

    try {
      final usuario = await _authRepository.twoFactorVerify(
        tempToken: tempToken,
        codigo: codigo,
        porEmail: porEmail,
      );
      return await _concluirLogin(usuario);
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Envia o OTP de 8 dígitos para o e-mail do usuário (etapa alternativa do
  /// 2FA-first). Devolve `null` em sucesso ou a mensagem de erro.
  Future<String?> enviarCodigoEmailTwoFactor() async {
    final tempToken = _tempToken;
    if (tempToken == null || tempToken.isEmpty) {
      return 'Sessão expirada. Refaça o login.';
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.twoFactorEmailSend(tempToken: tempToken);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return _errorMessage;
    }
  }

  /// Cancela a etapa 2 pendente (voltar do `/login/2fa` para o login).
  void cancelarTwoFactor() {
    _requiresTwoFactor = false;
    _tempToken = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _concluirLogin(UsuarioModel usuario,
      {String? cpfFallback}) async {
    if ((usuario.cpf == null || usuario.cpf!.isEmpty) &&
        cpfFallback != null) {
      _usuario = usuario.copyWith(cpf: cpfFallback);
    } else {
      _usuario = usuario;
    }
    await _saveSession(_usuario!);
    await _marcarInicioSessao();
    // Autenticação explícita por senha/código: não cobra biometria de novo.
    _sessaoDesbloqueada = true;
    _requiresTwoFactor = false;
    _tempToken = null;
    _isLoading = false;
    notifyListeners();
    registrarAtividade();
    _telemetria?.registrarLoginSucesso();
    return true;
  }

  /// Consulta se o 2FA do usuário logado está habilitado (`null` em erro,
  /// com a mensagem em [errorMessage]).
  Future<bool?> carregarStatusTwoFactor() async {
    try {
      return await _authRepository.twoFactorStatus();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Gera o segredo TOTP pendente (etapa 1 da ativação). `null` em erro.
  Future<Map<String, String>?> iniciarSetupTwoFactor() async {
    _errorMessage = null;
    try {
      return await _authRepository.twoFactorSetup();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Confirma o código TOTP e **ativa** o 2FA. `false` em erro.
  Future<bool> confirmarTwoFactor(String codigo) async {
    _errorMessage = null;
    try {
      await _authRepository.twoFactorConfirm(codigo: codigo);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Desativa o 2FA (exige código TOTP válido). `false` em erro.
  Future<bool> desabilitarTwoFactor(String codigo) async {
    _errorMessage = null;
    try {
      await _authRepository.twoFactorDisable(codigo: codigo);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> cadastrarEmpresa({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _usuario = await _authRepository.cadastrarEmpresa(
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
      if (_usuario!.cpf == null || _usuario!.cpf!.isEmpty) {
        _usuario = _usuario!.copyWith(cpf: responsavelCpf);
      }
      await _saveSession(_usuario!);
      await _marcarInicioSessao();
      // Cadastro concluído = autenticação explícita: não cobra biometria.
      _sessaoDesbloqueada = true;
      _isLoading = false;
      notifyListeners();
      registrarAtividade();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> alterarSenha({
    required String novaSenha,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.alterarSenha(
        novaSenha: novaSenha,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<String?> esqueciSenha(String cpf) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final mensagem = await _authRepository.esqueciSenha(cpf: cpf);
      _isLoading = false;
      notifyListeners();
      return mensagem;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> redefinirSenha({
    required String cpf,
    required String codigo,
    required String novaSenha,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.redefinirSenha(
        cpf: cpf,
        codigo: codigo,
        novaSenha: novaSenha,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> enviarFoto(List<int> bytes, String nomeArquivo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final foto = await _authRepository.enviarFoto(bytes, nomeArquivo);
      final atual = _usuario;
      if (atual != null) {
        _usuario = atual.copyWith(foto: foto);
        await _saveSession(_usuario!);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Ativa o vínculo de dispositivo do app (modo "bater ponto sem login" por
  /// 7 dias, mobile only). Devolve a data de expiração, ou `null` em erro
  /// (mensagem em [errorMessage]).
  Future<DateTime?> ativarVinculoDispositivo({String? deviceName}) async {
    final usuario = _usuario;
    if (usuario == null) return null;
    try {
      final cpcId = usuario.colaboradorId ?? usuario.cpcId;
      if (cpcId == null || cpcId.isEmpty) {
        throw Exception('Sessão sem identificação de colaborador.');
      }
      final vinculo = await _authRepository.vincularDevice(
        cpcId: cpcId,
        nome: usuario.nome,
        deviceName: deviceName,
      );
      return vinculo.expiraEm;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Desativa os vínculos de dispositivo da conta no servidor e limpa o
  /// armazenamento local. `false` = erro (mensagem em [errorMessage]).
  Future<bool> desativarVinculoDispositivo() async {
    try {
      await _authRepository.revogarDevice();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _idleTimer?.cancel();
    _authRepository.logout();
    _usuario = null;
    _errorMessage = null;
    _requiresTwoFactor = false;
    _tempToken = null;
    await _clearSession();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _marcarInicioSessao() async {
    final prefs = await SharedPreferences.getInstance();
    final inicio = DateTime.now().millisecondsSinceEpoch;
    if (prefs.getInt(_keySessionInicio) == null) {
      await prefs.setInt(_keySessionInicio, inicio);
    }
  }

  Future<void> _saveSession(UsuarioModel usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await SessionStorage.writeToken(keyAccessToken, usuario.token);
    if (usuario.refreshToken != null) {
      await SessionStorage.writeToken(keyRefreshToken, usuario.refreshToken!);
    }
    await prefs.setString(_keyRole, usuario.role);
    await _salvarPerfil(_keyNome, usuario.nome);
    await _salvarPerfil(_keyEmail, usuario.email);
    await _salvarPerfil(_keyCpf, usuario.cpf);
    if (usuario.tenantId != null) {
      await prefs.setString(_keyTenantId, usuario.tenantId!);
    }
    if (usuario.tenantSlug != null && usuario.tenantSlug!.isNotEmpty) {
      await prefs.setString(_keyTenantSlug, usuario.tenantSlug!);
    }
    if (usuario.cpcId != null) await prefs.setString(_keyCpcId, usuario.cpcId!);
    final colaboradorId = usuario.colaboradorId ?? usuario.cpcId;
    if (colaboradorId != null) {
      await prefs.setString(_keyColaboradorId, colaboradorId);
    } else {
      await prefs.remove(_keyColaboradorId);
    }
    await prefs.setBool(_keyAcessoEstoque, usuario.acessoEstoque);
    await _salvarPerfil(_keyFoto, usuario.foto);
    if (usuario.modulos.isNotEmpty) {
      await prefs.setStringList(_keyModulos, usuario.modulos);
    }
  }

  /// Limpa os dados locais do dispositivo (sessão + fila offline de pontos).
  Future<void> limparDadosLocais() async {
    await _clearSession();
    try {
      await _pontoLocalDataSource?.limparPontosLocais();
    } catch (_) {
      // Limpeza local é best-effort (LGPD): falha não pode bloquear o logout.
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await SessionStorage.removeToken(keyAccessToken);
    await SessionStorage.removeToken(keyRefreshToken);
    await _removerPerfil(_keyNome);
    await _removerPerfil(_keyEmail);
    await _removerPerfil(_keyCpf);
    await _removerPerfil(_keyFoto);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyTenantId);
    await prefs.remove(_keyTenantSlug);
    await prefs.remove(_keyCpcId);
    await prefs.remove(_keyColaboradorId);
    await prefs.remove(_keyAcessoEstoque);
    await prefs.remove(_keyModulos);
    await prefs.remove(_keySessionInicio);
    try {
      // Logout/expiração preserva a fila offline de pontos (offline-first:
      // batidas não sincronizadas são reenviadas após o próximo login);
      // só o histórico já sincronizado sai do dispositivo.
      await _pontoLocalDataSource?.limparPontosSincronizadosLocais();
    } catch (_) {
      // Limpeza local é best-effort (LGPD): falha não pode bloquear o logout.
    }
  }

  /// Perfis sensíveis (nome/e-mail/CPF/foto) ficam no armazenamento seguro
  /// (Keystore/Keychain no nativo; SharedPreferences na Web). Leitura sem
  /// travar a restauração de sessão quando o armazenamento seguro falhar.
  static Future<String?> _lerPerfil(String key) async {
    try {
      return await SessionStorage.readToken(key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _salvarPerfil(String key, String? valor) async {
    if (valor == null || valor.isEmpty) return;
    try {
      await SessionStorage.writeToken(key, valor);
    } catch (_) {
      // Best-effort: falha no armazenamento seguro não impede o login.
    }
  }

  static Future<void> _removerPerfil(String key) async {
    try {
      await SessionStorage.removeToken(key);
    } catch (_) {
      // Best-effort: falha na remoção não impede o logout.
    }
  }
}
