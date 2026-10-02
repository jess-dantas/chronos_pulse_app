import '../datasources/usuario_remote_datasource.dart';
import '../models/usuario_conta_model.dart';

class UsuarioRepository {
  final UsuarioRemoteDataSource remoteDataSource;

  UsuarioRepository({required this.remoteDataSource});

  Future<List<UsuarioContaModel>> listar() => remoteDataSource.listar();

  Future<UsuarioContaModel> criar({
    required String cpf,
    required String nome,
    String? emailCorporativo,
    required String senha,
    required String papel,
  }) =>
      remoteDataSource.criar(
        cpf: cpf,
        nome: nome,
        emailCorporativo: emailCorporativo,
        senha: senha,
        papel: papel,
      );

  Future<void> suspender(String usuarioId) =>
      remoteDataSource.suspender(usuarioId);
}
