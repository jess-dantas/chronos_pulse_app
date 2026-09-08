import '../datasources/admin_remote_datasource.dart';
import '../models/admin_models.dart';

class AdminRepository {
  final AdminRemoteDataSource _remoteDataSource;

  AdminRepository({required AdminRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<AdminDashboardModel> buscarDashboard() {
    return _remoteDataSource.buscarDashboard();
  }

  Future<List<AdminEmpresaModel>> listarEmpresas() {
    return _remoteDataSource.listarEmpresas();
  }

  Future<List<AdminColaboradorModel>> listarColaboradores() {
    return _remoteDataSource.listarColaboradores();
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
  }) {
    return _remoteDataSource.cadastrarEmpresa(
      cnpj: cnpj,
      nome: nome,
      responsavelNome: responsavelNome,
      responsavelEmail: responsavelEmail,
      responsavelTelefone: responsavelTelefone,
      responsavelCelular: responsavelCelular,
      enderecoLogradouro: enderecoLogradouro,
      enderecoNumero: enderecoNumero,
      enderecoComplemento: enderecoComplemento,
      enderecoBairro: enderecoBairro,
      enderecoCidade: enderecoCidade,
      enderecoUf: enderecoUf,
      enderecoCep: enderecoCep,
    );
  }

  Future<void> atualizarEmpresa({
    required String id,
    String? nome,
    bool? ativo,
  }) {
    return _remoteDataSource.atualizarEmpresa(id: id, nome: nome, ativo: ativo);
  }

  Future<List<AdminContratoModel>> listarContratos({String? tenantId}) {
    return _remoteDataSource.listarContratos(tenantId: tenantId);
  }

  Future<AdminContratoModel> cadastrarContrato({
    required String tenantId,
    required String numero,
    required String objeto,
    required String dataInicio,
    required String dataFim,
    required double valorMensal,
    required double valorTotal,
    double? valorEmpenhado,
    double? valorLiquidado,
    String? empenhoNumero,
    int? vencimentoAvisoDias,
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
      valorEmpenhado: valorEmpenhado,
      valorLiquidado: valorLiquidado,
      empenhoNumero: empenhoNumero,
      vencimentoAvisoDias: vencimentoAvisoDias,
      observacoes: observacoes,
    );
  }

  Future<AdminContratoModel> atualizarSaldoContrato({
    required String contratoId,
    double? valorEmpenhado,
    double? valorLiquidado,
    String? empenhoNumero,
    int? vencimentoAvisoDias,
  }) {
    return _remoteDataSource.atualizarSaldoContrato(
      contratoId: contratoId,
      valorEmpenhado: valorEmpenhado,
      valorLiquidado: valorLiquidado,
      empenhoNumero: empenhoNumero,
      vencimentoAvisoDias: vencimentoAvisoDias,
    );
  }

  Future<List<AdminContratoEventoModel>> listarEventosContrato(String contratoId) {
    return _remoteDataSource.listarEventosContrato(contratoId);
  }

  Future<AdminContratoEventoModel> adicionarEventoContrato({
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

  Future<List<AdminModuloModel>> listarCatalogoModulos() {
    return _remoteDataSource.listarCatalogoModulos();
  }

  Future<List<String>> listarModulosEmpresa(String tenantId) {
    return _remoteDataSource.listarModulosEmpresa(tenantId);
  }

  Future<List<String>> atualizarModulosEmpresa(String tenantId, List<String> modulos) {
    return _remoteDataSource.atualizarModulosEmpresa(tenantId, modulos);
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
  }) {
    return _remoteDataSource.cadastrarColaborador(
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
  }) {
    return _remoteDataSource.atualizarColaborador(
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

  Future<void> excluirColaborador(String id) {
    return _remoteDataSource.excluirColaborador(id);
  }
}
