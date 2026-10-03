import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:chronos_pulse_app/features/ponto/data/models/registro_ponto_model.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/dialogs/solicitar_ajuste_dialog.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/services/opcoes_ajuste.dart';

RegistroPontoModel _registro({
  required String id,
  required String tipo,
  required DateTime quando,
  bool ajusteManual = false,
}) =>
    RegistroPontoModel(
      idLocal: id,
      dataHoraDispositivo: quando,
      tipoRegistro: tipo,
      latitude: 0,
      longitude: 0,
      precisaoGps: 0,
      ajusteManual: ajusteManual,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  // Dia completo de batidas de botão + uma Entrada extra (HE) por ajuste.
  List<RegistroPontoModel> registrosDoDia() => [
        _registro(
            id: 'b1', tipo: 'ENTRADA', quando: DateTime(2026, 9, 12, 8, 0)),
        _registro(
            id: 'b2', tipo: 'INTERVALO', quando: DateTime(2026, 9, 12, 12, 0)),
        _registro(
            id: 'b3', tipo: 'RETORNO', quando: DateTime(2026, 9, 12, 13, 0)),
        _registro(
            id: 'b4', tipo: 'SAIDA', quando: DateTime(2026, 9, 12, 18, 0)),
        _registro(
            id: 'a1',
            tipo: 'ENTRADA',
            quando: DateTime(2026, 9, 12, 19, 0),
            ajusteManual: true),
      ];

  group('OpcoesAjuste.doDia', () {
    test('slots cronológicos, (HE) na duplicata e próxima batida ao final', () {
      final opcoes = OpcoesAjuste.doDia(
        registrosDoDia(),
        DateTime(2026, 9, 12),
        agora: const TimeOfDay(hour: 9, minute: 30),
      );

      expect(opcoes.map((o) => o.valor).toList(), [
        'ENTRADA#0',
        'INTERVALO#0',
        'RETORNO#0',
        'SAIDA#0',
        'ENTRADA#1',
        'SAIDA#1',
      ]);
      expect(opcoes.map((o) => o.rotulo).toList(), [
        'Entrada 08:00',
        'Intervalo 12:00',
        'Retorno 13:00',
        'Saída 18:00',
        'Entrada (HE) 19:00',
        'Saída — próxima batida',
      ]);
      expect(opcoes.last.hora, const TimeOfDay(hour: 9, minute: 30),
          reason: 'próxima batida pré-preenche a hora "agora"');
    });

    test('dia sem marcações gera apenas a próxima batida', () {
      final opcoes = OpcoesAjuste.doDia(
        registrosDoDia(),
        DateTime(2026, 9, 13),
        agora: const TimeOfDay(hour: 9, minute: 30),
      );

      expect(opcoes, hasLength(1));
      expect(opcoes.single.tipo, 'ENTRADA');
      expect(opcoes.single.rotulo, 'Entrada — próxima batida');
    });

    test('tipoDe extrai o tipo do valor composto', () {
      expect(OpcaoAjuste.tipoDe('ENTRADA#1'), 'ENTRADA');
      expect(OpcaoAjuste.tipoDe('SAIDA#0'), 'SAIDA');
    });
  });

  testWidgets('diálogo: escolher slot existente pré-preenche o horário',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 0.7;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => SolicitarAjusteDialog(
                  dataInicial: DateTime(2026, 9, 12),
                  todosRegistros: registrosDoDia(),
                ),
              ),
              child: const Text('Abrir diálogo'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir diálogo'));
    await tester.pumpAndSettle();

    // Padrão ao abrir: "próxima batida" com a hora atual. O dia tem 5
    // batidas na mesma jornada → a 6ª posição é Saída (HE).
    expect(find.text('Saída — próxima batida'), findsOneWidget);

    await tester.tap(find.text('Saída — próxima batida'));
    await tester.pumpAndSettle();

    // Todos os slots do dia estão disponíveis, incluindo a HE.
    expect(find.text('Entrada (HE) 19:00'), findsOneWidget);
    expect(find.text('Intervalo 12:00'), findsOneWidget);

    await tester.tap(find.text('Entrada 08:00').last);
    await tester.pumpAndSettle();

    expect(find.text('Entrada 08:00'), findsOneWidget);
    expect(find.text('8:00 AM'), findsOneWidget,
        reason: 'o horário do slot 08:00 foi pré-preenchido');
  });
}
