import 'package:flutter/foundation.dart';

import '../../data/models/licitacoes_models.dart';
import '../../data/repositories/licitacoes_repository.dart';

class LicitacoesProvider extends ChangeNotifier {
  final LicitacoesRepository _repository;
  LicitacoesProvider(this._repository);

  bool _isLoading = false;
  String? _errorMessage;
  List<LicitacaoModel> _licitacoes = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<LicitacaoModel> get licitacoes => _licitacoes;

  int get licitacoesEmDisputa =>
      _licitacoes.where((l) => l.emDisputa).length;
  int get licitacoesAdjudicadasHomologadas =>
      _licitacoes.where((l) => l.adjudicada || l.homologada).length;
  int get licitacoesCanceladas =>
      _licitacoes.where((l) => l.cancelada).length;

  Future<void> carregarTudo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _licitacoes = await _repository.getLicitacoes();
    } catch (e) {
      _errorMessage = 'Erro ao carregar licitações: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> criarLicitacao(CadastrarLicitacaoDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.criarLicitacao(dto);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao criar licitação: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> publicarLicitacao(String id, PublicarLicitacaoDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.publicarLicitacao(id, dto);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao publicar licitação: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrarPropostas(String id, RegistrarPropostasLicitacaoDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.registrarPropostas(id, dto);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao registrar propostas: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> adjudicarLicitacao(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.adjudicarLicitacao(id);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao adjudicar licitação: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> homologarLicitacao(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.homologarLicitacao(id);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao homologar licitação: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelarLicitacao(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.cancelarLicitacao(id);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao cancelar licitação: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> gerarPedidos(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.gerarPedidos(id);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao gerar pedidos da licitação: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}