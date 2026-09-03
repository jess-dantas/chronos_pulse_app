import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/estoque_models.dart';
import '../providers/estoque_provider.dart';
import 'dialogs/nova_requisicao_dialog.dart';

class EstoqueRequisicoesTab extends StatelessWidget {
  const EstoqueRequisicoesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final estoqueProvider = context.watch<EstoqueProvider>();

    return RefreshIndicator(
      onRefresh: () => estoqueProvider.carregarTudo(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra de Filtros e Criação
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Filtro de Status
                    Row(
                      children: [
                        const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        DropdownButton<String?>(
                          value: estoqueProvider.selectedStatusRequisicao,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Todas')),
                            DropdownMenuItem(value: 'PENDENTE', child: Text('Pendentes')),
                            DropdownMenuItem(value: 'APROVADA', child: Text('Aprovadas')),
                            DropdownMenuItem(value: 'ATENDIDA', child: Text('Atendidas')),
                          ],
                          onChanged: (val) =>
                              estoqueProvider.filtrarRequisicoesPorStatus(val),
                        ),
                      ],
                    ),

                    FilledButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nova Requisição'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const NovaRequisicaoDialog(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lista de Requisições
            if (estoqueProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (estoqueProvider.requisicoes.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhuma requisição encontrada com o filtro selecionado.',
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: estoqueProvider.requisicoes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final req = estoqueProvider.requisicoes[index];
                  return _RequisicaoCard(requisicao: req);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _RequisicaoCard extends StatelessWidget {
  final RequisicaoModel requisicao;

  const _RequisicaoCard({required this.requisicao});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDENTE':
        return Colors.orange;
      case 'APROVADA':
        return Colors.blue;
      case 'ATENDIDA':
        return Colors.green;
      case 'REJEITADA':
      case 'CANCELADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estoqueProvider = context.read<EstoqueProvider>();
    final statusColor = _getStatusColor(requisicao.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.description, color: statusColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Depto: ${requisicao.departamento ?? "Geral"}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Text(
                requisicao.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Almoxarifado: ${requisicao.almoxarifadoNome ?? "-"} | Itens: ${requisicao.itens.length}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (requisicao.justificativa != null && requisicao.justificativa!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      'Justificativa: ${requisicao.justificativa}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                const Text(
                  'Itens Requisitados:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: requisicao.itens.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final item = requisicao.itens[i];
                      return ListTile(
                        dense: true,
                        title: Text(item.materialDescricao ?? 'Item'),
                        subtitle: Text('Solicitado: ${item.quantidadeSolicitada} ${item.unidadeMedida ?? "UN"}'),
                        trailing: Text(
                          'Atendido: ${item.quantidadeAtendida}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: item.quantidadeAtendida > 0 ? Colors.green[700] : Colors.grey[700],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Botões de Ação por Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (requisicao.status == 'PENDENTE') ...[
                      FilledButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Aprovar Requisição'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.blue[700]),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Aprovar Requisição'),
                              content: const Text('Deseja aprovar esta requisição para atendimento?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Não')),
                                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sim, Aprovar')),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await estoqueProvider.aprovarRequisicao(requisicao.id);
                          }
                        },
                      ),
                    ],
                    if (requisicao.status == 'APROVADA') ...[
                      FilledButton.icon(
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('Atender e Baixar Estoque'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.green[700]),
                        onPressed: () async {
                          // Modal de Atendimento com preenchimento da quantidade a ser atendida
                          final itensAtendimento = requisicao.itens.map((item) {
                            return {
                              'materialId': item.materialId,
                              'quantidadeAtendida': item.quantidadeSolicitada,
                            };
                          }).toList();

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Atendimento de Requisição'),
                              content: const Text('Deseja confirmar o atendimento total dos itens e efetuar a baixa correspondente no estoque pelo PMP?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar Atendimento')),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await estoqueProvider.atenderRequisicao(requisicao.id, itensAtendimento);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
