import 'package:flutter/material.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  UsuarioModel? _usuario;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._authRepository);

  UsuarioModel? get usuario => _usuario;
  bool get isAuthenticated => _usuario != null && _usuario!.token.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String cpf, String senha) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _usuario = await _authRepository.login(cpf: cpf, senha: senha);
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

  void logout() {
    _authRepository.logout();
    _usuario = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
