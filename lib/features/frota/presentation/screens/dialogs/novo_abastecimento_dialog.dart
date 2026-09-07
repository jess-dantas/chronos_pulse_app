import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/frota_provider.dart';

class NovoAbastecimentoDialog extends StatefulWidget {
  const NovoAbastecimentoDialog({super.key});

  @override
  State<NovoAbastecimentoDialog> createState() => _NovoAbastecimentoDialogState();
}

class _NovoAbastecimentoDialogState extends State<NovoAbastecimentoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _litrosCtrl = TextEditingController();
  final _valorLitroCtrl = TextEditingController();
  final _odometroCtrl = TextEditingController();
  final _postoCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();

  String? _veiculoId;
  bool _salvando = false;

  @override
  void dispose() {
    _litrosCtrl.dispose();
    _valorLitroCtrl.dispose();
    _odometroCtrl.dispose();
    _postoCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final ok = await context.read<FrotaProvider>().registrarAbastecimento({
      'veiculoId': _veiculoId,
      'litros': _litrosCtrl.text.trim(),
      'valorLitro': _valorLitroCtrl.text.trim(),
      if (_odometroCtrl.text.isNotEmpty) 'odometroKm': _odometroCtrl.text.trim(),
      if (_postoCtrl.text.isNotEmpty) 'posto': _postoCtrl.text.trim(),
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
    final provider = context.watch<FrotaProvider>();

    return AlertDialog(
      title: const Text('Registrar Abastecimento'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _veiculoId,
                  decoration: const InputDecoration(
                    labelText: 'Veículo *',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                  ),
                  items: provider.veiculos
                      .map((v) => DropdownMenuItem(
                            value: v.id,
                            child: Text('${v.marca ?? ''} ${v.modelo ?? ''} (${v.placa})'.trim()),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _veiculoId = v),
                  validator: (v) => v == null ? 'Selecione um veículo' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _litrosCtrl,
                        decoration: const InputDecoration(labelText: 'Litros *', prefixIcon: Icon(Icons.water_drop_outlined)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe os litros' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _valorLitroCtrl,
                        decoration: const InputDecoration(labelText: r'R$/litro *', prefixIcon: Icon(Icons.attach_money)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o valor' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _odometroCtrl,
                        decoration: const InputDecoration(labelText: 'Odômetro (km)', prefixIcon: Icon(Icons.speed)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _postoCtrl,
                        decoration: const InputDecoration(labelText: 'Posto', prefixIcon: Icon(Icons.local_gas_station_outlined)),
                      ),
                    ),
                  ],
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