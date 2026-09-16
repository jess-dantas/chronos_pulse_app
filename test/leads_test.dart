import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/auth/data/repositories/lead_repository.dart';
import 'package:chronos_pulse_app/features/leads/presentation/providers/leads_provider.dart';

class _LeadRepositoryStub extends LeadRepository {
  _LeadRepositoryStub() : super(DioClient());
}

void main() {
  group('LeadEmpresaModel.fromJson', () {
    test('converte os campos principais do leiaute da API', () {
      final lead = LeadEmpresaModel.fromJson({
        'id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'cnpj': '12.345.678/0001-99',
        'razaoSocial': 'Prefeitura de Exemplo',
        'contatoNome': 'Ana Souza',
        'contatoEmail': 'ana@exemplo.gov.br',
        'enderecoCidade': 'São Paulo',
        'enderecoUf': 'SP',
        'status': 'AGENDADO',
        'criadoEm': '2026-09-15T10:30:00Z',
      });

      expect(lead.id, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');
      expect(lead.razaoSocial, 'Prefeitura de Exemplo');
      expect(lead.contatoNome, 'Ana Souza');
      expect(lead.status, 'AGENDADO');
      expect(lead.cidadeUf, 'São Paulo/SP');
      expect(lead.criadoEm.year, 2026);
    });

    test('cidadeUf suporta ausência de cidade/UF', () {
      final lead = LeadEmpresaModel.fromJson({
        'id': '1',
        'cnpj': '12345678000199',
        'razaoSocial': 'Empresa LTDA',
        'contatoNome': 'João',
        'contatoEmail': 'j@e.com',
      });

      expect(lead.cidadeUf, isEmpty);
      expect(lead.status, 'NOVO');
    });
  });

  group('LeadsProvider funil', () {
    test('ordemFunil segue o funil comercial', () {
      expect(LeadsProvider.ordemFunil,
          ['NOVO', 'AGENDADO', 'REUNIAO', 'CONTRATADO', 'DESCARTADO']);
    });

    test('proximoStatus avança até CONTRATADO', () {
      final provider = LeadsProvider(_LeadRepositoryStub());
      expect(provider.proximoStatus('NOVO'), 'AGENDADO');
      expect(provider.proximoStatus('AGENDADO'), 'REUNIAO');
      expect(provider.proximoStatus('REUNIAO'), 'CONTRATADO');
      expect(provider.proximoStatus('CONTRATADO'), isNull);
      expect(provider.proximoStatus('DESCARTADO'), isNull);
    });
  });
}