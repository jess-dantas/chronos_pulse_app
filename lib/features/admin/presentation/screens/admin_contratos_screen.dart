import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';

class AdminContratosScreen extends StatefulWidget {
  const AdminContratosScreen({super.key});

  @override
  State<AdminContratosScreen> createState() => _AdminContratosScreenState();
}

class _AdminContratosScreenState extends State<AdminContratosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().carregarContratos();
      context.read<AdminProvider>().carregarEmpresas();
    });
  }

  String? _nomeEmpresa(AdminProvider provider, Map<String, dynamic> contrato) {
    final empresas = provider.empresas;
    final tenantId = contrato['tenantId']?.toString();
    if (empresas.isEmpty || tenantId == null) return null;
    for (final e in empresas) {
      if (e['id']?.toString() == tenantId) return e['nome']?.toString();
    }
    return null;
  }

  void _abrirDialogNovoContrato() {
    showDialog(
      context: context,
      builder: (_) => const _CadastrarContratoDialog(),
    );
  }

  void _abrirDialogDetalhes(Map<String, dynamic> contrato, String? nomeEmpresa) {
    showDialog(
      context: context,
      builder: (_) => _ContratoDetalhesDialog(
        contrato: contrato,
        nomeEmpresa: nomeEmpresa,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final contratos = adminProvider.contratos;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contratos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _abrirDialogNovoContrato,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Novo Contrato'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (adminProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (contratos.isEmpty)
                  Card(
                    elevation: 0,
                    color: Colors.grey[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.description_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'Nenhum contrato cadastrado.',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: contratos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final c = contratos[index];
                      final status = c['status'] ?? 'ATIVO';
                      final statusCor = status == 'ATIVO'
                          ? Colors.green
                          : status == 'SUSPENSO'
                              ? Colors.orange
                              : Colors.red;
                      final nomeEmpresa = _nomeEmpresa(adminProvider, c);

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: statusCor.withOpacity(0.1),
                            child: Icon(Icons.description, color: statusCor),
                          ),
                          title: Text(
                            '${c['numero'] ?? 'S/N'} — ${c['objeto'] ?? 'Sem objeto'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (nomeEmpresa != null) ...[
                                  Text(
                                    nomeEmpresa,
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Text(
                                  'Vigência: ${c['dataInicio'] ?? '?'} a ${c['dataFim'] ?? '?'} | '
                                  'Valor Mensal: R\$ ${c['valorMensal'] ?? '0,00'}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusCor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusCor.withOpacity(0.3)),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusCor.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          onTap: () => _abrirDialogDetalhes(c, nomeEmpresa),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CadastrarContratoDialog extends StatefulWidget {
  const _CadastrarContratoDialog();

  @override
  State<_CadastrarContratoDialog> createState() => _CadastrarContratoDialogState();
}

class _CadastrarContratoDialogState extends State<_CadastrarContratoDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _tenantIdSelecionado;
  final _numeroController = TextEditingController();
  final _objetoController = TextEditingController();
  final _valorMensalController = TextEditingController();
  final _valorTotalController = TextEditingController();
  final _observacoesController = TextEditingController();
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _isEnviando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().carregarEmpresas();
    });
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _objetoController.dispose();
    _valorMensalController.dispose();
    _valorTotalController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData({required bool isInicio}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = picked;
        } else {
          _dataFim = picked;
        }
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tenantIdSelecionado == null) {
      _mostrarMensagem('Selecione a empresa (tenant).', vermelho: true);
      return;
    }
    if (_dataInicio == null || _dataFim == null) {
      _mostrarMensagem('Selecione as datas de início e fim.', vermelho: true);
      return;
    }

    setState(() => _isEnviando = true);

    try {
      final adminProvider = context.read<AdminProvider>();
      final sucesso = await adminProvider.cadastrarContrato(
        tenantId: _tenantIdSelecionado!,
        numero: _numeroController.text.trim(),
        objeto: _objetoController.text.trim(),
        dataInicio: _dataInicio!.toIso8601String().substring(0, 10),
        dataFim: _dataFim!.toIso8601String().substring(0, 10),
        valorMensal: double.tryParse(_valorMensalController.text.replaceAll(',', '.')) ?? 0,
        valorTotal: double.tryParse(_valorTotalController.text.replaceAll(',', '.')) ?? 0,
        observacoes: _observacoesController.text.trim().isNotEmpty
            ? _observacoesController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        _mostrarMensagem(sucesso ? 'Contrato cadastrado com sucesso!' : 'Erro ao cadastrar contrato.',
            vermelho: !sucesso);
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensagem('Erro: $e', vermelho: true);
      }
    } finally {
      if (mounted) setState(() => _isEnviando = false);
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
    final adminProvider = context.watch<AdminProvider>();
    final empresas = adminProvider.empresas;
    final empresasCarregando = adminProvider.isLoading && empresas.isEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Novo Contrato',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  if (empresasCarregando)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _tenantIdSelecionado,
                      items: empresas
                          .map(
                            (e) => DropdownMenuItem(
                              value: e['id']?.toString(),
                              child: Text(e['nome']?.toString() ?? 'Sem nome'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _tenantIdSelecionado = v),
                      decoration: InputDecoration(
                        labelText: 'Empresa (Tenant) *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Selecione a empresa' : null,
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _numeroController,
                    decoration: InputDecoration(
                      labelText: 'Nº do Contrato *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _objetoController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Objeto do Contrato *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selecionarData(isInicio: true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Data Início *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _dataInicio != null
                                  ? DateFormat('dd/MM/yyyy').format(_dataInicio!)
                                  : 'Selecionar',
                              style: TextStyle(
                                color: _dataInicio != null ? null : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selecionarData(isInicio: false),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Data Fim *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _dataFim != null
                                  ? DateFormat('dd/MM/yyyy').format(_dataFim!)
                                  : 'Selecionar',
                              style: TextStyle(
                                color: _dataFim != null ? null : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _valorMensalController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Valor Mensal (R\$) *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _valorTotalController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Valor Total (R\$) *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _observacoesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Observações (Opcional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isEnviando ? null : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isEnviando ? null : _salvar,
                        icon: _isEnviando
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: const Text('Salvar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContratoDetalhesDialog extends StatefulWidget {
  final Map<String, dynamic> contrato;
  final String? nomeEmpresa;

  const _ContratoDetalhesDialog({required this.contrato, this.nomeEmpresa});

  @override
  State<_ContratoDetalhesDialog> createState() => _ContratoDetalhesDialogState();
}

class _ContratoDetalhesDialogState extends State<_ContratoDetalhesDialog> {
  List<Map<String, dynamic>> _eventos = [];
  bool _carregandoEventos = true;
  String? _erroEventos;

  @override
  void initState() {
    super.initState();
    _carregarEventos();
  }

  Future<void> _carregarEventos() async {
    setState(() {
      _carregandoEventos = true;
      _erroEventos = null;
    });
    try {
      final eventos = await context
          .read<AdminProvider>()
          .listarEventosContrato(widget.contrato['id'].toString());
      if (!mounted) return;
      setState(() => _eventos = eventos);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erroEventos = 'Erro ao carregar eventos: $e');
    } finally {
      if (mounted) setState(() => _carregandoEventos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contrato;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      c['numero']?.toString() ?? 'Contrato',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.nomeEmpresa != null)
                        _infoLinha('Empresa', widget.nomeEmpresa!),
                      _infoLinha('Objeto', c['objeto']?.toString() ?? '—'),
                      _infoLinha(
                        'Vigência',
                        '${c['dataInicio'] ?? '?'} a ${c['dataFim'] ?? '?'}',
                      ),
                      _infoLinha('Valor Mensal', 'R\$ ${c['valorMensal'] ?? '0,00'}'),
                      _infoLinha('Valor Total', 'R\$ ${c['valorTotal'] ?? '0,00'}'),
                      _infoLinha('Status', c['status']?.toString() ?? 'ATIVO'),
                      if (c['observacoes'] != null)
                        _infoLinha('Observações', c['observacoes'].toString()),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Eventos',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton.filledTonal(
                            iconSize: 18,
                            icon: const Icon(Icons.add),
                            tooltip: 'Adicionar evento',
                            onPressed: () => _abrirDialogNovoEvento(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_carregandoEventos && _eventos.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (_erroEventos != null)
                        Text(_erroEventos!, style: const TextStyle(color: Colors.red))
                      else if (_eventos.isEmpty)
                        const Text(
                          'Nenhum evento registrado.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ..._eventos.map((e) => _eventoCard(e)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoLinha(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              rotulo,
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }

  Widget _eventoCard(Map<String, dynamic> e) {
    final tipo = e['tipo']?.toString() ?? 'OUTRO';
    final cor = tipo == 'ADITIVO'
        ? Colors.blue
        : tipo == 'PAGAMENTO'
            ? Colors.green
            : tipo == 'EVENTO'
                ? Colors.purple
                : Colors.grey;
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        isThreeLine: true,
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: cor.withOpacity(0.1),
          child: Icon(_iconeEvento(tipo), size: 18, color: cor),
        ),
        title: Text(tipo, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e['descricao']?.toString() ?? ''),
            if (e['criadoEm'] != null)
              Text(
                e['criadoEm'].toString(),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconeEvento(String tipo) {
    switch (tipo) {
      case 'ADITIVO':
        return Icons.edit_document;
      case 'PAGAMENTO':
        return Icons.payments;
      case 'EVENTO':
        return Icons.event;
      default:
        return Icons.info_outline;
    }
  }

  void _abrirDialogNovoEvento() {
    final contratoId = widget.contrato['id'].toString();
    showDialog(
      context: context,
      builder: (_) => _NovoEventoDialog(contratoId: contratoId),
    );
  }
}

class _NovoEventoDialog extends StatefulWidget {
  final String contratoId;

  const _NovoEventoDialog({required this.contratoId});

  @override
  State<_NovoEventoDialog> createState() => _NovoEventoDialogState();
}

class _NovoEventoDialogState extends State<_NovoEventoDialog> {
  final _formKey = GlobalKey<FormState>();
  String _tipo = 'EVENTO';
  final _descricaoController = TextEditingController();
  bool _isEnviando = false;

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isEnviando = true);
    try {
      await context.read<AdminProvider>().adicionarEventoContrato(
            contratoId: widget.contratoId,
            tipo: _tipo,
            descricao: _descricaoController.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Evento'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              items: const [
                DropdownMenuItem(value: 'EVENTO', child: Text('Evento')),
                DropdownMenuItem(value: 'ADITIVO', child: Text('Aditivo')),
                DropdownMenuItem(value: 'PAGAMENTO', child: Text('Pagamento')),
                DropdownMenuItem(value: 'OUTRO', child: Text('Outro')),
              ],
              onChanged: (v) => setState(() => _tipo = v ?? 'EVENTO'),
              decoration: const InputDecoration(labelText: 'Tipo *'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricaoController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descrição *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isEnviando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isEnviando ? null : _salvar,
          child: _isEnviando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
