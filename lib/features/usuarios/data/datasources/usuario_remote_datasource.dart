import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/usuario_conta_model.dart';

class UsuarioRemoteDataSource {
  final DioClient _dioClient;

  UsuarioRemoteDataSource(this._dioClient);

  Future<List<UsuarioContaModel>> listar() async {
    final response = await _dioClient.dio.get(ApiConstants.usuariosEndpoint);
    final List<dynamic> data = response.data;
    return data.map((item) => UsuarioContaModel.fromJson(item)).toList();
  }

  Future<UsuarioContaModel> criar({
    required String cpf,
    required String nome,
    String? emailCorporativo,
    required String senha,
    required String papel,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.usuariosEndpoint,
      data: {
        'cpf': cpf,
        'nome': nome,
        'emailCorporativo': emailCorporativo,
        'senha': senha,
        'papel': papel,
      },
    );
    return UsuarioContaModel.fromJson(response.data);
  }

  Future<void> suspender(String usuarioId) async {
    await _dioClient.dio
        .patch(ApiConstants.usuarioSuspenderEndpoint(usuarioId));
  }
}
