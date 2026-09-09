import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/patrimonio_models.dart';
import '../../providers/patrimonio_provider.dart';

class EditarBemDialog extends StatefulWidget {
  final PatrimonioModel bem;

  const EditarBemDialog({super.key, required this.bem});

  @override
  State<EditarBemDialog> createState() => _EditarBemDialogState();
}

class _EditarBemDialogState extends State<EditarBemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tombamentoCtrl;
  late final TextEditingController _descricaoCtrl;
  late final TextEditingController _categoriaCtrl;
  late final TextEditingController _localizacaoCtrl;
  late final TextEditingController _responsavelCtrl;
  late final TextEditingController _notaFiscalCtrl;
  late final TextEditingController _valorCtrl;
  late final TextEditingController _dataCtrl;
  late final TextEditingController _vidaUtilCtrl;
  late final TextEditingController _inicioDepreciacaoCtrl;
  late final TextEditingController _observacoesCtrl;

  late String _estado;
  bool _salvando = false;

  static const _estados = ['NOVO', 'OTIMO', 'BOM', 'REGULAR', 'INSERVIVEL'];

  @override
  void initState() {
    super.initState();
    final bem = widget.bem;
    _tombamentoCtrl = TextEditingController(text: bem.tombamento ?? '');
    _descricaoCtrl = TextEditingController(text: bem.descricao);
    _categoriaCtrl = TextEditingController(text: bem.categoria ?? '');
    _localizacaoCtrl = TextEditingController(text: bem.localizacao ?? '');
    _responsavelCtrl = TextEditingController(text: bem.responsavelNome ?? '');
    _notaFiscalCtrl = TextEditingController(text: bem.numeroNotaFiscal ?? '');
    _valorCtrl = TextEditingController(text: bem.valorAquisicao ?? '');
    _dataCtrl = TextEditingController(text: bem.dataAquisicao ?? '');
    _vidaUtilCtrl = TextEditingController(text: bem.vidaUtilMeses ?? '');
    _inicioDepreciacaoCtrl = TextEditingController(text: bem.dataInicioDepreciacao ?? '');
    _observacoesCtrl = TextEditingController(text: bem.observacoes ?? '');
    _estado = bem.estado;
  }

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
    _vidaUtilCtrl.dispose();
    _inicioDepreciacaoCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final ok = await context.read<PatrimonioProvider>().atualizarBem(
          id: widget.bem.id,
          tombamento: _tombamentoCtrl.text,
          descricao: _descricaoCtrl.text,
          categoria: _categoriaCtrl.text,
          estado: _estado,
          localizacao: _localizacaoCtrl.text,
          responsavelNome: _responsavelCtrl.text,
          numeroNotaFiscal: _notaFiscalCtrl.text,
          valorAquisicao: _valorCtrl.text,
          dataAquisicao: _dataCtrl.text,
          vidaUtilMeses: _vidaUtilCtrl.text,
          dataInicioDepreciacao: _inicioDepreciacaoCtrl.text,
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
      title: Text('Editar Bem — ${widget.bem.tombamento ?? widget.bem.descricao}'),
      content: SizedBox(
        width: 560,
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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _vidaUtilCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Vida Útil (meses)',
                          prefixIcon: Icon(Icons.timelapse),
                          hintText: 'Ex.: 60',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _inicioDepreciacaoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Início Depreciação (AAAA-MM-DD)',
                          hintText: 'Padrão: data de aquisição',
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.bem.vidaUtilMeses != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Depreciação atual: taxa ${widget.bem.taxaDepreciacaoMensal ?? '—'}/mês, '
                      'acumulado R\$ ${widget.bem.valorDepreciado ?? '0'} '
                      '(valor atual R\$ ${widget.bem.valorAtual ?? widget.bem.valorAquisicao ?? '0'}). '
                      'Os valores são recalculados ao salvar.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ),
                ],
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