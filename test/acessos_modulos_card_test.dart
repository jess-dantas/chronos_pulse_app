import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/widgets/acessos_modulos_card.dart';

void main() {
  Widget envolver(Widget child) =>
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

  group('AcessosModulosCard — agrupadores fixos', () {
    testWidgets('exibe os 5 agrupadores na ordem aprovada', (tester) async {
      await tester.pumpWidget(envolver(AcessosModulosCard(
        visiveis: AcessosModulosCard.codigosGlobais,
        selecionados: const {},
        onChanged: (_) {},
      )));

      // 'Transparência'.toUpperCase() mantém o acento (TRANSPARENCIA).
      final headers = [
        'RH',
        'ESTOQUE',
        'COMPRAS',
        'LOGÍSTICA',
        'Transparência'.toUpperCase(),
      ];
      for (final header in headers) {
        expect(find.text(header), findsOneWidget,
            reason: 'cabeçalho $header deve aparecer uma vez');
      }

      // Ordem de renderização (topo → base) igual à ordem aprovada.
      final ys = headers
          .map((h) => tester.getTopLeft(find.text(h)).dy)
          .toList(growable: false);
      for (var i = 1; i < ys.length; i++) {
        expect(ys[i], greaterThan(ys[i - 1]),
            reason: 'cabeçalho ${headers[i]} deve vir depois de ${headers[i - 1]}');
      }
    });

    testWidgets('agrupa todos os 9 códigos do catálogo (nenhum órfão)',
        (tester) async {
      final noGrupo =
          AcessosModulosCard.grupos.expand((g) => g.codigos).toSet();
      expect(noGrupo, AcessosModulosCard.codigosGlobais.toSet());
      expect(AcessosModulosCard.codigosGlobais, hasLength(9));
    });

    testWidgets('esconde agrupador sem módulo visível', (tester) async {
      await tester.pumpWidget(envolver(AcessosModulosCard(
        visiveis: const ['PONTO'],
        selecionados: const {},
        onChanged: (_) {},
      )));

      expect(find.text('RH'), findsOneWidget);
      expect(find.text('ESTOQUE'), findsNothing);
      expect(find.text('COMPRAS'), findsNothing);
      expect(find.text('LOGÍSTICA'), findsNothing);
      expect(find.text('Transparência'.toUpperCase()), findsNothing);
      expect(find.text('Ponto Eletrônico'), findsOneWidget);
      expect(find.text('Recursos Humanos'), findsNothing);
    });

    testWidgets('alternar um switch notifica o conjunto completo',
        (tester) async {
      Set<String>? recebidos;
      await tester.pumpWidget(envolver(AcessosModulosCard(
        visiveis: const ['PONTO', 'ESTOQUE'],
        selecionados: const {'PONTO'},
        onChanged: (novos) => recebidos = novos,
      )));

      await tester.tap(find.text('Estoque e Almoxarifado'));
      await tester.pumpAndSettle();

      expect(recebidos, isNotNull);
      expect(recebidos, containsAll(['PONTO', 'ESTOQUE']));
      expect(recebidos!.length, 2);
    });
  });
}
