import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/admin/data/datasources/admin_auth_remote_datasource.dart';
import 'package:chronos_pulse_app/features/admin/data/repositories/admin_auth_repository_impl.dart';
import 'package:chronos_pulse_app/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:chronos_pulse_app/features/admin/presentation/screens/admin_alterar_senha_screen.dart';

/// AdminAuthProvider com alterarSenha interceptado (mesmo padrão de
/// perfil_screen_test.dart), sem tocar em rede.
class _FakeAdminAuth extends AdminAuthProvider {
  _FakeAdminAuth()
      : super(
          AdminAuthRepositoryImpl(AdminAuthRemoteDataSource(DioClient())),
          DioClient(),
        );

  String? novaSenhaChamada;

  @override
  Future<bool> alterarSenha({required String novaSenha}) async {
    novaSenhaChamada = novaSenha;
    return true;
  }
}

void main() {
  late _FakeAdminAuth adminAuth;

  setUp(() {
    adminAuth = _FakeAdminAuth();
  });

  Future<void> pumpTela(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AdminAuthProvider>.value(
        value: adminAuth,
        child: const MaterialApp(home: AdminAlterarSenhaScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('dispensa senha atual e salva só após confirmação',
      (tester) async {
    await pumpTela(tester);

    expect(find.text('Senha atual'), findsNothing);
    expect(find.text('Nova senha'), findsOneWidget);
    expect(find.text('Confirmar nova senha'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Nova@1234');
    await tester.enterText(find.byType(TextFormField).at(1), 'Nova@1234');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar nova senha'));
    await tester.pumpAndSettle();

    expect(find.text('Certeza de alterar senha?'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Desistir'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Alterar'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Desistir'));
    await tester.pumpAndSettle();
    expect(adminAuth.novaSenhaChamada, isNull);
    expect(find.text('Nova senha'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar nova senha'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Alterar'));
    await tester.pumpAndSettle();

    expect(adminAuth.novaSenhaChamada, 'Nova@1234');
    expect(find.text('Senha alterada com sucesso.'), findsOneWidget);
    expect(find.text('Nova@1234'), findsNothing);
  });
}
