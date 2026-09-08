import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../../core/data/listas_govbr.dart';
import '../../../../../core/utils/cpf_input_formatter.dart';
import '../../../../../core/widgets/acessos_modulos_card.dart';
import '../../../data/models/admin_models.dart';
import '../../providers/admin_provider.dart';

class AdminNovoColaboradorDialog extends StatefulWidget {
  final List<AdminEmpresaModel> empresas;

  const AdminNovoColaboradorDialog({super.key, this.empresas = const []});

  @override
  State<AdminNovoColaboradorDialog> createState() => _AdminNovoColaboradorDialogState();
}

class _AdminNovoColaboradorDialogState extends State<AdminNovoColaboradorDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _matriculaController = TextEditingController();

  String? _tenantId;
  String? _cargo;
  String? _departamento;

  DateTime _dataNascimento = DateTime(1995, 1, 1);
  DateTime _dataAdmissao = DateTime.now();
  DateTime? _dataDesligamento;
  bool _acessoEstoque = false;
  bool _acessoPatrimonio = false;
  bool _acessoFrota = false;
  bool _acessoProtocolo = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
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
    final cpfLimpo = CpfInputFormatter.clean(_cpfController.text);

    final sucesso = await provider.cadastrarColaborador(
      cpf: cpfLimpo,
      nome: _nomeController.text.trim(),
      emailCorporativo: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      senha: _senhaController.text,
      matricula: _matriculaController.text.trim(),
      cargo: _cargo,
      departamento: _departamento,
      dataNascimento: dateFormat.format(_dataNascimento),
      dataAdmissao: dateFormat.format(_dataAdmissao),
      dataDesligamento: _dataDesligamento != null
          ? dateFormat.format(_dataDesligamento!)
          : null,
      tenantId: _tenantId,
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
            content: Text('Colaborador cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Erro ao cadastrar colaborador.'),
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
                      Icon(Icons.person_add, color: Colors.blue.shade700, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Novo Colaborador',
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
                                inputFormatters: [CpfInputFormatter()],
                                decoration: const InputDecoration(
                                  labelText: 'CPF (11 dígitos) *',
                                  hintText: '000.000.000-00',
                                  prefixIcon: Icon(Icons.credit_card),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe o CPF';
                                  }
                                  if (!CpfInputFormatter.isValidLength(v)) {
                                    return 'O CPF deve ter 11 dígitos';
                                  }
                                  if (!CpfInputFormatter.isValid(v)) {
                                    return 'CPF inválido';
                                  }
                                  return null;
                                },
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
                          controller: _senhaController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Senha de Acesso Inicial *',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Senha deve ter no mínimo 6 caracteres'
                              : null,
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
                        DropdownButtonFormField<String?>(
                          initialValue: _tenantId,
                          decoration: const InputDecoration(
                            labelText: 'Empresa',
                            hintText: 'Opcional. Em branco usa a empresa do usuário logado.',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Sem empresa (padrão do usuário)'),
                            ),
                            ...widget.empresas.map(
                              (e) => DropdownMenuItem<String?>(
                                value: e.id,
                                child: Text(
                                  e.nome.isNotEmpty ? e.nome : e.id,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _tenantId = v),
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
                    label: const Text('Salvar Colaborador'),
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
