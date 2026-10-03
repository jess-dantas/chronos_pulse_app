import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chronos_pulse_app/core/security/biometria_preferences.dart';
import 'package:chronos_pulse_app/features/perfil/presentation/screens/perfil_seguranca_screen.dart';

class _Tela2FAMarcador extends StatelessWidget {
  const _Tela2FAMarcador();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('tela-2fa')));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BiometriaPreferences prefs;

  Future<void> pumpTela(WidgetTester tester) async {
    prefs = await BiometriaPreferences.carregar();
    final router = GoRouter(
      initialLocation: '/perfil/seguranca',
      routes: [
        GoRoute(
          path: '/perfil/seguranca',
          builder: (context, state) => const PerfilSegurancaScreen(),
        ),
        GoRoute(
          path: '/perfil/2fa',
          builder: (context, state) => const _Tela2FAMarcador(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<BiometriaPreferences>.value(
        value: prefs,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('BiometriaPreferences', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('padrão é ativada quando não há valor persistido', () async {
      final carregada = await BiometriaPreferences.carregar();
      expect(carregada.ativa, isTrue);
    });

    test('setAtiva persiste em chronos_biometria_ativa', () async {
      final carregada = await BiometriaPreferences.carregar();

      await carregada.setAtiva(false);
      final bruto = (await SharedPreferences.getInstance())
          .getBool('chronos_biometria_ativa');
      expect(bruto, isFalse);

      await carregada.setAtiva(true);
      final depois = (await SharedPreferences.getInstance())
          .getBool('chronos_biometria_ativa');
      expect(depois, isTrue);
    });
  });

  group('PerfilSegurancaScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('exibe o toggle de biometria ativado por padrão',
        (tester) async {
      await pumpTela(tester);

      final chave = find.byKey(const Key('seguranca_biometria_switch'));
      expect(chave, findsOneWidget);
      expect(tester.widget<SwitchListTile>(chave).value, isTrue);
      expect(
          find.byKey(const Key('seguranca_two_factor_tile')), findsOneWidget);
    });

    testWidgets('desligar o toggle persiste a preferência', (tester) async {
      await pumpTela(tester);

      final chave = find.byKey(const Key('seguranca_biometria_switch'));
      await tester.ensureVisible(chave);
      await tester.pumpAndSettle();
      await tester.tap(chave);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(chave).value, isFalse);
      expect(prefs.ativa, isFalse);
      expect(
        (await SharedPreferences.getInstance())
            .getBool('chronos_biometria_ativa'),
        isFalse,
      );
    });

    testWidgets('ligar o toggle persiste a preferência', (tester) async {
      SharedPreferences.setMockInitialValues(
          {'chronos_biometria_ativa': false});
      await pumpTela(tester);

      final chave = find.byKey(const Key('seguranca_biometria_switch'));
      expect(tester.widget<SwitchListTile>(chave).value, isFalse);

      await tester.ensureVisible(chave);
      await tester.pumpAndSettle();
      await tester.tap(chave);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(chave).value, isTrue);
      expect(
        (await SharedPreferences.getInstance())
            .getBool('chronos_biometria_ativa'),
        isTrue,
      );
    });

    testWidgets('tile do 2FA navega para /perfil/2fa', (tester) async {
      await pumpTela(tester);

      await tester.tap(find.byKey(const Key('seguranca_two_factor_tile')));
      await tester.pumpAndSettle();

      expect(find.text('tela-2fa'), findsOneWidget);
    });

    testWidgets('em tela larga o conteúdo fica centrado com largura máx 540',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpTela(tester);

      expect(tester.getSize(find.byType(ListView)).width, equals(540),
          reason: 'não pode esticar de ponta a ponta no web/desktop');
      expect(
        tester.getCenter(find.byKey(const Key('seguranca_two_factor_tile'))).dx,
        equals(600),
        reason: 'conteúdo centrado na tela de 1200px',
      );
    });
  });
}
