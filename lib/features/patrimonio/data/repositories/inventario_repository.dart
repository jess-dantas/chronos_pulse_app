import '../datasources/inventario_remote_datasource.dart';
import '../models/patrimonio_models.dart';

class InventarioRepository {
  final InventarioRemoteDataSource _remoteDataSource;

  InventarioRepository({required InventarioRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<List<InventarioModel>> listarInventarios() =>
      _remoteDataSource.listarInventarios();

  Future<InventarioModel> buscarInventario(String id) =>
      _remoteDataSource.buscarInventario(id);

  Future<InventarioModel> criarInventario({
    required String descricao,
    String? dataInicio,
    String? dataFim,
  }) =>
      _remoteDataSource.criarInventario(
        descricao: descricao,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

  Future<InventarioModel> conferirItem(
    String inventarioId, {
    required String patrimonioId,
    required String resultado,
    String? observacao,
  }) =>
      _remoteDataSource.conferirItem(
        inventarioId,
        patrimonioId: patrimonioId,
        resultado: resultado,
        observacao: observacao,
      );

  Future<InventarioModel> finalizar(String inventarioId) =>
      _remoteDataSource.finalizar(inventarioId);

  Future<void> cancelar(String inventarioId) =>
      _remoteDataSource.cancelar(inventarioId);
}