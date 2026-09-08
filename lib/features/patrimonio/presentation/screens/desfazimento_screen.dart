import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/patrimonio_models.dart';
import '../providers/desfazimento_provider.dart';
import '../providers/patrimonio_provider.dart';
import 'dialogs/novo_desfazimento_dialog.dart';

class DesfazimentoScreen extends StatefulWidget {
  const DesfazimentoScreen({super.key});

  @override
  State<DesfazimentoScreen> createState() => _DesfazimentoScreenState();
}

class _DesfazimentoScreenState extends State<DesfazimentoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DesfazimentoProvider>().carregarSolicitacoes();
      context.read<PatrimonioProvider>().carregarBens();
    });
  }

  Future<void> _abrirNovaSolicitacao() async {
    final bens = context.read<PatrimonioProvider>().bens;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => NovoDesfazimentoDialog(bens: bens),
    );
    if (ok == true && mounted) {
      context.read<DesfazimentoProvider>().carregarSolicitacoes();
    }
  }

  Future<void> _aprovar(DesfazimentoModel d) async {
    final parecerCtrl = TextEditingController(text: d.parecerComissao ?? '');
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aprovar Desfazimento'),
        content: TextField(
          controller: parecerCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Parecer da Comissão',
            hintText: 'Parecer favorável ao desfazimento...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aprovar e Baixar')),
        ],
      ),
    );
    parecerCtrl.dispose();
    if (confirmar != true || !mounted) return;
    final ok = await context
        .read<DesfazimentoProvider>()
        .aprovar(d.id, parecerComissao: parecerCtrl.text.trim());
    if (!mounted) return;
    _mostrarMensagem(ok ? 'Desfazimento aprovado e bem baixado.' : 'Erro ao aprovar desfazimento.',
        vermelho: !ok);
  }

  Future<void> _cancelar(DesfazimentoModel d) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Solicitação'),
        content: const Text('Deseja cancelar esta solicitação de desfazimento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Não')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancelar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    final ok = await context.read<DesfazimentoProvider>().cancelar(d.id);
    if (!mounted) return;
    _mostrarMensagem(ok ? 'Solicitação cancelada.' : 'Erro ao cancelar.', vermelho: !ok);
  }

  void _detalhes(DesfazimentoModel d) {
    showDialog(context: context, builder: (_) => _DetalheDesfazimentoDialog(d: d));
  }

  void _mostrarMensagem(String mensagem, {bool vermelho = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: vermelho ? Colors.redAccent : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DesfazimentoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.remove_circle_outline, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Desfazimento de Bens'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: () => context.read<DesfazimentoProvider>().carregarSolicitacoes(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovaSolicitacao,
        icon: const Icon(Icons.add),
        label: const Text('Nova Solicitação'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          provider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () =>
                              context.read<DesfazimentoProvider>().carregarSolicitacoes(),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : provider.solicitacoes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.remove_circle_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Nenhuma solicitação de desfazimento.'),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          provider.solicitacoes.length + (provider.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index >= provider.solicitacoes.length) {
                          return Center(
                            child: OutlinedButton.icon(
                              onPressed: provider.carregandoMais
                                  ? null
                                  : () => context
                                      .read<DesfazimentoProvider>()
                                      .carregarMaisSolicitacoes(),
                              icon: provider.carregandoMais
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.expand_more),
                              label: const Text('Carregar mais'),
                            ),
                          );
                        }
                        final d = provider.solicitacoes[index];
                        return _card(d);
                      },
                    ),
    );
  }

  Widget _card(DesfazimentoModel d) {
    final (cor, rotulo) = switch (d.status) {
      'APROVADO' => (Colors.green, d.aprovado == true ? 'APROVADO' : 'BAIXADO'),
      'CANCELADO' => (Colors.red, 'CANCELADO'),
      _ => (Colors.orange, 'EM ANÁLISE'),
    };

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _detalhes(d),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.patrimonioDescricao ?? 'Bem patrimonial',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tombamento: ${d.tombamento ?? '—'} | ${d.tipoDesfazimento} | Estado: ${d.estadoBem}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Solicitante: ${d.responsavelSolicitacao ?? '—'}'
                      '${d.processoNumero != null ? ' | Processo: ${d.processoNumero}' : ''}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rotulo,
                      style: TextStyle(
                        color: cor.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (d.status == 'EM_ANALISE') ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                          tooltip: 'Aprovar',
                          onPressed: () => _aprovar(d),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                          tooltip: 'Cancelar',
                          onPressed: () => _cancelar(d),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalheDesfazimentoDialog extends StatelessWidget {
  final DesfazimentoModel d;

  const _DetalheDesfazimentoDialog({required this.d});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalhes do Desfazimento'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _linha('Bem', d.patrimonioDescricao ?? '—'),
              _linha('Tombamento', d.tombamento ?? '—'),
              _linha('Estado do Bem', d.estadoBem),
              _linha('Tipo', d.tipoDesfazimento),
              _linha('Justificativa', d.justificativa ?? '—'),
              _linha('Solicitante', d.responsavelSolicitacao ?? '—'),
              _linha('Solicitação em', d.dataSolicitacao ?? '—'),
              _linha('Processo', d.processoNumero ?? '—'),
              _linha('Status', d.status),
              if (d.parecerComissao != null) _linha('Parecer da Comissão', d.parecerComissao!),
              if (d.dataAprovacao != null) _linha('Aprovado em', d.dataAprovacao!),
              if (d.dataBaixa != null) _linha('Baixa em', d.dataBaixa!),
              const Divider(height: 24),
              Text(
                'Comissão (${d.comissao.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (d.comissao.isEmpty)
                const Text('Nenhum membro registrado.', style: TextStyle(color: Colors.grey))
              else
                ...d.comissao.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${m.nome}'
                        '${m.cargo != null ? ' (${m.cargo})' : ''}'
                        '${m.relator ? ' — relator' : ''}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
      ],
    );
  }

  Widget _linha(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              rotulo,
              style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}