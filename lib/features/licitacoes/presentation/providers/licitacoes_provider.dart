import 'package:flutter/foundation.dart';

import '../../data/models/execucao_contrato_models.dart';
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
  final Map<String, List<LanceModel>> _lancesCache = {};
  List<ContratoExecucaoModel> _contratosExecucao = [];
  final Map<String, ContratoExecucaoModel> _execucoes = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<LicitacaoModel> get licitacoes => _licitacoes;
  List<ContratoExecucaoModel> get contratosExecucao => _contratosExecucao;

  ContratoExecucaoModel? execucao(String contratoId) => _execucoes[contratoId];

  int get contratosEmAtencao => _contratosExecucao
      .where((c) => c.situacao == 'EXPIRANDO' || c.situacao == 'VENCIDO')
      .length;

  PlanejamentoLicitacaoModel? planejamento(String licitacaoId) =>
      _planejamentos[licitacaoId];

  List<LanceModel>? lances(String licitacaoId) => _lancesCache[licitacaoId];

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

  // ============================ DISPUTA (R29) ============================

  Future<bool> abrirDisputa(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final licitacao = await _repository.abrirDisputa(id);
      _afetarLicitacao(licitacao);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao abrir a disputa: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> carregarLances(String id) async {
    try {
      _lancesCache[id] = await _repository.listarLances(id);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao carregar os lances: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrarLance(String id, RegistrarLanceDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final licitacao = await _repository.registrarLance(id, dto);
      _afetarLicitacao(licitacao);
      await carregarLances(id);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao registrar o lance: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _afetarLicitacao(LicitacaoModel licitacao) {
    final index = _licitacoes.indexWhere((l) => l.id == licitacao.id);
    if (index >= 0) {
      _licitacoes[index] = licitacao;
    } else {
      _licitacoes.add(licitacao);
    }
    _isLoading = false;
    notifyListeners();
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

  Future<bool> publicarPncp(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.publicarPncp(id);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao publicar aviso no PNCP: $e';
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

  // ============================ FORMALIZAÇÃO CONTRATO (R30) ============================

  Future<bool> formalizarContrato(String id, FormalizarContratoDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final licitacao = await _repository.formalizarContrato(id, dto);
      _afetarLicitacao(licitacao);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao formalizar o contrato: $e';
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

  // ============================ EXECUÇÃO CONTRATUAL (R30) ============================

  Future<bool> carregarContratos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _contratosExecucao = await _repository.getContratos();
      for (final c in _contratosExecucao) {
        _execucoes[c.id] = c;
      }
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao carregar contratos: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> carregarExecucao(String contratoId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final executado = await _repository.getContrato(contratoId);
      _execucoes[contratoId] = executado;
      final index = _contratosExecucao.indexWhere((c) => c.id == contratoId);
      if (index >= 0) {
        _contratosExecucao[index] = executado;
      }
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao carregar a execução do contrato: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registrarAditivo(String id, AdicionarAditivoDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.registrarAditivo(id, dto);
      return await carregarExecucao(id);
    } catch (e) {
      _errorMessage = 'Erro ao registrar o aditivo: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrarApontamento(String id, AdicionarApontamentoDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.registrarApontamento(id, dto);
      return await carregarExecucao(id);
    } catch (e) {
      _errorMessage = 'Erro ao registrar o apontamento: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resolverApontamento(String id, String apontamentoId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.resolverApontamento(id, apontamentoId);
      return await carregarExecucao(id);
    } catch (e) {
      _errorMessage = 'Erro ao resolver o apontamento: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrarMedicao(String id, RegistrarMedicaoDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.registrarMedicao(id, dto);
      return await carregarExecucao(id);
    } catch (e) {
      _errorMessage = 'Erro ao registrar a medição: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrarSancao(String id, AdicionarSancaoDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.registrarSancao(id, dto);
      return await carregarExecucao(id);
    } catch (e) {
      _errorMessage = 'Erro ao registrar a sanção: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rescindirContrato(String id, RescindirContratoDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.rescindirContrato(id, dto);
      return await carregarExecucao(id);
    } catch (e) {
      _errorMessage = 'Erro ao rescindir o contrato: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}