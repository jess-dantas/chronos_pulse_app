import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/session_storage.dart';
import '../../data/models/admin_models.dart';
import '../../data/repositories/admin_auth_repository.dart';

class AdminAuthProvider extends ChangeNotifier {
  final AdminAuthRepository _repository;
  final DioClient _dioClient;

  bool _isLoading = false;
  String? _errorMessage;
  AdminPlataformaModel? _currentAdmin;
  String? _accessToken;
  String? _refreshToken;
  String? _tempToken;
  bool _requiresTwoFactor = false;
  bool _setupRequired = false;
  bool? _bootstrapAvailable;
  List<String> _recoveryCodes = const [];

  // Estado 2FA (login)
  bool? _twoFactorEnabled;
  String? _twoFactorSecret;
  String? _twoFactorOtpauthUrl;

  /// Sessão restaurada ao abrir o app fica TRANCADA até a biometria local.
  /// Login explícito nasce desbloqueado; web não tem trava (kIsWeb).
  bool _sessaoDesbloqueada = true;

  /// Chaves locais da sessão admin (complementa o perfil em memória).
  static const String keyAdminAccessToken = 'chronos_admin_access_token';
  static const String keyAdminRefreshToken = 'chronos_admin_refresh_token';
  static const String keyAdminSessao = 'chronos_admin_sessao';

  AdminAuthProvider(this._repository, this._dioClient);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AdminPlataformaModel? get currentAdmin => _currentAdmin;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _currentAdmin != null && _accessToken != null;
  bool get requiresTwoFactor => _requiresTwoFactor;
  bool get setupRequired => _setupRequired;
  bool? get bootstrapAvailable => _bootstrapAvailable;
  List<String> get recoveryCodes => _recoveryCodes;
  String? get tempToken => _tempToken;
  bool? get twoFactorEnabled => _twoFactorEnabled;
  String? get twoFactorSecret => _twoFactorSecret;
  String? get twoFactorOtpauthUrl => _twoFactorOtpauthUrl;
  bool get sessaoDesbloqueada => _sessaoDesbloqueada;

  /// Token a enviar explicitamente quando não há sessão ativa
  /// (fluxo de bootstrap/setup com tempToken).
  String? get _bearerTemporario =>
      (_accessToken == null && _tempToken != null) ? _tempToken : null;

