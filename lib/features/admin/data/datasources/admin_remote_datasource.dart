import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class AdminRemoteDataSource {
  final DioClient _dioClient;

  AdminRemoteDataSource(this._dioClient);

  Future<List<Map<String, dynamic>>> listarEmpresas() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.adminEmpresasEndpoint);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao listar empresas');
    }
  }

  Future<Map<String, dynamic>> buscarDashboard() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.adminDashboardEndpoint);
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      return {};
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao buscar dados do dashboard');
    }
  }

  Future<List<Map<String, dynamic>>> listarColaboradores() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.adminColaboradoresEndpoint);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao listar colaboradores');
    }
  }

  Future<List<Map<String, dynamic>>> listarContratos({String? tenantId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (tenantId != null) queryParams['tenantId'] = tenantId;

      final response = await _dioClient.dio.get(
        ApiConstants.adminContratosEndpoint,
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao listar contratos');
    }
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
  }) async {
    try {
      final payload = {
        'tenantId': tenantId,
        'numero': numero,
        'objeto': objeto,
        'dataInicio': dataInicio,
        'dataFim': dataFim,
        'valorMensal': valorMensal,
        'valorTotal': valorTotal,
        if (observacoes != null) 'observacoes': observacoes,
      };

      final response = await _dioClient.dio.post(
        ApiConstants.adminContratosEndpoint,
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Falha ao cadastrar contrato');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao cadastrar contrato');
    }
  }

  Future<List<Map<String, dynamic>>> listarEventosContrato(String contratoId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.adminContratoEventosEndpoint(contratoId),
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao listar eventos do contrato');
    }
  }

  Future<Map<String, dynamic>> adicionarEventoContrato({
    required String contratoId,
    required String tipo,
    required String descricao,
  }) async {
    try {
      final payload = {
        'contratoId': contratoId,
        'tipo': tipo,
        'descricao': descricao,
      };

      final response = await _dioClient.dio.post(
        ApiConstants.adminContratoEventoEndpoint,
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Falha ao adicionar evento');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao adicionar evento ao contrato');
    }
  }
}
