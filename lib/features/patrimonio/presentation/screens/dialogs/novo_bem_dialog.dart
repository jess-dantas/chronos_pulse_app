import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/patrimonio_provider.dart';

class NovoBemDialog extends StatefulWidget {
  const NovoBemDialog({super.key});

  @override
  State<NovoBemDialog> createState() => _NovoBemDialogState();
}

class _NovoBemDialogState extends State<NovoBemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tombamentoCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  final _localizacaoCtrl = TextEditingController();
  final _responsavelCtrl = TextEditingController();
  final _notaFiscalCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _dataCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();

  String _estado = 'BOM';
  bool _salvando = false;

  static const _estados = ['NOVO', 'OTIMO', 'BOM', 'REGULAR', 'INSERVIVEL'];

  @override
  void dispose() {
    _tombamentoCtrl.dispose();
    _descricaoCtrl.dispose();
    _categoriaCtrl.dispose();
    _localizacaoCtrl.dispose();
    _responsavelCtrl.dispose();
    _notaFiscalCtrl.dispose();
    _valorCtrl.dispose();
    _dataCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final ok = await context.read<PatrimonioProvider>().criarBem(
          tombamento: _tombamentoCtrl.text,
          descricao: _descricaoCtrl.text,
          categoria: _categoriaCtrl.text,
          estado: _estado,
          localizacao: _localizacaoCtrl.text,
          responsavelNome: _responsavelCtrl.text,
          numeroNotaFiscal: _notaFiscalCtrl.text,
          valorAquisicao: _valorCtrl.text,
          dataAquisicao: _dataCtrl.text,
          observacoes: _observacoesCtrl.text,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.read<PatrimonioProvider>().errorMessage ?? 'Erro ao salvar.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Bem Patrimonial'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _tombamentoCtrl,
                  decoration: const InputDecoration(labelText: 'Nº Tombamento', prefixIcon: Icon(Icons.tag)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descricaoCtrl,
                  decoration: const InputDecoration(labelText: 'Descrição *', prefixIcon: Icon(Icons.notes)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a descrição' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoriaCtrl,
                  decoration: const InputDecoration(labelText: 'Categoria', prefixIcon: Icon(Icons.category_outlined)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _estado,
                  decoration: const InputDecoration(labelText: 'Estado de Conservação'),
                  items: _estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _estado = v ?? 'BOM'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _localizacaoCtrl,
                  decoration: const InputDecoration(labelText: 'Localização', prefixIcon: Icon(Icons.place_outlined)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _responsavelCtrl,
                        decoration: const InputDecoration(labelText: 'Responsável', prefixIcon: Icon(Icons.person_outline)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _notaFiscalCtrl,
                        decoration: const InputDecoration(labelText: 'Nota Fiscal'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _valorCtrl,
                        decoration: const InputDecoration(labelText: 'Valor Aquisição', prefixIcon: Icon(Icons.attach_money)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _dataCtrl,
                        decoration: const InputDecoration(labelText: 'Data Aquisição (AAAA-MM-DD)'),
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