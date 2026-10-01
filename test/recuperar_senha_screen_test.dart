import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/auth/presentation/screens/recuperar_senha_screen.dart';

/// AuthProvider com os fluxos de recuperação interceptados.
class _FakeAuth extends AuthProvider {
  _FakeAuth()
      : super(AuthRepository(
          remoteDataSource: AuthRemoteDataSource(DioClient()),
          dioClient: DioClient(),
        ));

  int enviarChamadas = 0;
  String? redefinirCodigo;
  String? redefinirNovaSenha;
  bool redefinirOk = true;

  @override
  Future<String?> esqueciSenha(String cpf) async {
    enviarChamadas++;
    return 'Código de recuperação enviado para o e-mail cadastrado.';
  }

  @override
  Future<bool> redefinirSenha({
    required String cpf,
    required String codigo,
    required String novaSenha,
  }) async {
    redefinirCodigo = codigo;
    redefinirNovaSenha = novaSenha;
    return redefinirOk;
  }
}

void main() {
  late _FakeAuth auth;

  setUp(() {
    auth = _FakeAuth();
  });

  Future<void> pumpTela(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/recuperar-senha',
      routes: [
        GoRoute(
          path: '/recuperar-senha',
          builder: (context, state) => const RecuperarSenhaScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('login-ok')),
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> irParaEtapa2(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).first, '12345678901');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar código'));
    await tester.pumpAndSettle();
  }

  testWidgets('código exige 8 dígitos (OTP do backend é de 8)',
      (tester) async {
    await pumpTela(tester);
    await irParaEtapa2(tester);

    expect(find.text('Enviamos um código de 8 dígitos para o e-mail '
        'cadastrado no sistema.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.enterText(find.byType(TextFormField).at(2), 'Nova@123');
    await tester.enterText(find.byType(TextFormField).at(3), 'Nova@123');
    await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Redefinir senha'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Redefinir senha'));
    await tester.pumpAndSettle();

    expect(find.text('O código deve ter 8 dígitos'), findsOneWidget);
    expect(auth.redefinirCodigo, isNull);
  });

  testWidgets('Reenviar código chama a recuperação de novo', (tester) async {
    await pumpTela(tester);
    await irParaEtapa2(tester);
    expect(auth.enviarChamadas, 1);

    await tester.ensureVisible(find.widgetWithText(TextButton, 'Reenviar código'));
    await tester.tap(find.widgetWithText(TextButton, 'Reenviar código'));
    await tester.pumpAndSettle();

    expect(auth.enviarChamadas, 2);
    expect(find.text('Código de recuperação'), findsOneWidget);
  });

  testWidgets('código válido redefini e navega para o login', (tester) async {
    await pumpTela(tester);
    await irParaEtapa2(tester);

    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    await tester.enterText(find.byType(TextFormField).at(2), 'Nova@123');
    await tester.enterText(find.byType(TextFormField).at(3), 'Nova@123');
    await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Redefinir senha'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Redefinir senha'));
    await tester.pumpAndSettle();

    expect(auth.redefinirCodigo, '12345678');
    expect(auth.redefinirNovaSenha, 'Nova@123');
    expect(find.text('login-ok'), findsOneWidget);
  });
}