  /// Login admin. [senha] opcional (2FA-first): sem senha o backend exige
  /// 2FA habilitado e devolve `requiresTwoFactor` + `tempToken` direto.
  Future<bool> login(String username, {String? senha}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultado = await _repository.login(username, senha: senha);

      final requiresTwoFactor = resultado['requiresTwoFactor'] == true;
      if (requiresTwoFactor) {
        _requiresTwoFactor = true;
        _setupRequired = resultado['setupRequired'] == true;
        _tempToken = resultado['tempToken'] as String?;
        _isLoading = false;
        notifyListeners();
        return true; // aguardando código 2FA ou setup forçado
      }

      final accessToken = resultado['accessToken'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        await _aplicarSessao(resultado);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage =
          resultado['mensagem'] as String? ?? 'Revise suas credenciais';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// GET /admin/auth/bootstrap/status — true = primeira execução (tabela vazia).
  Future<void> carregarBootstrapStatus() async {
    try {
      final status = await _repository.bootstrapStatus();
      _bootstrapAvailable = status['bootstrapAvailable'] == true;
      notifyListeners();
    } catch (_) {
      // Indisponível não deve quebrar a tela de login.
      _bootstrapAvailable = false;
      notifyListeners();
    }
  }

  /// POST /admin/auth/bootstrap — cria o primeiro Administrator e devolve
  /// tempToken para o wizard de setup 2FA (forced).
  Future<bool> bootstrap({
    required String username,
    required String senha,
    required String nomeCompleto,
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultado = await _repository.bootstrap(
        username: username,
        senha: senha,
        nomeCompleto: nomeCompleto,
        email: email,
      );
      _requiresTwoFactor = resultado['requiresTwoFactor'] == true;
      _setupRequired = resultado['setupRequired'] == true;
      _tempToken = resultado['tempToken'] as String?;
      _bootstrapAvailable = false;
      _isLoading = false;
      notifyListeners();
      return _requiresTwoFactor && _tempToken != null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// POST /admin/auth/2fa/recover — acesso com código de recuperação; o
  /// backend devolve um novo conjunto de 8 códigos. [senha] opcional (o
  /// recovery code já autentica) e [novaSenha] opcional troca a senha no
  /// mesmo passo (R1).
  Future<bool> recuperar({
    required String username,
    String? senha,
    required String recoveryCode,
    String? novaSenha,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultado = await _repository.recover(
        username: username,
        senha: senha,
        recoveryCode: recoveryCode,
        novaSenha: novaSenha,
      );
      final accessToken = resultado['accessToken'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        _extrairRecoveryCodes(resultado);
        await _aplicarSessao(resultado);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Código de recuperação inválido';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void limparRecoveryCodes() {
    _recoveryCodes = const [];
    notifyListeners();
  }

  /// Envia o código TOTP do Google Authenticator para concluir o login.
  Future<bool> verifyTwoFactor(String codigo) async {
    final temp = _tempToken;
    if (temp == null || temp.isEmpty) {
      _errorMessage = 'Sessão 2FA expirada. Refaça o login.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultado = await _repository.verifyTwoFactor(temp, codigo);
      final accessToken = resultado['accessToken'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        await _aplicarSessao(resultado);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Verificação 2FA inválida';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Volta para o passo de usuário/senha (cancelar 2FA).
  void voltarParaLogin() {
    _requiresTwoFactor = false;
    _setupRequired = false;
    _tempToken = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.alterarSenha(senhaAtual, novaSenha);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> carregarStatusTwoFactor() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final status = await _repository.twoFactorStatus();
      _twoFactorEnabled = status['enabled'] == true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> iniciarSetupTwoFactor() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final setup =
          await _repository.twoFactorSetup(bearerToken: _bearerTemporario);
      _twoFactorSecret = setup['secret'] as String?;
      _twoFactorOtpauthUrl =
          (setup['otpauthUri'] ?? setup['otpauthUrl']) as String?;
      _isLoading = false;
      notifyListeners();
      return _twoFactorSecret != null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmarTwoFactor(String codigo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultado = await _repository.twoFactorConfirm(codigo,
          bearerToken: _bearerTemporario);
      _twoFactorEnabled = true;
      _twoFactorSecret = null;
      _twoFactorOtpauthUrl = null;
      _extrairRecoveryCodes(resultado);

      final accessToken = resultado['accessToken'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        // Confirm via tempToken (bootstrap/setup forçado): emite a sessão.
        await _aplicarSessao(resultado);
      } else {
        // Confirmação com sessão ativa (ativação pelo menu Segurança).
        _requiresTwoFactor = false;
        _setupRequired = false;
        _tempToken = null;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Desativa o 2FA exibindo um código TOTP válido do dispositivo atual.
  /// Retorna `true` quando a desativação é confirmada pelo backend.
  Future<bool> desabilitarTwoFactor(String codigo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.twoFactorDisable(codigo);
      _twoFactorEnabled = false;
      _twoFactorSecret = null;
      _twoFactorOtpauthUrl = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _extrairRecoveryCodes(Map<String, dynamic> resultado) {
    final codes = resultado['recoveryCodes'];
    if (codes is List) {
      _recoveryCodes = codes.map((c) => c.toString()).toList();
    } else {
      _recoveryCodes = const [];
    }
  }

  Future<void> _aplicarSessao(Map<String, dynamic> resultado) async {
    _currentAdmin = AdminPlataformaModel.fromJson(resultado);
    _accessToken = resultado['accessToken'] as String?;
    _refreshToken = resultado['refreshToken'] as String?;
    _requiresTwoFactor = false;
    _setupRequired = false;
    _tempToken = null;
    // Login explícito nasce desbloqueado (a trava só se aplica a sessão
    // restaurada ao abrir o app).
    _sessaoDesbloqueada = true;
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      _dioClient.updateAdminToken(_accessToken);
    }
    await _persistirSessao(resultado);
  }

  /// Grava tokens + perfil localmente para restauração no próximo app start.
  /// Persistência local é best-effort: falha aqui não derruba o login.
  Future<void> _persistirSessao(Map<String, dynamic> resultado) async {
    final access = resultado['accessToken'] as String?;
    final refresh = resultado['refreshToken'] as String?;
    try {
      if (access != null && access.isNotEmpty) {
        await SessionStorage.writeToken(keyAdminAccessToken, access);
      }
      if (refresh != null && refresh.isNotEmpty) {
        await SessionStorage.writeToken(keyAdminRefreshToken, refresh);
      }
      final perfil = Map<String, dynamic>.from(resultado)
        ..remove('accessToken')
        ..remove('refreshToken');
      await SessionStorage.writeToken(keyAdminSessao, jsonEncode(perfil));
    } catch (_) {
      // Sem storage (ambiente de teste): segue apenas em memória.
    }
  }

  /// Restaura a sessão admin salva localmente (app reaberto). A sessão
  /// restaurada nasce TRANCADA em apps nativos — exige o gate biométrico
  /// antes de liberar o conteúdo; web não tem trava.
  Future<void> restaurarSessao() async {
    try {
      final access = await SessionStorage.readToken(keyAdminAccessToken);
      final refresh = await SessionStorage.readToken(keyAdminRefreshToken);
      final perfilJson = await SessionStorage.readToken(keyAdminSessao);
      if (access == null ||
          access.isEmpty ||
          refresh == null ||
          refresh.isEmpty ||
          perfilJson == null ||
          perfilJson.isEmpty) {
        return;
      }
      final perfil = jsonDecode(perfilJson) as Map<String, dynamic>;
      _currentAdmin = AdminPlataformaModel.fromJson(perfil);
      _accessToken = access;
      _refreshToken = refresh;
      _sessaoDesbloqueada = kIsWeb;
      _dioClient.updateAdminToken(access);
      notifyListeners();
    } catch (_) {
      // Local inválido: mantém deslogado e deixa o login normal acontecer.
    }
  }

  /// Chamado pelo gate biométrico após a confirmação (ou liberação automática
  /// quando o aparelho não tem biometria cadastrada).
  void confirmarBiometria() {
    if (_sessaoDesbloqueada) return;
    _sessaoDesbloqueada = true;
    notifyListeners();
  }

  /// POST /admin/auth/2fa/email/send — envia OTP de 8 dígitos por e-mail
  /// (alternativa ao TOTP; exige tempToken do passo 2FA).
  Future<bool> enviarCodigoEmail() async {
    final temp = _tempToken;
    if (temp == null || temp.isEmpty) {
      _errorMessage = 'Sessão 2FA expirada. Refaça o login.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.sendEmailCode(temp);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// POST /admin/auth/2fa/email/verify — valida o OTP de 8 dígitos e emite
  /// a sessão (mesmo resultado do verifyTwoFactor).
  Future<bool> verifyEmailCode(String codigo) async {
    final temp = _tempToken;
    if (temp == null || temp.isEmpty) {
      _errorMessage = 'Sessão 2FA expirada. Refaça o login.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultado = await _repository.verifyEmailCode(temp, codigo);
      final accessToken = resultado['accessToken'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        await _aplicarSessao(resultado);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Verificação 2FA inválida';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// POST /admin/auth/refresh — rotação de tokens (usada pelo handler de
  /// 401 do DioClient em requisições `/admin/`). `false` = sem refresh
  /// ou falha (sessão encerrada na prática).
  Future<bool> renovarSessao() async {
    final refresh = _refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final novo = await _repository.refresh(refresh);
      final access = novo['accessToken'] as String?;
      if (access == null || access.isEmpty) return false;
      _accessToken = access;
      _refreshToken = (novo['refreshToken'] as String?) ?? _refreshToken;
      _dioClient.updateAdminToken(access);
      try {
        await SessionStorage.writeToken(keyAdminAccessToken, _accessToken!);
        if (_refreshToken != null && _refreshToken!.isNotEmpty) {
          await SessionStorage.writeToken(keyAdminRefreshToken, _refreshToken!);
        }
      } catch (_) {
        // Local é best-effort.
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    final refresh = _refreshToken;
    _currentAdmin = null;
    _accessToken = null;
    _refreshToken = null;
    _tempToken = null;
    _requiresTwoFactor = false;
    _setupRequired = false;
    _recoveryCodes = const [];
    _sessaoDesbloqueada = true;
    _dioClient.updateAdminToken(null);
    await _apagarSessaoLocal();
    notifyListeners();
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _repository.logout(refresh);
      } catch (_) {
        // Logout no backend é best-effort.
      }
    }
  }

  Future<void> _apagarSessaoLocal() async {
    try {
      await SessionStorage.removeToken(keyAdminAccessToken);
      await SessionStorage.removeToken(keyAdminRefreshToken);
      await SessionStorage.removeToken(keyAdminSessao);
    } catch (_) {
      // Local é best-effort.
    }
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}