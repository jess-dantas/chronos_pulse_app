import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/csv_export.dart';
import '../../data/models/patrimonio_models.dart';
import '../providers/inventario_provider.dart';
import '../providers/patrimonio_provider.dart';
import '../providers/transferencia_provider.dart';
import 'desfazimento_screen.dart';
import 'dialogs/editar_bem_dialog.dart';
import 'dialogs/novo_bem_dialog.dart';
import 'inventario_screen.dart';
import 'transferencia_screen.dart';

class PatrimonioHomeScreen extends StatefulWidget {
  const PatrimonioHomeScreen({super.key});

  @override
  State<PatrimonioHomeScreen> createState() => _PatrimonioHomeScreenState();
}

class _PatrimonioHomeScreenState extends State<PatrimonioHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatrimonioProvider>().carregarBens();
      context.read<InventarioProvider>().carregarInventarios();
      context.read<TransferenciaProvider>().carregarTransferencias();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.inventory, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Patrimônio Público'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: () {
              context.read<PatrimonioProvider>().carregarBens();
              context.read<InventarioProvider>().carregarInventarios();
              context.read<TransferenciaProvider>().carregarTransferencias();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Bens'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Inventário'),
            Tab(icon: Icon(Icons.swap_horiz), text: 'Transferências'),
            Tab(icon: Icon(Icons.remove_circle_outline), text: 'Desfazimento'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _BensPatrimonioTab(),
          InventarioScreen(),
          TransferenciaScreen(),
          DesfazimentoScreen(),
        ],
      ),
    );
  }
}

class _BensPatrimonioTab extends StatefulWidget {
  const _BensPatrimonioTab();

  @override
  State<_BensPatrimonioTab> createState() => _BensPatrimonioTabState();
}

