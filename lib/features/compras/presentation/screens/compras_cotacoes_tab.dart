import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/compras_models.dart';
import '../providers/compras_provider.dart';

class ComprasCotacoesTab extends StatelessWidget {
  const ComprasCotacoesTab({super.key});

  static final NumberFormat _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

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
                icon: Icons.handshake_outlined,
                label: '${provider.cotacoes.length} cotações',
                cor: Colors.deepPurple,
              ),
              const SizedBox(width: 8),
              _MetricChip(
                icon: Icons.pending_actions,
                label: '${provider.cotacoesEmAndamento} em andamento',
                cor: const Color(0xFF1565C0),
              ),
              const SizedBox(width: 8),
              _MetricChip(
                icon: Icons.check_circle_outline,
                label: '${provider.cotacoesConcluidas} concluídas',
                cor: const Color(0xFF2E7D32),
              ),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.add_chart_outlined, size: 18),
                label: const Text('Nova Cotação'),
                style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
                onPressed: () => _exibirDialogNovaCotacao(context),
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
          child: provider.isLoading && provider.cotacoes.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => context.read<ComprasProvider>().carregarTudo(),
                  child: provider.cotacoes.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Icon(Icons.handshake_outlined, size: 56, color: Colors.grey),
                            SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Nenhuma cotação encontrada.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: provider.cotacoes.length,
                          itemBuilder: (context, index) {
                            final c = provider.cotacoes[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.deepPurple.shade100,
                                  child: const Icon(
                                    Icons.handshake_outlined,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                title: Text('${c.numero} · ${c.requisicaoNumero}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      '${c.fornecedores.length} fornecedor(es) convidado(s) · '
                                      '${c.propostas.length} proposta(s)',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                    if (c.dataLimite != null && c.dataLimite!.isNotEmpty)
                                      Text(
                                        'Data limite: ${c.dataLimiteFormatada}',
                                        style:
                                            TextStyle(fontSize: 12, color: Colors.grey[700]),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _StatusChip(cotacao: c),
                                    PopupMenuButton<String>(
                                      tooltip: 'Ações',
                                      onSelected: (acao) {
                                        if (acao == 'detalhes') {
                                          _exibirDetalhes(context, c);
                                        } else if (acao == 'propostas') {
                                          _registrarPropostas(context, c);
                                        } else if (acao == 'concluir') {
                                          _concluirCotacao(context, c);
                                        } else if (acao == 'cancelar') {
                                          _cancelarCotacao(context, c);
                                        } else if (acao == 'pedidos') {
                                          _gerarPedidos(context, c);
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
                                        if (c.emAndamento)
                                          const PopupMenuItem(
                                            value: 'propostas',
                                            child: ListTile(
                                              leading: Icon(Icons.edit_note),
                                              title: Text('Registrar propostas'),
                                              dense: true,
                                            ),
                                          ),
                                        if (c.emAndamento)
                                          const PopupMenuItem(
                                            value: 'concluir',
                                            child: ListTile(
                                              leading: Icon(Icons.how_to_vote_outlined),
                                              title: Text('Concluir'),
                                              dense: true,
                                            ),
                                          ),
                                        if (c.emAndamento)
                                          const PopupMenuItem(
                                            value: 'cancelar',
                                            child: ListTile(
                                              leading: Icon(Icons.block),
                                              title: Text('Cancelar'),
                                              dense: true,
                                            ),
                                          ),
                                        if (c.podeGerarPedidos)
                                          const PopupMenuItem(
                                            value: 'pedidos',
                                            child: ListTile(
                                              leading: Icon(Icons.receipt_long_outlined),
                                              title: Text('Gerar pedidos'),
                                              dense: true,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () => _exibirDetalhes(context, c),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  void _exibirDetalhes(BuildContext context, CotacaoCompraModel c) {
    final vencedores = c.propostas.where((p) => p.vencedor == true).toList();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(c.numero),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LinhaInfo(label: 'Status', valor: c.statusLabel),
                _LinhaInfo(label: 'Requisição', valor: '${c.requisicaoNumero} · ${c.requisicaoId}'),
                if (c.dataLimite != null && c.dataLimite!.isNotEmpty)
                  _LinhaInfo(label: 'Data limite', valor: c.dataLimiteFormatada),
                if (c.observacoes != null && c.observacoes!.isNotEmpty)
                  _LinhaInfo(label: 'Observações', valor: c.observacoes!),
                _LinhaInfo(
                  label: 'Pedido gerado',
                  valor: c.pedidoGerado ? 'Sim' : 'Não',
                ),
                const Divider(),
                Text(
                  'Fornecedores convidados',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
                ...c.fornecedores.map(
                  (f) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.storefront_outlined, size: 20),
                    title: Text(f.razaoSocial),
                  ),
                ),
                const Divider(),
                const Text(
                  'Propostas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (c.propostas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Nenhuma proposta registrada.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  )
                else
                  ...c.propostas.map(
                    (p) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(
                        p.vencedor == true ? Icons.emoji_events : Icons.edit_note,
                        size: 20,
                        color: p.vencedor == true ? const Color(0xFFEF6C00) : Colors.grey[700],
                      ),
                      title: Text(p.materialDescricao),
                      subtitle: Text(
                        '${p.fornecedorNome} · ${_moeda.format(p.valorUnitario)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      trailing: p.vencedor == true
                          ? const Text(
                              'Vencedor',
                              style: TextStyle(fontSize: 12, color: Color(0xFFEF6C00)),
                            )
                          : null,
                    ),
                  ),
                if (vencedores.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Resultado',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...
                      vencedores.map(
                        (p) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text('${p.fornecedorNome} · ${p.materialDescricao}'),
                          trailing: Text(_moeda.format(p.valorUnitario)),
                        ),
                      ),
                ],
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

  Future<void> _exibirDialogNovaCotacao(BuildContext context) async {
    final provider = context.read<ComprasProvider>();
    final requisicoesCotaveis = provider.requisicoesCotaveis
        .where((r) => provider.cotacaoPorRequisicao(r.id) == null)
        .toList();
    final fornecedoresAtivos = provider.fornecedores.where((f) => f.ativo).toList();

    if (requisicoesCotaveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há requisições em aberto para cotar.')),
      );
      return;
    }
    if (fornecedoresAtivos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre ao menos um fornecedor ativo primeiro.')),
      );
      return;
    }

    final form = GlobalKey<FormState>();
    String? requisicaoId = requisicoesCotaveis.first.id;
    final convidados = <String>{};
    String? dataLimite;
    String? observacoes;

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Nova Cotação'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Form(
                  key: form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: requisicaoId,
                        decoration: const InputDecoration(labelText: 'Requisição'),
                        items: requisicoesCotaveis
                            .map((r) => DropdownMenuItem(
                                  value: r.id,
                                  child: Text(r.numero),
                                ))
                            .toList(),
                        onChanged: (v) => requisicaoId = v,
                      ),
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Data limite',
                          hintText: dataLimite == null
                              ? 'Opcional - toque para selecionar'
                              : dataLimite!,
                          suffixIcon: const Icon(Icons.event),
                        ),
                        onTap: () async {
                          final data = await showDatePicker(
                            context: dialogContext,
                            initialDate: DateTime.now().add(const Duration(days: 15)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (data != null) {
                            setDialogState(() {
                              dataLimite = '${data.year.toString().padLeft(4, '0')}-'
                                  '${data.month.toString().padLeft(2, '0')}-'
                                  '${data.day.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Observações'),
                        maxLines: 2,
                        onChanged: (v) => observacoes = v,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Fornecedores convidados*',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                        ),
                      ),
                      SizedBox(
                        height: 220,
                        child: ListView(
                          shrinkWrap: true,
                          children: fornecedoresAtivos.map((f) {
                            return CheckboxListTile(
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(f.razaoSocial,
                                  overflow: TextOverflow.ellipsis),
                              value: convidados.contains(f.id),
                              onChanged: (marcado) {
                                setDialogState(() {
                                  if (marcado == true) {
                                    convidados.add(f.id);
                                  } else {
                                    convidados.remove(f.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
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
                  if (requisicaoId == null) return;
                  if (convidados.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Selecione ao menos um fornecedor convidado.')),
                    );
                    return;
                  }
                  final sucesso = await provider.criarCotacao(
                    CadastrarCotacaoDTO(
                      requisicaoId: requisicaoId!,
                      fornecedoresIds: convidados.toList(),
                      dataLimite: dataLimite,
                      observacoes: observacoes,
                    ),
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(sucesso
                            ? 'Cotação criada.'
                            : provider.errorMessage ?? 'Falha ao criar cotação.'),
                      ),
                    );
                  }
                },
                child: const Text('Criar cotação'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _registrarPropostas(BuildContext context, CotacaoCompraModel c) async {
    final provider = context.read<ComprasProvider>();
    RequisicaoCompraModel? requisicao;
    for (final r in provider.requisicoes) {
      if (r.id == c.requisicaoId) {
        requisicao = r;
        break;
      }
    }
    if (requisicao == null || c.fornecedores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados insuficientes para registrar propostas.')),
      );
      return;
    }

    final req = requisicao;
    final form = GlobalKey<FormState>();
    String? fornecedorId = c.fornecedores.first.fornecedorId;
    final valores = <String, Map<String, TextEditingController>>{};
    for (final f in c.fornecedores) {
      final porMaterial = <String, TextEditingController>{};
      for (final rItem in req.itens) {
        final existente = c.propostas.where((p) =>
            p.fornecedorId == f.fornecedorId && p.materialId == rItem.materialId);
        porMaterial[rItem.materialId] = TextEditingController(
          text: existente.isNotEmpty
              ? existente.first.valorUnitario.toStringAsFixed(2).replaceAll('.', ',')
              : '',
        );
      }
      valores[f.fornecedorId] = porMaterial;
    }

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
        return AlertDialog(
            title: Text('Propostas · ${c.numero}'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Form(
                  key: form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: fornecedorId,
                        decoration: const InputDecoration(labelText: 'Fornecedor'),
                        items: c.fornecedores
                            .map((f) => DropdownMenuItem(
                                  value: f.fornecedorId,
                                  child: Text(f.razaoSocial),
                                ))
                            .toList(),
                        onChanged: (v) => setDialogState(() => fornecedorId = v),
                      ),
                      const SizedBox(height: 8),
                      Text('Itens da requisição ${req.numero}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                      ...req.itens.map((rItem) {
                        final controller = valores[fornecedorId]?[rItem.materialId];
                        return Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${rItem.materialDescricao} (${rItem.materialUnidadeMedida})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 160,
                              child: TextFormField(
                                controller: controller,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Valor unitário (R\$)',
                                  isDense: true,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe o valor';
                                  }
                                  final valor =
                                      double.tryParse(v.replaceAll(',', '.'));
                                  if (valor == null || valor < 0) {
                                    return 'Valor inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
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
                  if (fornecedorId == null) return;
                  final itensProposta = <PropostaItemDTO>[];
for (final rItem in req.itens) {
                    final controller = valores[fornecedorId]![rItem.materialId]!;
                    itensProposta.add(PropostaItemDTO(
                      materialId: rItem.materialId,
                      valorUnitario: double.parse(controller.text.replaceAll(',', '.')),
                    ));
                  }
                  final sucesso = await provider.registrarPropostas(
                    c.id,
                    RegistrarPropostasDTO(
                      fornecedorId: fornecedorId!,
                      itens: itensProposta,
                    ),
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(sucesso
                            ? 'Propostas registradas.'
                            : provider.errorMessage ?? 'Falha ao registrar propostas.'),
                      ),
                    );
                  }
                },
                child: const Text('Salvar propostas'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _concluirCotacao(BuildContext context, CotacaoCompraModel c) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Concluir cotação'),
        content: Text(
            'Concluir a cotação ${c.numero}? Os vencedores serão definidos pelo menor '
            'valor por item.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Não'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      final ok = await context.read<ComprasProvider>().concluirCotacao(c.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Cotação concluída.' : 'Falha ao concluir cotação.')),
        );
      }
    }
  }

  Future<void> _cancelarCotacao(BuildContext context, CotacaoCompraModel c) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar cotação'),
        content: Text('Deseja cancelar a cotação ${c.numero}?'),
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
      final ok = await context.read<ComprasProvider>().cancelarCotacao(c.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Cotação cancelada.' : 'Falha ao cancelar cotação.')),
        );
      }
    }
  }

  Future<void> _gerarPedidos(BuildContext context, CotacaoCompraModel c) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gerar pedidos'),
        content: Text(
            'Gerar pedidos de compra a partir da cotação ${c.numero}? Será criado um '
            'pedido por fornecedor vencedor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Não'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Gerar pedidos'),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      final ok = await context.read<ComprasProvider>().gerarPedidosCotacao(c.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                ok ? 'Pedidos gerados a partir da cotação.' : 'Falha ao gerar pedidos.'),
          ),
        );
      }
    }
  }
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
            width: 130,
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
  final CotacaoCompraModel cotacao;

  const _StatusChip({required this.cotacao});

  Color get _cor => switch (cotacao.status) {
        'EM_ANDAMENTO' => const Color(0xFF1565C0),
        'CONCLUIDA' => const Color(0xFF2E7D32),
        'CANCELADA' => Colors.grey[700]!,
        _ => Colors.grey[700]!,
      };

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(cotacao.statusLabel),
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