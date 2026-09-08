import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/patrimonio_models.dart';
import '../../providers/desfazimento_provider.dart';

class NovoDesfazimentoDialog extends StatefulWidget {
  final List<PatrimonioModel> bens;

  const NovoDesfazimentoDialog({super.key, required this.bens});

  @override
  State<NovoDesfazimentoDialog> createState() => _NovoDesfazimentoDialogState();
}

class _NovoDesfazimentoDialogState extends State<NovoDesfazimentoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _justificativaCtrl = TextEditingController();
  final _responsavelCtrl = TextEditingController();
  final _processoCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();

  String? _bemId;
  String _estadoBem = 'OCIOSO';
  String _tipoDesfazimento = 'VENDA';
  bool _salvando = false;

  final List<_MembroDraft> _membros = [];

  static const _estados = ['OCIOSO', 'RECUPERAVEL', 'ANTIECONOMICO', 'IRRECUPERAVEL'];
  static const _tipos = ['DOACAO', 'TROCA', 'VENDA', 'CEDENCIA', 'RECICLAGEM', 'OUTROS'];

  @override
  void dispose() {
    _justificativaCtrl.dispose();
    _responsavelCtrl.dispose();
    _processoCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bemId == null) {
      _mostrarMensagem('Selecione o bem patrimonial.', vermelho: true);
      return;
    }
    setState(() => _salvando = true);

    final membros = _membros
        .where((m) => m.nome.text.trim().isNotEmpty)
        .map((m) => <String, dynamic>{
              'nome': m.nome.text.trim(),
              if (m.cargo.text.trim().isNotEmpty) 'cargo': m.cargo.text.trim(),
              'relator': m.relator,
              if (m.parecer.text.trim().isNotEmpty) 'parecer': m.parecer.text.trim(),
            })
        .toList();

    final ok = await context.read<DesfazimentoProvider>().criarDesfazimento(
          patrimonioId: _bemId!,
          estadoBem: _estadoBem,
          tipoDesfazimento: _tipoDesfazimento,
          justificativa: _justificativaCtrl.text.trim(),
          responsavelSolicitacao: _responsavelCtrl.text.trim(),
          processoNumero: _processoCtrl.text.trim(),
          observacoes: _observacoesCtrl.text.trim(),
          membrosComissao: membros,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _salvando = false);
      _mostrarMensagem(
        context.read<DesfazimentoProvider>().errorMessage ?? 'Erro ao solicitar desfazimento.',
        vermelho: true,
      );
    }
  }

  void _mostrarMensagem(String mensagem, {bool vermelho = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: vermelho ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Solicitar Desfazimento'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.bens.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Cadastre um bem patrimonial antes de solicitar o desfazimento.',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _bemId,
                    decoration: const InputDecoration(
                      labelText: 'Bem Patrimonial *',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    items: widget.bens
                        .map((b) => DropdownMenuItem(
                              value: b.id,
                              child: Text(
                                '${b.tombamento ?? 'S/N'} — ${b.descricao.length > 60 ? '${b.descricao.substring(0, 60)}...' : b.descricao}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: widget.bens.isEmpty
                        ? null
                        : (v) => setState(() => _bemId = v),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _estadoBem,
                        decoration: const InputDecoration(labelText: 'Estado do Bem *'),
                        items: _estados
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _estadoBem = v ?? 'OCIOSO'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _tipoDesfazimento,
                        decoration: const InputDecoration(labelText: 'Tipo *'),
                        items: _tipos
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _tipoDesfazimento = v ?? 'VENDA'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _responsavelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Responsável pela Solicitação *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _justificativaCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Justificativa *',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a justificativa' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _processoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nº do Processo',
                          prefixIcon: Icon(Icons.tag),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _observacoesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Observações',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Comissão de Avaliação',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setState(() => _membros.add(_MembroDraft())),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Adicionar membro'),
                    ),
                  ],
                ),
                if (_membros.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Nenhum membro informado. A comissão pode ser adicionada posteriormente no parecer.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ..._membros.asMap().entries.map((entry) {
                  final i = entry.key;
                  final m = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: m.nome,
                            decoration: const InputDecoration(
                              labelText: 'Nome do membro',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: m.cargo,
                            decoration: const InputDecoration(
                              labelText: 'Cargo',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: m.parecer,
                            decoration: const InputDecoration(
                              labelText: 'Parecer',
                              isDense: true,
                            ),
                          ),
                        ),
                        Checkbox(
                          value: m.relator,
                          onChanged: (v) => setState(() => m.relator = v ?? false),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => setState(() => _membros.removeAt(i)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _salvando ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _salvando ? null : _salvar,
                      icon: _salvando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, size: 18),
                      label: const Text('Solicitar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MembroDraft {
  final nome = TextEditingController();
  final cargo = TextEditingController();
  final parecer = TextEditingController();
  bool relator = false;
}