import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/csv_export.dart';
import '../providers/frota_provider.dart';
import 'dialogs/novo_abastecimento_dialog.dart';
import 'dialogs/novo_veiculo_dialog.dart';

class FrotaHomeScreen extends StatefulWidget {
  const FrotaHomeScreen({super.key});

  @override
  State<FrotaHomeScreen> createState() => _FrotaHomeScreenState();
}

class _FrotaHomeScreenState extends State<FrotaHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FrotaProvider>().carregarTudo();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _abrirNovoVeiculo() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => const NovoVeiculoDialog());
    if (ok == true && mounted) context.read<FrotaProvider>().carregarTudo();
  }

  Future<void> _abrirNovoAbastecimento() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => const NovoAbastecimentoDialog());
    if (ok == true && mounted) context.read<FrotaProvider>().carregarTudo();
  }

  Future<void> _exportarCsv(FrotaProvider provider) async {
    if (_tabController.index == 0) {
      if (provider.veiculos.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sem veículos para exportar.')),
          );
        }
        return;
      }
      final exportado = await CsvExport.exportar(
        arquivoNome: 'frota_veiculos_${DateTime.now().toIso8601String().substring(0, 10)}.csv',
        cabecalho: const [
          'Placa',
          'Renavam',
          'Marca',
          'Modelo',
          'Ano Fabricação',
          'Ano Modelo',
          'Tipo',
          'Combustível',
          'Status',
          'Odômetro (km)',
          'Ativo',
        ],
        linhas: provider.veiculos.map((v) {
          return [
            v.placa,
            v.renavam ?? '',
            v.marca ?? '',
            v.modelo ?? '',
            v.anoFabricacao?.toString() ?? '',
            v.anoModelo?.toString() ?? '',
            v.tipo ?? '',
            v.combustivel ?? '',
            v.status,
            v.odometroAtual != null ? _fmtNum(v.odometroAtual) : '',
            v.ativo ? 'SIM' : 'NÃO',
          ];
        }).toList(),
      );
      if (mounted && exportado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exportado com sucesso.')),
        );
      }
      return;
    }

    if (provider.abastecimentos.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sem abastecimentos para exportar.')),
        );
      }
      return;
    }
    final exportado = await CsvExport.exportar(
      arquivoNome: 'frota_abastecimentos_${DateTime.now().toIso8601String().substring(0, 10)}.csv',
      cabecalho: const [
        'Data/Hora',
        'Veículo (Placa)',
        'Litros',
        'Valor por Litro (R\$)',
        'Valor Total (R\$)',
        'Odômetro (km)',
        'Posto',
        'Observações',
      ],
      linhas: provider.abastecimentos.map((a) {
        return [
          a.dataHora.replaceFirst('T', ' '),
          a.veiculoPlaca,
          _fmtNum(a.litros),
          _fmtNum(a.valorLitro, 4),
          _fmtNum(a.valorTotal, 2),
          a.odometroKm != null ? _fmtNum(a.odometroKm) : '',
          a.posto ?? '',
          a.observacoes ?? '',
        ];
      }).toList(),
    );
    if (mounted && exportado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV exportado com sucesso.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrotaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_shipping, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Gestão de Frota'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Exportar CSV da aba atual',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _exportarCsv(provider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.directions_car_outlined),
              text: 'Veículos',
            ),
            Tab(
              icon: Icon(Icons.local_gas_station_outlined),
              text: 'Abastecimentos',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tabController.index == 0 ? _abrirNovoVeiculo : _abrirNovoAbastecimento,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Novo Veículo' : 'Registrar Abastecimento'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVeiculos(provider),
          _buildAbastecimentos(provider),
        ],
      ),
    );
  }

  Widget _buildVeiculos(FrotaProvider provider) {
    if (provider.isLoading && provider.veiculos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.veiculos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(provider.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.read<FrotaProvider>().carregarTudo(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (provider.veiculos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Nenhum veículo cadastrado.'),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.veiculos.length + (provider.hasMoreVeiculos ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= provider.veiculos.length) {
          return Center(
            child: OutlinedButton.icon(
              onPressed: provider.carregandoMaisVeiculos
                  ? null
                  : () => context.read<FrotaProvider>().carregarMaisVeiculos(),
              icon: provider.carregandoMaisVeiculos
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more),
              label: const Text('Carregar mais veículos'),
            ),
          );
        }
        final v = provider.veiculos[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppTheme.lilasSurface(context),
              child: Icon(Icons.directions_car, color: AppTheme.onLilasSurface(context)),
            ),
            title: Text(
              '${v.marca ?? ''} ${v.modelo ?? ''}'.trim().isEmpty ? v.placa : '${v.marca ?? ''} ${v.modelo ?? ''} (${v.placa})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Placa: ${v.placa} | Tipo: ${v.tipo ?? '—'} | Combustível: ${v.combustivel ?? '—'}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                if (v.odometroAtual != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Odômetro: ${_fmtNum(v.odometroAtual)} km',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (v.status == 'ATIVO' ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                v.status,
                style: TextStyle(
                  color: (v.status == 'ATIVO' ? Colors.green : Colors.orange).shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAbastecimentos(FrotaProvider provider) {
    if (provider.isLoading && provider.abastecimentos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.abastecimentos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(provider.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.read<FrotaProvider>().carregarTudo(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (provider.abastecimentos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_gas_station_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Nenhum abastecimento registrado.'),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.abastecimentos.length + (provider.hasMoreAbastecimentos ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= provider.abastecimentos.length) {
          return Center(
            child: OutlinedButton.icon(
              onPressed: provider.carregandoMaisAbastecimentos
                  ? null
                  : () => context.read<FrotaProvider>().carregarMaisAbastecimentos(),
              icon: provider.carregandoMaisAbastecimentos
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more),
              label: const Text('Carregar mais abastecimentos'),
            ),
          );
        }
        final a = provider.abastecimentos[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              child: const Icon(Icons.local_gas_station, color: Colors.orange),
            ),
            title: Text(
              '${a.veiculoPlaca} — ${a.posto ?? 'Posto'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${_fmtNum(a.litros)} L × R\$ ${_fmtNum(a.valorLitro, 4)} = R\$ ${_fmtNum(a.valorTotal, 2)}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                if (a.dataHora.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    a.dataHora.replaceFirst('T', ' '),
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

String _fmtNum(double? valor, [int casas = 1]) {
  if (valor == null) return '—';
  return valor.toStringAsFixed(casas).replaceAll('.', ',');
}