import 'package:flutter/foundation.dart';
import '../../data/repositories/admin_repository.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository;

  Map<String, dynamic> _metrics = {};
  List<Map<String, dynamic>> _contratos = [];
  List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _colaboradores = [];
  bool _isLoading = false;
  String? _errorMessage;

  AdminProvider(this._repository);

  Map<String, dynamic> get metrics => _metrics;
  List<Map<String, dynamic>> get contratos => _contratos;
  List<Map<String, dynamic>> get empresas => _empresas;
  List<Map<String, dynamic>> get colaboradores => _colaboradores;
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

  Future<List<Map<String, dynamic>>> listarEventosContrato(String contratoId) async {
    try {
      return await _repository.listarEventosContrato(contratoId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      throw e;
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
      throw e;
    }
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}
