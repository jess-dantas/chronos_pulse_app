import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/estoque_models.dart';
import '../../providers/estoque_provider.dart';

class NovaEntradaDialog extends StatefulWidget {
  const NovaEntradaDialog({super.key});

  @override
  State<NovaEntradaDialog> createState() => _NovaEntradaDialogState();
}

class _NovaEntradaDialogState extends State<NovaEntradaDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedAlmoxarifadoId;
  String? _selectedMaterialId;
  final _quantidadeController = TextEditingController();
  final _valorUnitarioController = TextEditingController();
  final _loteController = TextEditingController();
  final _validadeController = TextEditingController();
  final _docReferenciaController = TextEditingController();

  @override
  void dispose() {
    _quantidadeController.dispose();
    _valorUnitarioController.dispose();
    _loteController.dispose();
    _validadeController.dispose();
    _docReferenciaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estoqueProvider = context.watch<EstoqueProvider>();

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_shopping_cart, color: Colors.deepPurple),
          SizedBox(width: 8),
          Text('Entrada de Material (NFe / Empenho)'),
        ],
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Almoxarifado',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedAlmoxarifadoId,
                  items: estoqueProvider.almoxarifados.map((a) {
                    return DropdownMenuItem(value: a.id, child: Text(a.nome));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAlmoxarifadoId = val),
                  validator: (val) => val == null ? 'Selecione o almoxarifado' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Material / Item',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedMaterialId,
                  items: estoqueProvider.materiais.map((m) {
                    final catmat = m.codigoCatmat != null ? '[${m.codigoCatmat}] ' : '';
                    return DropdownMenuItem(
                      value: m.id,
                      child: Text(
                        '$catmat${m.descricao} (${m.unidadeMedida})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedMaterialId = val),
                  validator: (val) => val == null ? 'Selecione o material' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantidadeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Quantidade',
                          hintText: 'Ex: 10.0',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Obrigatório';
                          final n = double.tryParse(val.replaceAll(',', '.'));
                          if (n == null || n <= 0) return 'Qtd inválida';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _valorUnitarioController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: r'Valor Unitário (R$)',
                          hintText: 'Ex: 25.50',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Obrigatório';
                          final n = double.tryParse(val.replaceAll(',', '.'));
                          if (n == null || n < 0) return 'Valor inválido';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _docReferenciaController,
                  decoration: const InputDecoration(
                    labelText: 'Doc. Referência / NFe / Empenho',
                    hintText: 'Ex: NF-e 004821 / Empenho 2026/102',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _loteController,
                        decoration: const InputDecoration(
                          labelText: 'Lote (Opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _validadeController,
                        decoration: const InputDecoration(
                          labelText: 'Validade (AAAA-MM-DD)',
                          hintText: '2027-12-31',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Confirmar Entrada'),
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final dto = EntradaEstoqueRequestDTO(
              almoxarifadoId: _selectedAlmoxarifadoId!,
              materialId: _selectedMaterialId!,
              quantidade: double.parse(_quantidadeController.text.replaceAll(',', '.')),
              valorUnitario: double.parse(_valorUnitarioController.text.replaceAll(',', '.')),
              documentoReferencia: _docReferenciaController.text.trim(),
              lote: _loteController.text.trim(),
              dataValidade: _validadeController.text.trim(),
            );

            final sucesso = await estoqueProvider.registrarEntrada(dto);
            if (context.mounted) {
              if (sucesso) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Entrada registrada e PMP recalculado com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(estoqueProvider.errorMessage ?? 'Erro ao registrar entrada.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
