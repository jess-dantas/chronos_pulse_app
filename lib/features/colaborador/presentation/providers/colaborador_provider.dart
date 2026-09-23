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

  Future<ColaboradorModel?> cadastrarColaborador({
    required String cpf,
    required String nome,
    String? emailCorporativo,
    String? celular,
    required String senha,
    String? matricula,
    String? cargo,
    String? departamento,
    required String dataNascimento,
    required String dataAdmissao,
    String? dataDesligamento,
    String? tenantId,
    bool acessoEstoque = false,
    bool acessoPatrimonio = false,
    bool acessoFrota = false,
    bool acessoProtocolo = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final criado = await _repository.cadastrarColaborador(
        cpf: cpf,
        nome: nome,
        emailCorporativo: emailCorporativo,
        celular: celular,
        senha: senha,
        matricula: matricula,
        cargo: cargo,
        departamento: departamento,
        dataNascimento: dataNascimento,
        dataAdmissao: dataAdmissao,
        dataDesligamento: dataDesligamento,
        tenantId: tenantId,
        acessoEstoque: acessoEstoque,
        acessoPatrimonio: acessoPatrimonio,
        acessoFrota: acessoFrota,
        acessoProtocolo: acessoProtocolo,
      );
      await carregarColaboradores();
      return criado;
    } catch (e) {
      _errorMessage = 'Erro ao cadastrar colaborador: ${e.toString()}';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<String>?> listarModulosUsuario(
      String usuarioId, String tenantId) async {
    try {
      return await _repository.listarModulosUsuario(usuarioId, tenantId);
    } catch (e) {
      _errorMessage = 'Erro ao carregar módulos: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  Future<bool> atualizarModulosUsuario(
      String usuarioId, String tenantId, List<String> codigos) async {
    try {
      await _repository.atualizarModulosUsuario(usuarioId, tenantId, codigos);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar módulos: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> atualizarColaborador({
    required String id,
    required String nome,
    String? emailCorporativo,
    String? celular,
    String? matricula,
    String? cargo,
    String? departamento,
    String? dataNascimento,
    String? dataAdmissao,
    String? dataDesligamento,
    bool acessoEstoque = false,
    bool acessoPatrimonio = false,
    bool acessoFrota = false,
    bool acessoProtocolo = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.atualizarColaborador(
        id: id,
        nome: nome,
        emailCorporativo: emailCorporativo,
        celular: celular,
        matricula: matricula,
        cargo: cargo,
        departamento: departamento,
        dataNascimento: dataNascimento,
        dataAdmissao: dataAdmissao,
        dataDesligamento: dataDesligamento,
        acessoEstoque: acessoEstoque,
        acessoPatrimonio: acessoPatrimonio,
        acessoFrota: acessoFrota,
        acessoProtocolo: acessoProtocolo,
      );
      await carregarColaboradores();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar colaborador: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> excluirColaborador(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.excluirColaborador(id);
      await carregarColaboradores();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao excluir colaborador: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
