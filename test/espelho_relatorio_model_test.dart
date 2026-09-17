import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/features/ponto/data/models/espelho_relatorio_model.dart';

void main() {
  group('EspelhoRelatorioModel.fromJson', () {
    test('Faz parse completo do payload vindo de /pontos/espelho/relatorio', () {
      final json = {
        'periodo': {'inicio': '2026-09-01', 'fim': '2026-09-30'},
        'dataEmissao': '2026-09-16T13:30:00Z',
        'empregador': {'nome': 'Empresa Teste LTDA', 'cnpj': '12.345.678/0001-99'},
        'trabalhador': {
          'nome': 'João da Silva',
          'cpf': '123.456.789-01',
          'dataAdmissao': '2020-03-02',
          'cargo': 'Analista de Sistemas',
          'matricula': '000123',
          'departamento': 'TI',
        },
        'jornadaContratual': {
          'nome': 'Jornada Administrativa 44h',
          'cargaHorariaDiariaMinutos': 440,
          'intervaloMinimoMinutos': 60,
        },
        'marcacoes': [
          {
            'id': 'reg-1',
            'colaboradorId': 'cpc-1',
            'tenantId': 'tenant-1',
            'dataHoraDispositivo': '2026-09-01T08:00:00Z',
            'dataHoraServidor': '2026-09-01T08:00:00Z',
            'tipoRegistro': 'ENTRADA',
            'latitude': 0,
            'longitude': 0,
            'precisaoGps': 0,
            'hashIntegridade': 'abc',
            'nsr': 1,
            'ajusteManual': false,
          },
        ],
        'codigoVerificacao': 'a' * 64,
      };

      final modelo = EspelhoRelatorioModel.fromJson(json);

      expect(modelo.periodo.inicio, equals(DateTime(2026, 9, 1)));
      expect(modelo.periodo.fim, equals(DateTime(2026, 9, 30)));
      expect(modelo.empregador?.nome, equals('Empresa Teste LTDA'));
      expect(modelo.empregador?.cnpj, equals('12.345.678/0001-99'));
      expect(modelo.trabalhador?.nome, equals('João da Silva'));
      expect(modelo.trabalhador?.dataAdmissao, equals(DateTime(2020, 3, 2)));
      expect(modelo.trabalhador?.cargo, equals('Analista de Sistemas'));
      expect(modelo.jornadaContratual?.cargaHorariaDiariaMinutos, equals(440));
      expect(modelo.jornadaContratual?.intervaloMinimoMinutos, equals(60));
      expect(modelo.codigoVerificacao, hasLength(64));
      expect(modelo.marcacoes, hasLength(1));
      expect(modelo.marcacoes.first.tipoRegistro, equals('ENTRADA'));
      expect(modelo.marcacoes.first.nsr, equals(1));
      expect(modelo.marcacoes.first.ajusteManual, isFalse);
    });

    test('Lida com campos ausentes sem quebrar', () {
      final modelo = EspelhoRelatorioModel.fromJson({
        'dataEmissao': '2026-09-16T13:30:00Z',
      });

      expect(modelo.empregador, isNull);
      expect(modelo.trabalhador, isNull);
      expect(modelo.jornadaContratual, isNull);
      expect(modelo.codigoVerificacao, isNull);
      expect(modelo.marcacoes, isEmpty);
    });
  });
}