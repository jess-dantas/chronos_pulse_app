import '../datasources/licitacoes_remote_datasource.dart';
import '../models/licitacoes_models.dart';

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

  Future<void> cancelarLicitacao(String id) => _remoteDataSource.cancelarLicitacao(id);

  Future<List<Map<String, dynamic>>> gerarPedidos(String id) =>
      _remoteDataSource.gerarPedidos(id);
}