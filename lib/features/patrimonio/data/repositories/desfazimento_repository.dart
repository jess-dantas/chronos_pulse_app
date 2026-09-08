import '../../../../core/network/paginated_response.dart';
import '../datasources/desfazimento_remote_datasource.dart';
import '../models/patrimonio_models.dart';

class DesfazimentoRepository {
  final DesfazimentoRemoteDataSource _remoteDataSource;

  DesfazimentoRepository({required DesfazimentoRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<PaginatedResponse<DesfazimentoModel>> listarDesfazimentos({
    int page = 0,
    int size = 50,
  }) =>
      _remoteDataSource.listarDesfazimentos(page: page, size: size);

  Future<DesfazimentoModel> criarDesfazimento(Map<String, dynamic> payload) =>
      _remoteDataSource.criarDesfazimento(payload);

  Future<DesfazimentoModel> aprovarDesfazimento(
    String id, {
    String? parecerComissao,
  }) =>
      _remoteDataSource.aprovarDesfazimento(id, parecerComissao: parecerComissao);

  Future<void> cancelarDesfazimento(String id) =>
      _remoteDataSource.cancelarDesfazimento(id);
}