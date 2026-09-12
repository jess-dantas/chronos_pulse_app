import '../../data/models/registro_ponto_model.dart';

/// Sequência oficial de marcações: Entrada → Intervalo → Retorno → Saída.
class SequenciaPonto {
  static const List<String> ordem = [
    'ENTRADA',
    'INTERVALO',
    'RETORNO',
    'SAIDA',
  ];

  /// Próximo tipo da sequência considerando APENAS batidas feitas pelo botão.
  ///
  /// Ajustes manuais (marcação corrigida/incluída) NÃO avançam o ciclo: senão o
  /// histórico mista faria a sequência pular para INTERVALO em vez de alcançar
  /// RETORNO/SAIDA. Mesma regra vale na tela principal e no diálogo de ajuste.
  static String proximo(List<RegistroPontoModel> registros) {
    final batidas = registros.where((r) => !r.ajusteManual).toList();
    return ordem[batidas.length % ordem.length];
  }
}