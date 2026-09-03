import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/estoque_models.dart';
import '../../providers/estoque_provider.dart';

class NovaSaidaDialog extends StatefulWidget {
  final EstoqueSaldoModel? itemPreSelecionado;

  const NovaSaidaDialog({super.key, this.itemPreSelecionado});

  @override
  State<NovaSaidaDialog> createState() => _NovaSaidaDialogState();
}

class _NovaSaidaDialogState extends State<NovaSaidaDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedAlmoxarifadoId;
  String? _selectedMaterialId;
  final _quantidadeController = TextEditingController();
  final _docReferenciaController = TextEditingController();
  final _loteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.itemPreSelecionado != null) {
      _selectedAlmoxarifadoId = widget.itemPreSelecionado!.almoxarifadoId;
      _selectedMaterialId = widget.itemPreSelecionado!.materialId;
      if (widget.itemPreSelecionado!.lote != null) {
        _loteController.text = widget.itemPreSelecionado!.lote!;
      }
    }
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _docReferenciaController.dispose();
    _loteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estoqueProvider = context.watch<EstoqueProvider>();

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.output, color: Colors.orange),
          SizedBox(width: 8),
          Text('Saída / Baixa de Estoque'),
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
                    return DropdownMenuItem(
                      value: m.id,
                      child: Text(
                        '${m.descricao} (${m.unidadeMedida})',
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
                          labelText: 'Quantidade para Baixa',
                          hintText: 'Ex: 2.0',
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
                        controller: _loteController,
                        decoration: const InputDecoration(
                          labelText: 'Lote (Se houver)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _docReferenciaController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo / Destino / Termo de Entrega',
                    hintText: 'Ex: Secretaria de Educação - Termo nº 12/2026',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Informe o motivo ou destino' : null,
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
          label: const Text('Confirmar Baixa'),
          style: FilledButton.styleFrom(backgroundColor: Colors.orange[800]),
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final dto = SaidaEstoqueRequestDTO(
              almoxarifadoId: _selectedAlmoxarifadoId!,
              materialId: _selectedMaterialId!,
              quantidade: double.parse(_quantidadeController.text.replaceAll(',', '.')),
              lote: _loteController.text.trim(),
              documentoReferencia: _docReferenciaController.text.trim(),
            );

            final sucesso = await estoqueProvider.registrarSaida(dto);
            if (context.mounted) {
              if (sucesso) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Saída registrada com sucesso no valor do PMP atual!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(estoqueProvider.errorMessage ?? 'Erro ao registrar saída.'),
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
