import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

class LeadEmpresaRequest {
  final String cnpj;
  final String razaoSocial;
  final String contatoNome;
  final String contatoEmail;
  final String? contatoTelefone;
  final String? contatoCelular;
  final String? enderecoLogradouro;
  final String? enderecoNumero;
  final String? enderecoComplemento;
  final String? enderecoBairro;
  final String? enderecoCidade;
  final String? enderecoUf;
  final String? enderecoCep;
  final String? observacao;

  const LeadEmpresaRequest({
    required this.cnpj,
    required this.razaoSocial,
    required this.contatoNome,
    required this.contatoEmail,
    this.contatoTelefone,
    this.contatoCelular,
    this.enderecoLogradouro,
    this.enderecoNumero,
    this.enderecoComplemento,
    this.enderecoBairro,
    this.enderecoCidade,
    this.enderecoUf,
    this.enderecoCep,
    this.observacao,
  });

  Map<String, dynamic> toJson() => {
        'cnpj': cnpj,
        'razaoSocial': razaoSocial,
        'contatoNome': contatoNome,
        'contatoEmail': contatoEmail,
        'contatoTelefone': contatoTelefone,
        'contatoCelular': contatoCelular,
        'enderecoLogradouro': enderecoLogradouro,
        'enderecoNumero': enderecoNumero,
        'enderecoComplemento': enderecoComplemento,
        'enderecoBairro': enderecoBairro,
        'enderecoCidade': enderecoCidade,
        'enderecoUf': enderecoUf,
        'enderecoCep': enderecoCep,
        'observacao': observacao,
      };
}

class LeadRepository {
  final DioClient _dioClient;

  LeadRepository(this._dioClient);

  Future<void> cadastrar(LeadEmpresaRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.leadsEmpresasEndpoint,
        data: request.toJson(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erro ao registrar os dados.');
      }
    } on DioException catch (e) {
      final msg =
          (e.response?.data is Map ? e.response?.data['message'] : null) ??
              e.message;
      throw Exception(msg ?? 'Erro ao registrar os dados.');
    }
  }
}