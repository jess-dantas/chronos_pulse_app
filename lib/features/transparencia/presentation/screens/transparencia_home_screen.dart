import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/transparencia_models.dart';
import '../providers/transparencia_provider.dart';

final NumberFormat _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class TransparenciaHomeScreen extends StatefulWidget {
  const TransparenciaHomeScreen({super.key});

  @override
  State<TransparenciaHomeScreen> createState() => _TransparenciaHomeScreenState();
}

class _TransparenciaHomeScreenState extends State<TransparenciaHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransparenciaProvider>().carregarTudo();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _abrirNovaPublicacao() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _NovaPublicacaoDialog(),
    );
    if (ok == true && mounted) context.read<TransparenciaProvider>().carregarTudo();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransparenciaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.public, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('CP Portal da Transparência'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Indicadores'),
            Tab(icon: Icon(Icons.show_chart), text: 'Despesas'),
            Tab(
              icon: Icon(Icons.article_outlined),
              text: 'Publicações (LC 131)',
            ),
          ],
        ),
      ),
      floatingActionButton: provider.hasData
          ? FloatingActionButton.extended(
              onPressed: _abrirNovaPublicacao,
              icon: const Icon(Icons.add),
              label: const Text('Nova Publicação'),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: const [
          _IndicadoresTab(),
          _DespesasTab(),
          _PublicacoesTab(),
        ],
      ),
    );
  }
}

class _IndicadoresTab extends StatelessWidget {
  const _IndicadoresTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransparenciaProvider>();

    if (provider.isLoading && !provider.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && !provider.hasData) {
      return _ErroWidget(mensagem: provider.errorMessage!);
    }
    final resumo = provider.resumo;
    if (resumo == null) {
      return const Center(child: Text('Sem dados para exibir.'));
    }

