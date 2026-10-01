import 'package:intl/intl.dart';
import '../../data/models/registro_ponto_model.dart';

/// Uma "célula" de espelho: a marcação exibida para um tipo de registro em um dia.
///
/// Quando há um ajuste manual cobrindo a batida original, [hora] é o valor
/// ajustado e [horaOriginal] carrega o horário original (botão), exibido entre
/// parênteses apenas para efeito de histórico.
class CelulaEspelho {
  final String tipoRegistro; // ENTRADA | INTERVALO | RETORNO | SAIDA
  final DateTime dataHora; // horário principal (ajustado, se houver)
  final String hora; // HH:mm principal
  final String? horaOriginal; // HH:mm original quando há sobreposição
  final bool ajuste;
  final bool incluiOriginal;
  final String? justificativa;
  final String? observacao;

  const CelulaEspelho({
    required this.tipoRegistro,
    required this.dataHora,
    required this.hora,
    this.horaOriginal,
    this.ajuste = false,
    this.incluiOriginal = false,
    this.justificativa,
    this.observacao,
  });
}

/// Agrupa os registros de um dia do espelho, sobrepondo o ajuste manual sobre a
/// batida original de mesmo tipo. Usado igualmente na tela e no PDF.
class EspelhoAgrupador {
  static const List<String> ordemTipos = [
    'ENTRADA',
    'INTERVALO',
    'RETORNO',
    'SAIDA',
  ];

  static String formatarHora(DateTime dataHora) =>
      DateFormat('HH:mm').format(dataHora.toLocal());

  /// Distância máxima entre um ajuste e a batida original do mesmo tipo para
  /// que o ajuste a sobrepõe (correção de horário). Mais longe que isso é uma
  /// marcação extra do dia (ex.: hora extra) e ganha célula própria.
  static const Duration sobreposicaoMaxima = Duration(hours: 4);

  /// Pareia ajustes com batidas originais do mesmo tipo por proximidade:
  /// candidatos em ordem crescentes de distância, cada batida e cada ajuste
  /// usados no máximo uma vez. Retorna `idLocal do ajuste → idLocal original`.
  static Map<String, String> parearPorProximidade(
    List<RegistroPontoModel> origens,
    List<RegistroPontoModel> ajustes,
  ) {
    final candidatos =
        <({RegistroPontoModel origem, RegistroPontoModel ajuste, int distancia})>[];
    for (final origem in origens) {
      for (final ajuste in ajustes) {
        if (ajuste.tipoRegistro != origem.tipoRegistro) continue;
        final distancia = ajuste.dataHoraDispositivo
            .difference(origem.dataHoraDispositivo)
            .abs()
            .inMinutes;
        if (distancia < sobreposicaoMaxima.inMinutes) {
          candidatos.add((origem: origem, ajuste: ajuste, distancia: distancia));
        }
      }
    }
    candidatos.sort((a, b) => a.distancia.compareTo(b.distancia));

    final origensUsadas = <String>{};
    final ajustesUsados = <String>{};
    final pareamento = <String, String>{};
    for (final c in candidatos) {
      if (origensUsadas.contains(c.origem.idLocal) ||
          ajustesUsados.contains(c.ajuste.idLocal)) {
        continue;
      }
      origensUsadas.add(c.origem.idLocal);
      ajustesUsados.add(c.ajuste.idLocal);
      pareamento[c.ajuste.idLocal] = c.origem.idLocal;
    }
    return pareamento;
  }

  static List<RegistroPontoModel> _ordenar(List<RegistroPontoModel> lista) {
    return List.from(lista)
      ..sort((a, b) => a.dataHoraDispositivo.compareTo(b.dataHoraDispositivo));
  }

