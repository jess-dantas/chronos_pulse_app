import 'package:flutter/foundation.dart';
import '../../data/models/compras_models.dart';
import '../../data/repositories/compras_repository.dart';

class ComprasProvider extends ChangeNotifier {
  final ComprasRepository _repository;

  ComprasProvider(this._repository);

  List<FornecedorModel> _fornecedores = [];
  List<PedidoCompraModel> _pedidos = [];
  List<EntradaNfeModel> _entradasNfe = [];
  List<PrecoConsultaModel> _precos = [];
  List<RequisicaoCompraModel> _requisicoes = [];
  List<CotacaoCompraModel> _cotacoes = [];

  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<FornecedorModel> get fornecedores {
    if (_searchQuery.isEmpty) return _fornecedores;
    final query = _searchQuery.toLowerCase();
    return _fornecedores.where((f) {
      return f.razaoSocial.toLowerCase().contains(query) ||
          f.cnpj.toLowerCase().contains(query) ||
          (f.nomeFantasia?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<PedidoCompraModel> get pedidos => _pedidos;
  List<EntradaNfeModel> get entradasNfe => _entradasNfe;
  List<PrecoConsultaModel> get precos => _precos;
  List<RequisicaoCompraModel> get requisicoes => _requisicoes;
  List<CotacaoCompraModel> get cotacoes => _cotacoes;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get pedidosEmitidos =>
      _pedidos.where((p) => p.status == 'EMITIDO').length;
  int get pedidosRecebidosParciais =>
      _pedidos.where((p) => p.status == 'RECEBIDO_PARCIAL').length;
  int get totalPedidos => _pedidos.length;
  int get fornecedoresAtivos =>
      _fornecedores.where((f) => f.ativo).length;
  int get totalEntradasNfe => _entradasNfe.length;
  int get requisicoesEmAberto =>
      _requisicoes.where((r) => r.status == 'EM_ABERTO').length;
  int get requisicoesCotadas =>
      _requisicoes.where((r) => r.status == 'COTADA').length;
  int get cotacoesEmAndamento =>
      _cotacoes.where((c) => c.status == 'EM_ANDAMENTO').length;
  int get cotacoesConcluidas =>
      _cotacoes.where((c) => c.status == 'CONCLUIDA').length;

  List<RequisicaoCompraModel> get requisicoesCotaveis =>
      _requisicoes.where((r) => r.cotavel).toList();

  CotacaoCompraModel? cotacaoPorRequisicao(String requisicaoId) {
    for (final cotacao in _cotacoes) {
      if (cotacao.requisicaoId == requisicaoId) return cotacao;
    }
    return null;
  }

  Future<void> carregarTudo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultados = await Future.wait([
        _repository.getFornecedores(),
        _repository.getPedidos(),
        _repository.getEntradasNfe(),
        _repository.getPrecos(),
        _repository.getRequisicoes(),
        _repository.getCotacoes(),
      ]);

      _fornecedores = resultados[0] as List<FornecedorModel>;
      _pedidos = resultados[1] as List<PedidoCompraModel>;
      _entradasNfe = resultados[2] as List<EntradaNfeModel>;
      _precos = resultados[3] as List<PrecoConsultaModel>;
      _requisicoes = resultados[4] as List<RequisicaoCompraModel>;
      _cotacoes = resultados[5] as List<CotacaoCompraModel>;
    } catch (e) {
      _errorMessage = 'Erro ao carregar dados de compras: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> cadastrarFornecedor(CadastrarFornecedorDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.cadastrarFornecedor(dto);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao cadastrar fornecedor: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> atualizarFornecedor(String id, AtualizarFornecedorDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.atualizarFornecedor(id, dto);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar fornecedor: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> inativarFornecedor(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.inativarFornecedor(id);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao inativar fornecedor: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> criarPedido(CadastrarPedidoCompraDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.criarPedido(dto);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao criar pedido de compra: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelarPedido(String pedidoId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.cancelarPedido(pedidoId);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao cancelar pedido: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> receberNfe(ReceberNfeDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.receberNfe(dto);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao registrar recebimento por NFe: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<NfeImportadoModel?> importarXmlNfe(List<int> bytes, String nomeArquivo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final resultado = await _repository.importarXmlNfe(bytes, nomeArquivo);
      _isLoading = false;
      notifyListeners();
      return resultado;
    } catch (e) {
      _errorMessage = 'Erro ao importar o XML da NFe: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<NfeImportadoModel?> consultarSefazNfe(String chaveNfe) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final resultado = await _repository.consultarSefazNfe(chaveNfe);
      _isLoading = false;
      notifyListeners();
      return resultado;
    } catch (e) {
      _errorMessage = 'Erro ao consultar a NFe na SEFAZ: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> criarRequisicao(CadastrarRequisicaoDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.criarRequisicao(dto);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao criar requisição de compra: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelarRequisicao(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.cancelarRequisicao(id);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao cancelar requisição: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> criarCotacao(CadastrarCotacaoDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.criarCotacao(dto);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao criar cotação: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrarPropostas(String cotacaoId, RegistrarPropostasDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.registrarPropostas(cotacaoId, dto);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao registrar propostas: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> concluirCotacao(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.concluirCotacao(id);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao concluir cotação: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelarCotacao(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.cancelarCotacao(id);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao cancelar cotação: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> gerarPedidosCotacao(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.gerarPedidosCotacao(id);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao gerar pedidos a partir da cotação: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}