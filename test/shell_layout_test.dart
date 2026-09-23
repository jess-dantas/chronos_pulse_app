import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/router/app_router.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/admin/data/datasources/admin_auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/admin/data/repositories/admin_auth_repository_impl.dart';
import 'package:chronos_pulse_app/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:chronos_pulse_app/features/admin/presentation/screens/admin_seguranca_screen.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/models/usuario_model.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/navigation/presentation/screens/admin_shell.dart';
import 'package:chronos_pulse_app/features/navigation/presentation/screens/main_shell.dart';
import 'package:chronos_pulse_app/features/privacidade/data/privacidade_datasource.dart';
import 'package:chronos_pulse_app/features/privacidade/presentation/providers/privacidade_provider.dart';
import 'package:chronos_pulse_app/features/privacidade/presentation/screens/privacidade_screen.dart';

/// AuthProvider com sessão injetada para o teste, sem tocar em rede/armazenamento.
class _FakeAuth extends AuthProvider {
  _FakeAuth()
      : super(AuthRepository(
          remoteDataSource: AuthRemoteDataSource(DioClient()),
          dioClient: DioClient(),
        ));

  UsuarioModel? _sessao;

  /// Define a sessão sem notificar o router: o teste chama `go` em seguida e o
  /// redirect é avaliado com o usuário já presente (sem passar pela landing).
  void definirSessao(UsuarioModel usuario) => _sessao = usuario;

  @override
  UsuarioModel? get usuario => _sessao;

  @override
  bool get isAuthenticated => _sessao != null && _sessao!.token.isNotEmpty;
}

class _FakePrivacidadeDataSource extends PrivacidadeDataSource {
  _FakePrivacidadeDataSource({this.aceitePendente = false})
      : super(DioClient());

  bool aceitePendente;
  bool consentimentoRegistrado = false;

  @override
  Future<Map<String, dynamic>> getPolitica() async {
    return {
      'versao': '1.0',
      'dataPublicacao': '2026-09-08',
      'texto': 'Política de privacidade v1',
    };
  }

  @override
  Future<Map<String, dynamic>> getStatusConsentimento() async {
    return {
      'versaoAtual': '1.0',
      'versaoAceita': aceitePendente ? null : '1.0',
      'dataConsentimento': aceitePendente ? null : '2026-09-08T10:00:00Z',
      'aceitePendente': aceitePendente,
    };
  }

  @override
  Future<void> registrarConsentimento(String versaoPolitica) async {
    aceitePendente = false;
    consentimentoRegistrado = true;
  }
}

UsuarioModel _usuario({String role = 'COLABORADOR', List<String> modulos = const ['PONTO']}) {
  return UsuarioModel(
    token: 'token',
    refreshToken: 'refresh',
    tipo: 'Bearer',
    nome: 'Teste Shell',
    email: 'teste@example.com',
    cpf: '12345678901',
    role: role,
    modulos: modulos,
  );
}

