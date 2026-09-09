import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../compras/presentation/providers/compras_provider.dart';
import '../../../estoque/presentation/providers/estoque_provider.dart';
import '../../data/models/licitacoes_models.dart';
import '../../data/models/planejamento_licitacao_models.dart';
import '../providers/licitacoes_provider.dart';
import 'planejamento_licitacao_dialog.dart';

final NumberFormat _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class LicitacoesHomeScreen extends StatefulWidget {
  const LicitacoesHomeScreen({super.key});

  @override
  State<LicitacoesHomeScreen> createState() => _LicitacoesHomeScreenState();
}

class _LicitacoesHomeScreenState extends State<LicitacoesHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LicitacoesProvider>().carregarTudo();
      context.read<ComprasProvider>().carregarTudo();
      context.read<EstoqueProvider>().carregarTudo();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final licitacoesProvider = context.watch<LicitacoesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.gavel_outlined, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('CP Licitações & Contratações'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              icon: Badge(
                isLabelVisible: licitacoesProvider.licitacoesEmDisputa > 0,
                label: Text('${licitacoesProvider.licitacoesEmDisputa}'),
                child: const Icon(Icons.gavel_outlined),
              ),
              text: 'Licitações',
            ),
            const Tab(
              icon: Icon(Icons.edit_note),
              text: 'Propostas',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: licitacoesProvider
                    .planejamentosEmElaboracaoPendentes,
                label: Text('${licitacoesProvider.planejamentosPendentes.length}'),
                child: const Icon(Icons.folder_shared_outlined),
              ),
              text: 'Planejamento',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LicitacoesListaTab(),
          _LicitacoesPropostasTab(),
          _LicitacoesPlanejamentoTab(),
        ],
      ),
    );
  }
}

