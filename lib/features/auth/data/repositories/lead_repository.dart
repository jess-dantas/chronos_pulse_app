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

class LeadEmpresaModel {
  final String id;
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
  final String status;
  final DateTime criadoEm;

  const LeadEmpresaModel({
    required this.id,
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
    required this.status,
    required this.criadoEm,
  });

  factory LeadEmpresaModel.fromJson(Map<String, dynamic> json) {
    return LeadEmpresaModel(
      id: json['id']?.toString() ?? '',
      cnpj: json['cnpj']?.toString() ?? '',
      razaoSocial: json['razaoSocial']?.toString() ?? '',
      contatoNome: json['contatoNome']?.toString() ?? '',
      contatoEmail: json['contatoEmail']?.toString() ?? '',
      contatoTelefone: json['contatoTelefone']?.toString(),
      contatoCelular: json['contatoCelular']?.toString(),
      enderecoLogradouro: json['enderecoLogradouro']?.toString(),
      enderecoNumero: json['enderecoNumero']?.toString(),
      enderecoComplemento: json['enderecoComplemento']?.toString(),
      enderecoBairro: json['enderecoBairro']?.toString(),
      enderecoCidade: json['enderecoCidade']?.toString(),
      enderecoUf: json['enderecoUf']?.toString(),
      enderecoCep: json['enderecoCep']?.toString(),
      observacao: json['observacao']?.toString(),
      status: json['status']?.toString() ?? 'NOVO',
      criadoEm: DateTime.tryParse(json['criadoEm']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  String get cidadeUf {
    final cidade = enderecoCidade?.isNotEmpty == true ? enderecoCidade : null;
    final uf = enderecoUf?.isNotEmpty == true ? enderecoUf : null;
    if (cidade != null && uf != null) return '$cidade/$uf';
    return cidade ?? uf ?? '';
  }
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

  Future<List<LeadEmpresaModel>> listar() async {
    final response = await _dioClient.dio.get(ApiConstants.leadsEndpoint);
    final dados = response.data;
    if (response.statusCode != 200 || dados is! List) {
      throw Exception('Erro ao carregar os leads.');
    }
    return dados
        .map((item) => LeadEmpresaModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<LeadEmpresaModel> alterarStatus(String id, String status) async {
    final response = await _dioClient.dio.patch(
      ApiConstants.leadsStatusEndpoint(id),
      data: {'status': status},
    );
    if (response.statusCode != 200 || response.data is! Map) {
      throw Exception('Erro ao atualizar o status do lead.');
    }
    return LeadEmpresaModel.fromJson(response.data as Map<String, dynamic>);
  }
}