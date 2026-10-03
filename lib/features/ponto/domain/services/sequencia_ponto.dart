import '../../data/models/registro_ponto_model.dart';

/// Sequência de marcações da jornada pela MESMA regra POSICIONAL do backend
/// (`RegistrarPontoUseCaseImpl`): 4 batidas principais + 2 de hora extra,
/// para qualquer regime (6h, 8h, 12h, 12x36, noturno).
class SequenciaPonto {
  static const List<String> ordem = [
    'ENTRADA',
    'INTERVALO',
    'RETORNO',
    'SAIDA',
    'ENTRADA', // 5ª batida: entrada de hora extra
    'SAIDA', // 6ª batida: saída de hora extra
  ];

  /// Intervalo máximo entre duas batidas da MESMA jornada (espelha
  /// `RegistrarPontoUseCaseImpl.LIMITE_JORNADA`): um turno que atravessa a
  /// virada continua a mesma jornada; um abismo maior abre jornada nova.
  static const Duration limiteJornada = Duration(hours: 10);

  /// A jornada fecha nas 6 batidas; a 7ª reinicia em ENTRADA.
  static const int tamanhoJornada = 6;

  /// Próximo tipo da sequência pela regra do backend: conta quantas batidas
  /// da MESMA jornada já existem (janela de até 10h entre vizinhas, teto de
  /// 6) e devolve a posição seguinte — a posição manda, não o tipo anterior,
  /// por isso a 5ª volta a ser ENTRADA e a 6ª é SAIDA.
  ///
  /// [agora] é o instante em que a próxima batida aconteceria (o relógio do
  /// dispositivo): se a última batida estiver a mais de 10h dele, a batida
  /// nova abre jornada nova. Sem [agora], vale só a cadeia da lista (usado
  /// para ajuste de dias anteriores, onde o relógio de hoje não decide).
  static String proximo(List<RegistroPontoModel> registros, {DateTime? agora}) {
    if (registros.isEmpty) return ordem.first;

    final instantes = registros.map((r) => r.dataHoraDispositivo).toList()
      ..sort((a, b) => a.compareTo(b));

    int posicao = 0;
    DateTime anterior = agora ?? instantes.last;
    for (int i = instantes.length - 1;
        i >= 0 && posicao < tamanhoJornada;
        i--) {
      if (anterior.difference(instantes[i]) > limiteJornada) break;
      posicao++;
      anterior = instantes[i];
    }
    return ordem[posicao % ordem.length];
  }
}