  /// Lista ordenada (pelo horário principal) de células de um dia.
  ///
  /// - Batida original sem ajuste → célula normal.
  /// - Ajuste próximo da batida original (mesmo tipo, até [sobreposicaoMaxima])
  ///   → célula com [hora] = valor ajustado e [horaOriginal] = horário original.
  /// - Ajuste sem batida original próxima → célula de ajuste (marcação incluída,
  ///   ex.: marcação extra/HORA EXTRA do dia).
  static List<CelulaEspelho> celulasDoDia(List<RegistroPontoModel> registros) {
    final origens =
        _ordenar(registros.where((r) => !r.ajusteManual).toList());
    final ajustes =
        _ordenar(registros.where((r) => r.ajusteManual).toList());

    final pareamento = parearPorProximidade(origens, ajustes);
    final ajustePorOrigem = <String, RegistroPontoModel>{};
    for (final ajuste in ajustes) {
      final origemId = pareamento[ajuste.idLocal];
      if (origemId != null) ajustePorOrigem[origemId] = ajuste;
    }

    final resultado = <CelulaEspelho>[];

    for (final origem in origens) {
      final ajuste = ajustePorOrigem[origem.idLocal];

      if (ajuste != null) {
        resultado.add(CelulaEspelho(
          tipoRegistro: origem.tipoRegistro,
          dataHora: ajuste.dataHoraDispositivo,
          hora: formatarHora(ajuste.dataHoraDispositivo),
          horaOriginal: formatarHora(origem.dataHoraDispositivo),
          ajuste: true,
          incluiOriginal: true,
          justificativa: ajuste.justificativa,
          observacao: ajuste.observacao,
        ));
      } else {
        resultado.add(CelulaEspelho(
          tipoRegistro: origem.tipoRegistro,
          dataHora: origem.dataHoraDispositivo,
          hora: formatarHora(origem.dataHoraDispositivo),
        ));
      }
    }

    for (final ajuste in ajustes) {
      if (pareamento.containsKey(ajuste.idLocal)) continue;
      resultado.add(CelulaEspelho(
        tipoRegistro: ajuste.tipoRegistro,
        dataHora: ajuste.dataHoraDispositivo,
        hora: formatarHora(ajuste.dataHoraDispositivo),
        ajuste: true,
        incluiOriginal: false,
        justificativa: ajuste.justificativa,
        observacao: ajuste.observacao,
      ));
    }

    resultado.sort((a, b) => a.dataHora.compareTo(b.dataHora));
    return resultado;
  }

  /// Monta as 4 colunas do PDF (Entrada, Intervalo, Retorno, Saída).
  ///
  /// Batidas originais ocupam sua coluna (com sobra caindo na primeira coluna
  /// livre, não perdendo registros); ajustes próximos sobrepõem a célula da
  /// batida pareada e os demais vão para a primeira coluna livre (ou são
  /// descartados quando as 4 colunas já estão cheias).
  static List<CelulaEspelho?> colunasDoDia(
    List<RegistroPontoModel> registros, {
    List<String> colunas = ordemTipos,
  }) {
    final celulas = List<CelulaEspelho?>.filled(colunas.length, null);
    final origens =
        _ordenar(registros.where((r) => !r.ajusteManual).toList());
    final ajustes =
        _ordenar(registros.where((r) => r.ajusteManual).toList());
    final pareamento = parearPorProximidade(origens, ajustes);

    final indiceDeOrigem = <String, int>{};
    for (final origem in origens) {
      final indiceFixo = colunas.indexOf(origem.tipoRegistro);
      int? alvo;
      if (indiceFixo >= 0 && celulas[indiceFixo] == null) {
        alvo = indiceFixo;
      } else {
        final livre = celulas.indexWhere((c) => c == null);
        if (livre >= 0) alvo = livre;
      }
      if (alvo == null) continue;

      celulas[alvo] = CelulaEspelho(
        tipoRegistro: origem.tipoRegistro,
        dataHora: origem.dataHoraDispositivo,
        hora: formatarHora(origem.dataHoraDispositivo),
      );
      indiceDeOrigem[origem.idLocal] = alvo;
    }

    for (final ajuste in ajustes) {
      final origemId = pareamento[ajuste.idLocal];
      final alvo = origemId != null && indiceDeOrigem.containsKey(origemId)
          ? indiceDeOrigem[origemId]!
          : celulas.indexWhere((c) => c == null);
      if (alvo < 0) continue;

      final base = celulas[alvo];
      celulas[alvo] = CelulaEspelho(
        tipoRegistro: ajuste.tipoRegistro,
        dataHora: ajuste.dataHoraDispositivo,
        hora: formatarHora(ajuste.dataHoraDispositivo),
        horaOriginal: base?.hora,
        ajuste: true,
        incluiOriginal: base != null,
        justificativa: ajuste.justificativa,
        observacao: ajuste.observacao,
      );
    }

    return celulas;
  }
}