import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/hardware/hardware_service.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/security/device_token_store.dart';
import 'package:chronos_pulse_app/core/theme/theme_provider.dart';
import 'package:chronos_pulse_app/core/widgets/dialogs/contingencia_gate.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/models/usuario_model.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/privacidade/data/privacidade_datasource.dart';
import 'package:chronos_pulse_app/features/privacidade/presentation/providers/privacidade_provider.dart';

/// AuthProvider com sessão injetada e ativação de vínculo controlável.
class _FakeAuth extends AuthProvider {
  _FakeAuth({this.ativacaoOk = true})
      : super(AuthRepository(
          remoteDataSource: AuthRemoteDataSource(DioClient()),
          dioClient: DioClient(),
        ));

  final bool ativacaoOk;
  int chamadasAtivacao = 0;

  UsuarioModel? _sessao;

  void definirSessao(UsuarioModel usuario) => _sessao = usuario;

  @override
  UsuarioModel? get usuario => _sessao;

  @override
  bool get isAuthenticated => _sessao != null && _sessao!.token.isNotEmpty;

  @override
  Future<DateTime?> ativarVinculoDispositivo({String? deviceName}) async {
    chamadasAtivacao++;
    if (!ativacaoOk) return null;
    return DateTime.now().toUtc().add(const Duration(days: 7));
  }
}

/// HardwareService com biometria controlável (sem tocar no plugin real).
class _FakeHardware extends HardwareService {
  _FakeHardware({this.disponivel = true, this.autenticar = true});

  bool disponivel;
  bool autenticar;

  @override
  Future<bool> biometriaDisponivel() async => disponivel;

  @override
  Future<bool> autenticarBiometria({String motivo = ''}) async =>
      autenticar;
}

class _FakePrivacidadeDataSource extends PrivacidadeDataSource {
  _FakePrivacidadeDataSource({this.aceitePendente = false})
      : super(DioClient());

  final bool aceitePendente;

  @override
  Future<Map<String, dynamic>> getStatusConsentimento() async => {
        'versaoAtual': '1.0',
        'versaoAceita': aceitePendente ? null : '1.0',
        'dataConsentimento': aceitePendente ? null : '2026-09-08T10:00:00Z',
        'aceitePendente': aceitePendente,
      };
}

UsuarioModel _usuario() => UsuarioModel(
      token: 'token',
      refreshToken: 'refresh',
      tipo: 'Bearer',
      nome: 'Teste',
      email: 'teste@example.com',
      cpf: '12345678901',
      role: 'COLABORADOR',
      modulos: const ['PONTO'],
    );

/// Store em memória (sem Keystore) com/sem vínculo válido.
DeviceTokenStore _fakeStore({bool comVinculo = false}) {
  final mem = <String, String>{};
  if (comVinculo) {
    mem[DeviceTokenStore.chaveToken] = 'token-teste';
    mem[DeviceTokenStore.chaveCpcId] = 'cpc-1';
    mem[DeviceTokenStore.chaveNome] = 'Teste';
    mem[DeviceTokenStore.chaveExpiraEm] = DateTime.now()
        .toUtc()
        .add(const Duration(days: 1))
        .millisecondsSinceEpoch
        .toString();
  }
  return DeviceTokenStore(
    ler: (k) async => mem[k],
    gravar: (k, v) async => mem[k] = v,
    remover: (k) async => mem.remove(k),
  );
}

