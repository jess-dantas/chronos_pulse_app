import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/colaborador_model.dart';

class ColaboradorRemoteDataSource {
  final DioClient _dioClient;

  ColaboradorRemoteDataSource(this._dioClient);

  Future<List<ColaboradorModel>> listarColaboradores() async {
    final response = await _dioClient.dio.get('/colaboradores');
    final List<dynamic> data = response.data;
    return data.map((item) => ColaboradorModel.fromJson(item)).toList();
  }

  Future<List<String>> listarModulosUsuario(
      String usuarioId, String tenantId) async {
    final response = await _dioClient.dio.get(
      ApiConstants.usuarioModulosEndpoint(usuarioId),
      queryParameters: {'tenantId': tenantId},
    );
    final data = response.data;
    final modulos = data is Map<String, dynamic> ? data['modulos'] : null;
    if (modulos is List) {
      return modulos.whereType<String>().toList();
    }
    return const [];
  }

  Future<void> atualizarModulosUsuario(
      String usuarioId, String tenantId, List<String> codigos) async {
    await _dioClient.dio.put(
      ApiConstants.usuarioModulosEndpoint(usuarioId),
      data: {'tenantId': tenantId, 'codigos': codigos},
    );
  }

  Future<ColaboradorModel> cadastrarColaborador({
    required String cpf,
    required String nome,
    String? emailCorporativo,
    String? celular,
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
    final response = await _dioClient.dio.post(
      '/colaboradores',
      data: {
        'cpf': cpf,
        'nome': nome,
        'emailCorporativo': emailCorporativo,
        'celular': celular,
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
    return ColaboradorModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<void> atualizarColaborador({
    required String id,
    required String nome,
    String? emailCorporativo,
    String? celular,
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
    await _dioClient.dio.put(
      '/colaboradores/$id',
      data: {
        'nome': nome,
        'emailCorporativo': emailCorporativo,
        'celular': celular,
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
  }

  Future<void> excluirColaborador(String id) async {
    await _dioClient.dio.delete('/colaboradores/$id');
  }
}
