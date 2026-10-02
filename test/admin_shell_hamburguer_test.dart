import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/router/app_router.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/admin/data/datasources/admin_auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:chronos_pulse_app/features/admin/data/repositories/admin_auth_repository_impl.dart';
import 'package:chronos_pulse_app/features/admin/data/repositories/admin_repository.dart';
import 'package:chronos_pulse_app/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:chronos_pulse_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/models/usuario_model.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/navigation/presentation/screens/admin_shell.dart';

class _FakeAuth extends AuthProvider {
  _FakeAuth()
      : super(AuthRepository(
          remoteDataSource: AuthRemoteDataSource(DioClient()),
          dioClient: DioClient(),
        ));

  UsuarioModel? _sessao;

  void definirSessao(UsuarioModel usuario) => _sessao = usuario;

  @override
  UsuarioModel? get usuario => _sessao;

  @override
  bool get isAuthenticated => _sessao != null && _sessao!.token.isNotEmpty;
}

UsuarioModel _usuario() => UsuarioModel(
      token: 'token',
      refreshToken: 'refresh',
      tipo: 'Bearer',
      nome: 'Admin Teste',
      email: 'admin@example.com',
      cpf: '12345678901',
      role: 'ADMIN_PLATAFORMA',
      modulos: const [],
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  late _FakeAuth auth;
  late AdminAuthProvider adminAuth;
  late AdminRepository adminRepository;
  late GoRouter router;

  setUp(() {
    final dio = DioClient();
    auth = _FakeAuth();
    adminAuth = AdminAuthProvider(
      AdminAuthRepositoryImpl(AdminAuthRemoteDataSource(dio)),
      dio,
    );
    adminRepository = AdminRepository(
      remoteDataSource: AdminRemoteDataSource(dio),
    );
    router = AppRouter.build(auth, adminAuth);
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    Size tamanho = const Size(400, 800),
    String rota = '/admin/seguranca',
  }) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Sessão + rota definidas ANTES do primeiro frame: evita montar a
    // landing (pública) e o branch do Dashboard em viewport estreito.
    auth.definirSessao(_usuario());
    router.go(rota);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<AdminAuthProvider>.value(value: adminAuth),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (_) => AdminProvider(adminRepository),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('layout estreito mostra o hambúrguer, sem rail, e dock de 4',
      (tester) async {
    await pumpShell(tester, rota: '/admin/modulos');

    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.byTooltip('Menu do admin'), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
      hasLength(4),
      reason: 'dock fixa em Dashboard/Leads/Empresas/Módulos (resto no drawer)',
    );
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
      reason: 'Módulos é o 4º item do dock',
    );
  });

  testWidgets('hambúrguer abre o drawer com as seções e navega',
      (tester) async {
    await pumpShell(tester); // /admin/seguranca — fora do dock

    expect(
      find.byType(NavigationBar),
      findsNothing,
      reason: 'Segurança só existe no drawer: dock renderizada sem destaque',
    );

    // O tap sintético não alcança o IconButton do AppBar neste ambiente de
    // teste (mesma observação do MainShell); a ação é invocada diretamente
    // para validar que o botão está wired ao drawer.
    final menuButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.menu),
        matching: find.byType(IconButton),
      ),
    );
    expect(menuButton.onPressed, isNotNull);
    menuButton.onPressed!();
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
    for (final secao in [
      'Dashboard',
      'Leads',
      'Empresas',
      'Contratos',
      'Módulos',
      'Alterar Senha',
      'Segurança',
    ]) {
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text(secao)),
        findsOneWidget,
        reason: 'drawer lista a seção $secao',
      );
    }
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Encerrar Sessão'), findsOneWidget);

    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('Módulos')),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/admin/modulos');
    expect(find.byType(Drawer), findsNothing, reason: 'drawer fecha ao navegar');
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
      reason: 'NavigationBar destaca Módulos (4º item do dock)',
    );
  });

  testWidgets('layout largo mantém o NavigationRail e esconde o hambúrguer',
      (tester) async {
    await pumpShell(tester, tamanho: const Size(1200, 900));

    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byTooltip('Menu do admin'), findsNothing);
    expect(find.byType(Drawer), findsNothing);
  });
}
