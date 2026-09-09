import '../../../../core/network/paginated_response.dart';
import '../datasources/patrimonio_remote_datasource.dart';
import '../models/patrimonio_models.dart';

class PatrimonioRepository {
  final PatrimonioRemoteDataSource _remoteDataSource;

  PatrimonioRepository({required PatrimonioRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<PaginatedResponse<PatrimonioModel>> getBens({int page = 0, int size = 50}) =>
      _remoteDataSource.getBens(page: page, size: size);

  Future<List<PatrimonioModel>> buscarBens(String termo) =>
      _remoteDataSource.buscarBens(termo);

  Future<PatrimonioModel> criarBem(Map<String, dynamic> payload) =>
      _remoteDataSource.criarBem(payload);

  Future<PatrimonioModel> atualizarBem(String id, Map<String, dynamic> payload) =>
      _remoteDataSource.atualizarBem(id, payload);

  Future<void> desativarBem(String id) => _remoteDataSource.desativarBem(id);

  Future<PatrimonioModel> buscarPorQrCode(String codigo) =>
      _remoteDataSource.buscarPorQrCode(codigo);
}