class JustificativaItem {
  final String titulo;
  final String descricao;

  const JustificativaItem({required this.titulo, required this.descricao});

  String get formatoCompleto => '$titulo: $descricao';
}

class JustificativasPonto {
  static const List<JustificativaItem> lista = [
    JustificativaItem(
      titulo: 'Esquecimento de marcação',
      descricao: 'quando o colaborador esquece de registrar entrada, saída ou intervalo.',
    ),
    JustificativaItem(
      titulo: 'Falha técnica',
      descricao: 'problemas no equipamento de ponto ou no crachá/biometria.',
    ),
    JustificativaItem(
      titulo: 'Atividade externa',
      descricao: 'reuniões, visitas a clientes, treinamentos fora da empresa.',
    ),
    JustificativaItem(
      titulo: 'Viagem a trabalho',
      descricao: 'deslocamentos que impossibilitam a marcação no sistema.',
    ),
    JustificativaItem(
      titulo: 'Trabalho remoto',
      descricao: 'ajustes necessários quando o registro não é feito automaticamente.',
    ),
    JustificativaItem(
      titulo: 'Atendimento médico',
      descricao: 'consultas ou exames que impactam o horário de entrada/saída.',
    ),
    JustificativaItem(
      titulo: 'Autorização da liderança',
      descricao: 'situações excepcionais aprovadas pelo gestor.',
    ),
    JustificativaItem(
      titulo: 'Plantão ou sobreaviso',
      descricao: 'quando há necessidade de ajuste por horas extras ou chamadas fora do expediente.',
    ),
  ];
}
