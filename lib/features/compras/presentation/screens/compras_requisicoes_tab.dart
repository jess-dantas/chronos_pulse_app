import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../estoque/data/models/estoque_models.dart';
import '../../../estoque/presentation/providers/estoque_provider.dart';
import '../../data/models/compras_models.dart';
import '../providers/compras_provider.dart';

class ComprasRequisicoesTab extends StatelessWidget {
  const ComprasRequisicoesTab({super.key});

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
                icon: Icons.task_alt,
                label: '${provider.requisicoes.length} requisições',
                cor: Colors.deepPurple,
              ),
              const SizedBox(width: 8),
              _MetricChip(
                icon: Icons.pending_actions,
                label: '${provider.requisicoesEmAberto} em aberto',
                cor: const Color(0xFF1565C0),
              ),
              const SizedBox(width: 8),
              _MetricChip(
                icon: Icons.gavel,
                label: '${provider.requisicoesCotadas} cotadas',
                cor: const Color(0xFF2E7D32),
              ),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.add_task_outlined, size: 18),
                label: const Text('Nova Requisição'),
                style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
                onPressed: () => _exibirDialogNovaRequisicao(context),
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
        Expanded(
          child: provider.isLoading && provider.requisicoes.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => context.read<ComprasProvider>().carregarTudo(),
                  child: provider.requisicoes.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Icon(Icons.task_alt, size: 56, color: Colors.grey),
                            SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Nenhuma requisição de compra encontrada.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: provider.requisicoes.length,
                          itemBuilder: (context, index) {
                            final r = provider.requisicoes[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.deepPurple.shade100,
                                  child: const Icon(
                                    Icons.request_page_outlined,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                title: Text(r.numero),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(r.justificativa,
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(
                                      '${r.solicitanteNome} · ${r.dataRequisicaoFormatada} · '
                                      '${r.itens.length} item(ns)',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _StatusChip(status: r.status),
                                    PopupMenuButton<String>(
                                      tooltip: 'Ações',
                                      onSelected: (acao) {
                                        if (acao == 'detalhes') {
                                          _exibirDetalhes(context, r);
                                        } else if (acao == 'cancelar') {
                                          _cancelarRequisicao(context, r);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'detalhes',
                                          child: ListTile(
                                            leading: Icon(Icons.visibility_outlined),
                                            title: Text('Ver detalhes'),
                                            dense: true,
                                          ),
                                        ),
                                        if (r.cancelavel)
                                          const PopupMenuItem(
                                            value: 'cancelar',
                                            child: ListTile(
                                              leading: Icon(Icons.block),
                                              title: Text('Cancelar'),
                                              dense: true,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () => _exibirDetalhes(context, r),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Future<void> _exibirDetalhes(BuildContext context, RequisicaoCompraModel r) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(r.numero),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LinhaInfo(label: 'Status', valor: r.statusLabel),
                _LinhaInfo(label: 'Solicitante', valor: r.solicitanteNome),
                _LinhaInfo(label: 'Data', valor: r.dataRequisicaoFormatada),
                _LinhaInfo(label: 'Justificativa', valor: r.justificativa),
                if (r.observacoes != null && r.observacoes!.isNotEmpty)
                  _LinhaInfo(label: 'Observações', valor: r.observacoes!),
                const Divider(),
                const Text(
                  'Itens',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...r.itens.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.inventory_2_outlined, size: 20),
                    title: Text(item.materialDescricao),
                    subtitle: Text(
                      'Qtd: ${_formatarQuantidade(item.quantidade)} ${item.materialUnidadeMedida}'
                      '${item.observacao != null && item.observacao!.isNotEmpty ? ' · ${item.observacao}' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelarRequisicao(BuildContext context, RequisicaoCompraModel r) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar requisição'),
        content: Text('Deseja cancelar a requisição ${r.numero}?'),
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
      final ok = await context.read<ComprasProvider>().cancelarRequisicao(r.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Requisição cancelada.' : 'Não foi possível cancelar.')),
        );
      }
    }
  }

  Future<void> _exibirDialogNovaRequisicao(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final solicitanteCpcId = authProvider.usuario?.cpcId;
    if (solicitanteCpcId == null || solicitanteCpcId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário sem identificação para solicitar.')),
      );
      return;
    }

    final comprasProvider = context.read<ComprasProvider>();
    final estoqueProvider = context.read<EstoqueProvider>();

    final form = GlobalKey<FormState>();
    String? justificativa;
    String? observacoes;
    final itens = <_RequisicaoItemEdit>[];

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Nova Requisição de Compra'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Form(
                  key: form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Justificativa*'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Informe a justificativa' : null,
                        onChanged: (v) => justificativa = v,
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
                            'Itens da requisição',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar item'),
                            onPressed: () {
                              setDialogState(() {
                                itens.add(_RequisicaoItemEdit(materiais: estoqueProvider.materiais));
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
                                        onChanged: (v) => item.quantidade =
                                            double.tryParse(v.replaceAll(',', '.')) ?? 0,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        decoration: const InputDecoration(
                                          labelText: 'Observação do item',
                                          isDense: true,
                                        ),
                                        onChanged: (v) => item.observacao = v,
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
                  if (itens.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Adicione ao menos um item à requisição.')),
                    );
                    return;
                  }
                  if (itens.any((i) => i.materialId == null || i.quantidade <= 0)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Preencha material e quantidade de todos os itens.')),
                    );
                    return;
                  }

                  final sucesso = await comprasProvider.criarRequisicao(
                    CadastrarRequisicaoDTO(
                      solicitanteCpcId: solicitanteCpcId,
                      justificativa: justificativa!,
                      observacoes: observacoes,
                      itens: itens
                          .map((i) => RequisicaoItemDTO(
                                materialId: i.materialId!,
                                quantidade: i.quantidade,
                                observacao: i.observacao,
                              ))
                          .toList(),
                    ),
                  );

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(sucesso
                            ? 'Requisição de compra criada.'
                            : comprasProvider.errorMessage ?? 'Falha ao criar requisição.'),
                      ),
                    );
                  }
                },
                child: const Text('Criar requisição'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RequisicaoItemEdit {
  final List<MaterialModel> materiais;
  String? materialId;
  double quantidade;
  String? observacao;

  _RequisicaoItemEdit({required this.materiais})
      : quantidade = 0 {
    materialId = materiais.isNotEmpty ? materiais.first.id : null;
  }
}

String _formatarQuantidade(double quantidade) {
  return NumberFormat('#,##0.###').format(quantidade);
}

class _LinhaInfo extends StatelessWidget {
  final String label;
  final String valor;

  const _LinhaInfo({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color get _cor => switch (status) {
        'EM_ABERTO' => const Color(0xFF1565C0),
        'COTADA' => const Color(0xFF2E7D32),
        'CANCELADA' => Colors.grey[700]!,
        _ => Colors.grey[700]!,
      };

  @override
  Widget build(BuildContext context) {
    final label = status.replaceAll('_', ' ');
    return Chip(
      label: Text(label),
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