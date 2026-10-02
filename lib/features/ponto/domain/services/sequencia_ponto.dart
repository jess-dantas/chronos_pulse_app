import '../../data/models/registro_ponto_model.dart';

/// Sequência oficial de marcações: Entrada → Intervalo → Retorno → Saída.
class SequenciaPonto {
  static const List<String> ordem = [
    'ENTRADA',
    'INTERVALO',
    'RETORNO',
    'SAIDA',
  ];

  /// Próximo tipo da sequência pela MESMA regra do backend
  /// (`RegistrarPontoUseCaseImpl.determinarProximoTipo`): pega o último tipo
  /// do dia em ordem cronológica — contando também ajustes manuais, que o
  /// servidor considera ao derivar — e devolve o próximo do ciclo.
  ///
  /// Tipo desconhecido/legado ou lista vazia → ENTRADA (fallback idêntico ao
  /// do BE). Usar contagem (`length % 4`) divergia do servidor depois de um
  /// ajuste: o botão anunciava um tipo e o servidor gravava outro.
  static String proximo(List<RegistroPontoModel> registros) {
    if (registros.isEmpty) return ordem.first;

    final ordenados = [...registros]
      ..sort((a, b) => a.dataHoraDispositivo.compareTo(b.dataHoraDispositivo));
    final indice = ordem.indexOf(ordenados.last.tipoRegistro);
    if (indice < 0) return ordem.first;
    return ordem[(indice + 1) % ordem.length];
  }
}
