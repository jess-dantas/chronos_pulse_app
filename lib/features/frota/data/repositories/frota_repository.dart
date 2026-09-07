import '../datasources/frota_remote_datasource.dart';
import '../models/frota_models.dart';

class FrotaRepository {
  final FrotaRemoteDataSource _remoteDataSource;

  FrotaRepository({required FrotaRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<List<FrotaVeiculoModel>> getVeiculos() => _remoteDataSource.getVeiculos();
  Future<FrotaVeiculoModel> criarVeiculo(Map<String, dynamic> payload) => _remoteDataSource.criarVeiculo(payload);
  Future<List<AbastecimentoModel>> getAbastecimentos() => _remoteDataSource.getAbastecimentos();
  Future<AbastecimentoModel> registrarAbastecimento(Map<String, dynamic> payload) =>
      _remoteDataSource.registrarAbastecimento(payload);
}