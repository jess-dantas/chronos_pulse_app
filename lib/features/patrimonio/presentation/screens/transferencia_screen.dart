import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/patrimonio_models.dart';
import '../providers/patrimonio_provider.dart';
import '../providers/transferencia_provider.dart';

class TransferenciaScreen extends StatefulWidget {
  const TransferenciaScreen({super.key});

  @override
  State<TransferenciaScreen> createState() => _TransferenciaScreenState();
}

class _TransferenciaScreenState extends State<TransferenciaScreen> {
  Future<void> _abrirNova() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _NovaTransferenciaDialog(),
    );
    if (ok == true && mounted) {
      _mostrarMensagem('Transferência solicitada.');
    }
  }

  Future<void> _confirmar(TransferenciaModel t) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Transferência'),
        content: const Text(
          'Ao confirmar, a localização e o responsável do bem serão atualizados. '
          'Confirmar a transferência?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    final ok = await context.read<TransferenciaProvider>().confirmar(t.id);
    if (mounted) {
      _mostrarMensagem(ok ? 'Transferência confirmada.' : 'Erro ao confirmar transferência.', vermelho: !ok);
    }
  }

  Future<void> _cancelar(TransferenciaModel t) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Transferência'),
        content: const Text('Cancelar esta solicitação de transferência?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    final ok = await context.read<TransferenciaProvider>().cancelar(t.id);
    if (mounted) {
      _mostrarMensagem(ok ? 'Transferência cancelada.' : 'Erro ao cancelar transferência.', vermelho: !ok);
    }
  }

  void _detalhes(TransferenciaModel t) {
    showDialog(context: context, builder: (_) => _DetalheTransferenciaDialog(t: t));
  }

  void _mostrarMensagem(String mensagem, {bool vermelho = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: vermelho ? Colors.redAccent : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransferenciaProvider>();
    final bens = context.watch<PatrimonioProvider>().bens;

    PatrimonioModel? bemDe(String id) => bens.where((b) => b.id == id).firstOrNull;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              const Icon(Icons.swap_horiz, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Text(
                'Transferências',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar',
                onPressed: () => context.read<TransferenciaProvider>().carregarTransferencias(),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nova Transferência'),
                onPressed: _abrirNova,
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading && provider.transferencias.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : provider.errorMessage != null && provider.transferencias.isEmpty
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
                              onPressed: () => context.read<TransferenciaProvider>().carregarTransferencias(),
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : provider.transferencias.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('Nenhuma transferência solicitada.'),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.transferencias.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final t = provider.transferencias[index];
                            return _cardTransferencia(t, bemDe(t.patrimonioId));
                          },
                        ),
        ),
      ],
    );
  }

  Widget _cardTransferencia(TransferenciaModel t, PatrimonioModel? bem) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _detalhes(t),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.swap_horiz, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bem?.descricao ?? 'Bem (id: ${t.patrimonioId})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _statusChip(t.status),
                ],
              ),
              if (bem?.tombamento != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Tombamento: ${bem!.tombamento}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${t.localizacaoOrigem ?? '—'}  ➜  ${t.localizacaoDestino}',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
              if (t.solicitadoPor != null || t.dataSolicitacao != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Solicitado por ${t.solicitadoPor ?? '—'}${t.dataSolicitacao != null ? ' em ${t.dataSolicitacao!.substring(0, 10)}' : ''}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
              if (t.status == 'SOLICITADA') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Confirmar'),
                      onPressed: () => _confirmar(t),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _cancelar(t),
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final (cor, rotulo) = switch (status) {
      'SOLICITADA' => (Colors.orangeAccent, 'SOLICITADA'),
      'CONFIRMADA' => (Colors.teal, 'CONFIRMADA'),
      'CANCELADA' => (Colors.redAccent, 'CANCELADA'),
      _ => (Colors.grey, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        rotulo,
        style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}

class _NovaTransferenciaDialog extends StatefulWidget {
  const _NovaTransferenciaDialog();

  @override
  State<_NovaTransferenciaDialog> createState() => _NovaTransferenciaDialogState();
}

class _NovaTransferenciaDialogState extends State<_NovaTransferenciaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _origemCtrl = TextEditingController();
  final _destinoCtrl = TextEditingController();
  final _responsavelOrigemCtrl = TextEditingController();
  final _responsavelDestinoCtrl = TextEditingController();
  final _dataPrevistaCtrl = TextEditingController();
  final _justificativaCtrl = TextEditingController();

  String? _bemId;
  bool _salvando = false;

  @override
  void dispose() {
    _origemCtrl.dispose();
    _destinoCtrl.dispose();
    _responsavelOrigemCtrl.dispose();
    _responsavelDestinoCtrl.dispose();
    _dataPrevistaCtrl.dispose();
    _justificativaCtrl.dispose();
    super.dispose();
  }

  void _selecionarBem(PatrimonioModel? bem) {
    setState(() {
      _bemId = bem?.id;
      _origemCtrl.text = bem?.localizacao ?? '';
      _responsavelOrigemCtrl.text = bem?.responsavelNome ?? '';
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o bem a transferir.')),
      );
      return;
    }
    setState(() => _salvando = true);
    final ok = await context.read<TransferenciaProvider>().solicitar(
          patrimonioId: _bemId!,
          localizacaoDestino: _destinoCtrl.text,
          localizacaoOrigem: _origemCtrl.text,
          responsavelOrigem: _responsavelOrigemCtrl.text,
          responsavelDestino: _responsavelDestinoCtrl.text,
          dataPrevista: _dataPrevistaCtrl.text,
          justificativa: _justificativaCtrl.text,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<TransferenciaProvider>().errorMessage ?? 'Erro ao solicitar transferência.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bens = context.read<PatrimonioProvider>().bens.where((b) => b.ativo).toList();
    final bemSelecionado = bens.where((b) => b.id == _bemId).firstOrNull;

    return AlertDialog(
      title: const Text('Nova Transferência'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _bemId,
                  decoration: const InputDecoration(
                    labelText: 'Bem Patrimonial *',
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  items: bens
                      .map((b) => DropdownMenuItem(
                            value: b.id,
                            child: Text('${b.tombamento ?? ''} — ${b.descricao}'),
                          ))
                      .toList(),
                  onChanged: (v) => _selecionarBem(bens.where((b) => b.id == v).firstOrNull),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _origemCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Localização de Origem',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _destinoCtrl,
                        decoration: const InputDecoration(labelText: 'Localização de Destino *'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o destino' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _responsavelOrigemCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Responsável Origem',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _responsavelDestinoCtrl,
                        decoration: const InputDecoration(labelText: 'Responsável Destino'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dataPrevistaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Data Prevista (AAAA-MM-DD)',
                    prefixIcon: Icon(Icons.event_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _justificativaCtrl,
                  decoration: const InputDecoration(labelText: 'Justificativa', alignLabelWithHint: true),
                  maxLines: 2,
                ),
                if (bemSelecionado != null && bemSelecionado.valorAtual != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Valor atual: R\$ ${bemSelecionado.valorAtual}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _salvando ? null : () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: _salvando ? null : _salvar,
          icon: _salvando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.swap_horiz),
          label: Text(_salvando ? 'Solicitando...' : 'Solicitar'),
        ),
      ],
    );
  }
}

class _DetalheTransferenciaDialog extends StatelessWidget {
  final TransferenciaModel t;

  const _DetalheTransferenciaDialog({required this.t});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transferência'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _linha('Status', t.status),
              _linha('ID do Bem', t.patrimonioId),
              _linha('Origem', t.localizacaoOrigem ?? '—'),
              _linha('Destino', t.localizacaoDestino),
              _linha('Responsável Origem', t.responsavelOrigem ?? '—'),
              _linha('Responsável Destino', t.responsavelDestino ?? '—'),
              _linha('Solicitado por', t.solicitadoPor ?? '—'),
              _linha('Data Solicitação', t.dataSolicitacao ?? '—'),
              _linha('Data Prevista', t.dataPrevista ?? '—'),
              _linha('Data Efetivação', t.dataEfetivacao ?? '—'),
              _linha('Aprovado por', t.aprovadoPor ?? '—'),
              _linha('Justificativa', t.justificativa ?? '—'),
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
            width: 150,
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