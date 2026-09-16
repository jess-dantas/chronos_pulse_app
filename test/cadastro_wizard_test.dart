import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/lead_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/screens/cadastrar_empresa_screen.dart';

class FakeLeadRepository extends LeadRepository {
  LeadEmpresaRequest? requisicaoRecebida;

  FakeLeadRepository() : super(DioClient());

  @override
  Future<void> cadastrar(LeadEmpresaRequest request) async {
    requisicaoRecebida = request;
  }
}

void main() {
  late FakeLeadRepository leadRepository;
  late GoRouter router;

  setUp(() {
    leadRepository = FakeLeadRepository();
    router = GoRouter(
      initialLocation: '/cadastro',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('landing')),
        ),
        GoRoute(
          path: '/cadastro',
          builder: (_, __) => const CadastrarEmpresaScreen(),
        ),
      ],
    );
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<LeadRepository>.value(value: leadRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> preencherEtapaEmpresa(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'CNPJ *'),
      '11.222.333/0001-81',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Razão Social / Nome da Empresa *'),
      'Empresa Teste LTDA',
    );
  }

  Future<void> tapVisivel(WidgetTester tester, String rotulo) async {
    await tester.ensureVisible(find.text(rotulo).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(rotulo).last);
    await tester.pumpAndSettle();
  }

  testWidgets('primeira etapa renderiza campos da empresa e botão voltar', (tester) async {
    await pumpApp(tester);

    expect(find.text('Quero experimentar o Chronos Pulse'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'CNPJ *'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('não avança com CNPJ inválido', (tester) async {
    await pumpApp(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'CNPJ *'),
      '123',
    );
    await tapVisivel(tester, 'Continuar');

    expect(find.text('O CNPJ deve conter 14 caracteres'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Voltar'), findsNothing);
  });

  testWidgets('percorre as 3 etapas e envia lead sem CPF e sem senha', (tester) async {
    await pumpApp(tester);

    await preencherEtapaEmpresa(tester);
    await tapVisivel(tester, 'Continuar');

    expect(find.text('CEP'), findsWidgets);
    expect(find.text('Voltar'), findsOneWidget);

    await tapVisivel(tester, 'Continuar');

    expect(find.text('Contato Comercial'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome do Responsável *'),
      'Maria Silva',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail para Contato *'),
      'maria@empresa.com',
    );
    await tapVisivel(tester, 'Enviar Interesse');

    expect(find.text('Recebemos seus dados!'), findsOneWidget);
    expect(leadRepository.requisicaoRecebida, isNotNull);
    expect(
      leadRepository.requisicaoRecebida!.cnpj.replaceAll(RegExp(r'\D'), ''),
      '11222333000181',
    );
    expect(leadRepository.requisicaoRecebida!.contatoNome, 'Maria Silva');
  });

  testWidgets('seta de voltar na barra de título retorna para a raiz', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('landing'), findsOneWidget);
  });
}