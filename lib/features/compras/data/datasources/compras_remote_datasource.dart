import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/compras_models.dart';

class ComprasRemoteDataSource {
  final DioClient _dioClient;

  ComprasRemoteDataSource(this._dioClient);

  Future<List<FornecedorModel>> getFornecedores() async {
    final response = await _dioClient.dio.get(ApiConstants.comprasFornecedoresEndpoint);
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((json) => FornecedorModel.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar fornecedores: ${response.statusCode}');
  }

  Future<FornecedorModel> cadastrarFornecedor(CadastrarFornecedorDTO dto) async {
    final response = await _dioClient.dio.post(
      ApiConstants.comprasFornecedoresEndpoint,
      data: dto.toJson(),
    );
    if (response.statusCode == 200) {
      return FornecedorModel.fromJson(response.data);
    }
    throw Exception('Falha ao cadastrar fornecedor: ${response.statusCode}');
  }

  Future<FornecedorModel> atualizarFornecedor(
    String id,
    AtualizarFornecedorDTO dto,
  ) async {
    final response = await _dioClient.dio.put(
      '${ApiConstants.comprasFornecedoresEndpoint}/$id',
      data: dto.toJson(),
    );
    if (response.statusCode == 200) {
      return FornecedorModel.fromJson(response.data);
    }
    throw Exception('Falha ao atualizar fornecedor: ${response.statusCode}');
  }

  Future<void> inativarFornecedor(String id) async {
    final response = await _dioClient.dio.delete(
      '${ApiConstants.comprasFornecedoresEndpoint}/$id',
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao inativar fornecedor: ${response.statusCode}');
    }
  }

  Future<List<PedidoCompraModel>> getPedidos() async {
    final response = await _dioClient.dio.get(ApiConstants.comprasPedidosEndpoint);
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((json) => PedidoCompraModel.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar pedidos de compra: ${response.statusCode}');
  }

  Future<PedidoCompraModel> criarPedido(CadastrarPedidoCompraDTO dto) async {
    final response = await _dioClient.dio.post(
      ApiConstants.comprasPedidosEndpoint,
      data: dto.toJson(),
    );
    if (response.statusCode == 200) {
      return PedidoCompraModel.fromJson(response.data);
    }
    throw Exception('Falha ao criar pedido de compra: ${response.statusCode}');
  }

  Future<void> cancelarPedido(String pedidoId) async {
    final response = await _dioClient.dio.post(
      '${ApiConstants.comprasPedidosEndpoint}/$pedidoId/cancelar',
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao cancelar pedido: ${response.statusCode}');
    }
  }

  Future<EntradaNfeModel> receberNfe(ReceberNfeDTO dto) async {
    final response = await _dioClient.dio.post(
      ApiConstants.comprasNfeReceberEndpoint,
      data: dto.toJson(),
    );
    if (response.statusCode == 200) {
      return EntradaNfeModel.fromJson(response.data);
    }
    throw Exception('Falha ao registrar recebimento por NFe: ${response.statusCode}');
  }

  Future<List<EntradaNfeModel>> getEntradasNfe() async {
    final response = await _dioClient.dio.get(ApiConstants.comprasNfeEndpoint);
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((json) => EntradaNfeModel.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar entradas por NFe: ${response.statusCode}');
  }

  Future<NfeImportadoModel> importarXmlNfe(List<int> bytes, String nomeArquivo) async {
    final formData = FormData.fromMap({
      'arquivo': MultipartFile.fromBytes(bytes, filename: nomeArquivo),
    });
    final response = await _dioClient.dio.post(
      ApiConstants.comprasNfeImportarXmlEndpoint,
      data: formData,
    );
    if (response.statusCode == 200) {
      return NfeImportadoModel.fromJson(response.data);
    }
    throw Exception('Falha ao importar o XML da NFe: ${response.statusCode}');
  }

  Future<NfeImportadoModel> consultarSefazNfe(String chaveNfe) async {
    final response = await _dioClient.dio.post(
      ApiConstants.comprasNfeConsultarSefazEndpoint,
      data: {'chaveNfe': chaveNfe.replaceAll(RegExp('[^0-9]'), '')},
    );
    if (response.statusCode == 200) {
      return NfeImportadoModel.fromJson(response.data);
    }
    throw Exception('Falha ao consultar a NFe na SEFAZ: ${response.statusCode}');
  }

  Future<List<PrecoConsultaModel>> getPrecos() async {
    final response = await _dioClient.dio.get(ApiConstants.comprasPrecosEndpoint);
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((json) => PrecoConsultaModel.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar banco de preços: ${response.statusCode}');
  }

  Future<List<RequisicaoCompraModel>> getRequisicoes() async {
    final response = await _dioClient.dio.get(ApiConstants.comprasRequisicoesEndpoint);
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((json) => RequisicaoCompraModel.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar requisições de compra: ${response.statusCode}');
  }

  Future<RequisicaoCompraModel> criarRequisicao(CadastrarRequisicaoDTO dto) async {
    final response = await _dioClient.dio.post(
      ApiConstants.comprasRequisicoesEndpoint,
      data: dto.toJson(),
    );
    if (response.statusCode == 200) {
      return RequisicaoCompraModel.fromJson(response.data);
    }
    throw Exception('Falha ao criar requisição de compra: ${response.statusCode}');
  }

  Future<void> cancelarRequisicao(String id) async {
    final response = await _dioClient.dio.post(
      ApiConstants.comprasRequisicaoCancelarEndpoint(id),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao cancelar requisição: ${response.statusCode}');
    }
  }

  Future<List<CotacaoCompraModel>> getCotacoes() async {
    final response = await _dioClient.dio.get(ApiConstants.comprasCotacoesEndpoint);
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((json) => CotacaoCompraModel.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar cotações: ${response.statusCode}');
  }

  Future<CotacaoCompraModel> criarCotacao(CadastrarCotacaoDTO dto) async {
    final response = await _dioClient.dio.post(
      ApiConstants.comprasCotacoesEndpoint,
      data: dto.toJson(),
    );
    if (response.statusCode == 200) {
      return CotacaoCompraModel.fromJson(response.data);
    }
    throw Exception('Falha ao criar cotação: ${response.statusCode}');
  }

  Future<CotacaoCompraModel> registrarPropostas(
    String cotacaoId,
    RegistrarPropostasDTO dto,
  ) async {
    final response = await _dioClient.dio.put(
      ApiConstants.comprasCotacaoPropostasEndpoint(cotacaoId),
      data: dto.toJson(),
    );
    if (response.statusCode == 200) {
      return CotacaoCompraModel.fromJson(response.data);
    }
    throw Exception('Falha ao registrar propostas: ${response.statusCode}');
  }

  Future<CotacaoCompraModel> concluirCotacao(String id) async {
    final response = await _dioClient.dio.post(
      ApiConstants.comprasCotacaoConcluirEndpoint(id),
    );
    if (response.statusCode == 200) {
      return CotacaoCompraModel.fromJson(response.data);
    }
    throw Exception('Falha ao concluir cotação: ${response.statusCode}');
  }

  Future<void> cancelarCotacao(String id) async {
    final response = await _dioClient.dio.post(
      ApiConstants.comprasCotacaoCancelarEndpoint(id),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao cancelar cotação: ${response.statusCode}');
    }
  }

  Future<List<PedidoCompraModel>> gerarPedidosCotacao(String id) async {
    final response = await _dioClient.dio.post(
      ApiConstants.comprasCotacaoGerarPedidosEndpoint(id),
    );
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((json) => PedidoCompraModel.fromJson(json)).toList();
    }
    throw Exception('Falha ao gerar pedidos a partir da cotação: ${response.statusCode}');
  }
}