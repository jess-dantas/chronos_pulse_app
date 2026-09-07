import 'package:chronos_pulse_app/core/constants/api_constants.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import '../models/patrimonio_models.dart';

class PatrimonioRemoteDataSource {
  final DioClient _dioClient;

  PatrimonioRemoteDataSource(this._dioClient);

  Future<List<PatrimonioModel>> getBens() async {
    final queryParams = <String, dynamic>{'page': 0, 'size': 100};
    final response = await _dioClient.dio.get(
      ApiConstants.patrimonioEndpoint,
      queryParameters: queryParams,
    );
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data.map((e) => PatrimonioModel.fromJson(e)).toList();
      }
      if (data is Map) {
        final content = data['content'] as List? ?? [];
        return content.map((e) => PatrimonioModel.fromJson(e)).toList();
      }
    }
    throw Exception('Falha ao carregar bens patrimoniais');
  }

  Future<PatrimonioModel> criarBem(Map<String, dynamic> payload) async {
    final response = await _dioClient.dio.post(
      ApiConstants.patrimonioEndpoint,
      data: payload,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return PatrimonioModel.fromJson(response.data);
    }
    throw Exception('Falha ao cadastrar bem patrimonial');
  }
}