import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/security/admin_device_token_store.dart';
import 'package:chronos_pulse_app/core/security/biometria_preferences.dart';
import 'package:chronos_pulse_app/features/admin/data/datasources/admin_auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/admin/data/models/admin_models.dart';
import 'package:chronos_pulse_app/features/admin/data/repositories/admin_auth_repository_impl.dart';
import 'package:chronos_pulse_app/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:chronos_pulse_app/features/perfil/presentation/screens/perfil_seguranca_screen.dart';

class _Tela2FAMarcador extends StatelessWidget {
  const _Tela2FAMarcador();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('tela-2fa')));
}

/// Sessão admin controlável (mesmo padrão dos testes de shell).
class _AdminFake extends AdminAuthProvider {
  _AdminFake()
      : super(
          AdminAuthRepositoryImpl(AdminAuthRemoteDataSource(DioClient())),
          DioClient(),
        );

  bool autenticado = false;
  int vincularChamadas = 0;
  int revogarChamadas = 0;
  bool vincularOk = true;

  @override
  bool get isAuthenticated => autenticado;

  @override
  AdminPlataformaModel? get currentAdmin => autenticado
      ? AdminPlataformaModel.fromJson({
          'id': '1',
          'username': 'root',
          'nomeCompleto': 'Root',
          'email': 'root@chronos.app',
          'criadoEm': '2026-01-01T00:00:00Z',
        })
      : null;

  @override
  Future<Map<String, dynamic>?> vincularDispositivo() async {
    vincularChamadas++;
    if (!vincularOk) return null;
    return {
      'deviceToken': 'dt-novo-cru',
      'expiraEm': DateTime.now()
          .toUtc()
          .add(const Duration(days: 30))
          .toIso8601String(),
    };
  }

  @override
  Future<bool> revogarDispositivo() async {
    revogarChamadas++;
    return true;
  }
}

/// Store em memória (sem Keystore/plugin de plataforma).
AdminDeviceTokenStore _storeDevice([Map<String, String>? base]) {
  final mapa = <String, String>{...?base};
  return AdminDeviceTokenStore(
    ler: (k) async => mapa[k],
    gravar: (k, v) async {
      mapa[k] = v;
    },
    remover: (k) async {
      mapa.remove(k);
    },
  );
}

/// Store com credencial vigente pré-gravada.
AdminDeviceTokenStore _storeDeviceAtivo() => _storeDevice({
      AdminDeviceTokenStore.chaveToken: 'dt-ativo',
      AdminDeviceTokenStore.chaveUsername: 'root',
      AdminDeviceTokenStore.chaveExpiraEm: DateTime.now()
          .toUtc()
          .add(const Duration(days: 30))
          .millisecondsSinceEpoch
          .toString(),
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BiometriaPreferences prefs;

  Future<void> pumpTela(
    WidgetTester tester, {
    AdminAuthProvider? adminAuth,
    AdminDeviceTokenStore? deviceStore,
  }) async {
    prefs = await BiometriaPreferences.carregar();
    final router = GoRouter(
      initialLocation: '/perfil/seguranca',
      routes: [
        GoRoute(
          path: '/perfil/seguranca',
          builder: (context, state) => PerfilSegurancaScreen(
            deviceStore: deviceStore ?? _storeDevice(),
          ),
        ),
        GoRoute(
          path: '/perfil/2fa',
          builder: (context, state) => const _Tela2FAMarcador(),
        ),
        GoRoute(
          path: '/admin/seguranca',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('tela-2fa-admin'))),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BiometriaPreferences>.value(value: prefs),
          ChangeNotifierProvider<AdminAuthProvider>.value(
            value: adminAuth ?? _AdminFake(),
          ),
        ],
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

    testWidgets('admin root: tile do 2FA navega para /admin/seguranca',
        (tester) async {
      final admin = _AdminFake()..autenticado = true;
      await pumpTela(tester, adminAuth: admin);

      await tester.tap(find.byKey(const Key('seguranca_two_factor_tile')));
      await tester.pumpAndSettle();

      expect(find.text('tela-2fa-admin'), findsOneWidget);
      expect(find.text('tela-2fa'), findsNothing);
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

  group('PerfilSegurancaScreen — dispositivo confiável (admin root)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('colaborador não vê o tile de dispositivo confiável',
        (tester) async {
      await pumpTela(tester);

      expect(find.byKey(const Key('seguranca_dispositivo_tile')), findsNothing);
    });

    testWidgets('admin root: ativar confia no dispositivo e grava a '
        'credencial', (tester) async {
      final store = _storeDevice();
      final admin = _AdminFake()..autenticado = true;
      await pumpTela(tester, adminAuth: admin, deviceStore: store);

      final tile = find.byKey(const Key('seguranca_dispositivo_tile'));
      expect(tile, findsOneWidget);
      expect(find.textContaining('Entre no próximo acesso'), findsOneWidget);

      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(admin.vincularChamadas, 1);
      expect(await store.possuiCredencial(), isTrue);
      expect(find.textContaining('Ativo até'), findsOneWidget);

      // Drena o timer do snackbar antes de encerrar o teste.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('falha ao vincular avisa e não grava credencial',
        (tester) async {
      final store = _storeDevice();
      final admin = _AdminFake()
        ..autenticado = true
        ..vincularOk = false;
      await pumpTela(tester, adminAuth: admin, deviceStore: store);

      final tile = find.byKey(const Key('seguranca_dispositivo_tile'));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(admin.vincularChamadas, 1);
      expect(await store.possuiCredencial(), isFalse);
      expect(find.textContaining('Entre no próximo acesso'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('admin root: revogar pede confirmação e limpa a credencial',
        (tester) async {
      final store = _storeDeviceAtivo();
      final admin = _AdminFake()..autenticado = true;
      await pumpTela(tester, adminAuth: admin, deviceStore: store);

      expect(find.textContaining('Ativo até'), findsOneWidget);

      final tile = find.byKey(const Key('seguranca_dispositivo_tile'));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.text('Revogar este dispositivo?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Revogar'));
      await tester.pumpAndSettle();

      expect(admin.revogarChamadas, 1);
      expect(await store.possuiCredencial(), isFalse);
      expect(find.textContaining('Entre no próximo acesso'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('cancelar a confirmação não revoga nem limpa a credencial',
        (tester) async {
      final store = _storeDeviceAtivo();
      final admin = _AdminFake()..autenticado = true;
      await pumpTela(tester, adminAuth: admin, deviceStore: store);

      final tile = find.byKey(const Key('seguranca_dispositivo_tile'));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(admin.revogarChamadas, 0);
      expect(await store.possuiCredencial(), isTrue);
      expect(find.textContaining('Ativo até'), findsOneWidget);
    });
  });
}
