import 'package:flutter/material.dart';
import '../../data/models/colaborador_model.dart';
import '../../data/repositories/colaborador_repository.dart';

class ColaboradorProvider extends ChangeNotifier {
  final ColaboradorRepository _repository;

  List<ColaboradorModel> _colaboradores = [];
  bool _isLoading = false;
  String? _errorMessage;

  ColaboradorProvider(this._repository);

  List<ColaboradorModel> get colaboradores => _colaboradores;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> carregarColaboradores() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _colaboradores = await _repository.listarColaboradores();
    } catch (e) {
      _errorMessage = 'Erro ao carregar colaboradores: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cadastrarColaborador({
    required String cpf,
    required String nome,
    required String emailCorporativo,
    required String senha,
    String? matricula,
    String? cargo,
    String? departamento,
    required String dataNascimento,
    required String dataAdmissao,
    String? tenantId,
    bool acessoEstoque = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.cadastrarColaborador(
        cpf: cpf,
        nome: nome,
        emailCorporativo: emailCorporativo,
        senha: senha,
        matricula: matricula,
        cargo: cargo,
        departamento: departamento,
        dataNascimento: dataNascimento,
        dataAdmissao: dataAdmissao,
        tenantId: tenantId,
        acessoEstoque: acessoEstoque,
      );
      await carregarColaboradores();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao cadastrar colaborador: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
