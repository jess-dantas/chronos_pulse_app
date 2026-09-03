import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/registro_ponto_model.dart';

class PontoRemoteDataSource {
  final DioClient _dioClient;

  PontoRemoteDataSource(this._dioClient);

  Future<void> registrarPonto({
    required RegistroPontoModel registro,
    required String cpfColaborador,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.pontosEndpoint}',
        data: {
          'registros': [registro.toJson()..['sincronizadoOffline'] = true],
        },
        options: Options(
          headers: {'X-CPF-Colaborador': cpfColaborador},
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Falha ao registrar ponto: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Erro de rede ao conectar com a API',
      );
    }
  }
}
