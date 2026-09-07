import 'package:chronos_pulse_app/core/constants/api_constants.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import '../models/protocolo_models.dart';

class ProtocoloRemoteDataSource {
  final DioClient _dioClient;

  ProtocoloRemoteDataSource(this._dioClient);

  Future<List<ProtocoloModel>> getProtocolos() async {
    final queryParams = <String, dynamic>{'page': 0, 'size': 100};
    final response = await _dioClient.dio.get(
      ApiConstants.protocoloEndpoint,
      queryParameters: queryParams,
    );
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data.map((e) => ProtocoloModel.fromJson(e)).toList();
      }
      if (data is Map) {
        final content = data['content'] as List? ?? [];
        return content.map((e) => ProtocoloModel.fromJson(e)).toList();
      }
    }
    throw Exception('Falha ao carregar protocolos');
  }

  Future<ProtocoloModel> criarProtocolo(Map<String, dynamic> payload) async {
    final response = await _dioClient.dio.post(
      ApiConstants.protocoloEndpoint,
      data: payload,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ProtocoloModel.fromJson(response.data);
    }
    throw Exception('Falha ao cadastrar protocolo');
  }

  Future<ProtocoloModel> atualizarStatus(
    String id,
    String status, {
    String? responsavel,
    String? observacoes,
  }) async {
    final response = await _dioClient.dio.patch(
      '${ApiConstants.protocoloEndpoint}/$id/status',
      data: {
        'status': status,
        if (responsavel != null && responsavel.isNotEmpty) 'responsavel': responsavel,
        if (observacoes != null && observacoes.isNotEmpty) 'observacoes': observacoes,
      },
    );
    if (response.statusCode == 200) {
      return ProtocoloModel.fromJson(response.data);
    }
    throw Exception('Falha ao atualizar status');
  }
}