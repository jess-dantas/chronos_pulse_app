import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/protocolo_provider.dart';

class NovoProtocoloDialog extends StatefulWidget {
  const NovoProtocoloDialog({super.key});

  @override
  State<NovoProtocoloDialog> createState() => _NovoProtocoloDialogState();
}

class _NovoProtocoloDialogState extends State<NovoProtocoloDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numeroCtrl = TextEditingController();
  final _assuntoCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _remetenteCtrl = TextEditingController();
  final _destinatarioCtrl = TextEditingController();
  final _responsavelCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();

  String _tipo = 'GERAL';
  bool _salvando = false;

  static const _tipos = [
    'GERAL',
    'OFICIO',
    'REQUERIMENTO',
    'ADMINISTRATIVO',
    'CONTRATO',
    'FISCAL',
    'LICITACAO',
    'RH',
    'LEGAL',
  ];

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _assuntoCtrl.dispose();
    _descricaoCtrl.dispose();
    _remetenteCtrl.dispose();
    _destinatarioCtrl.dispose();
    _responsavelCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final ok = await context.read<ProtocoloProvider>().criarProtocolo(
          numeroProtocolo: _numeroCtrl.text,
          tipo: _tipo,
          assunto: _assuntoCtrl.text,
          descricao: _descricaoCtrl.text,
          remetente: _remetenteCtrl.text,
          destinatario: _destinatarioCtrl.text,
          responsavel: _responsavelCtrl.text,
          observacoes: _observacoesCtrl.text,
        );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<ProtocoloProvider>().errorMessage ?? 'Erro ao salvar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Protocolo'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _numeroCtrl,
                  decoration: const InputDecoration(labelText: 'Número do protocolo *', prefixIcon: Icon(Icons.tag)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o número' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _assuntoCtrl,
                  decoration: const InputDecoration(labelText: 'Assunto *', prefixIcon: Icon(Icons.subject)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o assunto' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _tipo,
                  decoration: const InputDecoration(labelText: 'Tipo *'),
                  items: _tipos.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _tipo = v ?? 'GERAL'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descricaoCtrl,
                  decoration: const InputDecoration(labelText: 'Descrição', alignLabelWithHint: true),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _remetenteCtrl,
                        decoration: const InputDecoration(labelText: 'Remetente'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _destinatarioCtrl,
                        decoration: const InputDecoration(labelText: 'Destinatário'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _responsavelCtrl,
                  decoration: const InputDecoration(labelText: 'Responsável', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observacoesCtrl,
                  decoration: const InputDecoration(labelText: 'Observações', alignLabelWithHint: true),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _salvando ? null : _salvar,
          icon: _salvando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: Text(_salvando ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}