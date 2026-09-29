import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/admin/data/repositories/admin_auth_repository.dart';
import 'package:chronos_pulse_app/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:chronos_pulse_app/features/admin/presentation/screens/admin_seguranca_screen.dart';

/// Repositório falso: implementa só o que o teste usa e delega o resto para
/// `noSuchMethod` (mesmo padrão dos demais fakes do projeto).
class _RepositorioFake implements AdminAuthRepository {
  String? codigoDesabilitar;
  Object? erroDesabilitar;
  bool statusEnabled = true;

  @override
  Future<Map<String, dynamic>> twoFactorStatus() async =>
      {'enabled': statusEnabled};

  @override
  Future<void> twoFactorDisable(String codigo) async {
    final erro = erroDesabilitar;
    if (erro != null) throw erro;
    codigoDesabilitar = codigo;
    statusEnabled = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _RepositorioFake repositorio;
  late AdminAuthProvider provider;

  setUp(() {
    repositorio = _RepositorioFake();
    provider = AdminAuthProvider(repositorio, DioClient());
  });

  group('AdminAuthProvider.desabilitarTwoFactor', () {
    test('desativa o 2FA e repassa o código ao repositório', () async {
      await provider.carregarStatusTwoFactor();
      expect(provider.twoFactorEnabled, isTrue);

      final ok = await provider.desabilitarTwoFactor('123456');

      expect(ok, isTrue);
      expect(repositorio.codigoDesabilitar, '123456');
      expect(provider.twoFactorEnabled, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('mantém o 2FA ativo e expõe a mensagem quando o código é inválido',
        () async {
      await provider.carregarStatusTwoFactor();
      repositorio.erroDesabilitar = Exception('Código inválido');

      final ok = await provider.desabilitarTwoFactor('000000');

      expect(ok, isFalse);
      expect(provider.twoFactorEnabled, isTrue);
      expect(provider.errorMessage, contains('Código inválido'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('AdminSegurancaScreen', () {
    Future<void> pumpTela(WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AdminAuthProvider>.value(
          value: provider,
          child: const MaterialApp(home: AdminSegurancaScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('oferece a desativação quando o 2FA está ativo', (tester) async {
      await pumpTela(tester);

      expect(find.text('Ativa'), findsOneWidget);
      expect(find.text('Desativar 2FA'), findsOneWidget);
      expect(
        find.text('A desativação não está disponível para o '
            'Administrator da plataforma.'),
        findsNothing,
      );
    });

    testWidgets('desativa após confirmar com o código no diálogo',
        (tester) async {
      await pumpTela(tester);

      await tester.tap(find.text('Desativar 2FA'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'Desativar'));
      await tester.pumpAndSettle();

      expect(repositorio.codigoDesabilitar, '123456');
      expect(provider.twoFactorEnabled, isFalse);
      expect(find.text('Desativada'), findsOneWidget);
      expect(find.text('Ativar 2FA'), findsOneWidget);
    });
  });
}