void main() {
  group('Layout dos shells em tela larga (regressão: footer ∞ largura)', () {
    late _FakeAuth auth;
    late AdminAuthProvider adminAuth;
    late GoRouter router;

    setUp(() {
      final dioClient = DioClient();
      auth = _FakeAuth();
      adminAuth = AdminAuthProvider(
        AdminAuthRepositoryImpl(AdminAuthRemoteDataSource(dioClient)),
        dioClient,
      );
      router = AppRouter.build(auth, adminAuth);
    });

    Future<_FakePrivacidadeDataSource> pumpApp(
      WidgetTester tester, {
      _FakePrivacidadeDataSource? fakePrivacidade,
    }) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final fake = fakePrivacidade ?? _FakePrivacidadeDataSource();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<AdminAuthProvider>.value(value: adminAuth),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(
              create: (_) => PrivacidadeProvider(fake),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return fake;
    }

    testWidgets('MainShell: rail fixo à esquerda e conteúdo do branch com largura real', (
      tester,
    ) async {
      await pumpApp(tester);
      auth.definirSessao(_usuario(role: 'COLABORADOR', modulos: ['PONTO']));
      router.go('/painel/privacidade');
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Ponto'), findsWidgets, reason: 'destino do rail visível');

      final railSize = tester.getSize(find.byType(NavigationRail));
      expect(
        railSize.width,
        lessThan(300),
        reason: 'rail deve ter largura fixa (~120px) e não ocupar o corpo inteiro',
      );

      expect(find.byType(PrivacidadeScreen), findsOneWidget);
      final conteudo = tester.getSize(find.byType(PrivacidadeScreen));
      expect(
        conteudo.width,
        greaterThan(500),
        reason: 'conteúdo do branch deve ocupar o restante da tela '
            '(regressão anterior: largura 0px, só o AppBar aparecia)',
      );
    });

    testWidgets('AdminShell: rail fixo à esquerda e segurança content com largura real', (
      tester,
    ) async {
      await pumpApp(tester);
      auth.definirSessao(_usuario(role: 'ADMIN_PLATAFORMA', modulos: const []));
      router.go('/admin/seguranca');
      await tester.pumpAndSettle();

      expect(find.byType(AdminShell), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets, reason: 'destino do rail admin visível');

      final railSize = tester.getSize(find.byType(NavigationRail));
      expect(
        railSize.width,
        lessThan(300),
        reason: 'rail admin deve ter largura fixa (~120px)',
      );

      expect(find.byType(AdminSegurancaScreen), findsOneWidget);
      final conteudo = tester.getSize(find.byType(AdminSegurancaScreen));
      expect(
        conteudo.width,
        greaterThan(500),
        reason: 'conteúdo do branch admin deve ocupar o restante da tela',
      );
      expect(
        find.text('Privacidade'),
        findsNothing,
        reason: 'Administrator não possui aba de Privacidade',
      );
    });
  });

  group('Consentimento bloqueante (Termo de Ciência — LGPD)', () {
    late _FakeAuth auth;
    late AdminAuthProvider adminAuth;
    late GoRouter router;

    setUp(() {
      final dioClient = DioClient();
      auth = _FakeAuth();
      adminAuth = AdminAuthProvider(
        AdminAuthRepositoryImpl(AdminAuthRemoteDataSource(dioClient)),
        dioClient,
      );
      router = AppRouter.build(auth, adminAuth);
    });

    Future<_FakePrivacidadeDataSource> pumpApp(
      WidgetTester tester,
      _FakePrivacidadeDataSource fake,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<AdminAuthProvider>.value(value: adminAuth),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => PrivacidadeProvider(fake)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return fake;
    }

    testWidgets('abre modal bloqueante quando o aceite está pendente e só '
        'fecha após "Ciente e de acordo"', (tester) async {
      final fake = _FakePrivacidadeDataSource(aceitePendente: true);
      await pumpApp(tester, fake);
      auth.definirSessao(_usuario(role: 'COLABORADOR', modulos: ['PONTO']));
      router.go('/painel/privacidade');
      await tester.pumpAndSettle();

      expect(find.text('Termo de Ciência de Privacidade'), findsOneWidget);
      final botaoAceitar = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('Ciente e de acordo (v1.0)'),
      );
      expect(botaoAceitar, findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);

      await tester.tap(botaoAceitar);
      await tester.pumpAndSettle();

      expect(fake.consentimentoRegistrado, isTrue);
      expect(find.text('Termo de Ciência de Privacidade'), findsNothing);
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('não abre modal quando o aceite da versão atual já existe', (
      tester,
    ) async {
      final fake = _FakePrivacidadeDataSource(aceitePendente: false);
      await pumpApp(tester, fake);
      auth.definirSessao(_usuario(role: 'COLABORADOR', modulos: ['PONTO']));
      router.go('/painel/privacidade');
      await tester.pumpAndSettle();

      expect(find.text('Termo de Ciência de Privacidade'), findsNothing);
      expect(find.byType(MainShell), findsOneWidget);
    });
  });
}
