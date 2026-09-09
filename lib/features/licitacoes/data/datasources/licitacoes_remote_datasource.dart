import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/licitacoes_models.dart';
import '../models/planejamento_licitacao_models.dart';

class LicitacoesRemoteDataSource {
  final DioClient _dioClient;
  LicitacoesRemoteDataSource(this._dioClient);

  Future<List<LicitacaoModel>> getLicitacoes() async {
    final response = await _dioClient.dio.get(ApiConstants.licitacoesEndpoint);
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((json) => LicitacaoModel.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar licitações: ${response.statusCode}');
  }

  Future<LicitacaoModel> criarLicitacao(CadastrarLicitacaoDTO dto) async {
    final response = await _dioClient.dio.post(
      ApiConstants.licitacoesEndpoint,
      data: dto.toJson(),
    );
    return _licitacaoFromResponse(response.statusCode, response.data, 'criar a licitação');
  }

  Future<LicitacaoModel> publicarLicitacao(String id, PublicarLicitacaoDTO dto) async {
    final response = await _dioClient.dio.post(
      ApiConstants.licitacaoPublicarEndpoint(id),
      data: dto.toJson(),
    );
    return _licitacaoFromResponse(response.statusCode, response.data, 'publicar a licitação');
  }

  Future<LicitacaoModel> registrarPropostas(
      String id, RegistrarPropostasLicitacaoDTO dto) async {
    final response = await _dioClient.dio.put(
      ApiConstants.licitacaoPropostasEndpoint(id),
      data: dto.toJson(),
    );
    return _licitacaoFromResponse(response.statusCode, response.data, 'registrar propostas');
  }

  Future<LicitacaoModel> adjudicarLicitacao(String id) async {
    final response = await _dioClient.dio
        .post(ApiConstants.licitacaoAdjudicarEndpoint(id));
    return _licitacaoFromResponse(response.statusCode, response.data, 'adjudicar a licitação');
  }

  Future<LicitacaoModel> homologarLicitacao(String id) async {
    final response = await _dioClient.dio
        .post(ApiConstants.licitacaoHomologarEndpoint(id));
    return _licitacaoFromResponse(response.statusCode, response.data, 'homologar a licitação');
  }

  Future<LicitacaoModel> publicarPncp(String id) async {
    final response = await _dioClient.dio
        .post(ApiConstants.licitacaoPublicarPncpEndpoint(id));
    return _licitacaoFromResponse(response.statusCode, response.data, 'publicar o aviso no PNCP');
  }

  Future<void> cancelarLicitacao(String id) async {
    final response = await _dioClient.dio
        .post(ApiConstants.licitacaoCancelarEndpoint(id));
    if (response.statusCode != 200) {
      throw Exception('Falha ao cancelar a licitação: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> gerarPedidos(String id) async {
    final response = await _dioClient.dio
        .post(ApiConstants.licitacaoGerarPedidosEndpoint(id));
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((json) => Map<String, dynamic>.from(json)).toList();
    }
    throw Exception('Falha ao gerar pedidos da licitação: ${response.statusCode}');
  }

  // ============================ PLANEJAMENTO (R28) ============================

  Future<PlanejamentoLicitacaoModel> getPlanejamento(String id) async {
    final response = await _dioClient.dio
        .get(ApiConstants.licitacaoPlanejamentoEndpoint(id));
    return _planejamentoFromResponse(
        response.statusCode, response.data, 'carregar o planejamento');
  }

  Future<PlanejamentoLicitacaoModel> salvarEtp(String id, EtpDTO dto) async {
    final response = await _dioClient.dio
        .put(ApiConstants.licitacaoEtpEndpoint(id), data: dto.toJson());
    return _planejamentoFromResponse(response.statusCode, response.data, 'salvar o ETP');
  }

  Future<PlanejamentoLicitacaoModel> aprovarEtp(
      String id, AprovacaoDocumentoDTO dto) async {
    final response = await _dioClient.dio
        .post(ApiConstants.licitacaoEtpAprovarEndpoint(id), data: dto.toJson());
    return _planejamentoFromResponse(response.statusCode, response.data, 'aprovar o ETP');
  }

  Future<PlanejamentoLicitacaoModel> salvarTr(String id, TrDTO dto) async {
    final response = await _dioClient.dio
        .put(ApiConstants.licitacaoTrEndpoint(id), data: dto.toJson());
    return _planejamentoFromResponse(response.statusCode, response.data, 'salvar o Termo de Referência');
  }

  Future<PlanejamentoLicitacaoModel> aprovarTr(
      String id, AprovacaoDocumentoDTO dto) async {
    final response = await _dioClient.dio
        .post(ApiConstants.licitacaoTrAprovarEndpoint(id), data: dto.toJson());
    return _planejamentoFromResponse(response.statusCode, response.data, 'aprovar o Termo de Referência');
  }

  Future<PlanejamentoLicitacaoModel> salvarEdital(String id, EditalDTO dto) async {
    final response = await _dioClient.dio
        .put(ApiConstants.licitacaoEditalEndpoint(id), data: dto.toJson());
    return _planejamentoFromResponse(response.statusCode, response.data, 'salvar o edital');
  }

  Future<PlanejamentoLicitacaoModel> publicarEdital(String id) async {
    final response = await _dioClient.dio
        .post(ApiConstants.licitacaoEditalPublicarEndpoint(id));
    return _planejamentoFromResponse(response.statusCode, response.data, 'publicar o edital');
  }

  LicitacaoModel _licitacaoFromResponse(int? status, dynamic data, String acao) {
    if (status == 200 && data is Map<String, dynamic>) {
      return LicitacaoModel.fromJson(data);
    }
    throw Exception('Falha ao $acao: $status');
  }

  PlanejamentoLicitacaoModel _planejamentoFromResponse(
      int? status, dynamic data, String acao) {
    if (status == 200 && data is Map<String, dynamic>) {
      return PlanejamentoLicitacaoModel.fromJson(data);
    }
    throw Exception('Falha ao $acao: $status');
  }
}