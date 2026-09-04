import '../datasources/auth_remote_datasource.dart';
import '../models/usuario_model.dart';
import '../../../../core/network/dio_client.dart';

class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final DioClient _dioClient;

  AuthRepository({
    required AuthRemoteDataSource remoteDataSource,
    required DioClient dioClient,
  })  : _remoteDataSource = remoteDataSource,
        _dioClient = dioClient;

  Future<UsuarioModel> login({
    required String cpf,
    required String senha,
  }) async {
    final usuario = await _remoteDataSource.login(cpf: cpf, senha: senha);
    _dioClient.updateToken(usuario.token);
    return usuario;
  }

  Future<UsuarioModel> cadastrarEmpresa({
    required String cnpj,
    required String nomeEmpresa,
    required String responsavelNome,
    required String responsavelCpf,
    required String responsavelEmail,
    String? responsavelTelefone,
    String? responsavelCelular,
    required String responsavelSenha,
    String? enderecoLogradouro,
    String? enderecoNumero,
    String? enderecoComplemento,
    String? enderecoBairro,
    String? enderecoCidade,
    String? enderecoUf,
    String? enderecoCep,
  }) async {
    final usuario = await _remoteDataSource.cadastrarEmpresa(
      cnpj: cnpj,
      nomeEmpresa: nomeEmpresa,
      responsavelNome: responsavelNome,
      responsavelCpf: responsavelCpf,
      responsavelEmail: responsavelEmail,
      responsavelTelefone: responsavelTelefone,
      responsavelCelular: responsavelCelular,
      responsavelSenha: responsavelSenha,
      enderecoLogradouro: enderecoLogradouro,
      enderecoNumero: enderecoNumero,
      enderecoComplemento: enderecoComplemento,
      enderecoBairro: enderecoBairro,
      enderecoCidade: enderecoCidade,
      enderecoUf: enderecoUf,
      enderecoCep: enderecoCep,
    );
    _dioClient.updateToken(usuario.token);
    return usuario;
  }

  Future<UsuarioModel> refreshToken(String refreshToken) async {
    final usuario = await _remoteDataSource.refreshToken(refreshToken);
    _dioClient.updateToken(usuario.token);
    return usuario;
  }

  Future<String> alterarSenha({required String novaSenha}) {
    return _remoteDataSource.alterarSenha(novaSenha: novaSenha);
  }

  Future<String> esqueciSenha({required String cpf}) {
    return _remoteDataSource.esqueciSenha(cpf: cpf);
  }

  Future<String> redefinirSenha({
    required String cpf,
    required String codigo,
    required String novaSenha,
  }) {
    return _remoteDataSource.redefinirSenha(
      cpf: cpf,
      codigo: codigo,
      novaSenha: novaSenha,
    );
  }

  Future<String> enviarFoto(List<int> bytes, String nomeArquivo) {
    return _remoteDataSource.enviarFoto(bytes, nomeArquivo);
  }

  void logout() {
    _dioClient.updateToken(null);
  }

  void updateToken(String? token) {
    _dioClient.updateToken(token);
  }
}
