import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_client.dart';
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

  /// Token a enviar explicitamente quando não há sessão ativa
  /// (fluxo de bootstrap/setup com tempToken).
  String? get _bearerTemporario =>
      (_accessToken == null && _tempToken != null) ? _tempToken : null;

  Future<bool> login(String username, String senha) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultado = await _repository.login(username, senha);

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
        _aplicarSessao(resultado);
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

  /// POST /admin/auth/2fa/recover — acesso com código de recuperação;
  /// o backend devolve um novo conjunto de 8 códigos.
  Future<bool> recuperar({
    required String username,
    required String senha,
    required String recoveryCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultado = await _repository.recover(
        username: username,
        senha: senha,
        recoveryCode: recoveryCode,
      );
      final accessToken = resultado['accessToken'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        _extrairRecoveryCodes(resultado);
        _aplicarSessao(resultado);
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
        _aplicarSessao(resultado);
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
        _aplicarSessao(resultado);
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

  void _extrairRecoveryCodes(Map<String, dynamic> resultado) {
    final codes = resultado['recoveryCodes'];
    if (codes is List) {
      _recoveryCodes = codes.map((c) => c.toString()).toList();
    } else {
      _recoveryCodes = const [];
    }
  }

  void _aplicarSessao(Map<String, dynamic> resultado) {
    _currentAdmin = AdminPlataformaModel.fromJson(resultado);
    _accessToken = resultado['accessToken'] as String?;
    _refreshToken = resultado['refreshToken'] as String?;
    _requiresTwoFactor = false;
    _setupRequired = false;
    _tempToken = null;
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      _dioClient.updateAdminToken(_accessToken);
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
    _dioClient.updateAdminToken(null);
    notifyListeners();
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _repository.logout(refresh);
      } catch (_) {
        // Logout no backend é best-effort.
      }
    }
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}