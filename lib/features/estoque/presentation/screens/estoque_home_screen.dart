import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/estoque_provider.dart';
import 'estoque_saldos_tab.dart';
import 'estoque_requisicoes_tab.dart';

class EstoqueHomeScreen extends StatefulWidget {
  const EstoqueHomeScreen({super.key});

  @override
  State<EstoqueHomeScreen> createState() => _EstoqueHomeScreenState();
}

class _EstoqueHomeScreenState extends State<EstoqueHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final estoqueProvider = context.watch<EstoqueProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.inventory, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('CP Estoque & Almoxarifado'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(
              icon: Icon(Icons.table_chart_outlined),
              text: 'Saldos & Almoxarifado',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: estoqueProvider.totalRequisicoesPendentes > 0,
                label: Text('${estoqueProvider.totalRequisicoesPendentes}'),
                child: const Icon(Icons.assignment_turned_in_outlined),
              ),
              text: 'Requisições Públicas',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          EstoqueSaldosTab(),
          EstoqueRequisicoesTab(),
        ],
      ),
    );
  }
}
