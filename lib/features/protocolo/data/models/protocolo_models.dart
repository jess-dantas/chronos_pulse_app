class ProtocoloModel {
  final String id;
  final String numeroProtocolo;
  final String tipo;
  final String assunto;
  final String? descricao;
  final String? remetente;
  final String? destinatario;
  final String? dataProtocolo;
  final String status;
  final String? responsavel;
  final String? observacoes;
  final bool ativo;

  ProtocoloModel({
    required this.id,
    required this.numeroProtocolo,
    this.tipo = 'GERAL',
    required this.assunto,
    this.descricao,
    this.remetente,
    this.destinatario,
    this.dataProtocolo,
    this.status = 'RECEBIDO',
    this.responsavel,
    this.observacoes,
    this.ativo = true,
  });

  factory ProtocoloModel.fromJson(Map<String, dynamic> json) {
    return ProtocoloModel(
      id: json['id']?.toString() ?? '',
      numeroProtocolo: json['numeroProtocolo']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'GERAL',
      assunto: json['assunto']?.toString() ?? '',
      descricao: json['descricao']?.toString(),
      remetente: json['remetente']?.toString(),
      destinatario: json['destinatario']?.toString(),
      dataProtocolo: json['dataProtocolo']?.toString(),
      status: json['status']?.toString() ?? 'RECEBIDO',
      responsavel: json['responsavel']?.toString(),
      observacoes: json['observacoes']?.toString(),
      ativo: json['ativo'] ?? true,
    );
  }
}