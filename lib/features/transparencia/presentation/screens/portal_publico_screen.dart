import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/portal_publico_models.dart';
import '../../data/models/transparencia_models.dart';
import '../providers/portal_publico_provider.dart';

final NumberFormat _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class PortalPublicoScreen extends StatefulWidget {
  final String slug;

  const PortalPublicoScreen({super.key, required this.slug});

  @override
  State<PortalPublicoScreen> createState() => _PortalPublicoScreenState();
}

class _PortalPublicoScreenState extends State<PortalPublicoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortalPublicoProvider>().carregarTudo(widget.slug);
    });
  }

  Future<void> _abrirLicitacao(PortalLicitacaoModel licitacao) async {
    final provider = context.read<PortalPublicoProvider>();
    provider.limparDetalhes();
    await provider.carregarDetalheLicitacao(widget.slug, licitacao.id);
    if (!mounted) return;
    final detalhe = provider.licitacaoDetalhe;
    if (detalhe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Não foi possível abrir a licitação')),
      );
      return;
    }
    if (mounted) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _DetalheLicitacaoSheet(detalhe: detalhe),
      );
    }
  }

  Future<void> _abrirContrato(PortalContratoModel contrato) async {
    final provider = context.read<PortalPublicoProvider>();
    provider.limparDetalhes();
    await provider.carregarDetalheContrato(widget.slug, contrato.id);
    if (!mounted) return;
    final detalhe = provider.contratoDetalhe;
    if (detalhe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Não foi possível abrir o contrato')),
      );
      return;
    }
    if (mounted) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _DetalheContratoSheet(detalhe: detalhe),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortalPublicoProvider>();

    if (provider.isLoading && !provider.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && !provider.hasData) {
      return _ErroPortal(mensagem: provider.errorMessage!, slug: widget.slug);
    }
    final resumo = provider.resumo;
    if (resumo == null) {
      return const Center(child: Text('Sem dados para exibir.'));
    }

    return RefreshIndicator(
      onRefresh: () => context.read<PortalPublicoProvider>().carregarTudo(widget.slug),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OrgaoCard(orgao: resumo.orgao),
          const SizedBox(height: 12),
          Row(
            children: [
              _ValorCard(
                titulo: 'Licitações públicas',
                valor: '${resumo.licitacoesPublicadas}',
                icone: Icons.gavel_outlined,
                cor: Colors.deepPurple,
              ),
              const SizedBox(width: 12),
              _ValorCard(
                titulo: 'Em andamento',
                valor: '${resumo.licitacoesEmAndamento}',
                icone: Icons.trending_up,
                cor: Colors.deepPurple,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ValorCard(
                titulo: 'Homologadas',
                valor: '${resumo.licitacoesHomologadas}',
                icone: Icons.verified_outlined,
                cor: Colors.deepPurple,
              ),
              const SizedBox(width: 12),
              _ValorCard(
                titulo: 'Contratos ativos',
                valor: '${resumo.contratosAtivos}',
                icone: Icons.description_outlined,
                cor: Colors.deepPurple,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ValorCardLargo(
            titulo: 'Despesas do ano',
            valor: _moeda.format(resumo.valorDespesasAno),
            icone: Icons.payments_outlined,
          ),
          const SizedBox(height: 12),
          _ValorCardLargo(
            titulo: 'Valor empenhado (em execução)',
            valor: _moeda.format(resumo.valorEmpenhado),
            icone: Icons.assignment_turned_in_outlined,
          ),
          const SizedBox(height: 12),
          _ValorCardLargo(
            titulo: 'Valor liquidado',
            valor: _moeda.format(resumo.valorLiquidado),
            icone: Icons.verified_user_outlined,
          ),
          const SizedBox(height: 20),
          const _SecaoTitulo('Licitações em divulgação', Icons.gavel_outlined),
          const SizedBox(height: 8),
          if (provider.licitacoes.isEmpty)
            const _SemDados(texto: 'Nenhuma licitação em divulgação.')
          else
            ...provider.licitacoes.map(
              (l) => _PortalLicitacaoTile(licitacao: l, onTap: () => _abrirLicitacao(l)),
            ),
          const SizedBox(height: 20),
          const _SecaoTitulo('Contratos', Icons.receipt_long_outlined),
          const SizedBox(height: 8),
          if (provider.contratos.isEmpty)
            const _SemDados(texto: 'Nenhum contrato em divulgação.')
          else
            ...provider.contratos.map(
              (c) => _PortalContratoTile(contrato: c, onTap: () => _abrirContrato(c)),
            ),
          const SizedBox(height: 20),
          const _SecaoTitulo('Publicações (LC 131/2009)', Icons.verified_outlined),
          const SizedBox(height: 8),
          if (provider.publicacoes.isEmpty)
            const _SemDados(texto: 'Nenhuma publicação divulgada.')
          else
            ...provider.publicacoes.map((p) => _PortalPublicacaoCard(publicacao: p)),
          const SizedBox(height: 20),
          const _SecaoTitulo('Despesas mensais', Icons.bar_chart_outlined),
          const SizedBox(height: 8),
          _DespesasMensaisCards(despesas: provider.despesasMensais),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _OrgaoCard extends StatelessWidget {
  final PortalOrgaoModel orgao;

  const _OrgaoCard({required this.orgao});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.lilasSurface(context, lightAlpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.domain, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orgao.nome,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Portal público · ${orgao.slug}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'CNPJ ${_formatarCnpj(orgao.cnpj)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarCnpj(String cnpj) {
    final digitos = cnpj.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 14) return cnpj;
    return '${digitos.substring(0, 2)}.${digitos.substring(2, 5)}.'
        '${digitos.substring(5, 8)}/${digitos.substring(8, 12)}-${digitos.substring(12)}';
  }
}

class _PortalLicitacaoTile extends StatelessWidget {
  final PortalLicitacaoModel licitacao;
  final VoidCallback onTap;

  const _PortalLicitacaoTile({required this.licitacao, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.request_quote_outlined, color: Colors.deepPurple),
        title: Text(
          '${licitacao.numero} · ${licitacao.modalidadeRotulo}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              licitacao.objeto,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Estimado: ${_moeda.format(licitacao.valorEstimado)}',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: onTap,
      ),
    );
  }
}

class _PortalContratoTile extends StatelessWidget {
  final PortalContratoModel contrato;
  final VoidCallback onTap;

  const _PortalContratoTile({required this.contrato, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.description_outlined, color: Colors.deepPurple),
        title: Text(contrato.numero, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contrato.objeto,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Total: ${_moeda.format(contrato.valorTotal)}',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: onTap,
      ),
    );
  }
}

class _PortalPublicacaoCard extends StatelessWidget {
  final PortalPublicacaoModel publicacao;

  const _PortalPublicacaoCard({required this.publicacao});

  @override
  Widget build(BuildContext context) {
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
                    '${publicacao.competencia} · ${_tipoRotulo(publicacao.tipoPublicacao)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Chip(
                  avatar: Icon(Icons.verified, size: 16, color: Colors.green.shade700),
                  label: const Text(
                    'Divulgado',
                    style: TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_moeda.format(publicacao.valorTotal)} · ${publicacao.itensCount} item(ns)',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            if (publicacao.dataPublicacao != null) ...[
              const SizedBox(height: 4),
              Text(
                'Divulgado em ${publicacao.dataPublicacao}',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _tipoRotulo(String tipo) => switch (tipo) {
        'RECEITAS' => 'Receitas',
        'DESPESAS' => 'Despesas',
        'COMPRAS' => 'Compras',
        'LICITACOES' => 'Licitações',
        'CONTRATOS' => 'Contratos',
        'FROTA' => 'Frota',
        'PATRIMONIO' => 'Patrimônio',
        'FOLHA' => 'Folha',
        _ => tipo,
      };
}

class _DespesasMensaisCards extends StatelessWidget {
  final DespesasMensaisModel? despesas;

  const _DespesasMensaisCards({this.despesas});

  static const _mesesPorExtenso = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  @override
  Widget build(BuildContext context) {
    final d = despesas;
    if (d == null || d.meses.isEmpty) {
      return const _SemDados(texto: 'Sem despesas divulgadas para o período.');
    }
    final totalAno = d.meses.fold<double>(0, (acc, m) => acc + m.total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total no ano: ${_moeda.format(totalAno)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...d.meses.where((m) => m.total > 0).map((m) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_mesesPorExtenso[m.mes - 1], style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    _moeda.format(m.total),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _DetalheLicitacaoSheet extends StatelessWidget {
  final PortalLicitacaoDetalheModel detalhe;

  const _DetalheLicitacaoSheet({required this.detalhe});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                '${detalhe.numero} · ${detalhe.modalidade}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Situação: ${detalhe.status} · Julgamento: ${detalhe.tipoJulgamento}',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
              if (detalhe.dataAbertura != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Abertura: ${detalhe.dataAbertura}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
              const SizedBox(height: 8),
              Text(detalhe.objeto, style: const TextStyle(fontSize: 14)),
              if (detalhe.observacoes != null && detalhe.observacoes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  detalhe.observacoes!,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Estimado: ${_moeda.format(detalhe.valorEstimado)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const Text('Itens', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              if (detalhe.itens.isEmpty)
                const Text('Sem itens informados.', style: TextStyle(color: Colors.black54))
              else
                ...detalhe.itens.map(
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${i.descricao}\nQtd: ${i.quantidade}',
                            style: TextStyle(color: Colors.grey[800], fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _moeda.format(i.valorEstimadoTotal),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DetalheContratoSheet extends StatelessWidget {
  final PortalContratoDetalheModel detalhe;

  const _DetalheContratoSheet({required this.detalhe});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                detalhe.numero,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Situação: ${detalhe.status}',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(detalhe.objeto, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                'Total: ${_moeda.format(detalhe.valorTotal)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Empenhado: ${_moeda.format(detalhe.valorEmpenhado)} · '
                'Liquidado: ${_moeda.format(detalhe.valorLiquidado)}',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
              if (detalhe.empenhoNumero != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Empenho: ${detalhe.empenhoNumero}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Aditivos', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              if (detalhe.aditivos.isEmpty)
                const Text('Sem aditivos.', style: TextStyle(color: Colors.black54))
              else
                ...detalhe.aditivos.map(
                  (a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${a.tipo}${a.aprovado ? '' : ' (pendente de aprovação)'}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          a.descricao,
                          style: TextStyle(color: Colors.grey[800], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text('Sanções', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              if (detalhe.sancoes.isEmpty)
                const Text('Sem sanções.', style: TextStyle(color: Colors.black54))
              else
                ...detalhe.sancoes.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.tipo} · ${_moeda.format(s.valorMulta)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          s.descricao,
                          style: TextStyle(color: Colors.grey[800], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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

  const _ValorCardLargo({required this.titulo, required this.valor, required this.icone});

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
                  Text(titulo, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(valor, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
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

class _SemDados extends StatelessWidget {
  final String texto;

  const _SemDados({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(texto, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
    );
  }
}

class _ErroPortal extends StatelessWidget {
  final String mensagem;
  final String slug;

  const _ErroPortal({required this.mensagem, required this.slug});

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
            const Text('Não foi possível carregar o portal público.'),
            const SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifique se o portal de transparência está ativo para este órgão.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.read<PortalPublicoProvider>().carregarTudo(slug),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}