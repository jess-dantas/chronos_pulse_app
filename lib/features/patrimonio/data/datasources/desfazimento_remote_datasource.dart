import 'package:chronos_pulse_app/core/constants/api_constants.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/network/paginated_response.dart';
import '../models/patrimonio_models.dart';

class DesfazimentoRemoteDataSource {
  final DioClient _dioClient;

  DesfazimentoRemoteDataSource(this._dioClient);

  Future<PaginatedResponse<DesfazimentoModel>> listarDesfazimentos({
    int page = 0,
    int size = 50,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'size': size};
    final response = await _dioClient.dio.get(
      ApiConstants.patrimonioDesfazimentosEndpoint,
      queryParameters: queryParams,
    );
    if (response.statusCode == 200) {
      return PaginatedResponse.from(
        response.data,
        (itens) => itens.map(DesfazimentoModel.fromJson).toList(),
      );
    }
    throw Exception('Falha ao carregar solicitações de desfazimento');
  }

  Future<DesfazimentoModel> criarDesfazimento(
    Map<String, dynamic> payload,
  ) async {
    final response = await _dioClient.dio.post(
      ApiConstants.patrimonioDesfazimentosEndpoint,
      data: payload,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return DesfazimentoModel.fromJson(response.data);
    }
    throw Exception('Falha ao solicitar desfazimento');
  }

  Future<DesfazimentoModel> aprovarDesfazimento(
    String id, {
    String? parecerComissao,
  }) async {
    final response = await _dioClient.dio.patch(
      ApiConstants.patrimonioAprovarDesfazimentoEndpoint(id),
      data: {
        if (parecerComissao != null && parecerComissao.isNotEmpty)
          'parecerComissao': parecerComissao,
      },
    );
    if (response.statusCode == 200) {
      return DesfazimentoModel.fromJson(response.data);
    }
    throw Exception('Falha ao aprovar desfazimento');
  }

  Future<void> cancelarDesfazimento(String id) async {
    final response = await _dioClient.dio.delete(
      ApiConstants.patrimonioCancelarDesfazimentoEndpoint(id),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falha ao cancelar desfazimento');
    }
  }
}