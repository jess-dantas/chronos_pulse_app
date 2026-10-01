import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/registro_ponto_model.dart';
import '../../domain/services/sequencia_ponto.dart';

/// Opção do dropdown de ajuste: um slot do dia (marcação existente) ou a
/// próxima batida da sequência.
///
/// O [valor] é composto `TIPO#ordem` para permanecer único quando o dia tem
/// mais de uma marcação do mesmo tipo (2ª ocorrência de um tipo é marcação
/// extra, ex.: hora extra — ganha o rótulo "(HE)"). O backend só recebe o
/// [tipo]; a [ordem] é apenas identificação visual do slot.
class OpcaoAjuste {
  final String valor;
  final String tipo;
  final int ordem;
  final String rotulo;
  final TimeOfDay hora;

  const OpcaoAjuste({
    required this.valor,
    required this.tipo,
    required this.ordem,
    required this.rotulo,
    required this.hora,
  });

  /// Extrai o tipo (`ENTRADA#2` → `ENTRADA`) enviado no payload.
  static String tipoDe(String valor) => valor.split('#').first;
}

/// Opções do dropdown de ajuste, recalculadas a cada dia selecionado.
class OpcoesAjuste {
  static const Map<String, String> _nomes = {
    'ENTRADA': 'Entrada',
    'INTERVALO': 'Intervalo',
    'RETORNO': 'Retorno',
    'SAIDA': 'Saída',
  };

  static String nomeTipo(String tipo) => _nomes[tipo] ?? tipo;

  /// Slots das marcações existentes do dia em ordem cronológica (ocorrências
  /// repetidas do mesmo tipo com o rótulo "(HE)") + a próxima batida da
  /// sequência como última opção (padrão da seleção).
  static List<OpcaoAjuste> doDia(
    List<RegistroPontoModel> registros,
    DateTime data, {
    TimeOfDay? agora,
  }) {
    final doDia = registros.where((r) {
      final d = r.dataHoraDispositivo.toLocal();
      return d.year == data.year && d.month == data.month && d.day == data.day;
    }).toList()
      ..sort((a, b) => a.dataHoraDispositivo.compareTo(b.dataHoraDispositivo));

    final ocorrencias = <String, int>{};
    final opcoes = <OpcaoAjuste>[];
    for (final registro in doDia) {
      final ordem = ocorrencias[registro.tipoRegistro] ?? 0;
      ocorrencias[registro.tipoRegistro] = ordem + 1;
      final hora = registro.dataHoraDispositivo.toLocal();
      final nome = nomeTipo(registro.tipoRegistro);
      opcoes.add(OpcaoAjuste(
        valor: '${registro.tipoRegistro}#$ordem',
        tipo: registro.tipoRegistro,
        ordem: ordem,
        rotulo: ordem == 0
            ? '$nome ${DateFormat('HH:mm').format(hora)}'
            : '$nome (HE) ${DateFormat('HH:mm').format(hora)}',
        hora: TimeOfDay(hour: hora.hour, minute: hora.minute),
      ));
    }

    final proximo = SequenciaPonto.proximo(doDia);
    final ordem = ocorrencias[proximo] ?? 0;
    opcoes.add(OpcaoAjuste(
      valor: '$proximo#$ordem',
      tipo: proximo,
      ordem: ordem,
      rotulo: '${nomeTipo(proximo)} — próxima batida',
      hora: agora ?? TimeOfDay.now(),
    ));
    return opcoes;
  }
}
