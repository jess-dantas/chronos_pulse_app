import '../../../../core/network/paginated_response.dart';
import '../datasources/frota_remote_datasource.dart';
import '../models/frota_models.dart';

class FrotaRepository {
  final FrotaRemoteDataSource _remoteDataSource;

  FrotaRepository({required FrotaRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<PaginatedResponse<FrotaVeiculoModel>> getVeiculos({int page = 0, int size = 50}) =>
      _remoteDataSource.getVeiculos(page: page, size: size);
  Future<FrotaVeiculoModel> criarVeiculo(Map<String, dynamic> payload) => _remoteDataSource.criarVeiculo(payload);
  Future<PaginatedResponse<AbastecimentoModel>> getAbastecimentos({int page = 0, int size = 50}) =>
      _remoteDataSource.getAbastecimentos(page: page, size: size);
  Future<AbastecimentoModel> registrarAbastecimento(Map<String, dynamic> payload) =>
      _remoteDataSource.registrarAbastecimento(payload);
}