class _BensPatrimonioTabState extends State<_BensPatrimonioTab> {
  final _buscaCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _buscaCtrl.dispose();
    super.dispose();
  }

  void _aoBuscar(String texto) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<PatrimonioProvider>().buscarBens(texto);
    });
  }

  Future<void> _abrirNovoBem() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const NovoBemDialog(),
    );
    if (ok == true && mounted) {
      context.read<PatrimonioProvider>().carregarBens();
    }
  }

  Future<void> _editar(PatrimonioModel bem) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => EditarBemDialog(bem: bem),
    );
    if (ok == true && mounted) {
      _mostrarMensagem('Bem atualizado.');
    }
  }

  Future<void> _desativar(PatrimonioModel bem) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inativar Bem'),
        content: Text(
          'Inativar o bem "${bem.descricao}"? Ele deixará de aparecer em novos inventários e não poderá ser transferido.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Inativar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    final ok = await context.read<PatrimonioProvider>().desativarBem(bem.id);
    if (!mounted) return;
    _mostrarMensagem(ok ? 'Bem inativado.' : 'Erro ao inativar bem.', vermelho: !ok);
  }

  void _detalhes(PatrimonioModel bem) {
    showDialog(context: context, builder: (_) => _DetalheBemDialog(bem: bem));
  }

  void _mostrarMensagem(String mensagem, {bool vermelho = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: vermelho ? Colors.redAccent : Colors.green),
    );
  }

  Future<void> _exportarCsv(List<PatrimonioModel> bens) async {
    if (bens.isEmpty) {
      _mostrarMensagem('Sem bens para exportar.', vermelho: true);
      return;
    }
    final exportado = await CsvExport.exportar(
      arquivoNome: 'patrimonio_${DateTime.now().toIso8601String().substring(0, 10)}.csv',
      cabecalho: const [
        'Tombamento',
        'Descrição',
        'Categoria',
        'Estado',
        'Localização',
        'Data de Aquisição',
        'Valor de Aquisição (R\$)',
        'Valor Atual (R\$)',
        'Depreciação Acumulada (R\$)',
        'Vida Útil (meses)',
        'Responsável',
        'Nota Fiscal',
        'Observações',
      ],
      linhas: bens.map((b) {
        return [
          b.tombamento ?? '',
          b.descricao,
          b.categoria ?? '',
          b.estado,
          b.localizacao ?? '',
          b.dataAquisicao ?? '',
          b.valorAquisicao ?? '',
          b.valorAtual ?? b.valorAquisicao ?? '',
          b.valorDepreciado ?? '',
          b.vidaUtilMeses ?? '',
          b.responsavelNome ?? '',
          b.numeroNotaFiscal ?? '',
          b.observacoes ?? '',
        ];
      }).toList(),
    );
    if (mounted && exportado) {
      _mostrarMensagem('CSV exportado com sucesso.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatrimonioProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buscaCtrl,
                  onChanged: _aoBuscar,
                  decoration: InputDecoration(
                    hintText: 'Buscar por tombamento ou descrição...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: provider.buscando
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _buscaCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                tooltip: 'Limpar busca',
                                onPressed: () {
                                  _buscaCtrl.clear();
                                  context.read<PatrimonioProvider>().carregarBens();
                                },
                              ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.file_download_outlined),
                tooltip: 'Exportar CSV',
                onPressed: () => _exportarCsv(provider.bens),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Novo Bem'),
                onPressed: _abrirNovoBem,
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              provider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => context.read<PatrimonioProvider>().carregarBens(),
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : provider.bens.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('Nenhum bem patrimonial cadastrado.'),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.bens.length + (provider.hasMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            if (index >= provider.bens.length) {
                              return Center(
                                child: OutlinedButton.icon(
                                  onPressed: provider.carregandoMais
                                      ? null
                                      : () => context.read<PatrimonioProvider>().carregarMaisBens(),
                                  icon: provider.carregandoMais
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.expand_more),
                                  label: const Text('Carregar mais bens'),
                                ),
                              );
                            }
                            final bem = provider.bens[index];
                            return _cardBem(bem);
                          },
                        ),
        ),
      ],
    );
  }

  Widget _cardBem(PatrimonioModel bem) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _detalhes(bem),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: AppTheme.lilasSurface(context),
            child: Icon(Icons.inventory, color: AppTheme.onLilasSurface(context)),
          ),
          title: Text(
            bem.descricao,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Tombamento: ${bem.tombamento ?? '—'} | Categoria: ${bem.categoria ?? '—'}',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
              if (bem.localizacao != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Local: ${bem.localizacao}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
              if (bem.valorAquisicao != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Valor: R\$ ${bem.valorAtual ?? bem.valorAquisicao}'
                  '${bem.valorDepreciado != null && bem.valorDepreciado != '0' ? ' (depreciação R\$ ${bem.valorDepreciado})' : ''}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _estadoChip(bem.estado),
              PopupMenuButton<String>(
                tooltip: 'Ações',
                onSelected: (acao) {
                  switch (acao) {
                    case 'detalhes':
                      _detalhes(bem);
                    case 'editar':
                      _editar(bem);
                    case 'desativar':
                      _desativar(bem);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'detalhes', child: ListTile(
                    leading: Icon(Icons.visibility_outlined),
                    title: Text('Detalhes'),
                    contentPadding: EdgeInsets.zero,
                  )),
                  PopupMenuItem(value: 'editar', child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar'),
                    contentPadding: EdgeInsets.zero,
                  )),
                  PopupMenuItem(value: 'desativar', child: ListTile(
                    leading: Icon(Icons.block_outlined, color: Colors.red),
                    title: Text('Inativar', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _estadoChip(String estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.lilasSurface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: AppTheme.onLilasSurface(context),
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _DetalheBemDialog extends StatelessWidget {
  final PatrimonioModel bem;

  const _DetalheBemDialog({required this.bem});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Detalhes do Bem — ${bem.tombamento ?? bem.descricao}'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _linha('Descrição', bem.descricao),
              _linha('Tombamento', bem.tombamento ?? '—'),
              _linha('Categoria', bem.categoria ?? '—'),
              _linha('Estado', bem.estado),
              _linha('Localização', bem.localizacao ?? '—'),
              _linha('Data de Aquisição', bem.dataAquisicao ?? '—'),
              _linha('Valor de Aquisição', bem.valorAquisicao != null ? 'R\$ ${bem.valorAquisicao}' : '—'),
              _linha('Valor Atual', bem.valorAtual != null ? 'R\$ ${bem.valorAtual}' : bem.valorAquisicao != null ? 'R\$ ${bem.valorAquisicao}' : '—'),
              _linha('Depreciação Acumulada', bem.valorDepreciado != null ? 'R\$ ${bem.valorDepreciado}' : 'R\$ 0'),
              _linha('Vida Útil', bem.vidaUtilMeses != null ? '${bem.vidaUtilMeses} meses' : '—'),
              _linha('Taxa Depreciação Mensal', bem.taxaDepreciacaoMensal != null ? '${bem.taxaDepreciacaoMensal}/mês' : '—'),
              _linha('Início da Depreciação', bem.dataInicioDepreciacao ?? '—'),
              _linha('Responsável', bem.responsavelNome ?? '—'),
              _linha('Nota Fiscal', bem.numeroNotaFiscal ?? '—'),
              _linha('Observações', bem.observacoes ?? '—'),
              _linha('Situação', bem.ativo ? 'Ativo' : 'Inativo'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
      ],
    );
  }

  Widget _linha(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              rotulo,
              style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}