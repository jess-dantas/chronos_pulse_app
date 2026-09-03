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

  void logout() {
    _dioClient.updateToken(null);
  }
}
