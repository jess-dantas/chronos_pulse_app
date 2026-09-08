import 'package:flutter/foundation.dart';
import '../../data/models/admin_models.dart';
import '../../data/repositories/admin_repository.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository;

  AdminDashboardModel? _metrics;
  List<AdminContratoModel> _contratos = [];
  List<AdminEmpresaModel> _empresas = [];
  List<AdminColaboradorModel> _colaboradores = [];
  List<AdminModuloModel> _modulosCatalogo = [];
  bool _isLoading = false;
  String? _errorMessage;

  AdminProvider(this._repository);

  AdminDashboardModel? get metrics => _metrics;
  List<AdminContratoModel> get contratos => _contratos;
  List<AdminEmpresaModel> get empresas => _empresas;
  List<AdminColaboradorModel> get colaboradores => _colaboradores;
  List<AdminModuloModel> get modulosCatalogo => _modulosCatalogo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> carregarDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _metrics = await _repository.buscarDashboard();

    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> carregarEmpresas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _empresas = await _repository.listarEmpresas();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> carregarColaboradores() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _colaboradores = await _repository.listarColaboradores();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> carregarContratos({String? tenantId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contratos = await _repository.listarContratos(tenantId: tenantId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cadastrarContrato({
    required String tenantId,
    required String numero,
    required String objeto,
    required String dataInicio,
    required String dataFim,
    required double valorMensal,
    required double valorTotal,
    String? observacoes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.cadastrarContrato(
        tenantId: tenantId,
        numero: numero,
        objeto: objeto,
        dataInicio: dataInicio,
        dataFim: dataFim,
        valorMensal: valorMensal,
        valorTotal: valorTotal,
        observacoes: observacoes,
      );
      await carregarContratos();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<AdminContratoEventoModel>> listarEventosContrato(String contratoId) async {
    try {
      return await _repository.listarEventosContrato(contratoId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> carregarCatalogoModulos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _modulosCatalogo = await _repository.listarCatalogoModulos();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<String>> listarModulosEmpresa(String tenantId) async {
    try {
      return await _repository.listarModulosEmpresa(tenantId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> atualizarModulosEmpresa(String tenantId, List<String> modulos) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.atualizarModulosEmpresa(tenantId, modulos);
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

  Future<bool> adicionarEventoContrato({
    required String contratoId,
    required String tipo,
    required String descricao,
  }) async {
    try {
      await _repository.adicionarEventoContrato(
        contratoId: contratoId,
        tipo: tipo,
        descricao: descricao,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> cadastrarEmpresa({
    required String cnpj,
    required String nome,
    String? responsavelNome,
    String? responsavelEmail,
    String? responsavelTelefone,
    String? responsavelCelular,
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
      await _repository.cadastrarEmpresa(
        cnpj: cnpj,
        nome: nome,
        responsavelNome: responsavelNome,
        responsavelEmail: responsavelEmail,
        responsavelTelefone: responsavelTelefone,
        responsavelCelular: responsavelCelular,
        enderecoLogradouro: enderecoLogradouro,
        enderecoNumero: enderecoNumero,
        enderecoComplemento: enderecoComplemento,
        enderecoBairro: enderecoBairro,
        enderecoCidade: enderecoCidade,
        enderecoUf: enderecoUf,
        enderecoCep: enderecoCep,
      );
      await carregarEmpresas();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> atualizarEmpresa({
    required String id,
    String? nome,
    bool? ativo,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.atualizarEmpresa(id: id, nome: nome, ativo: ativo);
      await carregarEmpresas();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cadastrarColaborador({
    required String cpf,
    required String nome,
    String? emailCorporativo,
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
        dataDesligamento: dataDesligamento,
        tenantId: tenantId,
        acessoEstoque: acessoEstoque,
        acessoPatrimonio: acessoPatrimonio,
        acessoFrota: acessoFrota,
        acessoProtocolo: acessoProtocolo,
      );
      await carregarColaboradores();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> atualizarColaborador({
    required String id,
    required String nome,
    String? emailCorporativo,
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
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}
