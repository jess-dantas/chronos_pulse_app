import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/privacidade/data/privacidade_datasource.dart';
import 'package:chronos_pulse_app/features/privacidade/presentation/providers/privacidade_provider.dart';
import 'package:chronos_pulse_app/features/privacidade/presentation/screens/privacidade_screen.dart';

class FakePrivacidadeDataSource extends PrivacidadeDataSource {
  Map<String, dynamic>? politica;
  Map<String, dynamic>? meusDados;
  bool falharPolitica = false;
  bool falharConsentimento = false;
  bool falharExportar = false;
  bool falharApagar = false;
  String? ultimaVersaoConsentida;
  bool apagou = false;

  FakePrivacidadeDataSource() : super(DioClient());

  @override
  Future<Map<String, dynamic>> getPolitica() async {
    if (falharPolitica) throw Exception('Servidor indisponível');
    return politica ?? {'versao': '1.0', 'dataPublicacao': '2026-09-08', 'texto': 'Política de privacidade v1'};
  }

  @override
  Future<Map<String, dynamic>> getMeusDados() async {
    if (falharExportar) throw Exception('Falha ao exportar dados');
    return meusDados ?? {'nome': 'João', 'cpf': '***.456.789-**'};
  }

  @override
  Future<void> registrarConsentimento(String versaoPolitica) async {
    if (falharConsentimento) throw Exception('Falha ao registrar consentimento');
    ultimaVersaoConsentida = versaoPolitica;
  }

  @override
  Future<void> apagarMeusDados() async {
    if (falharApagar) throw Exception('Falha ao anonimizar dados');
    apagou = true;
  }
}

void main() {
  group('PrivacidadeProvider Tests', () {
    test('carregarPolitica carrega a política com sucesso', () async {
      final fake = FakePrivacidadeDataSource();
      final provider = PrivacidadeProvider(fake);

      await provider.carregarPolitica();

      expect(provider.politica, isNotNull);
      expect(provider.politica!['versao'], '1.0');
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('carregarPolitica expõe erro amigável quando falha', () async {
      final fake = FakePrivacidadeDataSource()..falharPolitica = true;
      final provider = PrivacidadeProvider(fake);

      await provider.carregarPolitica();

      expect(provider.politica, isNull);
      expect(provider.errorMessage, 'Servidor indisponível');
    });

    test('registrarConsentimento envia a versão vigente da política', () async {
      final fake = FakePrivacidadeDataSource();
      final provider = PrivacidadeProvider(fake);
      await provider.carregarPolitica();

      final erro = await provider.registrarConsentimento();

      expect(erro, isNull);
      expect(fake.ultimaVersaoConsentida, '1.0');
    });

    test('registrarConsentimento retorna erro quando falha', () async {
      final fake = FakePrivacidadeDataSource()..falharConsentimento = true;
      final provider = PrivacidadeProvider(fake);
      await provider.carregarPolitica();

      final erro = await provider.registrarConsentimento();

      expect(erro, contains('Falha ao registrar consentimento'));
    });

    test('exportarMeusDados preenche dados e retorna nulo', () async {
      final fake = FakePrivacidadeDataSource();
      final provider = PrivacidadeProvider(fake);

      final erro = await provider.exportarMeusDados();

      expect(erro, isNull);
      expect(provider.meusDados, isNotNull);
      expect(provider.meusDados!['cpf'], '***.456.789-**');
    });

    test('exportarMeusDados retorna erro quando falha', () async {
      final fake = FakePrivacidadeDataSource()..falharExportar = true;
      final provider = PrivacidadeProvider(fake);

      final erro = await provider.exportarMeusDados();

      expect(erro, contains('Falha ao exportar dados'));
    });

    test('apagarMeusDados chama anonimização com sucesso', () async {
      final fake = FakePrivacidadeDataSource();
      final provider = PrivacidadeProvider(fake);

      final erro = await provider.apagarMeusDados();

      expect(erro, isNull);
      expect(fake.apagou, isTrue);
    });

    test('apagarMeusDados retorna erro quando falha', () async {
      final fake = FakePrivacidadeDataSource()..falharApagar = true;
      final provider = PrivacidadeProvider(fake);

      final erro = await provider.apagarMeusDados();

      expect(erro, contains('Falha ao anonimizar dados'));
    });
  });

  group('PrivacidadeScreen Widget Tests', () {
    testWidgets('renderiza política e registra consentimento', (tester) async {
      final fake = FakePrivacidadeDataSource();
      final provider = PrivacidadeProvider(fake);

      await tester.pumpWidget(
        ChangeNotifierProvider<PrivacidadeProvider>(
          create: (_) => provider,
          child: const MaterialApp(home: PrivacidadeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Versão 1.0'), findsOneWidget);
      expect(find.textContaining('Política de privacidade v1'), findsOneWidget);
      expect(find.text('Privacidade & LGPD'), findsOneWidget);

      await tester.tap(find.textContaining('Registrar consentimento (v1.0)'));
      await tester.pumpAndSettle();

      expect(fake.ultimaVersaoConsentida, '1.0');
      expect(find.text('Consentimento registrado com sucesso.'), findsOneWidget);
    });

    testWidgets('mostra erro quando a política não carrega', (tester) async {
      final fake = FakePrivacidadeDataSource()..falharPolitica = true;
      final provider = PrivacidadeProvider(fake);

      await tester.pumpWidget(
        ChangeNotifierProvider<PrivacidadeProvider>(
          create: (_) => provider,
          child: const MaterialApp(home: PrivacidadeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Servidor indisponível'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });
  });
}