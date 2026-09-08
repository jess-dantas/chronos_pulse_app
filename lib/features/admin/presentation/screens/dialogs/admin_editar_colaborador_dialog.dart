import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../../core/data/listas_govbr.dart';
import '../../../../../core/widgets/acessos_modulos_card.dart';
import '../../../data/models/admin_models.dart';
import '../../providers/admin_provider.dart';

class AdminEditarColaboradorDialog extends StatefulWidget {
  final AdminColaboradorModel colaborador;

  const AdminEditarColaboradorDialog({super.key, required this.colaborador});

  @override
  State<AdminEditarColaboradorDialog> createState() => _AdminEditarColaboradorDialogState();
}

class _AdminEditarColaboradorDialogState extends State<AdminEditarColaboradorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _cpfController;
  late final TextEditingController _emailController;
  late final TextEditingController _matriculaController;

  late String? _cargo;
  late String? _departamento;

  late DateTime _dataNascimento;
  late DateTime _dataAdmissao;
  DateTime? _dataDesligamento;
  late bool _acessoEstoque;
  late bool _acessoPatrimonio;
  late bool _acessoFrota;
  late bool _acessoProtocolo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.colaborador;
    _nomeController = TextEditingController(text: c.nome);
    _cpfController = TextEditingController(text: c.cpf);
    _emailController = TextEditingController(text: c.email ?? '');
    _matriculaController = TextEditingController(text: c.matricula ?? '');
    _cargo = (c.cargo?.trim() ?? '').isNotEmpty ? c.cargo : null;
    _departamento = (c.departamento?.trim() ?? '').isNotEmpty ? c.departamento : null;
    _dataNascimento = _parseDate(c.dataNascimento) ?? DateTime(1995, 1, 1);
    _dataAdmissao = _parseDate(c.dataAdmissao) ?? DateTime.now();
    _dataDesligamento = _parseDate(c.dataDesligamento);
    _acessoEstoque = c.acessoEstoque;
    _acessoPatrimonio = c.acessoPatrimonio;
    _acessoFrota = c.acessoFrota;
    _acessoProtocolo = c.acessoProtocolo;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _matriculaController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context, bool isNascimento) async {
    final dataInicial = isNascimento ? _dataNascimento : _dataAdmissao;
    final primeiraData = isNascimento ? DateTime(1940) : DateTime(2000);
    final ultimaData = isNascimento ? DateTime.now() : DateTime(2030);

    final DateTime? escolhida = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: primeiraData,
      lastDate: ultimaData,
    );

    if (escolhida != null) {
      setState(() {
        if (isNascimento) {
          _dataNascimento = escolhida;
        } else {
          _dataAdmissao = escolhida;
        }
      });
    }
  }

  Future<void> _selecionarDesligamento() async {
    final dataInicial = _dataDesligamento ?? DateTime.now();
    final DateTime? escolhida = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (escolhida != null) {
      setState(() => _dataDesligamento = escolhida);
    } else if (_dataDesligamento != null) {
      setState(() => _dataDesligamento = null);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final provider = context.read<AdminProvider>();
    final dateFormat = DateFormat('yyyy-MM-dd');

    final sucesso = await provider.atualizarColaborador(
      id: widget.colaborador.id,
      nome: _nomeController.text.trim(),
      emailCorporativo: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      matricula: _matriculaController.text.trim(),
      cargo: _cargo,
      departamento: _departamento,
      dataNascimento: dateFormat.format(_dataNascimento),
      dataAdmissao: dateFormat.format(_dataAdmissao),
      dataDesligamento: _dataDesligamento != null
          ? dateFormat.format(_dataDesligamento!)
          : null,
      acessoEstoque: _acessoEstoque,
      acessoPatrimonio: _acessoPatrimonio,
      acessoFrota: _acessoFrota,
      acessoProtocolo: _acessoProtocolo,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (sucesso) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Colaborador atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Erro ao atualizar colaborador.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue.shade700, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Editar Colaborador',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '* = Obrigatório',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome Completo *',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o nome completo'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: TextFormField(
                                controller: _cpfController,
                                keyboardType: TextInputType.number,
                                enabled: false,
                                decoration: const InputDecoration(
                                  labelText: 'CPF (não editável)',
                                  prefixIcon: Icon(Icons.credit_card),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'E-mail Corporativo',
                                  hintText: 'Opcional',
                                  prefixIcon: Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  if (!v.contains('@') || !v.contains('.')) {
                                    return 'Informe um e-mail válido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _matriculaController,
                          decoration: const InputDecoration(
                            labelText: 'Matrícula',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _cargo,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Cargo',
                                  hintText: 'Selecione...',
                                  border: OutlineInputBorder(),
                                ),
                                items: ListasGovBr.cargos.map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e, overflow: TextOverflow.ellipsis),
                                  ),
                                ).toList(),
                                onChanged: (v) => setState(() => _cargo = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _departamento,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Departamento / Setor',
                                  hintText: 'Selecione...',
                                  border: OutlineInputBorder(),
                                ),
                                items: ListasGovBr.departamentos.map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e, overflow: TextOverflow.ellipsis),
                                  ),
                                ).toList(),
                                onChanged: (v) => setState(() => _departamento = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.cake_outlined, size: 20),
                                label: Text('Nasc.: ${dateFormat.format(_dataNascimento)}'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => _selecionarData(context, true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 20),
                                label: Text('Admissão: ${dateFormat.format(_dataAdmissao)}'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => _selecionarData(context, false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.event_busy, size: 20),
                          label: Text(
                            _dataDesligamento != null
                                ? 'Desligamento: ${dateFormat.format(_dataDesligamento!)}'
                                : 'Desligamento: não informado',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _selecionarDesligamento,
                        ),
                        const SizedBox(height: 20),
                        AcessosModulosCard(
                          acessoEstoque: _acessoEstoque,
                          acessoPatrimonio: _acessoPatrimonio,
                          acessoFrota: _acessoFrota,
                          acessoProtocolo: _acessoProtocolo,
                          onChanged: (e, p, f, pr) => setState(() {
                            _acessoEstoque = e;
                            _acessoPatrimonio = p;
                            _acessoFrota = f;
                            _acessoProtocolo = pr;
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _salvar,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Salvar Alterações'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}