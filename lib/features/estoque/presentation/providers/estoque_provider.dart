import 'package:flutter/foundation.dart';
import '../../data/models/estoque_models.dart';
import '../../data/repositories/estoque_repository.dart';

class EstoqueProvider extends ChangeNotifier {
  final EstoqueRepository _repository;

  EstoqueProvider(this._repository);

  List<EstoqueSaldoModel> _saldos = [];
  List<MaterialModel> _materiais = [];
  List<AlmoxarifadoModel> _almoxarifados = [];
  List<RequisicaoModel> _requisicoes = [];

  String? _selectedAlmoxarifadoId;
  String _searchQuery = '';
  String? _selectedStatusRequisicao;

  bool _isLoading = false;
  String? _errorMessage;

  List<EstoqueSaldoModel> get saldos {
    if (_searchQuery.isEmpty) return _saldos;
    final query = _searchQuery.toLowerCase();
    return _saldos.where((s) {
      final desc = s.materialDescricao?.toLowerCase() ?? '';
      final catmat = s.codigoCatmat?.toLowerCase() ?? '';
      final almox = s.almoxarifadoNome?.toLowerCase() ?? '';
      return desc.contains(query) || catmat.contains(query) || almox.contains(query);
    }).toList();
  }

  List<MaterialModel> get materiais => _materiais;
  List<AlmoxarifadoModel> get almoxarifados => _almoxarifados;
  List<RequisicaoModel> get requisicoes => _requisicoes;
  String? get selectedAlmoxarifadoId => _selectedAlmoxarifadoId;
  String get searchQuery => _searchQuery;
  String? get selectedStatusRequisicao => _selectedStatusRequisicao;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Métricas agregadas
  int get totalItensDistintos => _saldos.length;
  double get valorTotalEstoque =>
      _saldos.fold(0.0, (sum, item) => sum + item.valorTotal);
  int get itensAbaixoMinimo =>
      _saldos.where((s) => s.isAbaixoMinimo).length;
  int get totalRequisicoesPendentes =>
      _requisicoes.where((r) => r.status == 'PENDENTE').length;

  Future<void> carregarTudo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultados = await Future.wait([
        _repository.getAlmoxarifados(),
        _repository.getMateriais(),
        _repository.getSaldos(almoxarifadoId: _selectedAlmoxarifadoId),
        _repository.getRequisicoes(status: _selectedStatusRequisicao),
      ]);

      _almoxarifados = resultados[0] as List<AlmoxarifadoModel>;
      _materiais = resultados[1] as List<MaterialModel>;
      _saldos = resultados[2] as List<EstoqueSaldoModel>;
      _requisicoes = resultados[3] as List<RequisicaoModel>;
    } catch (e) {
      _errorMessage = 'Erro ao carregar dados de estoque: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filtrarPorAlmoxarifado(String? almoxarifadoId) async {
    _selectedAlmoxarifadoId = almoxarifadoId;
    _isLoading = true;
    notifyListeners();

    try {
      _saldos = await _repository.getSaldos(almoxarifadoId: almoxarifadoId);
    } catch (e) {
      _errorMessage = 'Erro ao filtrar por almoxarifado: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> filtrarRequisicoesPorStatus(String? status) async {
    _selectedStatusRequisicao = status;
    _isLoading = true;
    notifyListeners();

    try {
      _requisicoes = await _repository.getRequisicoes(status: status);
    } catch (e) {
      _errorMessage = 'Erro ao carregar requisições: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registrarEntrada(EntradaEstoqueRequestDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.registrarEntrada(dto);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao registrar entrada: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrarSaida(SaidaEstoqueRequestDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.registrarSaida(dto);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao registrar saída: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> criarRequisicao(CriarRequisicaoRequestDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.criarRequisicao(dto);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao criar requisição: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> aprovarRequisicao(String requisicaoId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.aprovarRequisicao(requisicaoId);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao aprovar requisição: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> atenderRequisicao(
    String requisicaoId,
    List<Map<String, dynamic>> itensAtendimento,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.atenderRequisicao(requisicaoId, itensAtendimento);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atender requisição: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
