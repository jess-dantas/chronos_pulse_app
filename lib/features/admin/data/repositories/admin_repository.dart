import '../datasources/admin_remote_datasource.dart';

class AdminRepository {
  final AdminRemoteDataSource _remoteDataSource;

  AdminRepository({required AdminRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<Map<String, dynamic>> buscarDashboard() {
    return _remoteDataSource.buscarDashboard();
  }

  Future<List<Map<String, dynamic>>> listarEmpresas() {
    return _remoteDataSource.listarEmpresas();
  }

  Future<List<Map<String, dynamic>>> listarColaboradores() {
    return _remoteDataSource.listarColaboradores();
  }

  Future<List<Map<String, dynamic>>> listarContratos({String? tenantId}) {
    return _remoteDataSource.listarContratos(tenantId: tenantId);
  }

  Future<Map<String, dynamic>> cadastrarContrato({
    required String tenantId,
    required String numero,
    required String objeto,
    required String dataInicio,
    required String dataFim,
    required double valorMensal,
    required double valorTotal,
    String? observacoes,
  }) {
    return _remoteDataSource.cadastrarContrato(
      tenantId: tenantId,
      numero: numero,
      objeto: objeto,
      dataInicio: dataInicio,
      dataFim: dataFim,
      valorMensal: valorMensal,
      valorTotal: valorTotal,
      observacoes: observacoes,
    );
  }

  Future<List<Map<String, dynamic>>> listarEventosContrato(String contratoId) {
    return _remoteDataSource.listarEventosContrato(contratoId);
  }

  Future<Map<String, dynamic>> adicionarEventoContrato({
    required String contratoId,
    required String tipo,
    required String descricao,
  }) {
    return _remoteDataSource.adicionarEventoContrato(
      contratoId: contratoId,
      tipo: tipo,
      descricao: descricao,
    );
  }
}
