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

  Future<void> cadastrarColaborador({
    required String cpf,
    required String nome,
    required String emailCorporativo,
    required String senha,
    String? matricula,
    String? cargo,
    String? departamento,
    required String dataNascimento,
    required String dataAdmissao,
    String? tenantId,
    bool acessoEstoque = false,
  }) async {
    await _dioClient.dio.post(
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
        if (tenantId != null && tenantId.isNotEmpty) 'tenantId': tenantId,
        'acessoEstoque': acessoEstoque,
      },
    );
  }
}
