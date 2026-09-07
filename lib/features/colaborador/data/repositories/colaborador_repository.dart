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
      dataDesligamento: dataDesligamento,
      tenantId: tenantId,
      acessoEstoque: acessoEstoque,
      acessoPatrimonio: acessoPatrimonio,
      acessoFrota: acessoFrota,
      acessoProtocolo: acessoProtocolo,
    );
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
    return await remoteDataSource.atualizarColaborador(
      id: id,
      nome: nome,
      emailCorporativo: emailCorporativo,
      matricula: matricula,
      cargo: cargo,
      departamento: departamento,
      dataNascimento: dataNascimento,
      dataAdmissao: dataAdmissao,
      dataDesligamento: dataDesligamento,
      acessoEstoque: acessoEstoque,
      acessoPatrimonio: acessoPatrimonio,
      acessoFrota: acessoFrota,
      acessoProtocolo: acessoProtocolo,
    );
  }

  Future<void> excluirColaborador(String id) async {
    return await remoteDataSource.excluirColaborador(id);
  }
}
