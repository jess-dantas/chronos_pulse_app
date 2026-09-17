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

  static List<RegistroPontoModel> _ordenar(List<RegistroPontoModel> lista) {
    return List.from(lista)
      ..sort((a, b) => a.dataHoraDispositivo.compareTo(b.dataHoraDispositivo));
  }

  /// Lista ordenada (pelo horário principal) de células de um dia.
  ///
  /// - Batida original sem ajuste → célula normal.
  /// - Ajuste com batida original no mesmo dia/tipo → célula com [hora] = valor
  ///   ajustado e [horaOriginal] = horário original (sobreposição).
  /// - Ajuste sem batida original → célula de ajuste (marcação incluída).
  static List<CelulaEspelho> celulasDoDia(List<RegistroPontoModel> registros) {
    final origens =
        _ordenar(registros.where((r) => !r.ajusteManual).toList());
    final ajustes =
        _ordenar(registros.where((r) => r.ajusteManual).toList());

    final ajustesUsados = <String>{};
    final resultado = <CelulaEspelho>[];

    for (final origem in origens) {
      RegistroPontoModel? ajuste;
      for (final a in ajustes) {
        if (a.tipoRegistro == origem.tipoRegistro &&
            !ajustesUsados.contains(a.idLocal)) {
          ajuste = a;
          break;
        }
      }

      if (ajuste != null) {
        ajustesUsados.add(ajuste.idLocal);
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
      if (ajustesUsados.contains(ajuste.idLocal)) continue;
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
  /// livre, não perdendo registros) e ajustes sobrepõem a coluna correspondente.
  static List<CelulaEspelho?> colunasDoDia(
    List<RegistroPontoModel> registros, {
    List<String> colunas = ordemTipos,
  }) {
    final celulas = List<CelulaEspelho?>.filled(colunas.length, null);
    final ajustesUsados = <String>{};

    for (final origem in _ordenar(registros.where((r) => !r.ajusteManual).toList())) {
      final indiceFixo = colunas.indexOf(origem.tipoRegistro);
      if (indiceFixo >= 0 && celulas[indiceFixo] == null) {
        celulas[indiceFixo] = CelulaEspelho(
          tipoRegistro: origem.tipoRegistro,
          dataHora: origem.dataHoraDispositivo,
          hora: formatarHora(origem.dataHoraDispositivo),
        );
        continue;
      }
      // Sobra (ex.: segunda Entrada no dia): primeira coluna livre
      final livre = celulas.indexWhere((c) => c == null);
      if (livre >= 0) {
        celulas[livre] = CelulaEspelho(
          tipoRegistro: origem.tipoRegistro,
          dataHora: origem.dataHoraDispositivo,
          hora: formatarHora(origem.dataHoraDispositivo),
        );
      }
    }

    for (final ajuste in _ordenar(registros.where((r) => r.ajusteManual).toList())) {
      final indiceFixo = colunas.indexOf(ajuste.tipoRegistro);
      final alvo = indiceFixo >= 0 && celulas[indiceFixo] != null
          ? indiceFixo
          : celulas.indexWhere((c) => c == null);

      if (alvo >= 0) {
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
        ajustesUsados.add(ajuste.idLocal);
      }
    }

    return celulas;
  }
}