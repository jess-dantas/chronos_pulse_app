import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/config/app_modo.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/router/app_router.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/admin/data/datasources/admin_auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/admin/data/repositories/admin_auth_repository_impl.dart';
import 'package:chronos_pulse_app/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/models/usuario_model.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/auth/presentation/screens/login_screen.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/screens/modo_ponto_screen.dart';

UsuarioModel _usuario({
  String role = 'COLABORADOR',
  List<String> modulos = const [],
  bool acessoEstoque = false,
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
    acessoEstoque: acessoEstoque,
  );
}

void main() {
  group('AppRouter — permissões de módulos do painel', () {
    test('primeiraRotaPainel sempre cai em Home (primeira da ordem fixa)', () {
      final usuario = _usuario(modulos: ['COMPRAS', 'PONTO']);
      expect(AppRouter.primeiraRotaPainel(usuario), '/painel/home');
    });

    test('primeiraRotaPainel cai em Home mesmo sem módulos contratados', () {
      final usuario = _usuario();
      expect(AppRouter.primeiraRotaPainel(usuario), '/painel/home');
      expect(AppRouter.podeModuloPainel(usuario, 'home'), isTrue);
      expect(AppRouter.podeModuloPainel(usuario, 'ponto'), isFalse);
    });

    test('empreende a ordem fixa: Estoque antes de Compras', () {
      final usuario = _usuario(
        role: 'COLABORADOR',
        modulos: ['ESTOQUE', 'COMPRAS'],
        acessoEstoque: true,
      );
      expect(
        AppRouter.painelOrdem.indexOf('estoque') <
            AppRouter.painelOrdem.indexOf('compras'),
        isTrue,
      );
      expect(AppRouter.podeModuloPainel(usuario, 'estoque'), isTrue);
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
      expect(AppRouter.primeiraRotaPainel(usuario), '/painel/home');
    });
  });

  group('AppRouter — redirects e deep-linking', () {
    late AuthProvider authProvider;
    late AdminAuthProvider adminAuthProvider;
    late GoRouter router;

    setUp(() {
      final dioClient = DioClient();
      final repository = AuthRepository(
        remoteDataSource: AuthRemoteDataSource(dioClient),
        dioClient: dioClient,
      );
      authProvider = AuthProvider(repository);
      adminAuthProvider = AdminAuthProvider(
        AdminAuthRepositoryImpl(AdminAuthRemoteDataSource(dioClient)),
        dioClient,
      );
      router = AppRouter.build(authProvider, adminAuthProvider);
    });

    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: adminAuthProvider),
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

  group('AppRouter — modos de build (APP_MODE)', () {
    late AuthProvider authProvider;
    late AdminAuthProvider adminAuthProvider;

    setUp(() {
      final dioClient = DioClient();
      final repository = AuthRepository(
        remoteDataSource: AuthRemoteDataSource(dioClient),
        dioClient: dioClient,
      );
      authProvider = AuthProvider(repository);
      adminAuthProvider = AdminAuthProvider(
        AdminAuthRepositoryImpl(AdminAuthRemoteDataSource(dioClient)),
        dioClient,
      );
    });

    Future<void> pumpComModo(
      WidgetTester tester,
      String modo, {
      GoRouter? router,
    }) async {
      final r = router ??
          AppRouter.build(authProvider, adminAuthProvider, modo: modo);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: adminAuthProvider),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp.router(routerConfig: r),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('modo completo (padrão): /admin/auth/login segue público',
        (tester) async {
      final router = AppRouter.build(authProvider, adminAuthProvider,
          modo: AppModo.completo);
      await pumpComModo(tester, AppModo.completo, router: router);
      router.go('/admin/auth/login');
      await tester.pumpAndSettle();
      expect(find.text('Login Administrator'), findsOneWidget);
    });

    testWidgets('modo cliente: deep link /admin/auth/login cai no login',
        (tester) async {
      final router =
          AppRouter.build(authProvider, adminAuthProvider, modo: AppModo.cliente);
      await pumpComModo(tester, AppModo.cliente, router: router);
      router.go('/admin/auth/login');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Login Administrator'), findsNothing);
    });

    testWidgets('modo cliente: /admin/dashboard também é bloqueado',
        (tester) async {
      final router =
          AppRouter.build(authProvider, adminAuthProvider, modo: AppModo.cliente);
      await pumpComModo(tester, AppModo.cliente, router: router);
      router.go('/admin/dashboard');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Login Administrator'), findsNothing);
    });

    testWidgets('modo cliente: inicia direto no /login (sem ver a landing)',
        (tester) async {
      await pumpComModo(tester, AppModo.cliente);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Pronto para acessar o Chronos Pulse?'), findsNothing);
    });

    testWidgets('modo completo (padrão): inicia na landing',
        (tester) async {
      await pumpComModo(tester, AppModo.completo);
      expect(find.text('Pronto para acessar o Chronos Pulse?'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('modo cliente: rota protegida deslogado cai no login',
        (tester) async {
      final router =
          AppRouter.build(authProvider, adminAuthProvider, modo: AppModo.cliente);
      await pumpComModo(tester, AppModo.cliente, router: router);
      router.go('/painel/estoque');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Pronto para acessar o Chronos Pulse?'), findsNothing);
    });

    testWidgets(
        'modo cliente: /ponto/dispositivo é pública (bater ponto sem login)',
        (tester) async {
      final router =
          AppRouter.build(authProvider, adminAuthProvider, modo: AppModo.cliente);
      await pumpComModo(tester, AppModo.cliente, router: router);
      router.go('/ponto/dispositivo');
      // Sem pumpAndSettle: em ambiente de teste o Keystore fica pendurado e
      // a tela repousa no carregamento — o que basta para provar o redirect
      // (o guard próprio de vínculo/biometria é coberto em
      // modo_dispositivo_test.dart).
      await tester.pump();
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(ModoPontoScreen), findsOneWidget);
    });

    testWidgets('modo admin: inicia direto no login da plataforma',
        (tester) async {
      await pumpComModo(tester, AppModo.admin);
      expect(find.text('Login Administrator'), findsOneWidget);
      expect(find.text('Pronto para acessar o Chronos Pulse?'), findsNothing);
    });

    testWidgets('modo admin: /login de cliente é redirecionado pro admin',
        (tester) async {
      final router =
          AppRouter.build(authProvider, adminAuthProvider, modo: AppModo.admin);
      await pumpComModo(tester, AppModo.admin, router: router);
      router.go('/login');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('Login Administrator'), findsOneWidget);
    });

    testWidgets('modo admin: /painel/home é redirecionado pro admin',
        (tester) async {
      final router =
          AppRouter.build(authProvider, adminAuthProvider, modo: AppModo.admin);
      await pumpComModo(tester, AppModo.admin, router: router);
      router.go('/painel/home');
      await tester.pumpAndSettle();
      expect(find.text('Login Administrator'), findsOneWidget);
    });
  });
}