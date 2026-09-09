import '../datasources/compras_remote_datasource.dart';
import '../models/compras_models.dart';

class ComprasRepository {
  final ComprasRemoteDataSource _remoteDataSource;

  ComprasRepository({required ComprasRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<List<FornecedorModel>> getFornecedores() => _remoteDataSource.getFornecedores();

  Future<FornecedorModel> cadastrarFornecedor(CadastrarFornecedorDTO dto) =>
      _remoteDataSource.cadastrarFornecedor(dto);

  Future<FornecedorModel> atualizarFornecedor(String id, AtualizarFornecedorDTO dto) =>
      _remoteDataSource.atualizarFornecedor(id, dto);

  Future<void> inativarFornecedor(String id) => _remoteDataSource.inativarFornecedor(id);

  Future<List<PedidoCompraModel>> getPedidos() => _remoteDataSource.getPedidos();

  Future<PedidoCompraModel> criarPedido(CadastrarPedidoCompraDTO dto) =>
      _remoteDataSource.criarPedido(dto);

  Future<void> cancelarPedido(String pedidoId) => _remoteDataSource.cancelarPedido(pedidoId);

  Future<EntradaNfeModel> receberNfe(ReceberNfeDTO dto) => _remoteDataSource.receberNfe(dto);

  Future<List<EntradaNfeModel>> getEntradasNfe() => _remoteDataSource.getEntradasNfe();

  Future<NfeImportadoModel> importarXmlNfe(List<int> bytes, String nomeArquivo) =>
      _remoteDataSource.importarXmlNfe(bytes, nomeArquivo);

  Future<NfeImportadoModel> consultarSefazNfe(String chaveNfe) =>
      _remoteDataSource.consultarSefazNfe(chaveNfe);

  Future<List<PrecoConsultaModel>> getPrecos() => _remoteDataSource.getPrecos();

  Future<List<RequisicaoCompraModel>> getRequisicoes() => _remoteDataSource.getRequisicoes();

  Future<RequisicaoCompraModel> criarRequisicao(CadastrarRequisicaoDTO dto) =>
      _remoteDataSource.criarRequisicao(dto);

  Future<void> cancelarRequisicao(String id) => _remoteDataSource.cancelarRequisicao(id);

  Future<List<CotacaoCompraModel>> getCotacoes() => _remoteDataSource.getCotacoes();

  Future<CotacaoCompraModel> criarCotacao(CadastrarCotacaoDTO dto) =>
      _remoteDataSource.criarCotacao(dto);

  Future<CotacaoCompraModel> registrarPropostas(String cotacaoId, RegistrarPropostasDTO dto) =>
      _remoteDataSource.registrarPropostas(cotacaoId, dto);

  Future<CotacaoCompraModel> concluirCotacao(String id) => _remoteDataSource.concluirCotacao(id);

  Future<void> cancelarCotacao(String id) => _remoteDataSource.cancelarCotacao(id);

  Future<List<PedidoCompraModel>> gerarPedidosCotacao(String id) =>
      _remoteDataSource.gerarPedidosCotacao(id);
}