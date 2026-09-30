import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/hardware/hardware_service.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/ponto/data/repositories/ponto_repository.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/providers/ponto_provider.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/screens/home_ponto_screen.dart';

import 'ponto_test.dart'
    show MockPontoLocalDataSource, MockPontoRemoteDataSource;

/// Localização controlável: status fixo (o "Ativar agora" do teste não
/// muda nada — prova que o aviso reavalia ao voltar das configurações).
class _HardwareFake extends HardwareService {
  LocalizacaoStatus status = LocalizacaoStatus.pronta;
  final List<LocalizacaoStatus> aberturas = [];
  int biometrias = 0;

  @override
  Future<LocalizacaoStatus> statusLocalizacao() async => status;

  @override
  Future<void> abrirConfigLocalizacao(LocalizacaoStatus atual) async {
    aberturas.add(atual);
  }

  @override
  Future<bool> autenticarBiometria() async {
    biometrias++;
    return true;
  }

  @override
  Future<Position?> obterLocalizacaoAtual() async =>
      throw Exception('sem GPS no host de teste');
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  late AuthProvider auth;
  late PontoProvider ponto;
  late _HardwareFake hw;
  var pumpou = false;
  var encerrou = false;

  setUp(() {
    hw = _HardwareFake();
    pumpou = false;
    encerrou = false;
  });

  // O dispose precisa ANTES do fim do corpo: o binding valida timers
  // pendurados antes dos tearDowns.
  void encerrar() {
    ponto.dispose();
    auth.dispose();
    encerrou = true;
  }

  tearDown(() {
    if (pumpou && !encerrou) {
      ponto.dispose();
      auth.dispose();
    }
  });

  Future<void> pumpHome(WidgetTester tester) async {
    // Criados DENTRO do corpo do teste (FakeAsync): os timers/cadeias do
    // construtor precisam da mesma zona do pump — no setUp (zona real) eles
    // congelam e a batida espera o carregarDados indefinidamente.
    auth = AuthProvider(AuthRepository(
      remoteDataSource: AuthRemoteDataSource(DioClient()),
      dioClient: DioClient(),
    ));
    ponto = PontoProvider(PontoRepository(
      localDataSource: MockPontoLocalDataSource(),
      remoteDataSource: MockPontoRemoteDataSource(),
    ));
    pumpou = true;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<PontoProvider>.value(value: ponto),
        ],
        child: MaterialApp(home: HomePontoScreen(hardwareService: hw)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  Future<void> baterPonto(WidgetTester tester) async {
    // Histórico vazio: o próximo tipo é ENTRADA → "Bater Entrada".
    final botao = find.widgetWithText(ElevatedButton, 'Bater Entrada');
    await tester.ensureVisible(botao);
    await tester.tap(botao);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('GPS desligado: aviso com as 3 opções e reavaliação após Ativar',
      (tester) async {
    hw.status = LocalizacaoStatus.servicoDesligado;
    await pumpHome(tester);
    await baterPonto(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Localização desativada'), findsOneWidget);
    expect(find.text('Ativar agora'), findsOneWidget);
    expect(find.text('Registrar sem localização'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);

    await tester.tap(find.text('Ativar agora'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(hw.aberturas, equals([LocalizacaoStatus.servicoDesligado]));
    expect(find.byType(AlertDialog), findsOneWidget,
        reason: 'voltou das configurações e o status segue desligado');

    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(AlertDialog), findsNothing);
    expect(hw.biometrias, equals(0),
        reason: 'cancelar aborta a batida antes da biometria');
    encerrar();
  });

  testWidgets('Permissão negada: "Registrar sem localização" segue a batida',
      (tester) async {
    hw.status = LocalizacaoStatus.permissaoNegada;
    await pumpHome(tester);
    await baterPonto(tester);

    expect(find.text('Permissão de localização negada'), findsOneWidget);

    await tester.tap(find.text('Registrar sem localização'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(hw.biometrias, equals(1),
        reason: 'seguu para a biometria depois da escolha');
    expect(find.text('Identificação Facial'), findsOneWidget);
    expect(find.text('Continuar sem foto'), findsOneWidget,
        reason: 'câmera indisponível no host → avisa e permite seguir');

    await tester.tap(find.text('Continuar sem foto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // O SnackBar nasce enquanto a rota da câmera ainda está saindo (2
    // scaffolds → exibição duplicada); ao final da transição sobra 1.
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SnackBar), findsOneWidget,
        reason: 'batida concluída com o fallback de localização');
    expect(find.byType(AlertDialog), findsNothing);
    encerrar();
  });

  testWidgets('Localização pronta: bate ponto sem nenhum aviso', (tester) async {
    hw.status = LocalizacaoStatus.pronta;
    await pumpHome(tester);
    await baterPonto(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(hw.biometrias, equals(1));

    await tester.tap(find.text('Continuar sem foto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Mesma janela do teste anterior: espera a rota da câmera sair de vez.
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SnackBar), findsOneWidget);
    encerrar();
  });

  testWidgets('Permissão bloqueada: "Ativar agora" abre as configurações do app',
      (tester) async {
    hw.status = LocalizacaoStatus.permissaoBloqueada;
    await pumpHome(tester);
    await baterPonto(tester);

    expect(find.text('Permissão de localização negada'), findsOneWidget);

    await tester.tap(find.text('Ativar agora'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(hw.aberturas, equals([LocalizacaoStatus.permissaoBloqueada]),
        reason: 'negada em definitivo → configurações do app');
    expect(find.byType(AlertDialog), findsOneWidget,
        reason: 'reavaliou ao voltar e segue bloqueada');

    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(hw.biometrias, equals(0));
    encerrar();
  });
}
