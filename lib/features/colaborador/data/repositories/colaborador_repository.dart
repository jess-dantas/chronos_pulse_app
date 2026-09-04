import '../datasources/colaborador_remote_datasource.dart';
import '../models/colaborador_model.dart';

class ColaboradorRepository {
  final ColaboradorRemoteDataSource remoteDataSource;

  ColaboradorRepository({required this.remoteDataSource});

  Future<List<ColaboradorModel>> listarColaboradores() async {
    return await remoteDataSource.listarColaboradores();
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
    return await remoteDataSource.cadastrarColaborador(
      cpf: cpf,
      nome: nome,
      emailCorporativo: emailCorporativo,
      senha: senha,
      matricula: matricula,
      cargo: cargo,
      departamento: departamento,
      dataNascimento: dataNascimento,
      dataAdmissao: dataAdmissao,
      tenantId: tenantId,
      acessoEstoque: acessoEstoque,
    );
  }

  Future<void> atualizarColaborador({
    required String id,
    required String nome,
    required String emailCorporativo,
    String? matricula,
    String? cargo,
    String? departamento,
    String? dataNascimento,
    String? dataAdmissao,
    bool acessoEstoque = false,
  }) async {
    return await remoteDataSource.atualizarColaborador(
      id: id,
      nome: nome,
      emailCorporativo: emailCorporativo,
      matricula: matricula,
      cargo: cargo,
      departamento: departamento,
      dataNascimento: dataNascimento,
      dataAdmissao: dataAdmissao,
      acessoEstoque: acessoEstoque,
    );
  }

  Future<void> excluirColaborador(String id) async {
    return await remoteDataSource.excluirColaborador(id);
  }
}