void main() {
  Future<void> pumpGate(
    WidgetTester tester, {
    required _FakeHardware hardware,
    required _FakeAuth auth,
    bool comVinculo = false,
    bool? ativo,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (_) => PrivacidadeProvider(_FakePrivacidadeDataSource()),
          ),
        ],
        child: MaterialApp(
          home: ContingenciaGate(
            ativo: ativo ?? true,
            store: _fakeStore(comVinculo: comVinculo),
            hardwareService: hardware,
            child: const Scaffold(body: Text('CONTEUDO_PAINEL')),
          ),
        ),
      ),
    );
    await tester.pump(); // cadeia assíncrona do gate (termo + vínculo)
    await tester.pumpAndSettle(); // renderiza o modal (se for o caso)
  }

  group('ContingenciaGate — bloqueio do 1º acesso', () {
    testWidgets('não abre quando já há vínculo de contingência ativo',
        (tester) async {
      await pumpGate(
        tester,
        hardware: _FakeHardware(),
        auth: _FakeAuth(),
        comVinculo: true,
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Bater ponto sem login'), findsNothing);
      expect(find.text('CONTEUDO_PAINEL'), findsOneWidget);
    });

    testWidgets('não abre quando o gate está inativo (fora do app cliente)',
        (tester) async {
      await pumpGate(
        tester,
        hardware: _FakeHardware(),
        auth: _FakeAuth(),
        comVinculo: false,
        ativo: false,
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('CONTEUDO_PAINEL'), findsOneWidget);
    });

    testWidgets('não abre quando o Termo de Ciência está pendente',
        (tester) async {
      final auth = _FakeAuth()..definirSessao(_usuario());
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(
              create: (_) =>
                  PrivacidadeProvider(_FakePrivacidadeDataSource(aceitePendente: true)),
            ),
          ],
          child: MaterialApp(
            home: ContingenciaGate(
              ativo: true,
              store: _fakeStore(),
              hardwareService: _FakeHardware(),
              child: const Scaffold(body: Text('CONTEUDO_PAINEL')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      // O consentimento assume; não empilhamos o modal de contingência.
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('CONTEUDO_PAINEL'), findsOneWidget);
    });

    testWidgets(
        'com biometria: bloqueia sem saída e ativa a contingência '
        '(toast de sucesso)', (tester) async {
      final auth = _FakeAuth();
      auth.definirSessao(_usuario());
      await pumpGate(
        tester,
        hardware: _FakeHardware(disponivel: true, autenticar: true),
        auth: auth,
      );

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Bater ponto sem login'), findsOneWidget);
      expect(find.text('Continuar sem contingência'), findsNothing); // sem saída

      await tester.tap(find.byKey(const Key('contingencia_ativar_button')));
      await tester.pumpAndSettle();

      expect(auth.chamadasAtivacao, 1);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('CONTEUDO_PAINEL'), findsOneWidget);
      expect(find.text('Bater ponto sem login ativado!'), findsOneWidget);

      // Drena o timer do snackbar de sucesso antes de encerrar.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('biometria cancelada: permanece no modal com "Tentar novamente"',
        (tester) async {
      final auth = _FakeAuth();
      auth.definirSessao(_usuario());
      final hardware = _FakeHardware(disponivel: true, autenticar: false);
      await pumpGate(tester, hardware: hardware, auth: auth);

      await tester.tap(find.byKey(const Key('contingencia_ativar_button')));
      await tester.pumpAndSettle();

      expect(find.text('Autenticação biométrica cancelada.'), findsOneWidget);
      expect(find.byKey(const Key('contingencia_retry_button')), findsOneWidget);
      // Sem saída: a saída livre exigiria justamente a biometria garantida.
      expect(find.text('Continuar sem contingência'), findsNothing);
      expect(find.byType(AlertDialog), findsOneWidget);

      // "Tentar novamente" com biometria agora disponível → ativa e fecha.
      hardware.autenticar = true;
      await tester.tap(find.byKey(const Key('contingencia_retry_button')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Bater ponto sem login ativado!'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('sem biometria cadastrada: explica e permite continuar',
        (tester) async {
      final auth = _FakeAuth();
      auth.definirSessao(_usuario());
      await pumpGate(
        tester,
        hardware: _FakeHardware(disponivel: false),
        auth: auth,
      );

      expect(
        find.text('Nenhuma biometria cadastrada neste aparelho.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('contingencia_continuar_button')),
        findsOneWidget,
      );
      expect(auth.chamadasAtivacao, 0);

      await tester.tap(find.byKey(const Key('contingencia_continuar_button')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('CONTEUDO_PAINEL'), findsOneWidget);
    });

    testWidgets('falha técnica na ativação: mostra erro e permite sair',
        (tester) async {
      final auth = _FakeAuth(ativacaoOk: false);
      auth.definirSessao(_usuario());
      await pumpGate(
        tester,
        hardware: _FakeHardware(disponivel: true, autenticar: true),
        auth: auth,
      );

      await tester.tap(find.byKey(const Key('contingencia_ativar_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Não foi possível ativar'), findsOneWidget);
      expect(
        find.byKey(const Key('contingencia_continuar_button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('contingencia_continuar_button')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('CONTEUDO_PAINEL'), findsOneWidget);
    });
  });
}
