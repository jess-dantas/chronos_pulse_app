import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_local_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_remote_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/models/fila_ajuste_model.dart';
import 'package:chronos_pulse_app/features/ponto/data/models/registro_ponto_model.dart';
import 'package:chronos_pulse_app/features/ponto/data/repositories/ponto_repository.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/providers/ponto_provider.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/screens/aprovacao_ajustes_screen.dart';

/// PontoProvider com a fila injetada: nada de rede/armazenamento nativo.
class _FakeFilaPontoProvider extends PontoProvider {
  _FakeFilaPontoProvider({this.fila = const [], this.erroAoCarregar})
      : super(PontoRepository(
          localDataSource: PontoLocalDataSource(),
          remoteDataSource: PontoRemoteDataSource(DioClient()),
        ));

  final List<FilaAjusteModel> fila;
  final Object? erroAoCarregar;
  String? registroAprovado;
  String? registroRejeitado;

  @override
  Future<void> carregarDados() async {}

  @override
  void iniciarMonitoramento({Duration interval = const Duration(seconds: 30)}) {}

  @override
  Future<List<FilaAjusteModel>> listarFilaAjustes() async {
    if (erroAoCarregar != null) throw erroAoCarregar!;
    return fila;
  }

  @override
  Future<RegistroPontoModel?> aprovarAjuste(String registroId) async {
    registroAprovado = registroId;
    return RegistroPontoModel(
      idLocal: registroId,
      dataHoraDispositivo: DateTime(2026, 9, 10, 10),
      tipoRegistro: 'ENTRADA',
      latitude: 0,
      longitude: 0,
      precisaoGps: 0,
    );
  }

  @override
  Future<RegistroPontoModel?> rejeitarAjuste(String registroId, String motivo) async {
    registroRejeitado = registroId;
    return RegistroPontoModel(
      idLocal: registroId,
      dataHoraDispositivo: DateTime(2026, 9, 10, 10),
      tipoRegistro: 'ENTRADA',
      latitude: 0,
      longitude: 0,
      precisaoGps: 0,
    );
  }
}

FilaAjusteModel _ajuste({String id = 'reg-1'}) => FilaAjusteModel(
      registroId: id,
      colaboradorId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      colaboradorNome: 'Maria Silva',
      dataHoraDispositivo: DateTime(2026, 9, 10, 10),
      tipoRegistro: 'ENTRADA',
      justificativa: 'Esqueci o ponto do almoço',
      nsrLogico: 7,
      marcacoesDoDia: [
        MarcacaoDiaModel(
            dataHora: DateTime(2026, 9, 10, 8), tipoRegistro: 'ENTRADA', ajuste: false),
        MarcacaoDiaModel(
            dataHora: DateTime(2026, 9, 10, 10), tipoRegistro: 'ENTRADA', ajuste: true),
        MarcacaoDiaModel(
            dataHora: DateTime(2026, 9, 10, 12), tipoRegistro: 'SAIDA', ajuste: false),
      ],
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  // Fonte de teste (Ahem) deixa textos largos: escala menor evita overflow falso.
  void escalaDeTeste(WidgetTester tester) {
    tester.platformDispatcher.textScaleFactorTestValue = 0.7;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
  }

  Future<void> pumpTela(WidgetTester tester, PontoProvider ponto) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<PontoProvider>.value(
        value: ponto,
        child: const MaterialApp(home: AprovacaoAjustesScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra colaborador, marcações do dia e ações da fila',
      (tester) async {
    escalaDeTeste(tester);
    await pumpTela(tester, _FakeFilaPontoProvider(fila: [_ajuste()]));

    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('Marcações do dia:'), findsOneWidget);
    expect(find.text('08:00 ENTRADA'), findsOneWidget);
    expect(find.text('10:00 ENTRADA (ajuste)'), findsOneWidget);
    expect(find.text('12:00 SAIDA'), findsOneWidget);
    expect(find.text('Esqueci o ponto do almoço'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Aprovar'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Rejeitar'), findsOneWidget);
  });

  testWidgets('aprovar envia o registro da fila', (tester) async {
    escalaDeTeste(tester);
    final ponto = _FakeFilaPontoProvider(fila: [_ajuste(id: 'reg-42')]);
    await pumpTela(tester, ponto);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Aprovar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Aprovar'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('Colaborador: Maria Silva'), findsOneWidget);

    final confirmar = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Aprovar'));
    await tester.tap(confirmar);
    await tester.pumpAndSettle();

    expect(ponto.registroAprovado, 'reg-42');
    expect(find.text('Ajuste aprovado com sucesso!'), findsOneWidget);
  });

  testWidgets('fila agrupa por colaborador e dia em cards com linhas compactas',
      (tester) async {
    escalaDeTeste(tester);
    final mariaHoje = _ajuste(id: 'reg-1');
    final mariaOntem = FilaAjusteModel(
      registroId: 'reg-3',
      colaboradorId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      colaboradorNome: 'Maria Silva',
      dataHoraDispositivo: DateTime(2026, 9, 9, 9),
      tipoRegistro: 'INTERVALO',
      justificativa: 'Intervalo não registrado',
    );
    final joao = FilaAjusteModel(
      registroId: 'reg-2',
      colaboradorId: 'ffffffff-0000-1111-2222-333333333333',
      colaboradorNome: 'João Souza',
      dataHoraDispositivo: DateTime(2026, 9, 10, 14),
      tipoRegistro: 'SAIDA',
      justificativa: 'Esqueci a saída',
    );

    await pumpTela(
      tester,
      _FakeFilaPontoProvider(fila: [mariaHoje, joao, mariaOntem]),
    );

    //3 grupos: Maria (10/09), Maria (09/09) e João (10/09) — nome no cabeçalho.
    expect(find.text('Maria Silva'), findsNWidgets(2));
    expect(find.text('João Souza'), findsOneWidget);
    expect(find.text('10/09/2026 · 1 ajuste pendente'), findsNWidgets(2));
    expect(find.text('09/09/2026 · 1 ajuste pendente'), findsOneWidget);

    // Todas as linhas compactas e ações visíveis sem expansão (um card por
    // colaborador+dia); chips das marcações aparecem só no card de Maria 10/09.
    expect(find.text('Esqueci a saída'), findsOneWidget);
    expect(find.text('Esqueci o ponto do almoço'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Aprovar'), findsNWidgets(3));
    expect(find.widgetWithText(OutlinedButton, 'Rejeitar'), findsNWidgets(3));
    expect(find.text('Marcações do dia:'), findsOneWidget);
  });

  testWidgets('fila vazia mostra estado de nada pendente', (tester) async {
    escalaDeTeste(tester);
    await pumpTela(tester, _FakeFilaPontoProvider());

    expect(find.text('Nenhum ajuste pendente de aprovação'), findsOneWidget);
  });

  testWidgets('erro de carga mostra o estado de falha com nova tentativa',
      (tester) async {
    escalaDeTeste(tester);
    await pumpTela(
      tester,
      _FakeFilaPontoProvider(erroAoCarregar: Exception('api fora do ar')),
    );

    expect(find.textContaining('Erro ao carregar fila de ajustes'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Tentar novamente'), findsOneWidget);
  });
}
