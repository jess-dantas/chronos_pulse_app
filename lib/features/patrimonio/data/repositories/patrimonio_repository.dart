import '../datasources/patrimonio_remote_datasource.dart';
import '../models/patrimonio_models.dart';

class PatrimonioRepository {
  final PatrimonioRemoteDataSource _remoteDataSource;

  PatrimonioRepository({required PatrimonioRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<List<PatrimonioModel>> getBens() => _remoteDataSource.getBens();

  Future<PatrimonioModel> criarBem(Map<String, dynamic> payload) =>
      _remoteDataSource.criarBem(payload);
}