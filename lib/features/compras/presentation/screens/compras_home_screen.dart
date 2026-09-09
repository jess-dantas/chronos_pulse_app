import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/compras_provider.dart';
import '../../../estoque/presentation/providers/estoque_provider.dart';
import 'compras_cotacoes_tab.dart';
import 'compras_fornecedores_tab.dart';
import 'compras_nfe_tab.dart';
import 'compras_pedidos_tab.dart';
import 'compras_precos_tab.dart';
import 'compras_requisicoes_tab.dart';

class ComprasHomeScreen extends StatefulWidget {
  const ComprasHomeScreen({super.key});

  @override
  State<ComprasHomeScreen> createState() => _ComprasHomeScreenState();
}

class _ComprasHomeScreenState extends State<ComprasHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final comprasProvider = context.watch<ComprasProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shopping_cart_outlined, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('CP Compras & Fornecedores'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(
              icon: Icon(Icons.storefront_outlined),
              text: 'Fornecedores',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: comprasProvider.pedidosEmitidos > 0,
                label: Text('${comprasProvider.pedidosEmitidos}'),
                child: const Icon(Icons.receipt_long_outlined),
              ),
              text: 'Pedidos',
            ),
            Tab(
              icon: const Icon(Icons.request_page_outlined),
              text: 'Requisições',
            ),
            Tab(
              icon: const Icon(Icons.handshake_outlined),
              text: 'Cotações',
            ),
            const Tab(
              icon: Icon(Icons.qr_code_2_outlined),
              text: 'NFe',
            ),
            const Tab(
              icon: Icon(Icons.stacked_bar_chart_outlined),
              text: 'Preços',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ComprasFornecedoresTab(),
          ComprasPedidosTab(),
          ComprasRequisicoesTab(),
          ComprasCotacoesTab(),
          ComprasNfeTab(),
          ComprasPrecosTab(),
        ],
      ),
    );
  }
}