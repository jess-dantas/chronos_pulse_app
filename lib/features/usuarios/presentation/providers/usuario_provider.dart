import 'package:flutter/material.dart';
import '../../data/models/usuario_conta_model.dart';
import '../../data/repositories/usuario_repository.dart';

/// Gestão de contas administrativas da empresa (listar/criar/suspender)
/// — restrita ao ADMIN_EMPRESA no backend (`UsuarioController`).
class UsuarioProvider extends ChangeNotifier {
  final UsuarioRepository _repository;

  List<UsuarioContaModel> _usuarios = [];
  bool _isLoading = false;
  String? _errorMessage;

  UsuarioProvider(this._repository);

  List<UsuarioContaModel> get usuarios => _usuarios;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> carregarUsuarios() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _usuarios = await _repository.listar();
    } catch (e) {
      _errorMessage = 'Erro ao carregar usuários: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UsuarioContaModel?> criarUsuario({
    required String cpf,
    required String nome,
    String? emailCorporativo,
    required String senha,
    required String papel,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final criado = await _repository.criar(
        cpf: cpf,
        nome: nome,
        emailCorporativo: emailCorporativo,
        senha: senha,
        papel: papel,
      );
      await carregarUsuarios();
      return criado;
    } catch (e) {
      _errorMessage = 'Erro ao criar usuário: ${e.toString()}';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> suspenderUsuario(String usuarioId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.suspender(usuarioId);
      await carregarUsuarios();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao suspender usuário: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
