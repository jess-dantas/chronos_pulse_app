import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  UsuarioModel? _usuario;
  bool _isLoading = false;
  String? _errorMessage;
  static const _keyToken = 'chronos_access_token';
  static const _keyRefreshToken = 'chronos_refresh_token';
  static const _keyRole = 'chronos_role';
  static const _keyNome = 'chronos_nome';
  static const _keyEmail = 'chronos_email';
  static const _keyTenantId = 'chronos_tenant_id';
  static const _keyCpcId = 'chronos_cpc_id';
  static const _keyAcessoEstoque = 'chronos_acesso_estoque';
  static const _keySessionInicio = 'chronos_session_inicio';

  /// Tempo de inatividade antes de encerrar a sessão.
  static const Duration idleTimeout = Duration(minutes: 15);

  /// Limite absoluto de duração da sessão desde o login.
  static const Duration sessaoMaxima = Duration(hours: 8);

  Timer? _idleTimer;
  String? _motivoEncerramento;
  int _ultimaAtividade = 0;

  AuthProvider(this._authRepository);

  UsuarioModel? get usuario => _usuario;
  bool get isAuthenticated => _usuario != null && _usuario!.token.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
    if (_ultimaAtividade > 0 && agora - _ultimaAtividade >= idleTimeout.inMilliseconds) {
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
    _motivoEncerramento = 'Sua sessão expirou por inatividade. Por segurança, faça login novamente.';
    logout();
  }

  bool _sessaoAbsolutaExpirada(int sessionInicio) {
    final agora = DateTime.now().millisecondsSinceEpoch;
    return sessionInicio > 0 && agora - sessionInicio >= sessaoMaxima.inMilliseconds;
  }

  Future<void> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final refreshToken = prefs.getString(_keyRefreshToken);
    final sessionInicio = prefs.getInt(_keySessionInicio) ?? 0;

    if (_sessaoAbsolutaExpirada(sessionInicio)) {
      _motivoEncerramento =
          'Sua sessão expirou. Para sua segurança, faça login novamente.';
      await _clearSession();
      notifyListeners();
      return;
    }

    if (token != null && token.isNotEmpty && refreshToken != null && refreshToken.isNotEmpty) {
      _usuario = UsuarioModel(
        token: token,
        refreshToken: refreshToken,
        tipo: 'Bearer',
        nome: prefs.getString(_keyNome) ?? '',
        email: prefs.getString(_keyEmail) ?? '',
        role: prefs.getString(_keyRole) ?? '',
        tenantId: prefs.getString(_keyTenantId),
        cpcId: prefs.getString(_keyCpcId),
        acessoEstoque: prefs.getBool(_keyAcessoEstoque) ?? false,
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
          role: refreshed.role,
          tenantId: refreshed.tenantId,
          cpcId: refreshed.cpcId,
          acessoEstoque: refreshed.acessoEstoque,
        );
        _authRepository.updateToken(refreshed.token);
        await _saveSession(_usuario!);
      } catch (_) {
        await _clearSession();
      }
      notifyListeners();
      if (isAuthenticated) {
        registrarAtividade();
      }
    }
  }

  Future<bool> login(String cpf, String senha) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _usuario = await _authRepository.login(cpf: cpf, senha: senha);
      await _saveSession(_usuario!);
      await _marcarInicioSessao();
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

  Future<bool> cadastrarEmpresa({
    required String cnpj,
    required String nomeEmpresa,
    required String responsavelNome,
    required String responsavelCpf,
    required String responsavelEmail,
    String? responsavelCelular,
    required String responsavelSenha,
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
        responsavelCelular: responsavelCelular,
        responsavelSenha: responsavelSenha,
      );
      await _saveSession(_usuario!);
      await _marcarInicioSessao();
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

  Future<void> logout() async {
    _idleTimer?.cancel();
    _authRepository.logout();
    _usuario = null;
    _errorMessage = null;
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
    await prefs.setString(_keyToken, usuario.token);
    if (usuario.refreshToken != null) {
      await prefs.setString(_keyRefreshToken, usuario.refreshToken!);
    }
    await prefs.setString(_keyRole, usuario.role);
    await prefs.setString(_keyNome, usuario.nome);
    await prefs.setString(_keyEmail, usuario.email);
    if (usuario.tenantId != null) await prefs.setString(_keyTenantId, usuario.tenantId!);
    if (usuario.cpcId != null) await prefs.setString(_keyCpcId, usuario.cpcId!);
    await prefs.setBool(_keyAcessoEstoque, usuario.acessoEstoque);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyNome);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyTenantId);
    await prefs.remove(_keyCpcId);
    await prefs.remove(_keyAcessoEstoque);
    await prefs.remove(_keySessionInicio);
  }
}
