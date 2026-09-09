import '../datasources/transparencia_remote_datasource.dart';
import '../models/transparencia_models.dart';

class TransparenciaRepository {
  final TransparenciaRemoteDataSource _remoteDataSource;

  TransparenciaRepository({required TransparenciaRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<TransparenciaResumoModel> getResumo() => _remoteDataSource.getResumo();

  Future<DespesasMensaisModel> getDespesasMensais(int ano) =>
      _remoteDataSource.getDespesasMensais(ano);

  Future<List<TransparenciaPublicacaoModel>> getPublicacoes() =>
      _remoteDataSource.getPublicacoes();

  Future<TransparenciaPublicacaoModel> criarPublicacao(Map<String, dynamic> payload) =>
      _remoteDataSource.criarPublicacao(payload);

  Future<TransparenciaPublicacaoModel> publicarPublicacao(String id) =>
      _remoteDataSource.publicarPublicacao(id);

  Future<void> removerPublicacao(String id) => _remoteDataSource.removerPublicacao(id);
}