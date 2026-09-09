import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../estoque/data/models/estoque_models.dart';
import '../../../estoque/presentation/providers/estoque_provider.dart';
import '../../data/models/compras_models.dart';
import '../providers/compras_provider.dart';

class ComprasPedidosTab extends StatefulWidget {
  const ComprasPedidosTab({super.key});

  @override
  State<ComprasPedidosTab> createState() => _ComprasPedidosTabState();
}

class _ComprasPedidosTabState extends State<ComprasPedidosTab> {
  static final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComprasProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              _MetricChip(
                icon: Icons.receipt_long,
                label: '${provider.totalPedidos} pedidos',
                cor: Colors.deepPurple,
              ),
              const SizedBox(width: 8),
              _MetricChip(
                icon: Icons.pending_actions,
                label: '${provider.pedidosEmitidos} emitidos',
                cor: const Color(0xFF1565C0),
              ),
              const SizedBox(width: 8),
              _MetricChip(
                icon: Icons.assignment_late,
                label: '${provider.pedidosRecebidosParciais} parciais',
                cor: const Color(0xFFEF6C00),
              ),
            ],
          ),
        ),
        if (provider.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              provider.errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('Novo Pedido de Compra'),
              style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
              onPressed: () => _exibirDialogNovoPedido(context),
            ),
          ),
        ),
        Expanded(
          child: provider.isLoading && provider.pedidos.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => context.read<ComprasProvider>().carregarTudo(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: provider.pedidos.length,
                    itemBuilder: (context, index) {
                      final p = provider.pedidos[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ExpansionTile(
                          leading: const Icon(Icons.receipt_long, color: Colors.deepPurple),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.numero,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              _StatusChip(status: p.status),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.fornecedorNome),
                              if (p.objeto != null && p.objeto!.isNotEmpty) Text(p.objeto!),
                              Text('${p.dataEmissaoFormatada}  •  ${_moeda.format(p.valorTotal)}'),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (p.empenhoNumero != null && p.empenhoNumero!.isNotEmpty)
                                    Text('Empenho: ${p.empenhoNumero}'),
                                  const Divider(height: 16),
                                  ...p.itens.map((item) => ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(item.materialDescricao),
                                        subtitle: Text(
                                          '${item.quantidade.toStringAsFixed(3)} ${item.materialUnidadeMedida} '
                                          '• recebido ${item.quantidadeRecebida.toStringAsFixed(3)}',
                                        ),
                                        trailing: Text(_moeda.format(
                                          item.valorUnitario * item.quantidade,
                                        )),
                                      )),
                                  if (p.cancelavel)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        icon: const Icon(Icons.cancel_outlined),
                                        label: const Text('Cancelar pedido'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red.shade700,
                                        ),
                                        onPressed: () => _confirmarCancelamento(context, p),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _confirmarCancelamento(BuildContext context, PedidoCompraModel p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: Text('Deseja cancelar o pedido ${p.numero}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Não'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      final ok = await context.read<ComprasProvider>().cancelarPedido(p.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Pedido cancelado.' : 'Não foi possível cancelar o pedido.')),
        );
      }
    }
  }

  Future<void> _exibirDialogNovoPedido(BuildContext context) async {
    final comprasProvider = context.read<ComprasProvider>();
    final estoqueProvider = context.read<EstoqueProvider>();

    final form = GlobalKey<FormState>();
    String? fornecedorId = comprasProvider.fornecedores.isNotEmpty
        ? comprasProvider.fornecedores.firstWhere((f) => f.ativo, orElse: () => comprasProvider.fornecedores.first).id
        : null;
    String? objeto;
    String? prazoEntrega;
    String? empenhoNumero;
    String? observacoes;

    final itens = <_PedidoItemEdit>[];

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Novo Pedido de Compra'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Form(
                  key: form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: fornecedorId,
                        decoration: const InputDecoration(labelText: 'Fornecedor'),
                        items: comprasProvider.fornecedores
                            .where((f) => f.ativo)
                            .map((f) => DropdownMenuItem(
                                  value: f.id,
                                  child: Text(f.razaoSocial),
                                ))
                            .toList(),
                        onChanged: (v) => fornecedorId = v,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Objeto'),
                        onChanged: (v) => objeto = v,
                      ),
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Prazo de Entrega',
                          hintText: prazoEntrega == null
                              ? 'Opcional - toque para selecionar'
                              : prazoEntrega!,
                          suffixIcon: const Icon(Icons.event),
                        ),
                        onTap: () async {
                          final data = await showDatePicker(
                            context: dialogContext,
                            initialDate: DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (data != null) {
                            setDialogState(() {
                              prazoEntrega = '${data.year.toString().padLeft(4, '0')}-'
                                  '${data.month.toString().padLeft(2, '0')}-'
                                  '${data.day.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Nº Empenho (opcional)'),
                        onChanged: (v) => empenhoNumero = v,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Observações'),
                        maxLines: 2,
                        onChanged: (v) => observacoes = v,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Itens do pedido',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar item'),
                            onPressed: () {
                              setDialogState(() {
                                itens.add(_PedidoItemEdit(materiais: estoqueProvider.materiais));
                              });
                            },
                          ),
                        ],
                      ),
                      ...itens.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  initialValue: item.materialId,
                                  decoration: const InputDecoration(
                                    labelText: 'Material',
                                    isDense: true,
                                  ),
                                  items: estoqueProvider.materiais
                                      .map((m) => DropdownMenuItem(
                                            value: m.id,
                                            child: Text(
                                              m.descricao,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setDialogState(() => item.materialId = v),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: '0',
                                        keyboardType:
                                            const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          labelText: 'Quantidade',
                                          isDense: true,
                                        ),
                                        onChanged: (v) =>
                                            item.quantidade = double.tryParse(v.replaceAll(',', '.')) ?? 0,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: '0',
                                        keyboardType:
                                            const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          labelText: 'Valor unitário',
                                          isDense: true,
                                        ),
                                        onChanged: (v) =>
                                            item.valorUnitario = double.tryParse(v.replaceAll(',', '.')) ?? 0,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Remover item',
                                      onPressed: () =>
                                          setDialogState(() => itens.removeAt(idx)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  if (fornecedorId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selecione um fornecedor.')),
                    );
                    return;
                  }
                  if (itens.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Adicione ao menos um item ao pedido.')),
                    );
                    return;
                  }
                  if (itens.any((i) => i.materialId == null || i.quantidade <= 0)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preencha material e quantidade de todos os itens.')),
                    );
                    return;
                  }

                  final sucesso = await comprasProvider.criarPedido(
                    CadastrarPedidoCompraDTO(
                      fornecedorId: fornecedorId!,
                      objeto: objeto,
                      prazoEntrega: prazoEntrega,
                      empenhoNumero: empenhoNumero,
                      observacoes: observacoes,
                      itens: itens
                          .map((i) => PedidoCompraItemDTO(
                                materialId: i.materialId!,
                                quantidade: i.quantidade,
                                valorUnitario: i.valorUnitario,
                              ))
                          .toList(),
                    ),
                  );

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(sucesso
                            ? 'Pedido de compra criado.'
                            : comprasProvider.errorMessage ?? 'Falha ao criar pedido.'),
                      ),
                    );
                  }
                },
                child: const Text('Criar pedido'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PedidoItemEdit {
  final List<MaterialModel> materiais;
  String? materialId;
  double quantidade;
  double valorUnitario;

  _PedidoItemEdit({required this.materiais})
      : quantidade = 0,
        valorUnitario = 0 {
    materialId = materiais.isNotEmpty ? materiais.first.id : null;
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color get _cor => switch (status) {
        'EMITIDO' => const Color(0xFF1565C0),
        'RECEBIDO_PARCIAL' => const Color(0xFFEF6C00),
        'RECEBIDO' => const Color(0xFF2E7D32),
        'CANCELADO' => Colors.grey[700]!,
        _ => Colors.grey[700]!,
      };

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.replaceAll('_', ' ')),
      labelStyle: TextStyle(fontSize: 11, color: _cor),
      backgroundColor: _cor.withValues(alpha: 0.10),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color cor;

  const _MetricChip({required this.icon, required this.label, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: cor),
      label: Text(label),
      labelStyle: TextStyle(fontSize: 12, color: cor),
      backgroundColor: cor.withValues(alpha: 0.08),
    );
  }
}