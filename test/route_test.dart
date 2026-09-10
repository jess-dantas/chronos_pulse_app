import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/router/app_router.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/models/usuario_model.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/auth/presentation/screens/login_screen.dart';

UsuarioModel _usuario({
  String role = 'COLABORADOR',
  List<String> modulos = const [],
}) {
  return UsuarioModel(
    token: 'token',
    refreshToken: 'refresh',
    tipo: 'Bearer',
    nome: 'Teste',
    email: 'teste@example.com',
    cpf: '12345678901',
    role: role,
    modulos: modulos,
  );
}

void main() {
  group('AppRouter — permissões de módulos do painel', () {
    test('primeiraRotaPainel prioriza o primeiro módulo ativo na ordem fixa', () {
      final usuario = _usuario(modulos: ['COMPRAS', 'PONTO']);
      expect(AppRouter.primeiraRotaPainel(usuario), '/painel/ponto');
    });

    test('primeiraRotaPainel cai em Privacidade quando não há módulos', () {
      final usuario = _usuario();
      expect(AppRouter.primeiraRotaPainel(usuario), '/painel/privacidade');
    });

    test('empreende a ordem fixa: Ponto antes de Estoque e Compras', () {
      final usuario = _usuario(modulos: ['ESTOQUE', 'COMPRAS']);
      expect(AppRouter.primeiraRotaPainel(usuario), '/painel/estoque');
    });

    test('colaborador sem módulo RH não acessa /painel/colaboradores', () {
      final usuario = _usuario();
      expect(AppRouter.podeModuloPainel(usuario, 'colaboradores'), isFalse);
    });

    test('gestor RH com módulo RH acessa /painel/colaboradores', () {
      final usuario = _usuario(role: 'GESTOR_RH', modulos: ['RECURSOS_HUMANOS']);
      expect(AppRouter.podeModuloPainel(usuario, 'colaboradores'), isTrue);
    });

    test('administrador de empresa herda acesso a módulos contratados', () {
      final usuario = _usuario(role: 'ADMIN_EMPRESA', modulos: ['ESTOQUE']);
      expect(AppRouter.podeModuloPainel(usuario, 'estoque'), isTrue);
      expect(AppRouter.primeiraRotaPainel(usuario), '/painel/estoque');
    });
  });

  group('AppRouter — redirects e deep-linking', () {
    late AuthProvider authProvider;
    late GoRouter router;

    setUp(() {
      final dioClient = DioClient();
      final repository = AuthRepository(
        remoteDataSource: AuthRemoteDataSource(dioClient),
        dioClient: dioClient,
      );
      authProvider = AuthProvider(repository);
      router = AppRouter.build(authProvider);
    });

    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('rota de módulo protegido redireciona deslogado para a landing', (tester) async {
      await pumpApp(tester);
      router.go('/painel/estoque');
      await tester.pumpAndSettle();
      expect(find.text('Pronto para acessar o Chronos Pulse?'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('rota /login é pública e abre a tela de login', (tester) async {
      await pumpApp(tester);
      router.go('/login');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Logar'), findsOneWidget);
    });

    testWidgets('rota desconhecida redireciona deslogado para a landing', (tester) async {
      await pumpApp(tester);
      router.go('/rota-inexistente');
      await tester.pumpAndSettle();
      expect(find.text('Pronto para acessar o Chronos Pulse?'), findsOneWidget);
    });

    testWidgets('ativo da landing navega para o login via URL', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('landing_hero_login_button')));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Logar'), findsOneWidget);
    });
  });
}