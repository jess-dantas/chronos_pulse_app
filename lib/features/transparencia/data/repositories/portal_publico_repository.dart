import '../datasources/portal_publico_remote_datasource.dart';
import '../models/portal_publico_models.dart';
import '../models/transparencia_models.dart';

class PortalPublicoRepository {
  final PortalPublicoRemoteDataSource _remoteDataSource;

  PortalPublicoRepository({required PortalPublicoRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<PortalResumoModel> getResumo(String slug) => _remoteDataSource.getResumo(slug);

  Future<List<PortalLicitacaoModel>> getLicitacoes(String slug) =>
      _remoteDataSource.getLicitacoes(slug);

  Future<PortalLicitacaoDetalheModel> getLicitacao(String slug, String id) =>
      _remoteDataSource.getLicitacao(slug, id);

  Future<List<PortalContratoModel>> getContratos(String slug) =>
      _remoteDataSource.getContratos(slug);

  Future<PortalContratoDetalheModel> getContrato(String slug, String id) =>
      _remoteDataSource.getContrato(slug, id);

  Future<DespesasMensaisModel> getDespesasMensais(String slug, int ano) =>
      _remoteDataSource.getDespesasMensais(slug, ano);

  Future<List<PortalPublicacaoModel>> getPublicacoes(String slug) =>
      _remoteDataSource.getPublicacoes(slug);
}