class _LicitacoesListaTab extends StatelessWidget {
  const _LicitacoesListaTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LicitacoesProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              _MetricChip(
                icon: Icons.gavel_outlined,
                label: '${provider.licitacoes.length} licitações',
                cor: Colors.deepPurple,
              ),
              const SizedBox(width: 8),
              _MetricChip(
                icon: Icons.hourglass_top,
                label: '${provider.licitacoesEmDisputa} em disputa',
                cor: const Color(0xFF1565C0),
              ),
              const SizedBox(width: 8),
              _MetricChip(
                icon: Icons.emoji_events_outlined,
                label: '${provider.licitacoesAdjudicadasHomologadas} concluídas',
                cor: const Color(0xFF2E7D32),
              ),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.add_chart_outlined, size: 18),
                label: const Text('Nova Licitação'),
                style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
                onPressed: () => exibirDialogNovaLicitacao(context),
              ),
            ],
          ),
        ),
        if (provider.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              provider.errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        Expanded(
          child: provider.isLoading && provider.licitacoes.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => context.read<LicitacoesProvider>().carregarTudo(),
                  child: provider.licitacoes.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Icon(Icons.gavel_outlined, size: 56, color: Colors.grey),
                            SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Nenhuma licitação cadastrada.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: provider.licitacoes.length,
                          itemBuilder: (context, index) {
                            final l = provider.licitacoes[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.deepPurple.shade100,
                                  child: const Icon(
                                    Icons.gavel_outlined,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                title: Text(l.numero),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${l.modalidadeLabel} · ${l.tipoJulgamentoLabel}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                    Text(
                                      '${l.itens.length} item(ns) · ${l.participantes.length} '
                                      'participante(s) · ${l.propostas.length} proposta(s)',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                    if (l.dataAbertura != null && l.dataAbertura!.isNotEmpty)
                                      Text(
                                        'Abertura: ${l.dataAberturaFormatada}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _StatusChip(licitacao: l),
                                    PopupMenuButton<String>(
                                      tooltip: 'Ações',
                                      onSelected: (acao) {
                                        if (acao == 'detalhes') {
                                          exibirDetalhesLicitacao(context, l);
                                        } else if (acao == 'publicar') {
                                          exibirDialogPublicar(context, l);
                                        } else if (acao == 'propostas') {
                                          exibirDialogRegistrarPropostas(context, l);
                                        } else if (acao == 'adjudicar') {
                                          _adjudicar(context, l);
                                        } else if (acao == 'homologar') {
                                          _homologar(context, l);
                                        } else if (acao == 'cancelar') {
                                          _cancelar(context, l);
                                        } else if (acao == 'pedidos') {
                                          _gerarPedidos(context, l);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'detalhes',
                                          child: ListTile(
                                            leading: Icon(Icons.visibility_outlined),
                                            title: Text('Ver detalhes'),
                                            dense: true,
                                          ),
                                        ),
                                        if (l.publicavel)
                                          const PopupMenuItem(
                                            value: 'publicar',
                                            child: ListTile(
                                              leading: Icon(Icons.campaign_outlined),
                                              title: Text('Publicar'),
                                              dense: true,
                                            ),
                                          ),
                                        if (l.emDisputa)
                                          const PopupMenuItem(
                                            value: 'propostas',
                                            child: ListTile(
                                              leading: Icon(Icons.edit_note),
                                              title: Text('Registrar propostas'),
                                              dense: true,
                                            ),
                                          ),
                                        if (l.emDisputa)
                                          const PopupMenuItem(
                                            value: 'adjudicar',
                                            child: ListTile(
                                              leading: Icon(Icons.emoji_events_outlined),
                                              title: Text('Adjudicar'),
                                              dense: true,
                                            ),
                                          ),
                                        if (l.adjudicada)
                                          const PopupMenuItem(
                                            value: 'homologar',
                                            child: ListTile(
                                              leading: Icon(Icons.verified_outlined),
                                              title: Text('Homologar'),
                                              dense: true,
                                            ),
                                          ),
                                        if (l.cancelavel)
                                          const PopupMenuItem(
                                            value: 'cancelar',
                                            child: ListTile(
                                              leading: Icon(Icons.block),
                                              title: Text('Cancelar'),
                                              dense: true,
                                            ),
                                          ),
                                        if ((l.adjudicada || l.homologada) && !l.pedidoGerado)
                                          const PopupMenuItem(
                                            value: 'pedidos',
                                            child: ListTile(
                                              leading: Icon(Icons.receipt_long_outlined),
                                              title: Text('Gerar pedidos'),
                                              dense: true,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () => exibirDetalhesLicitacao(context, l),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

class _LicitacoesPropostasTab extends StatelessWidget {
  const _LicitacoesPropostasTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LicitacoesProvider>();
    final emDisputa = provider.licitacoes.where((l) => l.emDisputa).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              _MetricChip(
                icon: Icons.hourglass_top,
                label: '${emDisputa.length} em disputa',
                cor: const Color(0xFF1565C0),
              ),
              const SizedBox(width: 8),
              _MetricChip(
                icon: Icons.edit_note,
                label:
                    '${provider.licitacoes.fold<int>(0, (a, l) => a + l.propostas.length)} '
                    'propostas registradas',
                cor: Colors.deepPurple,
              ),
            ],
          ),
        ),
        if (provider.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              provider.errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        Expanded(
          child: provider.isLoading && provider.licitacoes.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => context.read<LicitacoesProvider>().carregarTudo(),
                  child: emDisputa.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Icon(Icons.edit_note, size: 56, color: Colors.grey),
                            SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Nenhuma licitação em disputa.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: emDisputa.length,
                          itemBuilder: (context, index) {
                            final l = emDisputa[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.12),
                                  child: const Icon(Icons.edit_note, color: Color(0xFF1565C0)),
                                ),
                                title: Text(l.numero),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${l.modalidadeLabel} · ${l.tipoJulgamentoLabel}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                    Text(
                                      '${l.participantes.length} fornecedor(es) habilitado(s) · '
                                      '${l.propostas.length} proposta(s) registrada(s)',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                trailing: FilledButton.tonalIcon(
                                  onPressed: () =>
                                      exibirDialogRegistrarPropostas(context, l),
                                  icon: const Icon(Icons.edit_note, size: 16),
                                  label: const Text('Propostas'),
                                ),
                                onTap: () => exibirDetalhesLicitacao(context, l),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

class _LicitacoesPlanejamentoTab extends StatelessWidget {
  const _LicitacoesPlanejamentoTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LicitacoesProvider>();
    final emElaboracao =
        provider.licitacoes.where((l) => l.emElaboracao).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              _MetricChip(
                icon: Icons.folder_shared_outlined,
                label: '${emElaboracao.length} em elaboração',
                cor: const Color(0xFF8D6E63),
              ),
              const SizedBox(width: 8),
              _MetricChip(
                icon: Icons.campaign_outlined,
                label: '${provider.planejamentosPendentes.length} sem edital publicado',
                cor: const Color(0xFFEF6C00),
              ),
            ],
          ),
        ),
        if (provider.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              provider.errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<LicitacoesProvider>().carregarPlanejamentos(),
            child: emElaboracao.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Icon(Icons.folder_shared_outlined,
                          size: 56, color: Colors.grey),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Nenhuma licitação em elaboração.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: emElaboracao.length,
                    itemBuilder: (context, index) {
                      final l = emElaboracao[index];
                      final planejamento = provider.planejamento(l.id);
                      final etapa = planejamento == null
                          ? 'ETP não elaborado'
                          : planejamento.edital?.publicado == true
                              ? 'Edital publicado'
                              : _etapaAtual(planejamento);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                const Color(0xFF8D6E63).withValues(alpha: 0.12),
                            child: const Icon(Icons.folder_shared_outlined,
                                color: Color(0xFF8D6E63)),
                          ),
                          title: Text(l.numero),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l.modalidadeLabel} · ${l.tipoJulgamentoLabel}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[700]),
                              ),
                              Text(
                                'Etapa: $etapa',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          trailing: FilledButton.tonalIcon(
                            onPressed: () =>
                                exibirDialogPlanejamento(context, l),
                            icon: const Icon(Icons.folder_shared_outlined,
                                size: 16),
                            label: const Text('Planejamento'),
                          ),
                          onTap: () => exibirDialogPlanejamento(context, l),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  String _etapaAtual(PlanejamentoLicitacaoModel planejamento) {
    if (planejamento.etp == null) return 'ETP não elaborado';
    if (!planejamento.etp!.aprovado) return 'ETP em rascunho';
    if (planejamento.tr == null) return 'Elabore o Termo de Referência';
    if (!planejamento.tr!.aprovado) return 'TR em rascunho';
    if (planejamento.edital == null) return 'Elabore o edital';
    return 'Edital em elaboração';
  }
}

void exibirDetalhesLicitacao(BuildContext context, LicitacaoModel l) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l.numero),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LinhaInfo(label: 'Modalidade', valor: l.modalidadeLabel),
              _LinhaInfo(label: 'Julgamento', valor: l.tipoJulgamentoLabel),
              _LinhaInfo(label: 'Status', valor: l.statusLabel),
              if (l.dataAbertura != null && l.dataAbertura!.isNotEmpty)
                _LinhaInfo(label: 'Data de abertura', valor: l.dataAberturaFormatada),
              if (l.valorEstimado != null)
                _LinhaInfo(label: 'Valor estimado', valor: _moeda.format(l.valorEstimado!)),
              if (l.observacoes != null && l.observacoes!.isNotEmpty)
                _LinhaInfo(label: 'Observações', valor: l.observacoes!),
              _LinhaInfo(label: 'Pedido gerado', valor: l.pedidoGerado ? 'Sim' : 'Não'),
              if (l.criadoEm != null && l.criadoEm!.isNotEmpty)
                _LinhaInfo(label: 'Criado em', valor: l.criadoEm!),
              const Divider(),
              Text(
                'Itens',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              if (l.itens.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nenhum item cadastrado.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                )
              else
                ...l.itens.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.category_outlined, size: 20),
                    title: Text(item.descricao),
                    subtitle: Text(
                      'Qtde: ${item.quantidade.toStringAsFixed(2).replaceAll('.', ',')} '
                      '${item.unidadeMedida}'
                      '${item.valorEstimadoUnitario != null ? ' · ${_moeda.format(item.valorEstimadoUnitario!)}/un' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    trailing: Text(_moeda.format(item.valorEstimadoTotal)),
                  ),
                ),
              const Divider(),
              Text(
                'Participantes',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              if (l.participantes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nenhum participante habilitado.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                )
              else
                ...l.participantes.map(
                  (p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      p.habilitado ? Icons.storefront_outlined : Icons.block,
                      size: 20,
                      color: p.habilitado ? Colors.grey[700] : Colors.grey,
                    ),
                    title: Text(p.fornecedorNome),
                    trailing: p.habilitado
                        ? const Text(
                            'Habilitado',
                            style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                          )
                        : const Text(
                            'Inabilitado',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                  ),
                ),
              const Divider(),
              const Text(
                'Propostas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (l.propostas.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nenhuma proposta registrada.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                )
              else
                ...l.propostas.map(
                  (p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      p.vencedor ? Icons.emoji_events : Icons.edit_note,
                      size: 20,
                      color: p.vencedor ? const Color(0xFFEF6C00) : Colors.grey[700],
                    ),
                    title: Text(p.materialDescricao),
                    subtitle: Text(
                      '${p.fornecedorNome} · ${_moeda.format(p.valorUnitario)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    trailing: p.vencedor
                        ? const Text(
                            'Vencedor',
                            style: TextStyle(fontSize: 12, color: Color(0xFFEF6C00)),
                          )
                        : null,
                  ),
                ),
              if (l.vencedores.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Resultado',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...l.vencedores.map(
                  (p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text('${p.fornecedorNome} · ${p.materialDescricao}'),
                    trailing: Text(_moeda.format(p.valorUnitario)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
}

Future<void> exibirDialogNovaLicitacao(BuildContext context) async {
  final provider = context.read<LicitacoesProvider>();
  final materiaisAtivos =
      context.read<EstoqueProvider>().materiais.where((m) => m.ativo).toList();

  if (materiaisAtivos.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Cadastre ao menos um material no módulo Estoque primeiro.')),
    );
    return;
  }

  final form = GlobalKey<FormState>();
  String modalidade = 'PREGAO';
  String tipoJulgamento = 'MENOR_PRECO';
  String objeto = '';
  String? dataAbertura;
  String? observacoes;
  var sequenciaItens = 0;
  final itens = <_ItemLicitacao>[
    _ItemLicitacao(
      id: 'item_${sequenciaItens++}',
      qtdController: TextEditingController(text: '1'),
    ),
  ];

  await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        void adicionarItem() {
          setDialogState(() {
            itens.add(
              _ItemLicitacao(
                id: 'item_${sequenciaItens++}',
                qtdController: TextEditingController(text: '1'),
              ),
            );
          });
        }

        void removerItem(int index) {
          setDialogState(() {
            itens.removeAt(index);
          });
        }

        return AlertDialog(
          title: const Text('Nova Licitação'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: modalidade,
                      decoration: const InputDecoration(labelText: 'Modalidade'),
                      items: const [
                        DropdownMenuItem(value: 'PREGAO', child: Text('Pregão')),
                        DropdownMenuItem(value: 'CONCORRENCIA', child: Text('Concorrência')),
                        DropdownMenuItem(value: 'LEILAO', child: Text('Leilão')),
                        DropdownMenuItem(value: 'CONCURSO', child: Text('Concurso')),
                        DropdownMenuItem(
                            value: 'DIALOGO_COMPETITIVO', child: Text('Diálogo Competitivo')),
                      ],
                      onChanged: (v) => modalidade = v ?? modalidade,
                      validator: (v) => (v == null || v.isEmpty) ? 'Selecione' : null,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: tipoJulgamento,
                      decoration: const InputDecoration(labelText: 'Tipo de julgamento'),
                      items: const [
                        DropdownMenuItem(value: 'MENOR_PRECO', child: Text('Menor Preço')),
                        DropdownMenuItem(value: 'MAIOR_DESCONTO', child: Text('Maior Desconto')),
                        DropdownMenuItem(value: 'MELHOR_TECNICA', child: Text('Melhor Técnica')),
                        DropdownMenuItem(
                            value: 'TECNICA_E_PRECO', child: Text('Técnica e Preço')),
                        DropdownMenuItem(value: 'MAIOR_LANCE', child: Text('Maior Lance')),
                      ],
                      onChanged: (v) => tipoJulgamento = v ?? tipoJulgamento,
                      validator: (v) => (v == null || v.isEmpty) ? 'Selecione' : null,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Objeto*'),
                      maxLines: 2,
                      onChanged: (v) => objeto = v,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Informe o objeto' : null,
                    ),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Data de abertura',
                        hintText: dataAbertura == null
                            ? 'Opcional - toque para selecionar'
                            : dataAbertura!,
                        suffixIcon: const Icon(Icons.event),
                      ),
                      onTap: () async {
                        final data = await showDatePicker(
                          context: dialogContext,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (data != null) {
                          setDialogState(() {
                            dataAbertura = '${data.year.toString().padLeft(4, '0')}-'
                                '${data.month.toString().padLeft(2, '0')}-'
                                '${data.day.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Observações'),
                      maxLines: 2,
                      onChanged: (v) => observacoes = v,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Itens*',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                      ),
                    ),
                    ...List.generate(itens.length, (i) {
                      final item = itens[i];
                      return Row(
                        key: ValueKey(item.id),
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              key: ValueKey('${item.id}_material'),
                              initialValue: item.materialId,
                              decoration: const InputDecoration(labelText: 'Material'),
                              items: materiaisAtivos
                                  .map((m) => DropdownMenuItem(
                                        value: m.id,
                                        child: Text(
                                          m.descricao,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) => setDialogState(() => item.materialId = v),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Selecione' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 90,
                            child: TextFormField(
                              controller: item.qtdController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Qtde', isDense: true),
                              validator: (v) {
                                final qtd = double.tryParse((v ?? '').replaceAll(',', '.'));
                                if (qtd == null || qtd <= 0) return 'Inválida';
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            tooltip: 'Remover item',
                            onPressed: itens.length > 1 ? () => removerItem(i) : null,
                          ),
                        ],
                      );
                    }),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: adicionarItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Adicionar item'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final formValido = form.currentState!.validate();
                final temMaterial = itens.any((i) => i.materialId != null && i.materialId!.isNotEmpty);
                if (!formValido || !temMaterial) {
                  if (!temMaterial) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Selecione ao menos um material para a licitação.')),
                    );
                  }
                  return;
                }
                final itensDTO = <LicitacaoItemDTO>[];
                for (final item in itens) {
                  if (item.materialId == null || item.materialId!.isEmpty) continue;
                  itensDTO.add(LicitacaoItemDTO(
                    materialId: item.materialId!,
                    quantidade: double.parse(
                        item.qtdController.text.replaceAll(',', '.')),
                  ));
                }
                final sucesso = await provider.criarLicitacao(
                  CadastrarLicitacaoDTO(
                    modalidade: modalidade,
                    tipoJulgamento: tipoJulgamento,
                    objeto: objeto,
                    dataAbertura: dataAbertura,
                    observacoes: observacoes,
                    itens: itensDTO,
                  ),
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(sucesso
                          ? 'Licitação criada.'
                          : provider.errorMessage ?? 'Falha ao criar licitação.'),
                    ),
                  );
                }
              },
              child: const Text('Criar licitação'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> exibirDialogPublicar(BuildContext context, LicitacaoModel l) async {
  final provider = context.read<LicitacoesProvider>();
  final fornecedoresAtivos = context
      .read<ComprasProvider>()
      .fornecedores
      .where((f) => f.ativo)
      .toList();

  if (fornecedoresAtivos.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Cadastre ao menos um fornecedor ativo no módulo Compras.')),
    );
    return;
  }

  final convidados = <String>{};

  await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return AlertDialog(
          title: Text('Publicar · ${l.numero}'),
          content: SizedBox(
            width: 480,
            child: SizedBox(
              height: 320,
              child: ListView(
                shrinkWrap: true,
                children: fornecedoresAtivos.map((f) {
                  return CheckboxListTile(
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(f.razaoSocial, overflow: TextOverflow.ellipsis),
                    value: convidados.contains(f.id),
                    onChanged: (marcado) {
                      setDialogState(() {
                        if (marcado == true) {
                          convidados.add(f.id);
                        } else {
                          convidados.remove(f.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (convidados.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Selecione ao menos um fornecedor para participar.')),
                  );
                  return;
                }
                final sucesso = await provider.publicarLicitacao(
                  l.id,
                  PublicarLicitacaoDTO(fornecedoresIds: convidados.toList()),
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(sucesso
                          ? 'Licitação publicada.'
                          : provider.errorMessage ?? 'Falha ao publicar licitação.'),
                    ),
                  );
                }
              },
              child: const Text('Publicar'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> exibirDialogRegistrarPropostas(
    BuildContext context, LicitacaoModel l) async {
  final provider = context.read<LicitacoesProvider>();
  final participantes = l.participantes.where((p) => p.habilitado).toList();

  if (l.itens.isEmpty || participantes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Licitação sem itens ou sem participantes habilitados.')),
    );
    return;
  }

  final form = GlobalKey<FormState>();
  String? fornecedorId = participantes.first.fornecedorId;
  final valores = <String, Map<String, TextEditingController>>{};
  for (final p in participantes) {
    final porMaterial = <String, TextEditingController>{};
    for (final item in l.itens) {
      final existente =
          l.propostas.where((prop) =>
              prop.fornecedorId == p.fornecedorId &&
              prop.materialId == item.materialId);
      porMaterial[item.materialId] = TextEditingController(
        text: existente.isNotEmpty
            ? existente.first.valorUnitario.toStringAsFixed(2).replaceAll('.', ',')
            : '',
      );
    }
    valores[p.fornecedorId] = porMaterial;
  }

  await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return AlertDialog(
          title: Text('Propostas · ${l.numero}'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: fornecedorId,
                      decoration: const InputDecoration(labelText: 'Fornecedor'),
                      items: participantes
                          .map((p) => DropdownMenuItem(
                                value: p.fornecedorId,
                                child: Text(p.fornecedorNome),
                              ))
                          .toList(),
                      onChanged: (v) => setDialogState(() => fornecedorId = v),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Itens da licitação ${l.numero}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                    ...l.itens.map((item) {
                      final controller =
                          valores[fornecedorId]![item.materialId];
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.descricao} (${item.unidadeMedida})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 160,
                            child: TextFormField(
                              controller: controller,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Valor unitário (R\$)',
                                isDense: true,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Informe o valor';
                                }
                                final valor =
                                    double.tryParse(v.replaceAll(',', '.'));
                                if (valor == null || valor < 0) {
                                  return 'Valor inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!form.currentState!.validate()) return;
                if (fornecedorId == null) return;
                final itensProposta = <LicitacaoPropostaDTO>[];
                for (final item in l.itens) {
                  final controller = valores[fornecedorId]![item.materialId]!;
                  itensProposta.add(LicitacaoPropostaDTO(
                    materialId: item.materialId,
                    valorUnitario: double.parse(controller.text.replaceAll(',', '.')),
                  ));
                }
                final sucesso = await provider.registrarPropostas(
                  l.id,
                  RegistrarPropostasLicitacaoDTO(
                    fornecedorId: fornecedorId!,
                    itens: itensProposta,
                  ),
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(sucesso
                          ? 'Propostas registradas.'
                          : provider.errorMessage ?? 'Falha ao registrar propostas.'),
                    ),
                  );
                }
              },
              child: const Text('Salvar propostas'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> _adjudicar(BuildContext context, LicitacaoModel l) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Adjudicar licitação'),
      content: Text(
          'Adjudicar a licitação ${l.numero}? Os vencedores por item serão definidos '
          'pelo menor valor de proposta.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Não'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Adjudicar'),
        ),
      ],
    ),
  );
  if (confirmar == true && context.mounted) {
    final ok = await context.read<LicitacoesProvider>().adjudicarLicitacao(l.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Licitação adjudicada.' : 'Falha ao adjudicar.')),
      );
    }
  }
}

Future<void> _homologar(BuildContext context, LicitacaoModel l) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Homologar licitação'),
      content: Text('Homologar a licitação ${l.numero}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Não'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Homologar'),
        ),
      ],
    ),
  );
  if (confirmar == true && context.mounted) {
    final ok = await context.read<LicitacoesProvider>().homologarLicitacao(l.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Licitação homologada.' : 'Falha ao homologar.')),
      );
    }
  }
}

Future<void> _cancelar(BuildContext context, LicitacaoModel l) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cancelar licitação'),
      content: Text('Deseja cancelar a licitação ${l.numero}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Não'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Sim, cancelar'),
        ),
      ],
    ),
  );
  if (confirmar == true && context.mounted) {
    final ok = await context.read<LicitacoesProvider>().cancelarLicitacao(l.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Licitação cancelada.' : 'Falha ao cancelar.')),
      );
    }
  }
}

Future<void> _gerarPedidos(BuildContext context, LicitacaoModel l) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Gerar pedidos'),
      content: Text(
          'Gerar pedidos de compra a partir da licitação ${l.numero}? Será criado um '
          'pedido por fornecedor vencedor.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Não'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Gerar pedidos'),
        ),
      ],
    ),
  );
  if (confirmar == true && context.mounted) {
    final ok = await context.read<LicitacoesProvider>().gerarPedidos(l.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              ok ? 'Pedidos gerados a partir da licitação.' : 'Falha ao gerar pedidos.'),
        ),
      );
    }
  }
}

class _LinhaInfo extends StatelessWidget {
  final String label;
  final String valor;

  const _LinhaInfo({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final LicitacaoModel licitacao;

  const _StatusChip({required this.licitacao});

  Color get _cor => switch (licitacao.status) {
        'EM_ELABORACAO' => const Color(0xFF8D6E63),
        'PUBLICADA' || 'ABERTA' => const Color(0xFF1565C0),
        'ADJUDICADA' => const Color(0xFFEF6C00),
        'HOMOLOGADA' => const Color(0xFF2E7D32),
        'CANCELADA' => Colors.grey[700]!,
        _ => Colors.grey[700]!,
      };

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(licitacao.statusLabel),
      labelStyle: TextStyle(fontSize: 11, color: _cor),
      backgroundColor: _cor.withValues(alpha: 0.10),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color cor;

  const _MetricChip({required this.icon, required this.label, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: cor),
      label: Text(label),
      labelStyle: TextStyle(fontSize: 12, color: cor),
      backgroundColor: cor.withValues(alpha: 0.08),
    );
  }
}

class _ItemLicitacao {
  final String id;
  String? materialId;
  final TextEditingController qtdController;

  _ItemLicitacao({required this.id, required this.qtdController});
}