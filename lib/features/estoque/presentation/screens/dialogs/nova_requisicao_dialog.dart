import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/estoque_models.dart';
import '../../providers/estoque_provider.dart';

class NovaRequisicaoDialog extends StatefulWidget {
  const NovaRequisicaoDialog({super.key});

  @override
  State<NovaRequisicaoDialog> createState() => _NovaRequisicaoDialogState();
}

class _NovaRequisicaoDialogState extends State<NovaRequisicaoDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedAlmoxarifadoId;
  final _departamentoController = TextEditingController();
  final _justificativaController = TextEditingController();

  final List<RequisicaoItemModel> _itens = [];

  // Variáveis para adicionar item temporário
  String? _tempMaterialId;
  String? _tempMaterialDesc;
  final _tempQtdController = TextEditingController();

  @override
  void dispose() {
    _departamentoController.dispose();
    _justificativaController.dispose();
    _tempQtdController.dispose();
    super.dispose();
  }

  void _adicionarItem() {
    if (_tempMaterialId == null || _tempQtdController.text.isEmpty) return;
    final qtd = double.tryParse(_tempQtdController.text.replaceAll(',', '.'));
    if (qtd == null || qtd <= 0) return;

    setState(() {
      _itens.add(RequisicaoItemModel(
        materialId: _tempMaterialId!,
        materialDescricao: _tempMaterialDesc,
        quantidadeSolicitada: qtd,
      ));
      _tempMaterialId = null;
      _tempMaterialDesc = null;
      _tempQtdController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final estoqueProvider = context.watch<EstoqueProvider>();

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.assignment_add, color: Colors.blue),
          SizedBox(width: 8),
          Text('Nova Requisição de Material'),
        ],
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Almoxarifado de Origem',
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
                TextFormField(
                  controller: _departamentoController,
                  decoration: const InputDecoration(
                    labelText: 'Secretaria / Departamento Solicitante',
                    hintText: 'Ex: Secretaria Municipal de Saúde / Protocolo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Informe o departamento' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _justificativaController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Justificativa do Pedido',
                    hintText: 'Ex: Reposição de insumos para atendimento ao cidadão',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Informe a justificativa' : null,
                ),
                const SizedBox(height: 24),
                const Divider(),
                Text(
                  'Itens da Requisição (${_itens.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Selecionar Item',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        value: _tempMaterialId,
                        items: estoqueProvider.materiais.map((m) {
                          return DropdownMenuItem(
                            value: m.id,
                            child: Text(
                              '${m.descricao} (${m.unidadeMedida})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          final mat = estoqueProvider.materiais.firstWhere((m) => m.id == val);
                          setState(() {
                            _tempMaterialId = val;
                            _tempMaterialDesc = mat.descricao;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _tempQtdController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Qtd',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.add),
                      onPressed: _adicionarItem,
                      tooltip: 'Adicionar item à lista',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_itens.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'Nenhum item adicionado ainda. Escolha um material e clique no botão +.',
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _itens.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _itens[index];
                        return ListTile(
                          dense: true,
                          title: Text(item.materialDescricao ?? 'Item'),
                          subtitle: Text('Quantidade Solicitada: ${item.quantidadeSolicitada}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              setState(() => _itens.removeAt(index));
                            },
                          ),
                        );
                      },
                    ),
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
          icon: const Icon(Icons.send),
          label: const Text('Enviar Requisição'),
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            if (_itens.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Adicione pelo menos um item à requisição.'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            final dto = CriarRequisicaoRequestDTO(
              almoxarifadoId: _selectedAlmoxarifadoId!,
              departamento: _departamentoController.text.trim(),
              justificativa: _justificativaController.text.trim(),
              itens: _itens,
            );

            final sucesso = await estoqueProvider.criarRequisicao(dto);
            if (context.mounted) {
              if (sucesso) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Requisição criada com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(estoqueProvider.errorMessage ?? 'Erro ao criar requisição.'),
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
