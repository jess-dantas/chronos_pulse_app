import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/patrimonio_models.dart';
import '../providers/inventario_provider.dart';
import '../providers/patrimonio_provider.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  Future<void> _abrirNovoInventario() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _NovoInventarioDialog(),
    );
    if (ok == true && mounted) {
      _mostrarMensagem('Inventário criado.');
    }
  }

  Future<void> _conferir(InventarioModel inventario) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ConferirQRScreen(inventario: inventario),
      ),
    );
    if (ok == true && mounted) {
      context.read<InventarioProvider>().carregarInventarios();
    }
  }

  Future<void> _finalizar(InventarioModel inventario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar Inventário'),
        content: Text(
          'Itens ainda não conferidos serão marcados como divergência. '
          'Finalizar "${inventario.descricao}"?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Finalizar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    final ok = await context.read<InventarioProvider>().finalizar(inventario.id);
    if (mounted) {
      _mostrarMensagem(ok ? 'Inventário finalizado.' : 'Erro ao finalizar inventário.', vermelho: !ok);
    }
  }

  Future<void> _cancelar(InventarioModel inventario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Inventário'),
        content: Text('Cancelar o inventário "${inventario.descricao}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Cancelar Inventário'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    final ok = await context.read<InventarioProvider>().cancelar(inventario.id);
    if (mounted) {
      _mostrarMensagem(ok ? 'Inventário cancelado.' : 'Erro ao cancelar inventário.', vermelho: !ok);
    }
  }

  void _detalhes(InventarioModel inventario) {
    showDialog(
      context: context,
      builder: (_) => _DetalheInventarioDialog(
        inventario: inventario,
        onConferir: _conferir,
      ),
    );
  }

  void _mostrarMensagem(String mensagem, {bool vermelho = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: vermelho ? Colors.redAccent : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              const Icon(Icons.qr_code_scanner, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Text(
                'Inventário Físico',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar',
                onPressed: () => context.read<InventarioProvider>().carregarInventarios(),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Novo Inventário'),
                onPressed: _abrirNovoInventario,
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading && provider.inventarios.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : provider.errorMessage != null && provider.inventarios.isEmpty
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
                              onPressed: () => context.read<InventarioProvider>().carregarInventarios(),
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : provider.inventarios.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('Nenhum inventário criado.'),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.inventarios.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final i = provider.inventarios[index];
                            return _cardInventario(i);
                          },
                        ),
        ),
      ],
    );
  }

  Widget _cardInventario(InventarioModel i) {
    final emAndamento = i.status == 'EM_ANDAMENTO';
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _detalhes(i),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      i.descricao,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _statusChip(i.status),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${i.totalConferidos} de ${i.totalItens} itens conferidos'
                      '${i.totalDivergencias > 0 ? ' · ${i.totalDivergencias} divergências' : ''}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                  if (i.criadoEm != null)
                    Text(
                      i.criadoEm!.substring(0, 10),
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: i.progresso,
                  minHeight: 6,
                  backgroundColor: AppTheme.lilasSurface(context),
                  color: Colors.deepPurple,
                ),
              ),
              if (emAndamento) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.qr_code, size: 18),
                      label: const Text('Conferir via QR'),
                      onPressed: () => _conferir(i),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _finalizar(i),
                      child: const Text('Finalizar'),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () => _cancelar(i),
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final (cor, rotulo) = switch (status) {
      'EM_ANDAMENTO' => (Colors.deepPurple, 'EM ANDAMENTO'),
      'CONCLUIDO' => (Colors.teal, 'CONCLUÍDO'),
      'CANCELADO' => (Colors.redAccent, 'CANCELADO'),
      _ => (Colors.grey, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        rotulo,
        style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}

class _NovoInventarioDialog extends StatefulWidget {
  const _NovoInventarioDialog();

  @override
  State<_NovoInventarioDialog> createState() => _NovoInventarioDialogState();
}

class _NovoInventarioDialogState extends State<_NovoInventarioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoCtrl = TextEditingController();
  final _dataInicioCtrl = TextEditingController();
  final _dataFimCtrl = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _dataInicioCtrl.dispose();
    _dataFimCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    final ok = await context.read<InventarioProvider>().criar(
          descricao: _descricaoCtrl.text,
          dataInicio: _dataInicioCtrl.text,
          dataFim: _dataFimCtrl.text,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<InventarioProvider>().errorMessage ?? 'Erro ao criar inventário.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Inventário'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descricaoCtrl,
                decoration: const InputDecoration(labelText: 'Descrição *', prefixIcon: Icon(Icons.title)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a descrição' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dataInicioCtrl,
                      decoration: const InputDecoration(labelText: 'Início (AAAA-MM-DD)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _dataFimCtrl,
                      decoration: const InputDecoration(labelText: 'Fim (AAAA-MM-DD)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _salvando ? null : () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: _salvando ? null : _salvar,
          icon: _salvando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.playlist_add_check),
          label: Text(_salvando ? 'Criando...' : 'Criar'),
        ),
      ],
    );
  }
}

