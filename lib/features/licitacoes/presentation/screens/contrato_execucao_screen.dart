import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/execucao_contrato_models.dart';
import '../providers/licitacoes_provider.dart';

final NumberFormat _moedaExec = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class ContratoExecucaoScreen extends StatefulWidget {
  final String? contratoId;

  const ContratoExecucaoScreen({super.key, this.contratoId});

  @override
  State<ContratoExecucaoScreen> createState() => _ContratoExecucaoScreenState();
}

class _ContratoExecucaoScreenState extends State<ContratoExecucaoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool get _detalhe => widget.contratoId != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LicitacoesProvider>();
      if (_detalhe) {
        provider.carregarExecucao(widget.contratoId!);
      } else {
        provider.carregarContratos();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LicitacoesProvider>();

    if (_detalhe) {
      final exec = provider.execucao(widget.contratoId!);
      if (exec == null) {
        return _carregando(context);
      }
      return _buildDetalhe(context, provider, exec);
    }
    return _buildLista(context, provider);
  }

  Scaffold _carregando(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestão da Execução Contratual')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  // ============================ LISTA DE CONTRATOS ============================

  Widget _buildLista(BuildContext context, LicitacoesProvider provider) {
    if (provider.isLoading && provider.contratosExecucao.isEmpty) {
      return _carregando(context);
    }
    if (provider.contratosExecucao.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contratos em execução')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_outlined, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Nenhum contrato formalizado ainda.'),
              const SizedBox(height: 4),
              const Text('Formalize o contrato a partir de uma licitação homologada.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context
                    .read<LicitacoesProvider>()
                    .carregarContratos(),
                child: const Text('Recarregar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Contratos em execução')),
      body: RefreshIndicator(
        onRefresh: () async => context.read<LicitacoesProvider>().carregarContratos(),
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: provider.contratosExecucao.length,
          itemBuilder: (context, index) {
            final c = provider.contratosExecucao[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade100,
                  child: const Icon(Icons.assignment_turned_in_outlined,
                      color: Colors.deepPurple),
                ),
                title: Text(c.numero),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.objeto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    Text(
                      'Empenhado: ${_moedaExec.format(c.valorEmpenhado)} · '
                      'Liquidado: ${_moedaExec.format(c.valorLiquidado)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
                trailing: _SituacaoChip(situacao: c.situacao),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ContratoExecucaoScreen(contratoId: c.id),
                  ));
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================ DETALHE / EXECUÇÃO ============================

  Widget _buildDetalhe(
      BuildContext context, LicitacoesProvider provider, ContratoExecucaoModel exec) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exec.numero),
        actions: [
          if (!exec.rescindido)
            PopupMenuButton<String>(
              tooltip: 'Ações da execução',
              onSelected: (acao) async {
                switch (acao) {
                  case 'aditivo':
                    await _dialogAditivo(context, exec);
                    break;
                  case 'apontamento':
                    await _dialogApontamento(context, exec);
                    break;
                  case 'medicao':
                    await _dialogMedicao(context, exec);
                    break;
                  case 'sancao':
                    await _dialogSancao(context, exec);
                    break;
                  case 'rescindir':
                    await _dialogRescindir(context, exec);
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'aditivo',
                  child: ListTile(
                    leading: Icon(Icons.update_outlined),
                    title: Text('Registrar aditivo'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'apontamento',
                  child: ListTile(
                    leading: Icon(Icons.report_problem_outlined),
                    title: Text('Registrar apontamento'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'medicao',
                  child: ListTile(
                    leading: Icon(Icons.square_foot_outlined),
                    title: Text('Registrar medição'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'sancao',
                  child: ListTile(
                    leading: Icon(Icons.gavel_outlined),
                    title: Text('Registrar sanção'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'rescindir',
                  child: ListTile(
                    leading: Icon(Icons.block_outlined),
                    title: Text('Rescindir contrato'),
                    dense: true,
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Resumo'),
            Tab(text: 'Aditivos (${exec.aditivos.length})'),
            Tab(
              text: 'Fiscalização (${exec.apontamentosAbertos})',
            ),
            Tab(text: 'Medições (${exec.medicoes.length})'),
            Tab(text: 'Sanções (${exec.sancoes.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResumo(context, exec),
          _buildAditivos(context, exec),
          _buildApontamentos(context, exec),
          _buildMedicoes(context, exec),
          _buildSancoes(context, exec),
        ],
      ),
    );
  }

  // ============================ TAB RESUMO ============================

  Widget _buildResumo(BuildContext context, ContratoExecucaoModel exec) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SituacaoChip(situacao: exec.situacao),
                    const SizedBox(width: 8),
                    if (exec.rescindido && exec.rescisao != null)
                      Text(
                        'Rescisão ${exec.rescisao!.tipoLabel} em '
                        '${exec.rescisao!.dataRescisaoFormatada}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Objeto: ${exec.objeto}'),
                const SizedBox(height: 8),
                _ExecLinhaInfo(
                    label: 'Vigência',
                    valor:
                        '${exec.dataInicioFormatada} até ${exec.dataFimFormatada}'),
                _ExecLinhaInfo(label: 'Empenho', valor: exec.empenhoNumero ?? '-'),
                if (exec.atrasado)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Contrato vencido há ${exec.diasParaVencimento.abs()} dia(s).',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  )
                else if (exec.diasParaVencimento <= 30)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Vence em ${exec.diasParaVencimento} dia(s).',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Valores',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _ExecLinhaInfo(label: 'Valor total', valor: _moedaExec.format(exec.valorTotal)),
                _ExecLinhaInfo(label: 'Valor mensal', valor: _moedaExec.format(exec.valorMensal)),
                _ExecLinhaInfo(label: 'Empenhado', valor: _moedaExec.format(exec.valorEmpenhado)),
                _ExecLinhaInfo(label: 'Liquidado', valor: _moedaExec.format(exec.valorLiquidado)),
                _ExecLinhaInfo(label: 'Medido (medições)', valor: _moedaExec.format(exec.valorMedidoTotal)),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Observações', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(exec.observacoes ?? '-'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================ TAB ADITIVOS ============================

  Widget _buildAditivos(BuildContext context, ContratoExecucaoModel exec) {
    if (exec.aditivos.isEmpty) {
      return const _EmptyState(text: 'Nenhum aditivo registrado.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: exec.aditivos.length,
      itemBuilder: (context, index) {
        final a = exec.aditivos[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.update_outlined, color: Colors.deepPurple),
            title: Text(a.tipoLabel),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.descricao),
                if (a.justificativa != null && a.justificativa!.isNotEmpty)
                  Text(a.justificativa!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                if (a.prazoAdicionadoDias != null)
                  Text('Prazo: +${a.prazoAdicionadoDias} dia(s)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                if (a.novoValorTotal != null)
                  Text('Novo valor total: ${_moedaExec.format(a.novoValorTotal!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                Text('Registrado em ${a.criadoEmFormatado}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================ TAB FISCALIZAÇÃO ============================

  Widget _buildApontamentos(BuildContext context, ContratoExecucaoModel exec) {
    if (exec.apontamentos.isEmpty) {
      return const _EmptyState(text: 'Nenhum apontamento de fiscalização registrado.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: exec.apontamentos.length,
      itemBuilder: (context, index) {
        final a = exec.apontamentos[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: a.resolvido
                  ? Colors.green.shade100
                  : a.gravidadeCor.withValues(alpha: 0.15),
              child: Icon(
                a.resolvido ? Icons.check_circle_outline : Icons.report_problem_outlined,
                color: a.resolvido ? Colors.green : a.gravidadeCor,
              ),
            ),
            title: Text('${a.gravidadeLabel} · Fiscal ${a.fiscal}'),
            subtitle: Text(a.descricao),
            trailing: a.resolvido
                ? Text('Resolvido em ${a.criadoEmFormatado}',
                    style: TextStyle(fontSize: 11, color: Colors.green[700]))
                : IconButton(
                    tooltip: 'Marcar como resolvido',
                    icon: const Icon(Icons.check),
                    onPressed: () async {
                      final ok = await context
                          .read<LicitacoesProvider>()
                          .resolverApontamento(exec.id, a.id);
                      if (context.mounted) {
                        _snack(context,
                            ok ? 'Apontamento resolvido.' : 'Falha ao resolver o apontamento.');
                      }
                    },
                  ),
          ),
        );
      },
    );
  }

  // ============================ TAB MEDIÇÕES ============================

  Widget _buildMedicoes(BuildContext context, ContratoExecucaoModel exec) {
    if (exec.medicoes.isEmpty) {
      return const _EmptyState(text: 'Nenhuma medição registrada.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: exec.medicoes.length,
      itemBuilder: (context, index) {
        final m = exec.medicoes[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.square_foot_outlined, color: Colors.deepPurple),
            title: Text('Período ${m.periodo}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Medido: ${_moedaExec.format(m.valorMedido)}'),
                Text('Pago: ${_moedaExec.format(m.valorPago)}'
                    '${m.pagoEm != null ? ' em ${m.pagoEmFormatado}' : ''}'),
                if (m.observacao != null && m.observacao!.isNotEmpty)
                  Text(m.observacao!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================ TAB SANÇÕES ============================

  Widget _buildSancoes(BuildContext context, ContratoExecucaoModel exec) {
    if (exec.sancoes.isEmpty) {
      return const _EmptyState(text: 'Nenhuma sanção registrada.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: exec.sancoes.length,
      itemBuilder: (context, index) {
        final s = exec.sancoes[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.gavel_outlined, color: Colors.redAccent),
            title: Text(s.tipoLabel),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.descricao),
                if (s.baseLegal != null && s.baseLegal!.isNotEmpty)
                  Text(s.baseLegal!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                if (s.percentualMulta != null)
                  Text('Multa: ${s.percentualMulta!.toStringAsFixed(3)}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                if (s.valorMulta != null)
                  Text('Multa: ${_moedaExec.format(s.valorMulta!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                Text('Aplicada em ${s.aplicadaEmFormatado}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================ DIÁLOGOS ============================

  Future<void> _dialogAditivo(BuildContext context, ContratoExecucaoModel exec) async {
    final form = GlobalKey<FormState>();
    String tipo = 'VALOR';
    final descricao = TextEditingController();
    final justificativa = TextEditingController();
    final prazo = TextEditingController();
    final novoValor = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Registrar aditivo — ${exec.numero}'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration: const InputDecoration(labelText: 'Tipo do aditivo*'),
                    items: const [
                      DropdownMenuItem(value: 'VALOR', child: Text('Valor')),
                      DropdownMenuItem(value: 'PRAZO', child: Text('Prazo')),
                      DropdownMenuItem(value: 'QUANTITATIVO', child: Text('Quantitativo')),
                      DropdownMenuItem(value: 'OBJETO', child: Text('Objeto')),
                    ],
                    onChanged: (v) => setState(() => tipo = v ?? tipo),
                  ),
                  TextFormField(
                    controller: descricao,
                    decoration: const InputDecoration(labelText: 'Descrição*'),
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a descrição' : null,
                  ),
                  TextFormField(
                    controller: justificativa,
                    decoration: const InputDecoration(labelText: 'Justificativa'),
                    maxLines: 2,
                  ),
                  if (tipo == 'PRAZO')
                    TextFormField(
                      controller: prazo,
                      decoration: const InputDecoration(labelText: 'Dias adicionados*'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Informe os dias' : null,
                    ),
                  if (tipo == 'VALOR')
                    TextFormField(
                      controller: novoValor,
                      decoration: const InputDecoration(labelText: 'Novo valor total*'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Informe o novo valor total' : null,
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!form.currentState!.validate()) return;
                final dias = int.tryParse(prazo.text.trim());
                final valor = double.tryParse(novoValor.text.replaceAll(',', '.'));
                final dto = AdicionarAditivoDTO(
                  tipo: tipo,
                  descricao: descricao.text.trim(),
                  justificativa: justificativa.text.trim().isEmpty
                      ? null
                      : justificativa.text.trim(),
                  prazoAdicionadoDias: tipo == 'PRAZO' ? dias : null,
                  novoValorTotal: tipo == 'VALOR' ? valor : null,
                );
                Navigator.of(ctx).pop();
                if (context.mounted) {
                  final ok = await context
                      .read<LicitacoesProvider>()
                      .registrarAditivo(exec.id, dto);
                  if (context.mounted) {
                    _snack(
                        context, ok ? 'Aditivo registrado.' : 'Falha ao registrar o aditivo.');
                  }
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dialogApontamento(BuildContext context, ContratoExecucaoModel exec) async {
    final form = GlobalKey<FormState>();
    String gravidade = 'MEDIA';
    final fiscal = TextEditingController();
    final descricao = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Registrar apontamento — ${exec.numero}'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: fiscal,
                    decoration: const InputDecoration(labelText: 'Fiscal*'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o fiscal' : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: gravidade,
                    decoration: const InputDecoration(labelText: 'Gravidade*'),
                    items: const [
                      DropdownMenuItem(value: 'LEVE', child: Text('Leve')),
                      DropdownMenuItem(value: 'MEDIA', child: Text('Média')),
                      DropdownMenuItem(value: 'GRAVE', child: Text('Grave')),
                    ],
                    onChanged: (v) => setState(() => gravidade = v ?? gravidade),
                  ),
                  TextFormField(
                    controller: descricao,
                    decoration: const InputDecoration(labelText: 'Descrição*'),
                    maxLines: 3,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe a descrição' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!form.currentState!.validate()) return;
                final dto = AdicionarApontamentoDTO(
                  fiscal: fiscal.text.trim(),
                  descricao: descricao.text.trim(),
                  gravidade: gravidade,
                );
                Navigator.of(ctx).pop();
                if (context.mounted) {
                  final ok = await context
                      .read<LicitacoesProvider>()
                      .registrarApontamento(exec.id, dto);
                  if (context.mounted) {
                    _snack(context,
                        ok ? 'Apontamento registrado.' : 'Falha ao registrar o apontamento.');
                  }
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dialogMedicao(BuildContext context, ContratoExecucaoModel exec) async {
    final form = GlobalKey<FormState>();
    final periodo = TextEditingController(text: _periodoAtual());
    final valorMedido = TextEditingController();
    final valorPago = TextEditingController();
    final observacao = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Registrar medição — ${exec.numero}'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: periodo,
                    decoration: const InputDecoration(labelText: 'Período* (ex.: 2026-07)'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o período' : null,
                  ),
                  TextFormField(
                    controller: valorMedido,
                    decoration: const InputDecoration(labelText: 'Valor medido*'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe o valor medido' : null,
                  ),
                  TextFormField(
                    controller: valorPago,
                    decoration: const InputDecoration(labelText: 'Valor pago'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  TextFormField(
                    controller: observacao,
                    decoration: const InputDecoration(labelText: 'Observação'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              final dto = RegistrarMedicaoDTO(
                periodo: periodo.text.trim(),
                valorMedido:
                    double.tryParse(valorMedido.text.replaceAll(',', '.')) ?? 0.0,
                valorPago: double.tryParse(valorPago.text.replaceAll(',', '.')) ?? 0.0,
                observacao: observacao.text.trim().isEmpty ? null : observacao.text.trim(),
              );
              Navigator.of(ctx).pop();
              if (context.mounted) {
                final ok = await context
                    .read<LicitacoesProvider>()
                    .registrarMedicao(exec.id, dto);
                if (context.mounted) {
                  _snack(context,
                      ok ? 'Medição registrada.' : 'Falha ao registrar a medição.');
                }
              }
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _dialogSancao(BuildContext context, ContratoExecucaoModel exec) async {
    final form = GlobalKey<FormState>();
    String tipo = 'MULTA';
    String? aplicadaEm;
    final descricao = TextEditingController();
    final baseLegal = TextEditingController();
    final percentual = TextEditingController();
    final valorMulta = TextEditingController();

    Future<void> selecionarData() async {
      final data = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now(),
      );
      if (data != null) {
        aplicadaEm = '${data.year.toString().padLeft(4, '0')}-'
            '${data.month.toString().padLeft(2, '0')}-'
            '${data.day.toString().padLeft(2, '0')}';
      }
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Registrar sanção — ${exec.numero}'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: form,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: tipo,
                      decoration: const InputDecoration(labelText: 'Tipo*'),
                      items: const [
                        DropdownMenuItem(value: 'ADVERTENCIA', child: Text('Advertência')),
                        DropdownMenuItem(value: 'MULTA', child: Text('Multa')),
                        DropdownMenuItem(
                            value: 'SUSPENSAO_TEMPORARIA', child: Text('Suspensão temporária')),
                        DropdownMenuItem(
                            value: 'IMPEDIMENTO', child: Text('Impedimento de licitar')),
                        DropdownMenuItem(
                            value: 'DECLARACAO_INIDONEIDADE', child: Text('Declaração de inidoneidade')),
                      ],
                      onChanged: (v) => setState(() => tipo = v ?? tipo),
                    ),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Aplicada em*',
                        hintText: aplicadaEm ?? 'Selecione a data',
                        suffixIcon: const Icon(Icons.event),
                      ),
                      onTap: () async {
                        await selecionarData();
                        setState(() {});
                      },
                      validator: (v) => aplicadaEm == null ? 'Selecione' : null,
                    ),
                    TextFormField(
                      controller: descricao,
                      decoration: const InputDecoration(labelText: 'Descrição*'),
                      maxLines: 2,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Informe a descrição' : null,
                    ),
                    TextFormField(
                      controller: baseLegal,
                      decoration: const InputDecoration(labelText: 'Base legal'),
                      maxLines: 2,
                    ),
                    if (tipo == 'MULTA') ...[
                      TextFormField(
                        controller: percentual,
                        decoration: const InputDecoration(
                            labelText: 'Percentual da multa (%)'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                      TextFormField(
                        controller: valorMulta,
                        decoration:
                            const InputDecoration(labelText: 'Valor da multa (R\$)'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!form.currentState!.validate()) return;
                if (tipo == 'MULTA' &&
                    percentual.text.trim().isEmpty &&
                    valorMulta.text.trim().isEmpty) {
                  _snack(context, 'Informe o percentual ou o valor da multa.');
                  return;
                }
                final dto = AdicionarSancaoDTO(
                  tipo: tipo,
                  baseLegal: baseLegal.text.trim().isEmpty ? null : baseLegal.text.trim(),
                  descricao: descricao.text.trim(),
                  percentualMulta:
                      double.tryParse(percentual.text.replaceAll(',', '.')),
                  valorMulta: double.tryParse(valorMulta.text.replaceAll(',', '.')),
                  aplicadaEm: aplicadaEm!,
                );
                Navigator.of(ctx).pop();
                if (context.mounted) {
                  final ok = await context
                      .read<LicitacoesProvider>()
                      .registrarSancao(exec.id, dto);
                  if (context.mounted) {
                    _snack(context,
                        ok ? 'Sanção registrada.' : 'Falha ao registrar a sanção.');
                  }
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dialogRescindir(BuildContext context, ContratoExecucaoModel exec) async {
    final form = GlobalKey<FormState>();
    String tipo = 'UNILATERAL';
    String? dataRescisao;
    final motivo = TextEditingController();

    Future<void> selecionarData() async {
      final data = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 3650)),
        lastDate: DateTime.now().add(const Duration(days: 30)),
      );
      if (data != null) {
        dataRescisao = '${data.year.toString().padLeft(4, '0')}-'
            '${data.month.toString().padLeft(2, '0')}-'
            '${data.day.toString().padLeft(2, '0')}';
      }
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Rescindir contrato — ${exec.numero}'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration: const InputDecoration(labelText: 'Tipo*'),
                    items: const [
                      DropdownMenuItem(value: 'UNILATERAL', child: Text('Unilateral')),
                      DropdownMenuItem(value: 'AMIGAVEL', child: Text('Amigável')),
                      DropdownMenuItem(value: 'JUDICIAL', child: Text('Judicial')),
                    ],
                    onChanged: (v) => setState(() => tipo = v ?? tipo),
                  ),
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Data da rescisão*',
                      hintText: dataRescisao ?? 'Selecione a data',
                      suffixIcon: const Icon(Icons.event),
                    ),
                    onTap: () async {
                      await selecionarData();
                      setState(() {});
                    },
                    validator: (v) => dataRescisao == null ? 'Selecione' : null,
                  ),
                  TextFormField(
                    controller: motivo,
                    decoration: const InputDecoration(labelText: 'Motivo*'),
                    maxLines: 3,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe o motivo' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (!form.currentState!.validate()) return;
                final dto = RescindirContratoDTO(
                  tipo: tipo,
                  motivo: motivo.text.trim(),
                  dataRescisao: dataRescisao!,
                );
                Navigator.of(ctx).pop();
                if (context.mounted) {
                  final ok = await context
                      .read<LicitacoesProvider>()
                      .rescindirContrato(exec.id, dto);
                  if (context.mounted) {
                    _snack(context,
                        ok ? 'Contrato rescindido.' : 'Falha ao rescindir o contrato.');
                  }
                }
              },
              child: const Text('Rescindir'),
            ),
          ],
        ),
      ),
    );
  }
}

String _periodoAtual() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

class _SituacaoChip extends StatelessWidget {
  final String situacao;
  const _SituacaoChip({required this.situacao});

  @override
  Widget build(BuildContext context) {
    final (cor, fundo, label) = _coresSituacao(situacao);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cor),
      ),
    );
  }

  (Color, Color, String) _coresSituacao(String s) {
    switch (s) {
      case 'VIGENTE':
        return (const Color(0xFF2E7D32), const Color(0xFFE8F5E9), 'Vigente');
      case 'EXPIRANDO':
        return (const Color(0xFFE65100), const Color(0xFFFFF3E0), 'Próx. vencimento');
      case 'VENCIDO':
        return (const Color(0xFFD32F2F), const Color(0xFFFFEBEE), 'Vencido');
      case 'RESCINDIDO':
        return (const Color(0xFF616161), const Color(0xFFEEEEEE), 'Rescindido');
      default:
        return (const Color(0xFF616161), const Color(0xFFEEEEEE), s);
    }
  }
}

class _ExecLinhaInfo extends StatelessWidget {
  final String label;
  final String valor;

  const _ExecLinhaInfo({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(valor, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }
}