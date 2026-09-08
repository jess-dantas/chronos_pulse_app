import '../../../../core/network/paginated_response.dart';
import '../datasources/patrimonio_remote_datasource.dart';
import '../models/patrimonio_models.dart';

class PatrimonioRepository {
  final PatrimonioRemoteDataSource _remoteDataSource;

  PatrimonioRepository({required PatrimonioRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<PaginatedResponse<PatrimonioModel>> getBens({int page = 0, int size = 50}) =>
      _remoteDataSource.getBens(page: page, size: size);

  Future<PatrimonioModel> criarBem(Map<String, dynamic> payload) =>
      _remoteDataSource.criarBem(payload);
}