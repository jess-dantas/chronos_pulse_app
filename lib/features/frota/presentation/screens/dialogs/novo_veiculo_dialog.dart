import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/frota_provider.dart';

class NovoVeiculoDialog extends StatefulWidget {
  const NovoVeiculoDialog({super.key});

  @override
  State<NovoVeiculoDialog> createState() => _NovoVeiculoDialogState();
}

class _NovoVeiculoDialogState extends State<NovoVeiculoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _placaCtrl = TextEditingController();
  final _renavamCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _tipoCtrl = TextEditingController();
  final _combustivelCtrl = TextEditingController();
  final _odometroCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();

  String _status = 'ATIVO';
  bool _salvando = false;

  static const _statusList = ['ATIVO', 'MANUTENCAO', 'INATIVO'];

  @override
  void dispose() {
    _placaCtrl.dispose();
    _renavamCtrl.dispose();
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _tipoCtrl.dispose();
    _combustivelCtrl.dispose();
    _odometroCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final ok = await context.read<FrotaProvider>().criarVeiculo({
      'placa': _placaCtrl.text.trim().toUpperCase(),
      if (_renavamCtrl.text.isNotEmpty) 'renavam': _renavamCtrl.text.trim(),
      if (_marcaCtrl.text.isNotEmpty) 'marca': _marcaCtrl.text.trim(),
      if (_modeloCtrl.text.isNotEmpty) 'modelo': _modeloCtrl.text.trim(),
      if (_tipoCtrl.text.isNotEmpty) 'tipo': _tipoCtrl.text.trim().toUpperCase(),
      if (_combustivelCtrl.text.isNotEmpty) 'combustivel': _combustivelCtrl.text.trim().toUpperCase(),
      'status': _status,
      if (_odometroCtrl.text.isNotEmpty) 'odometroAtual': _odometroCtrl.text.trim(),
      if (_observacoesCtrl.text.isNotEmpty) 'observacoes': _observacoesCtrl.text,
    });

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<FrotaProvider>().errorMessage ?? 'Erro ao salvar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Veículo'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _placaCtrl,
                  decoration: const InputDecoration(labelText: 'Placa *', prefixIcon: Icon(Icons.directions_car)),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a placa' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _marcaCtrl,
                        decoration: const InputDecoration(labelText: 'Marca'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _modeloCtrl,
                        decoration: const InputDecoration(labelText: 'Modelo'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _renavamCtrl,
                        decoration: const InputDecoration(labelText: 'Renavam'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _odometroCtrl,
                        decoration: const InputDecoration(labelText: 'Odômetro (km)', prefixIcon: Icon(Icons.speed)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tipoCtrl,
                        decoration: const InputDecoration(labelText: 'Tipo (UTILITARIO, CAMINHAO...)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _combustivelCtrl,
                        decoration: const InputDecoration(labelText: 'Combustível (FLEX, DIESEL...)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: _statusList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _status = v ?? 'ATIVO'),
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