class _DetalheInventarioDialog extends StatefulWidget {
  final InventarioModel inventario;
  final void Function(InventarioModel inventario) onConferir;

  const _DetalheInventarioDialog({required this.inventario, required this.onConferir});

  @override
  State<_DetalheInventarioDialog> createState() => _DetalheInventarioDialogState();
}

class _DetalheInventarioDialogState extends State<_DetalheInventarioDialog> {
  late InventarioModel _inventario = widget.inventario;

  Future<void> _conferirManual(InventarioItemModel item) async {
    final pops = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _ConferirManualDialog(item: item),
    );
    if (pops == null || !mounted) return;
    final novo = await context.read<InventarioProvider>().conferirItem(
          _inventario.id,
          patrimonioId: item.patrimonioId,
          resultado: pops['resultado']!,
          observacao: pops['observacao'],
        );
    if (novo != null && mounted) {
      setState(() => _inventario = novo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = _inventario;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.qr_code_scanner, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Inventário — ${i.descricao}', overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${i.totalConferidos} de ${i.totalItens} conferidos · '
                '${i.totalConformes} conforme(s) · ${i.totalDivergencias} divergência(s)'
                '${i.dataInicio != null ? ' · Início: ${i.dataInicio!.substring(0, 10)}' : ''}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: i.progresso,
                  minHeight: 8,
                  backgroundColor: AppTheme.lilasSurface(context),
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 12),
              if (i.status == 'EM_ANDAMENTO')
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Conferir via QR Code'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onConferir(i);
                    },
                  ),
                ),
              const SizedBox(height: 8),
              if (i.itens.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Nenhum item neste inventário.'),
                )
              else
                ...i.itens.map((item) => _cardItem(item)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
      ],
    );
  }

  Widget _cardItem(InventarioItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: item.conferido ? (item.resultado == 'CONFORME' ? Colors.teal : Colors.redAccent).withValues(alpha: 0.06) : null,
      child: ListTile(
        dense: true,
        leading: Icon(
          item.conferido ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          color: item.conferido ? (item.resultado == 'CONFORME' ? Colors.teal : Colors.redAccent) : Colors.grey,
        ),
        title: Text(item.patrimonioDescricao ?? 'Bem'),
        subtitle: Text(
          '${item.patrimonioTombamento ?? '—'}'
          '${item.resultado != null ? ' · ${item.resultado}' : ''}'
          '${item.observacao != null && item.observacao!.isNotEmpty ? ' · ${item.observacao}' : ''}',
          style: TextStyle(color: Colors.grey[700], fontSize: 12),
        ),
        trailing: _inventario.status == 'EM_ANDAMENTO' && !item.conferido
            ? PopupMenuButton<String>(
                tooltip: 'Conferir',
                onSelected: (r) => _conferirManual(item),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'manual', child: Text('Conferir manualmente')),
                ],
              )
            : null,
        onTap: _inventario.status == 'EM_ANDAMENTO' && !item.conferido ? () => _conferirManual(item) : null,
      ),
    );
  }
}

