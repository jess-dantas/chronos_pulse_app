import '../datasources/licitacoes_remote_datasource.dart';
import '../models/licitacoes_models.dart';
import '../models/planejamento_licitacao_models.dart';

class LicitacoesRepository {
  final LicitacoesRemoteDataSource _remoteDataSource;
  LicitacoesRepository({required LicitacoesRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<List<LicitacaoModel>> getLicitacoes() => _remoteDataSource.getLicitacoes();

  Future<LicitacaoModel> criarLicitacao(CadastrarLicitacaoDTO dto) =>
      _remoteDataSource.criarLicitacao(dto);

  Future<LicitacaoModel> publicarLicitacao(String id, PublicarLicitacaoDTO dto) =>
      _remoteDataSource.publicarLicitacao(id, dto);

  Future<LicitacaoModel> registrarPropostas(
          String id, RegistrarPropostasLicitacaoDTO dto) =>
      _remoteDataSource.registrarPropostas(id, dto);

  Future<LicitacaoModel> adjudicarLicitacao(String id) =>
      _remoteDataSource.adjudicarLicitacao(id);

  Future<LicitacaoModel> homologarLicitacao(String id) =>
      _remoteDataSource.homologarLicitacao(id);

  Future<LicitacaoModel> publicarPncp(String id) =>
      _remoteDataSource.publicarPncp(id);

  Future<void> cancelarLicitacao(String id) => _remoteDataSource.cancelarLicitacao(id);

  Future<List<Map<String, dynamic>>> gerarPedidos(String id) =>
      _remoteDataSource.gerarPedidos(id);

  Future<LicitacaoModel> abrirDisputa(String id) =>
      _remoteDataSource.abrirDisputa(id);

  Future<LicitacaoModel> registrarLance(String id, RegistrarLanceDTO dto) =>
      _remoteDataSource.registrarLance(id, dto);

  Future<List<LanceModel>> listarLances(String id) =>
      _remoteDataSource.listarLances(id);

  Future<PlanejamentoLicitacaoModel> getPlanejamento(String id) =>
      _remoteDataSource.getPlanejamento(id);

  Future<PlanejamentoLicitacaoModel> salvarEtp(String id, EtpDTO dto) =>
      _remoteDataSource.salvarEtp(id, dto);

  Future<PlanejamentoLicitacaoModel> aprovarEtp(String id, AprovacaoDocumentoDTO dto) =>
      _remoteDataSource.aprovarEtp(id, dto);

  Future<PlanejamentoLicitacaoModel> salvarTr(String id, TrDTO dto) =>
      _remoteDataSource.salvarTr(id, dto);

  Future<PlanejamentoLicitacaoModel> aprovarTr(String id, AprovacaoDocumentoDTO dto) =>
      _remoteDataSource.aprovarTr(id, dto);

  Future<PlanejamentoLicitacaoModel> salvarEdital(String id, EditalDTO dto) =>
      _remoteDataSource.salvarEdital(id, dto);

  Future<PlanejamentoLicitacaoModel> publicarEdital(String id) =>
      _remoteDataSource.publicarEdital(id);
}