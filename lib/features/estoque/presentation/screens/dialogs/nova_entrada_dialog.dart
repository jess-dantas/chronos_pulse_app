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
  final _codigoBarrasController = TextEditingController();
  final _numeroTermoController = TextEditingController();
  String _tipoTermo = 'DEFINITIVO';

  MaterialModel? get _materialSelecionado {
    if (_selectedMaterialId == null) return null;
    return context.read<EstoqueProvider>().materiais
        .where((m) => m.id == _selectedMaterialId)
        .firstOrNull;
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _valorUnitarioController.dispose();
    _loteController.dispose();
    _validadeController.dispose();
    _docReferenciaController.dispose();
    _codigoBarrasController.dispose();
    _numeroTermoController.dispose();
    super.dispose();
  }

  void _buscarPorCodigoBarras(String codigo) {
    if (codigo.trim().isEmpty) return;
    final material = context.read<EstoqueProvider>().materiais.where((m) {
      final cb = m.codigoBarras?.trim();
      return cb != null && cb.isNotEmpty && cb.toUpperCase() == codigo.trim().toUpperCase();
    }).firstOrNull;
    if (material != null && material.id != _selectedMaterialId) {
      setState(() => _selectedMaterialId = material.id);
    }
  }

  String? _validarValidade(String? val) {
    if (val == null || val.isEmpty) {
      return _materialSelecionado?.controlaLoteValidade == true ? 'Obrigatório para perecível' : null;
    }
    final partes = val.split('-');
    if (partes.length != 3) return 'Formato AAAA-MM-DD';
    if (DateTime.tryParse(val) == null) return 'Data inválida';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final estoqueProvider = context.watch<EstoqueProvider>();
    final materialPerecivel = _materialSelecionado?.controlaLoteValidade ?? false;

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
                  initialValue: _selectedAlmoxarifadoId,
                  items: estoqueProvider.almoxarifados.map((a) {
                    return DropdownMenuItem(value: a.id, child: Text(a.nome));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAlmoxarifadoId = val),
                  validator: (val) => val == null ? 'Selecione o almoxarifado' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codigoBarrasController,
                  decoration: const InputDecoration(
                    labelText: 'Código de Barras (Opcional)',
                    hintText: 'Escaneie ou digite para localizar o item',
                    prefixIcon: Icon(Icons.qr_code_scanner),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _buscarPorCodigoBarras,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    final formatoOk = val.trim().length >= 8 && val.trim().length <= 32;
                    return formatoOk ? null : 'Código deve ter entre 8 e 32 caracteres';
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Material / Item',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedMaterialId,
                  items: estoqueProvider.materiais.map((m) {
                    final catmat = m.codigoCatmat != null ? '[${m.codigoCatmat}] ' : '';
                    final perecivel = m.controlaLoteValidade ? ' / Perecível' : '';
                    return DropdownMenuItem(
                      value: m.id,
                      child: Text(
                        '$catmat${m.descricao} (${m.unidadeMedida})$perecivel',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedMaterialId = val;
                      if (val != null) {
                        final m = estoqueProvider.materiais
                            .where((e) => e.id == val)
                            .firstOrNull;
                        if (m?.codigoBarras != null && m!.codigoBarras!.isNotEmpty) {
                          _codigoBarrasController.text = m.codigoBarras!;
                        }
                      }
                    });
                  },
                  validator: (val) =>
                      val == null ? 'Selecione ou escaneie o material' : null,
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
                        decoration: InputDecoration(
                          labelText: materialPerecivel
                              ? 'Lote *'
                              : 'Lote (Opcional)',
                          hintText: materialPerecivel ? 'Ex: L2026-0098' : null,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (materialPerecivel && (val == null || val.trim().isEmpty)) {
                            return 'Obrigatório para perecível';
                          }
                          if (materialPerecivel && val!.trim().length < 3) {
                            return 'Lote inválido (mín. 3)';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _validadeController,
                        decoration: InputDecoration(
                          labelText: materialPerecivel ? 'Validade *' : 'Validade (AAAA-MM-DD)',
                          hintText: '2027-12-31',
                          border: const OutlineInputBorder(),
                        ),
                        validator: _validarValidade,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Tipo do Termo de Recebimento',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _tipoTermo,
                        items: const [
                          DropdownMenuItem(value: 'DEFINITIVO', child: Text('Definitivo')),
                          DropdownMenuItem(value: 'PROVISORIO', child: Text('Provisório')),
                        ],
                        onChanged: (val) => setState(() => _tipoTermo = val ?? 'DEFINITIVO'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _numeroTermoController,
                        decoration: const InputDecoration(
                          labelText: 'Nº do Termo',
                          hintText: 'Ex: 45/2026',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (_tipoTermo == 'PROVISORIO' &&
                              (val == null || val.trim().isEmpty)) {
                            return 'Nº obrigatório p/ provisório';
                          }
                          return null;
                        },
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
              tipoTermo: _tipoTermo,
              numeroTermo: _numeroTermoController.text.trim(),
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