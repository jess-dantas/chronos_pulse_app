import '../datasources/estoque_remote_datasource.dart';
import '../models/estoque_models.dart';

class EstoqueRepository {
  final EstoqueRemoteDataSource _remoteDataSource;

  EstoqueRepository({required EstoqueRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<List<EstoqueSaldoModel>> getSaldos({String? almoxarifadoId}) {
    return _remoteDataSource.getSaldos(almoxarifadoId: almoxarifadoId);
  }

  Future<List<MaterialModel>> getMateriais() {
    return _remoteDataSource.getMateriais();
  }

  Future<List<AlmoxarifadoModel>> getAlmoxarifados() {
    return _remoteDataSource.getAlmoxarifados();
  }

  Future<void> registrarEntrada(EntradaEstoqueRequestDTO dto) {
    return _remoteDataSource.registrarEntrada(dto);
  }

  Future<void> registrarSaida(SaidaEstoqueRequestDTO dto) {
    return _remoteDataSource.registrarSaida(dto);
  }

  Future<List<RequisicaoModel>> getRequisicoes({String? status}) {
    return _remoteDataSource.getRequisicoes(status: status);
  }

  Future<RequisicaoModel> criarRequisicao(CriarRequisicaoRequestDTO dto) {
    return _remoteDataSource.criarRequisicao(dto);
  }

  Future<void> aprovarRequisicao(String requisicaoId) {
    return _remoteDataSource.aprovarRequisicao(requisicaoId);
  }

  Future<void> atenderRequisicao(
    String requisicaoId,
    List<Map<String, dynamic>> itensAtendimento,
  ) {
    return _remoteDataSource.atenderRequisicao(requisicaoId, itensAtendimento);
  }
}
