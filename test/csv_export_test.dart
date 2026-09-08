import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/utils/csv_export.dart';

void main() {
  group('CsvExport Tests', () {
    test('gerarConteudo adiciona BOM UTF-8', () {
      final conteudo = CsvExport.gerarConteudo(
        cabecalho: ['A', 'B'],
        linhas: [
          ['1', '2'],
        ],
      );
      expect(conteudo.startsWith('\uFEFF'), isTrue);
    });

    test('gerarConteudo monta cabeçalho e linhas com separador ;', () {
      final conteudo = CsvExport.gerarConteudo(
        cabecalho: ['ColA', 'ColB'],
        linhas: [
          ['v1', 'v2'],
          ['v3', 'v4'],
        ],
      );
      final linhas = conteudo.replaceFirst('\uFEFF', '').split('\n');
      expect(linhas[0], 'ColA;ColB');
      expect(linhas[1], 'v1;v2');
      expect(linhas[2], 'v3;v4');
    });

    test('campo com separador é envolvido em aspas', () {
      final conteudo = CsvExport.gerarConteudo(
        cabecalho: ['A', 'B'],
        linhas: [
          ['texto;extra', 'ok'],
        ],
      );
      expect(conteudo.replaceFirst('\uFEFF', '').split('\n')[1], '"texto;extra";ok');
    });

    test('aspas dentro do campo são duplicadas e o campo é citado', () {
      final conteudo = CsvExport.gerarConteudo(
        cabecalho: ['A', 'B'],
        linhas: [
          ['abc "xyz"', 'ok'],
        ],
      );
      expect(
        conteudo.replaceFirst('\uFEFF', '').split('\n')[1],
        '"abc ""xyz""";ok',
      );
    });

    test('quebra de linha no campo é preservada dentro das aspas', () {
      final conteudo = CsvExport.gerarConteudo(
        cabecalho: ['A'],
        linhas: [
          ['linha1\nlinha2'],
        ],
      );
      final semBom = conteudo.replaceFirst('\uFEFF', '');
      expect(semBom.contains('"linha1\nlinha2"'), isTrue);
    });

    test('campos simples não são citados', () {
      final conteudo = CsvExport.gerarConteudo(
        cabecalho: ['A'],
        linhas: [
          ['sem_aspas'],
        ],
      );
      final semBom = conteudo.replaceFirst('\uFEFF', '');
      expect(semBom.contains('"'), isFalse);
    });
  });
}