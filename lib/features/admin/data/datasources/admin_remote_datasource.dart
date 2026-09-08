import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/admin_models.dart';

class AdminRemoteDataSource {
  final DioClient _dioClient;

  AdminRemoteDataSource(this._dioClient);

  Future<List<AdminEmpresaModel>> listarEmpresas() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.adminEmpresasEndpoint);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(AdminEmpresaModel.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao listar empresas');
    }
  }

  Future<void> cadastrarEmpresa({
    required String cnpj,
    required String nome,
    String? responsavelNome,
    String? responsavelEmail,
    String? responsavelTelefone,
    String? responsavelCelular,
    String? enderecoLogradouro,
    String? enderecoNumero,
    String? enderecoComplemento,
    String? enderecoBairro,
    String? enderecoCidade,
    String? enderecoUf,
    String? enderecoCep,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.adminEmpresasEndpoint,
        data: {
          'cnpj': cnpj,
          'nome': nome,
          'responsavelNome': responsavelNome,
          'responsavelEmail': responsavelEmail,
          'responsavelTelefone': responsavelTelefone,
          'responsavelCelular': responsavelCelular,
          'enderecoLogradouro': enderecoLogradouro,
          'enderecoNumero': enderecoNumero,
          'enderecoComplemento': enderecoComplemento,
          'enderecoBairro': enderecoBairro,
          'enderecoCidade': enderecoCidade,
          'enderecoUf': enderecoUf,
          'enderecoCep': enderecoCep,
        },
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Falha ao cadastrar empresa');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao cadastrar empresa');
    }
  }

  Future<void> atualizarEmpresa({
    required String id,
    String? nome,
    bool? ativo,
  }) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConstants.adminEmpresasEndpoint}/$id',
        data: {
          if (nome != null) 'nome': nome,
          if (ativo != null) 'ativo': ativo,
        },
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Falha ao atualizar empresa');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao atualizar empresa');
    }
  }

  Future<AdminDashboardModel> buscarDashboard() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.adminDashboardEndpoint);
      if (response.statusCode == 200 && response.data is Map) {
        return AdminDashboardModel.fromJson(Map<String, dynamic>.from(response.data));
      }
      throw Exception('Resposta inesperada do dashboard');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao buscar dados do dashboard');
    }
  }

  Future<List<AdminColaboradorModel>> listarColaboradores() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.adminColaboradoresEndpoint);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(AdminColaboradorModel.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao listar colaboradores');
    }
  }

  Future<List<AdminContratoModel>> listarContratos({String? tenantId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (tenantId != null) queryParams['tenantId'] = tenantId;

      final response = await _dioClient.dio.get(
        ApiConstants.adminContratosEndpoint,
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(AdminContratoModel.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao listar contratos');
    }
  }

  Future<AdminContratoModel> cadastrarContrato({
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
        return AdminContratoModel.fromJson(Map<String, dynamic>.from(response.data));
      }
      throw Exception('Falha ao cadastrar contrato');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao cadastrar contrato');
    }
  }

  Future<List<AdminContratoEventoModel>> listarEventosContrato(String contratoId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.adminContratoEventosEndpoint(contratoId),
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(AdminContratoEventoModel.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao listar eventos do contrato');
    }
  }

  Future<AdminContratoEventoModel> adicionarEventoContrato({
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
        return AdminContratoEventoModel.fromJson(Map<String, dynamic>.from(response.data));
      }
      throw Exception('Falha ao adicionar evento');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao adicionar evento ao contrato');
    }
  }

  Future<List<AdminModuloModel>> listarCatalogoModulos() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.adminModulosCatalogoEndpoint);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(AdminModuloModel.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao listar módulos');
    }
  }

  Future<List<String>> listarModulosEmpresa(String tenantId) async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.adminModulosEmpresaEndpoint(tenantId));
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).whereType<String>().toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao listar módulos da empresa');
    }
  }

  Future<List<String>> atualizarModulosEmpresa(String tenantId, List<String> modulos) async {
    try {
      final response = await _dioClient.dio.put(
        ApiConstants.adminModulosEmpresaEndpoint(tenantId),
        data: {'modulos': modulos},
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).whereType<String>().toList();
      }
      throw Exception('Falha ao atualizar módulos da empresa');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao atualizar módulos da empresa');
    }
  }

  Future<void> cadastrarColaborador({
    required String cpf,
    required String nome,
    String? emailCorporativo,
    required String senha,
    String? matricula,
    String? cargo,
    String? departamento,
    required String dataNascimento,
    required String dataAdmissao,
    String? dataDesligamento,
    String? tenantId,
    bool acessoEstoque = false,
    bool acessoPatrimonio = false,
    bool acessoFrota = false,
    bool acessoProtocolo = false,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/colaboradores',
        data: {
          'cpf': cpf,
          'nome': nome,
          'emailCorporativo': emailCorporativo,
          'senha': senha,
          'matricula': matricula,
          'cargo': cargo,
          'departamento': departamento,
          'dataNascimento': dataNascimento,
          'dataAdmissao': dataAdmissao,
          'dataDesligamento': dataDesligamento,
          if (tenantId != null && tenantId.isNotEmpty) 'tenantId': tenantId,
          'acessoEstoque': acessoEstoque,
          'acessoPatrimonio': acessoPatrimonio,
          'acessoFrota': acessoFrota,
          'acessoProtocolo': acessoProtocolo,
        },
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Falha ao cadastrar colaborador');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao cadastrar colaborador');
    }
  }

  Future<void> atualizarColaborador({
    required String id,
    required String nome,
    String? emailCorporativo,
    String? matricula,
    String? cargo,
    String? departamento,
    String? dataNascimento,
    String? dataAdmissao,
    String? dataDesligamento,
    bool acessoEstoque = false,
    bool acessoPatrimonio = false,
    bool acessoFrota = false,
    bool acessoProtocolo = false,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        '/colaboradores/$id',
        data: {
          'nome': nome,
          'emailCorporativo': emailCorporativo,
          'matricula': matricula,
          'cargo': cargo,
          'departamento': departamento,
          'dataNascimento': dataNascimento,
          'dataAdmissao': dataAdmissao,
          'dataDesligamento': dataDesligamento,
          'acessoEstoque': acessoEstoque,
          'acessoPatrimonio': acessoPatrimonio,
          'acessoFrota': acessoFrota,
          'acessoProtocolo': acessoProtocolo,
        },
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Falha ao atualizar colaborador');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao atualizar colaborador');
    }
  }

  Future<void> excluirColaborador(String id) async {
    try {
      final response = await _dioClient.dio.delete('/colaboradores/$id');
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Falha ao excluir colaborador');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erro ao excluir colaborador');
    }
  }
}