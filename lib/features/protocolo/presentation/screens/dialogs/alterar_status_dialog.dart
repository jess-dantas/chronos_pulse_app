import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/protocolo_models.dart';
import '../../providers/protocolo_provider.dart';

class AlterarStatusDialog extends StatefulWidget {
  const AlterarStatusDialog({super.key, required this.protocolo});

  final ProtocoloModel protocolo;

  @override
  State<AlterarStatusDialog> createState() => _AlterarStatusDialogState();
}

class _AlterarStatusDialogState extends State<AlterarStatusDialog> {
  String? _novoStatus;
  final _responsavelCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();
  bool _salvando = false;

  static const _statusList = ['RECEBIDO', 'TRIAGEM', 'EM_TRAMITACAO', 'ARQUIVADO', 'CANCELADO'];

  @override
  void dispose() {
    _responsavelCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final status = _novoStatus;
    if (status == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione o novo status.')));
      return;
    }
    setState(() => _salvando = true);

    final ok = await context.read<ProtocoloProvider>().atualizarStatus(
          widget.protocolo.id,
          status,
          responsavel: _responsavelCtrl.text,
          observacoes: _observacoesCtrl.text,
        );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<ProtocoloProvider>().errorMessage ?? 'Erro ao atualizar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Alterar status — ${widget.protocolo.numeroProtocolo}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: widget.protocolo.status,
              decoration: const InputDecoration(labelText: 'Status atual'),
              items: _statusList
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _novoStatus = v),
            ),
            if (_novoStatus != null) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _responsavelCtrl,
                decoration: const InputDecoration(labelText: 'Responsável', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacoesCtrl,
                decoration: const InputDecoration(labelText: 'Observações', alignLabelWithHint: true),
                maxLines: 3,
              ),
            ],
          ],
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
              : const Icon(Icons.update),
          label: Text(_salvando ? 'Salvando...' : 'Alterar'),
        ),
      ],
    );
  }
}