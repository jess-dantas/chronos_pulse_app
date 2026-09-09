import 'package:chronos_pulse_app/core/constants/api_constants.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import '../models/patrimonio_models.dart';

class TransferenciaRemoteDataSource {
  final DioClient _dioClient;

  TransferenciaRemoteDataSource(this._dioClient);

  Future<List<TransferenciaModel>> listarTransferencias() async {
    final response = await _dioClient.dio.get(
      ApiConstants.patrimonioTransferenciasEndpoint,
    );
    if (response.statusCode == 200) {
      final itens = (response.data as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TransferenciaModel.fromJson)
          .toList();
      return itens;
    }
    throw Exception('Falha ao carregar transferências');
  }

  Future<TransferenciaModel> solicitar({
    required String patrimonioId,
    required String localizacaoDestino,
    String? localizacaoOrigem,
    String? responsavelOrigem,
    String? responsavelDestino,
    String? dataPrevista,
    String? justificativa,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.patrimonioTransferenciasEndpoint,
      data: {
        'patrimonioId': patrimonioId,
        'localizacaoDestino': localizacaoDestino,
        if (localizacaoOrigem != null && localizacaoOrigem.isNotEmpty)
          'localizacaoOrigem': localizacaoOrigem,
        if (responsavelOrigem != null && responsavelOrigem.isNotEmpty)
          'responsavelOrigem': responsavelOrigem,
        if (responsavelDestino != null && responsavelDestino.isNotEmpty)
          'responsavelDestino': responsavelDestino,
        if (dataPrevista != null && dataPrevista.isNotEmpty)
          'dataPrevista': dataPrevista,
        if (justificativa != null && justificativa.isNotEmpty)
          'justificativa': justificativa,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return TransferenciaModel.fromJson(response.data);
    }
    throw Exception('Falha ao solicitar transferência');
  }

  Future<TransferenciaModel> confirmar(String id) async {
    final response = await _dioClient.dio.post(
      ApiConstants.patrimonioTransferenciaConfirmarEndpoint(id),
    );
    if (response.statusCode == 200) {
      return TransferenciaModel.fromJson(response.data);
    }
    throw Exception('Falha ao confirmar transferência');
  }

  Future<void> cancelar(String id) async {
    final response = await _dioClient.dio.delete(
      ApiConstants.patrimonioTransferenciaCancelarEndpoint(id),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falha ao cancelar transferência');
    }
  }
}