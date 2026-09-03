import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/features/estoque/data/models/estoque_models.dart';

void main() {
  group('Estoque Models Tests', () {
    test('MaterialModel deve desserializar JSON corretamente', () {
      final json = {
        'id': 'mat-001',
        'grupoId': 'grp-001',
        'grupoNome': 'Expediente',
        'codigoCatmat': 'CAT-1001',
        'descricao': 'Papel A4 Sulfite',
        'unidadeMedida': 'RESMA',
        'estoqueMinimo': 10.0,
        'controlaLoteValidade': false,
        'ativo': true,
      };

      final model = MaterialModel.fromJson(json);

      expect(model.id, 'mat-001');
      expect(model.codigoCatmat, 'CAT-1001');
      expect(model.descricao, 'Papel A4 Sulfite');
      expect(model.unidadeMedida, 'RESMA');
      expect(model.estoqueMinimo, 10.0);
    });

    test('EstoqueSaldoModel deve calcular valor total e alertar estoque baixo', () {
      final jsonAbaixo = {
        'id': 'saldo-001',
        'almoxarifadoId': 'almox-001',
        'almoxarifadoNome': 'Almoxarifado Central',
        'materialId': 'mat-001',
        'materialDescricao': 'Papel A4',
        'quantidadeAtual': 5.0,
        'custoMedioUnitario': 28.50,
        'valorTotal': 142.50,
        'estoqueMinimo': 10.0,
      };

      final saldoAbaixo = EstoqueSaldoModel.fromJson(jsonAbaixo);
      expect(saldoAbaixo.isAbaixoMinimo, isTrue);
      expect(saldoAbaixo.valorTotal, 142.50);

      final jsonNormal = {
        'id': 'saldo-002',
        'almoxarifadoId': 'almox-001',
        'materialId': 'mat-002',
        'quantidadeAtual': 20.0,
        'custoMedioUnitario': 10.0,
        'estoqueMinimo': 5.0,
      };

      final saldoNormal = EstoqueSaldoModel.fromJson(jsonNormal);
      expect(saldoNormal.isAbaixoMinimo, isFalse);
      expect(saldoNormal.valorTotal, 200.0);
    });

    test('RequisicaoModel deve desserializar itens corretamente', () {
      final json = {
        'id': 'req-001',
        'almoxarifadoId': 'almox-001',
        'almoxarifadoNome': 'Almoxarifado Central',
        'solicitanteCpcId': 'usr-001',
        'solicitanteNome': 'João Silva',
        'departamento': 'Secretaria de Educação',
        'justificativa': 'Uso pedagógico',
        'status': 'PENDENTE',
        'itens': [
          {
            'id': 'item-001',
            'materialId': 'mat-001',
            'materialDescricao': 'Papel A4',
            'quantidadeSolicitada': 5.0,
            'quantidadeAtendida': 0.0,
          }
        ]
      };

      final req = RequisicaoModel.fromJson(json);
      expect(req.id, 'req-001');
      expect(req.status, 'PENDENTE');
      expect(req.itens.length, 1);
      expect(req.itens.first.quantidadeSolicitada, 5.0);
    });
  });
}
