import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/auth/data/models/usuario_model.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chronos_pulse_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_local_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_remote_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/models/registro_ponto_model.dart';
import 'package:chronos_pulse_app/features/ponto/data/repositories/ponto_repository.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/dialogs/solicitar_ajuste_dialog.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/providers/ponto_provider.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/screens/espelho_ponto_tab.dart';

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

/// PontoProvider com espelho injetado (sem rede/SQLite) para o teste de UI.
class _FakePontoProvider extends PontoProvider {
  _FakePontoProvider()
      : super(PontoRepository(
          localDataSource: PontoLocalDataSource(),
          remoteDataSource: PontoRemoteDataSource(DioClient()),
        ));

  List<RegistroPontoModel> espelhoFake = [];

  @override
  List<RegistroPontoModel> get espelho => espelhoFake;
}

UsuarioModel _colaborador() => UsuarioModel(
      token: 'token',
      refreshToken: 'refresh',
      tipo: 'Bearer',
      nome: 'Maria Colaboradora',
      email: 'maria@example.com',
      cpf: '12345678901',
      role: 'COLABORADOR',
      modulos: const ['PONTO'],
    );

RegistroPontoModel _registro({
  required DateTime dataHora,
  String? ajusteStatus,
  bool ajusteManual = false,
}) =>
    RegistroPontoModel(
      idLocal: '${dataHora.microsecondsSinceEpoch}',
      colaboradorId: 'col-1',
      dataHoraDispositivo: dataHora,
      tipoRegistro: 'ENTRADA',
      latitude: 0,
      longitude: 0,
      precisaoGps: 0,
      ajusteManual: ajusteManual,
      ajusteStatus: ajusteStatus,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  // O fonte de teste (Ahem) desenha cada glifo quadrado, deixando textos bem
  // mais largos que o real; escala menor evita falso positivo de overflow.
  void escalaDeTeste(WidgetTester tester) {
    tester.platformDispatcher.textScaleFactorTestValue = 0.7;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
  }

  group('Bloqueio de solicitação no dia com ajuste aprovado (Fase 5)', () {
    late _FakeAuth auth;
    late _FakePontoProvider ponto;

    setUp(() {
      auth = _FakeAuth();
      auth.definirSessao(_colaborador());
      ponto = _FakePontoProvider();
      final agora = DateTime.now();
      ponto.espelhoFake = [
        _registro(
          dataHora: DateTime(agora.year, agora.month, 9, 9),
          ajusteStatus: 'PENDENTE',
          ajusteManual: true,
        ),
        _registro(
          dataHora: DateTime(agora.year, agora.month, 10, 9),
          ajusteStatus: 'APROVADO',
          ajusteManual: true,
        ),
      ];
    });

    testWidgets('Espelho desabilita o atalho do dia com ajuste aprovado',
        (tester) async {
      escalaDeTeste(tester);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<PontoProvider>.value(value: ponto),
          ],
          child: const MaterialApp(
            home: Scaffold(body: EspelhoPontoTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bloqueado =
          find.byTooltip('Dia com ajuste aprovado — novas solicitações de ajuste estão bloqueadas.');
      expect(bloqueado, findsOneWidget);
      final iconeBloqueado = find.descendant(
          of: bloqueado, matching: find.byType(IconButton));
      expect(iconeBloqueado, findsOneWidget);
      expect(tester.widget<IconButton>(iconeBloqueado).onPressed, isNull);

      // Dias sem aprovação continuam liberados.
      final livre = find.byTooltip(
          'Solicitar ajuste neste dia (aguardará aprovação do RH)');
      expect(livre, findsWidgets);
      final iconeLivre = find.descendant(
          of: livre.first, matching: find.byType(IconButton));
      expect(iconeLivre, findsOneWidget);
      expect(tester.widget<IconButton>(iconeLivre).onPressed, isNotNull);
    });

    testWidgets('Diálogo de solicitação recusa o dia bloqueado ao enviar',
        (tester) async {
      escalaDeTeste(tester);
      final agora = DateTime.now();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<PontoProvider>.value(value: ponto),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => SolicitarAjusteDialog(
                      dataInicial: DateTime(agora.year, agora.month, 10),
                      todosRegistros: ponto.espelhoFake,
                    ),
                  ),
                  child: const Text('Abrir diálogo'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir diálogo'));
      await tester.pumpAndSettle();
      expect(find.text('Solicitar Ajuste de Ponto'), findsOneWidget);

      await tester.tap(find.text('Enviar Solicitação'));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Este dia já possui ajuste aprovado — novas solicitações estão bloqueadas.'),
        findsOneWidget,
      );
      expect(find.text('Solicitar Ajuste de Ponto'), findsOneWidget,
          reason: 'diálogo deve continuar aberto para trocar a data');
    });
  });
}
