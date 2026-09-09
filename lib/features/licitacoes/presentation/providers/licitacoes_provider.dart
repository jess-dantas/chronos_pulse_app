import 'package:flutter/foundation.dart';

import '../../data/models/licitacoes_models.dart';
import '../../data/models/planejamento_licitacao_models.dart';
import '../../data/repositories/licitacoes_repository.dart';

class LicitacoesProvider extends ChangeNotifier {
  final LicitacoesRepository _repository;
  LicitacoesProvider(this._repository);

  bool _isLoading = false;
  String? _errorMessage;
  List<LicitacaoModel> _licitacoes = [];
  final Map<String, PlanejamentoLicitacaoModel> _planejamentos = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<LicitacaoModel> get licitacoes => _licitacoes;

  PlanejamentoLicitacaoModel? planejamento(String licitacaoId) =>
      _planejamentos[licitacaoId];

  List<LicitacaoModel> get planejamentosPendentes => _licitacoes
      .where((l) =>
          l.emElaboracao &&
          (_planejamentos[l.id]?.edital?.publicado ?? false) == false)
      .toList();

  bool get planejamentosEmElaboracaoPendentes =>
      planejamentosPendentes.isNotEmpty;

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
    await carregarPlanejamentos();
  }

  Future<void> carregarPlanejamentos() async {
    for (final licitacao in _licitacoes) {
      try {
        _planejamentos[licitacao.id] =
            await _repository.getPlanejamento(licitacao.id);
      } catch (_) {
        // Planejamento não está disponível (ex.: licitação sem documentos);
        // o cache permanece como está e pode ser recarregado ao abrir o diálogo.
      }
    }
    notifyListeners();
  }

  Future<bool> carregarPlanejamento(String licitacaoId) async {
    try {
      _planejamentos[licitacaoId] =
          await _repository.getPlanejamento(licitacaoId);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao carregar o planejamento: $e';
      notifyListeners();
      return false;
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

  // ============================ PLANEJAMENTO (R28) ============================

  Future<bool> salvarEtp(String licitacaoId, EtpDTO dto) =>
      _salvarPlanejamento(
          () => _repository.salvarEtp(licitacaoId, dto), 'salvar o ETP');

  Future<bool> aprovarEtp(String licitacaoId, String responsavel) =>
      _salvarPlanejamento(
          () => _repository.aprovarEtp(
              licitacaoId, AprovacaoDocumentoDTO(responsavel: responsavel)),
          'aprovar o ETP');

  Future<bool> salvarTr(String licitacaoId, TrDTO dto) => _salvarPlanejamento(
      () => _repository.salvarTr(licitacaoId, dto),
      'salvar o Termo de Referência');

  Future<bool> aprovarTr(String licitacaoId, String responsavel) =>
      _salvarPlanejamento(
          () => _repository.aprovarTr(
              licitacaoId, AprovacaoDocumentoDTO(responsavel: responsavel)),
          'aprovar o Termo de Referência');

  Future<bool> salvarEdital(String licitacaoId, EditalDTO dto) =>
      _salvarPlanejamento(
          () => _repository.salvarEdital(licitacaoId, dto), 'salvar o edital');

  Future<bool> publicarEdital(String licitacaoId) => _salvarPlanejamento(
      () => _repository.publicarEdital(licitacaoId), 'publicar o edital');

  Future<bool> _salvarPlanejamento(
      Future<PlanejamentoLicitacaoModel> Function() acao,
      String nomeAcao) async {
    try {
      final resultado = await acao();
      _planejamentos[resultado.licitacaoId] = resultado;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao $nomeAcao: $e';
      notifyListeners();
      return false;
    }
  }
}