import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/features/home_deslogada/presentation/screens/home_deslogada_screen.dart';

void main() {
  group('HomeDeslogadaScreen — primeira tela do app cliente', () {
    late bool foiPonto;
    late bool foiLogin;

    Future<void> pumpHome(WidgetTester tester) async {
      foiPonto = false;
      foiLogin = false;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeDeslogadaScreen(),
          ),
          GoRoute(
            path: '/ponto/dispositivo',
            builder: (context, state) {
              foiPonto = true;
              return const Scaffold(body: Text('DESTINO_PONTO'));
            },
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) {
              foiLogin = true;
              return const Scaffold(body: Text('DESTINO_LOGIN'));
            },
          ),
        ],
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('exibe ícone de ponto, botão "Bater ponto" e botão "Logar"',
        (tester) async {
      await pumpHome(tester);
      expect(find.byIcon(Icons.fingerprint), findsWidgets);
      expect(find.text('Bater ponto'), findsOneWidget);
      expect(find.text('Logar'), findsOneWidget);
      expect(find.text('Pronto para acessar o Chronos Pulse?'), findsNothing);
    });

    testWidgets('"Bater ponto" vai para a rota pública /ponto/dispositivo',
        (tester) async {
      await pumpHome(tester);
      await tester.tap(find.byKey(const Key('home_deslogada_bater_ponto_button')));
      await tester.pumpAndSettle();
      expect(foiPonto, isTrue);
      expect(foiLogin, isFalse);
      expect(find.text('DESTINO_PONTO'), findsOneWidget);
    });

    testWidgets('"Logar" vai para a tela de login', (tester) async {
      await pumpHome(tester);
      await tester.tap(find.byKey(const Key('home_deslogada_login_button')));
      await tester.pumpAndSettle();
      expect(foiLogin, isTrue);
      expect(foiPonto, isFalse);
      expect(find.text('DESTINO_LOGIN'), findsOneWidget);
    });
  });
}