    return RefreshIndicator(
      onRefresh: () => context.read<TransparenciaProvider>().carregarTudo(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _ValorCard(
                titulo: 'Despesas contratadas (empenhado)',
                valor: _moeda.format(resumo.contratos.valorEmpenhado),
                icone: Icons.assignment_turned_in_outlined,
                cor: Colors.deepPurple,
              ),
              const SizedBox(width: 12),
              _ValorCard(
                titulo: 'Saldo a liquidar',
                valor: _moeda.format(resumo.contratos.saldoTotal),
                icone: Icons.account_balance_wallet_outlined,
                cor: Colors.orange.shade800,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ValorCardLargo(
            titulo: 'Contratos ativos (${resumo.contratos.ativos})',
            valor:
                '${resumo.contratos.vencendo30Dias} vencendo em até 30 dias · ${resumo.contratos.vencidos} vencidos',
            icone: Icons.description_outlined,
          ),
          const SizedBox(height: 20),
          const _SecaoTitulo('Ativos & Patrimônio', Icons.inventory_outlined),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _IndicadorCard(
                rotulo: 'Valor do patrimônio',
                valor: _moeda.format(resumo.patrimonio.valorAtual),
                icone: Icons.home_work_outlined,
              ),
              _IndicadorCard(
                rotulo: 'Bens ativos',
                valor: '${resumo.patrimonio.bensAtivos} de ${resumo.patrimonio.totalBens}',
                icone: Icons.inventory_2_outlined,
              ),
              _IndicadorCard(
                rotulo: 'Estoque em valor (PMP)',
                valor: _moeda.format(resumo.estoque.valorTotalEstoque),
                icone: Icons.warehouse_outlined,
              ),
              _IndicadorCard(
                rotulo: 'Itens abaixo do mínimo',
                valor: '${resumo.estoque.abaixoDoMinimo}',
                icone: Icons.warning_amber_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SecaoTitulo('Compras, Licitações & Frota', Icons.receipt_long_outlined),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _IndicadorCard(
                rotulo: 'Pedidos emitidos',
                valor: '${resumo.compras.pedidosEmitidos} · ${_moeda.format(resumo.compras.valorPedidos)}',
                icone: Icons.shopping_cart_outlined,
              ),
              _IndicadorCard(
                rotulo: 'Notas recebidas',
                valor: '${resumo.compras.notasFiscaisRecebidas} · ${_moeda.format(resumo.compras.valorNotasFiscais)}',
                icone: Icons.receipt_outlined,
              ),
              _IndicadorCard(
                rotulo: 'Licitações (estimado)',
                valor: '${resumo.licitacoes.total} · ${_moeda.format(resumo.licitacoes.valorEstimadoTotal)}',
                icone: Icons.gavel_outlined,
              ),
              _IndicadorCard(
                rotulo: 'Combustível no mês',
                valor: _moeda.format(resumo.frota.valorAbastecimentosMes),
                icone: Icons.local_gas_station_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SecaoTitulo('Corpo Funcional', Icons.people_outline),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _IndicadorCard(
                rotulo: 'Colaboradores ativos',
                valor: '${resumo.colaboradores.ativos} de ${resumo.colaboradores.total}',
                icone: Icons.badge_outlined,
              ),
              _IndicadorCard(
                rotulo: 'Registros de ponto no mês',
                valor: '${resumo.ponto.registrosMes}',
                icone: Icons.fingerprint,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SecaoTitulo('Portal da Transparência', Icons.public),
          const SizedBox(height: 8),
          _ValorCardLargo(
            titulo: 'Publicações divulgadas',
            valor:
                '${resumo.publicacoes.publicadas} divulgadas · última competência ${resumo.publicacoes.ultimaCompetencia}',
            icone: Icons.verified_outlined,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DespesasTab extends StatelessWidget {
  const _DespesasTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransparenciaProvider>();

    if (provider.isLoading && provider.despesasMensais == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.despesasMensais == null) {
      return _ErroWidget(mensagem: provider.errorMessage!);
    }
    final despesas = provider.despesasMensais;
    if (despesas == null) {
      return const Center(child: Text('Sem dados para exibir.'));
    }

    final meses = despesas.meses;
    final totalAno = meses.fold<double>(0, (acc, m) => acc + m.total);
    final nomesMeses = _mesesPorExtenso;

    return RefreshIndicator(
      onRefresh: () => context.read<TransparenciaProvider>().carregarTudo(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ValorCardLargo(
            titulo: 'Total de despesas executadas em ${despesas.ano}',
            valor: _moeda.format(totalAno),
            icone: Icons.payments_outlined,
          ),
          const SizedBox(height: 20),
          const _SecaoTitulo('Despesa executada por mês', Icons.bar_chart_outlined),
          const SizedBox(height: 8),
          ...meses.map((m) {
            final nome = nomesMeses[m.mes - 1];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          _moeda.format(m.total),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${m.notasFiscais} notaf(s) · ${m.abastecimentos} abastecimento(s) · ${m.quantidadePedidos} pedido(s)',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: totalAno > 0 ? m.total / totalAno : 0,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(6),
                      backgroundColor: AppTheme.lilasSurface(context, lightAlpha: 0.12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'NFe: ${_moeda.format(m.despesasNfe)} · Combustível: ${_moeda.format(m.combustivel)}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static const _mesesPorExtenso = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];
}

class _PublicacoesTab extends StatelessWidget {
  const _PublicacoesTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransparenciaProvider>();

    if (provider.isLoading && provider.publicacoes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.publicacoes.isEmpty) {
      return _ErroWidget(mensagem: provider.errorMessage!);
    }

    return RefreshIndicator(
      onRefresh: () => context.read<TransparenciaProvider>().carregarPublicacoes(),
      child: provider.publicacoes.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 80),
                Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Center(
                  child: Text(
                    'Nenhuma publicação registrada.\nUse o botão "Nova Publicação" para divulgar a gestão.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Divulgação ativa das despesas por competência (LC 131/2009)',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ),
                ...provider.publicacoes.map((p) => _PublicacaoCard(publicacao: p)),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

class _PublicacaoCard extends StatelessWidget {
  final TransparenciaPublicacaoModel publicacao;

  const _PublicacaoCard({required this.publicacao});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransparenciaProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${publicacao.competencia} · ${publicacao.tipoRotulo}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Chip(
                  avatar: Icon(
                    publicacao.isPublicado ? Icons.verified : Icons.schedule,
                    size: 16,
                    color: publicacao.isPublicado ? Colors.green.shade700 : Colors.orange.shade800,
                  ),
                  label: Text(
                    publicacao.isPublicado ? 'Divulgado' : 'Em elaboração',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.payments_outlined, size: 18, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text(_moeda.format(publicacao.valorTotal)),
                const Spacer(),
                Text(
                  '${publicacao.itensCount} item(ns)',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            if (publicacao.observacoes != null && publicacao.observacoes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                publicacao.observacoes!,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
            if (publicacao.dataPublicacao != null) ...[
              const SizedBox(height: 8),
              Text(
                'Divulgado em ${publicacao.dataPublicacao}',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ],
            if (!publicacao.isPublicado)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final ok = await provider.publicar(publicacao.id);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Publicação divulgada no portal.')),
                          );
                        } else if (context.mounted && provider.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.errorMessage!)),
                          );
                        }
                      },
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Publicar'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final ok = await provider.remover(publicacao.id);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Publicação removida.')),
                          );
                        } else if (context.mounted && provider.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.errorMessage!)),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remover'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NovaPublicacaoDialog extends StatefulWidget {
  const _NovaPublicacaoDialog();

  @override
  State<_NovaPublicacaoDialog> createState() => _NovaPublicacaoDialogState();
}

class _NovaPublicacaoDialogState extends State<_NovaPublicacaoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _competenciaController = TextEditingController(text: '${DateTime.now().year}-MM');
  final _valorController = TextEditingController();
  final _itensController = TextEditingController();
  final _observacoesController = TextEditingController();
  String _tipo = 'DESPESAS';

  final _tipos = [
    ('DESPESAS', 'Despesas'),
    ('RECEITAS', 'Receitas'),
    ('COMPRAS', 'Compras'),
    ('LICITACOES', 'Licitações'),
    ('CONTRATOS', 'Contratos'),
    ('FROTA', 'Frota'),
    ('PATRIMONIO', 'Patrimônio'),
    ('FOLHA', 'Folha'),
  ];

  @override
  void dispose() {
    _competenciaController.dispose();
    _valorController.dispose();
    _itensController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TransparenciaProvider>();
    final ok = await provider.criarPublicacao({
      'competencia': _competenciaController.text,
      'tipoPublicacao': _tipo,
      'valorTotal': _valorController.text.isNotEmpty ? _valorController.text : null,
      'itensCount': _itensController.text.isNotEmpty ? _itensController.text : null,
      'observacoes': _observacoesController.text.isNotEmpty ? _observacoesController.text : null,
    });
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Falha ao criar publicação')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Publicação'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: _tipos
                    .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                    .toList(),
                onChanged: (v) => setState(() => _tipo = v ?? 'DESPESAS'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _competenciaController,
                decoration: const InputDecoration(
                  labelText: 'Competência (AAAA-MM)',
                  hintText: '2026-08',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final valor = v?.trim() ?? '';
                  final regex = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');
                  if (!regex.hasMatch(valor)) return 'Use o formato AAAA-MM';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valorController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor total (R\$)',
                  hintText: '0,00',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _itensController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade de itens',
                  hintText: '0',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacoesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _salvar,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _ValorCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;

  const _ValorCard({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: cor, semanticLabel: titulo),
              const SizedBox(height: 12),
              Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(titulo, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValorCardLargo extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;

  const _ValorCardLargo({
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icone, color: Colors.deepPurple, semanticLabel: titulo),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(valor,
                      style:
                          const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicadorCard extends StatelessWidget {
  final String rotulo;
  final String valor;
  final IconData icone;

  const _IndicadorCard({
    required this.rotulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 22, color: Colors.deepPurple, semanticLabel: rotulo),
            const Spacer(),
            Text(valor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(rotulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700], fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _SecaoTitulo extends StatelessWidget {
  final String titulo;
  final IconData icone;

  const _SecaoTitulo(this.titulo, this.icone);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 18, color: Colors.deepPurple, semanticLabel: titulo),
        const SizedBox(width: 8),
        Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ErroWidget extends StatelessWidget {
  final String mensagem;

  const _ErroWidget({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            const Text('Não foi possível carregar os dados.'),
            const SizedBox(height: 8),
            Text(mensagem, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.read<TransparenciaProvider>().carregarTudo(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}