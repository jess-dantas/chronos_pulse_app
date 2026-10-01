import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/admin/data/repositories/admin_auth_repository.dart';
import 'package:chronos_pulse_app/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:chronos_pulse_app/features/admin/presentation/screens/admin_auth_screen.dart';
import 'package:chronos_pulse_app/features/admin/presentation/screens/admin_reset_senha_screen.dart';

/// Repositório falso dos fluxos de reset (mesmo padrão dos fakes do projeto:
/// implementa o que os testes usam e delega o resto para `noSuchMethod`).
class _RepoFake implements AdminAuthRepository {
  int enviarChamadas = 0;
  String? ultimoUsername;
  String? verificarUsername;
  String? verificarCodigo;
  String? verificarNovaSenha;
  bool enviarFalha = false;
  bool verificarFalha = false;

  @override
  Future<void> resetSenhaEnviar(String username) async {
    enviarChamadas++;
    ultimoUsername = username;
    if (enviarFalha) throw Exception('Credenciais inválidas');
  }

  @override
  Future<void> resetSenhaVerificar(
      String username, String codigo, String novaSenha) async {
    verificarUsername = username;
    verificarCodigo = codigo;
    verificarNovaSenha = novaSenha;
    if (verificarFalha) throw Exception('Código inválido');
  }

  @override
  Future<Map<String, dynamic>> bootstrapStatus() async =>
      {'bootstrapAvailable': false};

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

GoRouter _router() => GoRouter(
      initialLocation: '/admin/auth/login',
      routes: [
        GoRoute(
          path: '/admin/auth/login',
          builder: (context, state) => const AdminLoginScreen(),
        ),
        GoRoute(
          path: '/admin/auth/reset-senha',
          builder: (context, state) => const AdminResetSenhaScreen(),
        ),
      ],
    );

void main() {
  late _RepoFake repo;
  late AdminAuthProvider provider;

  setUp(() {
    repo = _RepoFake();
    provider = AdminAuthProvider(repo, DioClient());
  });

  Future<GoRouter> pumpTela(WidgetTester tester,
      {String local = '/admin/auth/reset-senha'}) async {
    final router = _router();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AdminAuthProvider>.value(value: provider),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    if (local != '/admin/auth/login') {
      router.go(local);
      await tester.pumpAndSettle();
    }
    return router;
  }

  testWidgets('passo 1 envia o código e avança para a etapa 2',
      (tester) async {
    await pumpTela(tester);

    expect(find.text('Recuperação de senha'), findsOneWidget);
    expect(find.text('Código de recuperação'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'root');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar código'));
    await tester.pumpAndSettle();

    expect(repo.enviarChamadas, 1);
    expect(repo.ultimoUsername, 'root');
    expect(find.text('Digite o código recebido'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Código de recuperação'),
        findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Nova senha'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Confirmar nova senha'),
        findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Usuário'), findsOneWidget);
  });

  testWidgets('valida código de 8 dígitos e senha curta', (tester) async {
    await pumpTela(tester);
    await tester.enterText(find.byType(TextFormField).first, 'root');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar código'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Redefinir senha'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Redefinir senha'));
    await tester.pumpAndSettle();
    expect(find.text('O código deve ter 8 dígitos'), findsOneWidget);
    expect(repo.verificarCodigo, isNull);

    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    await tester.enterText(find.byType(TextFormField).at(2), '123456');
    await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Redefinir senha'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Redefinir senha'));
    await tester.pumpAndSettle();
    expect(find.text('A senha deve ter no mínimo 8 caracteres'),
        findsOneWidget);
    expect(repo.verificarCodigo, isNull);
  });

  testWidgets('reenviar chama o endpoint sem validar os campos vazios',
      (tester) async {
    await pumpTela(tester);
    await tester.enterText(find.byType(TextFormField).first, 'root');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar código'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
        find.widgetWithText(TextButton, 'Reenviar código'));
    await tester.tap(find.widgetWithText(TextButton, 'Reenviar código'));
    await tester.pumpAndSettle();

    expect(repo.enviarChamadas, 2);
    expect(find.text('Digite o código recebido'), findsOneWidget);
  });

  testWidgets('erro no envio mantém a etapa 1 com o aviso', (tester) async {
    repo.enviarFalha = true;
    await pumpTela(tester);

    await tester.enterText(find.byType(TextFormField).first, 'desconhecido');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar código'));
    await tester.pumpAndSettle();

    expect(find.text('Credenciais inválidas'), findsOneWidget);
    expect(find.text('Recuperação de senha'), findsOneWidget);
    expect(find.text('Digite o código recebido'), findsNothing);
  });

  testWidgets('sucesso redefine a senha e volta para o login',
      (tester) async {
    await pumpTela(tester);
    await tester.enterText(find.byType(TextFormField).first, 'root');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar código'));
    await tester.pumpAndSettle();

    // expira o snackbar da etapa 1 para não enfileirar o da etapa 2
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    await tester.enterText(find.byType(TextFormField).at(2), 'Nova@1234');
    await tester.enterText(find.byType(TextFormField).at(3), 'Nova@1234');
    await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Redefinir senha'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Redefinir senha'));
    await tester.pumpAndSettle();

    expect(repo.verificarUsername, 'root');
    expect(repo.verificarCodigo, '12345678');
    expect(repo.verificarNovaSenha, 'Nova@1234');
    expect(find.text('Senha redefinida com sucesso. Faça login com a '
        'nova senha.'), findsOneWidget);
  });

  testWidgets('login Administrator oferece o link Esqueci minha senha',
      (tester) async {
    await pumpTela(tester, local: '/admin/auth/login');

    final link = find.text('Esqueci minha senha');
    expect(link, findsOneWidget);
    await tester.ensureVisible(link);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(find.text('Recuperação de senha'), findsOneWidget);
  });
}