class _ConferirManualDialog extends StatefulWidget {
  final InventarioItemModel item;

  const _ConferirManualDialog({required this.item});

  @override
  State<_ConferirManualDialog> createState() => _ConferirManualDialogState();
}

class _ConferirManualDialogState extends State<_ConferirManualDialog> {
  final _observacaoCtrl = TextEditingController();
  String _resultado = 'CONFORME';

  @override
  void dispose() {
    _observacaoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return AlertDialog(
      title: const Text('Conferir Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.patrimonioDescricao ?? 'Bem', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            'Tombamento: ${item.patrimonioTombamento ?? '—'}',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'CONFORME', label: Text('Conforme'), icon: Icon(Icons.check)),
              ButtonSegment(value: 'DIVERGENCIA', label: Text('Divergência'), icon: Icon(Icons.error_outline)),
            ],
            selected: {_resultado},
            onSelectionChanged: (s) => setState(() => _resultado = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _observacaoCtrl,
            decoration: const InputDecoration(
              labelText: 'Observação',
              hintText: 'Obrigatória em caso de divergência',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Voltar')),
        FilledButton(
          onPressed: () {
            if (_resultado == 'DIVERGENCIA' && _observacaoCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Informe a observação da divergência.')),
              );
              return;
            }
            Navigator.pop(context, {
              'resultado': _resultado,
              'observacao': _observacaoCtrl.text.trim(),
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _ConferirQRScreen extends StatefulWidget {
  final InventarioModel inventario;

  const _ConferirQRScreen({required this.inventario});

  @override
  State<_ConferirQRScreen> createState() => _ConferirQRScreenState();
}

class _ConferirQRScreenState extends State<_ConferirQRScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _aoDetectar(BarcodeCapture capture) async {
    if (_processando) return;
    final codigo = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (codigo == null || codigo.isEmpty) return;

    setState(() => _processando = true);
    try {
      final bem = await context.read<PatrimonioProvider>().buscarPorQrCode(codigo);
      if (!mounted) return;
      if (bem == null) {
        _mostrar('Código não reconhecido. Tente novamente.');
        return;
      }
      final item = widget.inventario.itens
          .where((i) => i.patrimonioId == bem.id)
          .firstOrNull;
      if (item == null) {
        _mostrar('Este bem não pertence a este inventário.');
        return;
      }
      if (item.conferido) {
        _mostrar('Item "${bem.tombamento ?? bem.descricao}" já foi conferido.');
        return;
      }
      final atualizado = await context.read<InventarioProvider>().conferirItem(
            widget.inventario.id,
            patrimonioId: bem.id,
            resultado: 'CONFORME',
          );
      if (!mounted) return;
      if (atualizado == null) {
        _mostrar(context.read<InventarioProvider>().errorMessage ?? 'Erro ao conferir item.');
        return;
      }
      final restantes = atualizado.totalItens - atualizado.totalConferidos;
      _mostrar(
        'Bem "${bem.tombamento ?? bem.descricao}" conferido! '
        '(${atualizado.totalConferidos}/${atualizado.totalItens})'
        '${restantes > 0 ? ' Falta(m) $restantes.' : ' Inventário concluído!'}',
      );
      if (restantes <= 0) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  void _mostrar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(mensagem), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.inventario;
    return Scaffold(
      appBar: AppBar(
        title: Text('Conferir — ${i.descricao}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            tooltip: 'Alternar câmera',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Aponte a câmera para o QR Code do bem patrimonial. '
              'Conferidos: ${i.totalConferidos}/${i.totalItens}.',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _aoDetectar,
              overlayBuilder: (context, args) {
                return Container(
                  margin: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepPurple, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: Text('Concluir conferência (${i.totalItens - i.totalConferidos} restantes)'),
              onPressed: () {
                Navigator.of(context).pop(true);
                context.read<InventarioProvider>().carregarInventarios();
              },
            ),
          ),
        ],
      ),
    );
  }
}