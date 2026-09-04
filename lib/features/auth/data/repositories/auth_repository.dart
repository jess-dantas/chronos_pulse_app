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
    String? responsavelCelular,
    required String responsavelSenha,
  }) async {
    final usuario = await _remoteDataSource.cadastrarEmpresa(
      cnpj: cnpj,
      nomeEmpresa: nomeEmpresa,
      responsavelNome: responsavelNome,
      responsavelCpf: responsavelCpf,
      responsavelEmail: responsavelEmail,
      responsavelCelular: responsavelCelular,
      responsavelSenha: responsavelSenha,
    );
    _dioClient.updateToken(usuario.token);
    return usuario;
  }

  Future<UsuarioModel> refreshToken(String refreshToken) async {
    final usuario = await _remoteDataSource.refreshToken(refreshToken);
    _dioClient.updateToken(usuario.token);
    return usuario;
  }

  void logout() {
    _dioClient.updateToken(null);
  }

  void updateToken(String? token) {
    _dioClient.updateToken(token);
  }
}
