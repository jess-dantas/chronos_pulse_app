import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../estoque/presentation/providers/estoque_provider.dart';
import '../../data/models/compras_models.dart';
import '../providers/compras_provider.dart';

class ComprasNfeTab extends StatefulWidget {
  const ComprasNfeTab({super.key});

  @override
  State<ComprasNfeTab> createState() => _ComprasNfeTabState();
}

class _ComprasNfeTabState extends State<ComprasNfeTab> {
  static final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComprasProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: const Text('Importar XML'),
                style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
                onPressed: () => _importarXml(context),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.cloud_download_outlined, size: 18),
                label: const Text('Consultar SEFAZ'),
                onPressed: () => _exibirDialogConsultarSefaz(context),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_scanner_outlined, size: 18),
                label: const Text('Receber NFe'),
                onPressed: () => _exibirDialogReceberNfe(context),
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
          child: provider.isLoading && provider.entradasNfe.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => context.read<ComprasProvider>().carregarTudo(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: provider.entradasNfe.length,
                    itemBuilder: (context, index) {
                      final e = provider.entradasNfe[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.receipt_outlined, color: Colors.deepPurple),
                          title: Text('NFe ${e.numeroNfe ?? '-'}  •  Pedido ${e.pedidoNumero}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formatarChaveNfe(e.chaveNfe)),
                              if (e.razaoEmitente != null)
                                Text(
                                  e.razaoEmitente!,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                              Text(
                                '${e.dataEmissaoFormatada}  •  '
                                '${_moeda.format(e.valorNota ?? 0)}  •  ${e.tipoTermo}',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _importarXml(BuildContext context) async {
    final provider = context.read<ComprasProvider>();
    final arquivo = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xml'],
    );
    if (arquivo == null) return;

    late final List<int> bytes;
    try {
      bytes = await arquivo.readAsBytes();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível ler o conteúdo do arquivo XML.')),
        );
      }
      return;
    }

    final conteudoXml = utf8.decode(bytes, allowMalformed: true);
    final importada = await provider.importarXmlNfe(bytes, arquivo.name);
    if (importada == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Falha ao importar o XML da NFe.')),
        );
      }
      return;
    }
    if (context.mounted) {
      await _exibirDialogReceberNfe(context, importada: importada, conteudoXml: conteudoXml);
    }
  }

  Future<void> _exibirDialogConsultarSefaz(BuildContext context) async {
    final provider = context.read<ComprasProvider>();
    final form = GlobalKey<FormState>();
    String chave = '';

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Consultar NFe na SEFAZ'),
        content: Form(
          key: form,
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Chave NFe (44 dígitos)',
              prefixIcon: Icon(Icons.tag),
            ),
            validator: (v) {
              if (v == null || !validarChaveNfe(v)) {
                return 'Chave NFe inválida';
              }
              return null;
            },
            onChanged: (v) => chave = v,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Consultar'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    final importada = await provider.consultarSefazNfe(chave);
    if (importada == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Falha ao consultar a NFe na SEFAZ.')),
        );
      }
      return;
    }
    if (context.mounted) {
      await _exibirDialogReceberNfe(context, importada: importada);
    }
  }

  Future<void> _exibirDialogReceberNfe(
    BuildContext context, {
    NfeImportadoModel? importada,
    String? conteudoXml,
  }) async {
    final comprasProvider = context.read<ComprasProvider>();
    final estoqueProvider = context.read<EstoqueProvider>();

    final form = GlobalKey<FormState>();
    String chaveNfe = importada?.chaveNfe ?? '';
    String? numeroNfe = importada?.numero;
    String? serie = importada?.serie;
    String? dataEmissao = importada?.dataEmissao;
    double? valorNota = importada?.valorNota;
    String? pedidoId;
    String? almoxarifadoId;
    String tipoTermo = 'DEFINITIVO';
    String? numeroTermo;
    String? observacoes;

    final quantidadesRecebidas = <String, double>{};

    final pedidosDisponiveis = comprasProvider.pedidos
        .where((p) => p.status == 'EMITIDO' || p.status == 'RECEBIDO_PARCIAL')
        .toList();

    if (importada != null && importada.cnpjEmitente != null) {
      FornecedorModel? fornecedorEmitente;
      for (final f in comprasProvider.fornecedores) {
        if (f.cnpj == importada.cnpjEmitente) {
          fornecedorEmitente = f;
          break;
        }
      }
      if (fornecedorEmitente != null) {
        for (final p in pedidosDisponiveis) {
          if (p.fornecedorId == fornecedorEmitente.id) {
            pedidoId = p.id;
            break;
          }
        }
      }
    }

    void preencherQuantidades(String? id) {
      if (id == null) {
        quantidadesRecebidas.clear();
        return;
      }
      quantidadesRecebidas.clear();
      final pedido = pedidosDisponiveis.firstWhere(
        (p) => p.id == id,
        orElse: () => pedidosDisponiveis.first,
      );
      for (final item in pedido.itens) {
        quantidadesRecebidas[item.materialId] = item.quantidadeDisponivel;
      }
    }

    preencherQuantidades(pedidoId);

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          PedidoCompraModel? pedidoSelecionado;
          if (pedidoId != null) {
            for (final p in pedidosDisponiveis) {
              if (p.id == pedidoId) {
                pedidoSelecionado = p;
                break;
              }
            }
          }

          return AlertDialog(
            title: const Text('Recebimento por NFe'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Form(
                  key: form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (importada != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                importada.origem == 'SEFAZ'
                                    ? 'Documento consultado na SEFAZ'
                                    : 'Documento importado do XML',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Emitente: ${importada.razaoEmitente ?? '-'}  •  '
                                'CNPJ ${importada.cnpjEmitente ?? '-'}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              ),
                              Text(
                                'Itens do documento: ${importada.totalItens}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      TextFormField(
                        initialValue: chaveNfe.isEmpty ? null : chaveNfe,
                        decoration: const InputDecoration(
                          labelText: 'Chave NFe (44 dígitos)',
                          prefixIcon: Icon(Icons.tag),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe a chave da NFe';
                          }
                          if (!validarChaveNfe(v)) {
                            return 'Chave NFe inválida (verifique os 44 dígitos)';
                          }
                          return null;
                        },
                        onChanged: (v) => chaveNfe = v,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: numeroNfe,
                              decoration: const InputDecoration(labelText: 'Nº NFe'),
                              onChanged: (v) => numeroNfe = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: serie,
                              decoration: const InputDecoration(labelText: 'Série'),
                              onChanged: (v) => serie = v,
                            ),
                          ),
                        ],
                      ),
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Data de Emissão',
                          hintText: dataEmissao == null
                              ? 'Opcional - toque para selecionar'
                              : dataEmissao!,
                          suffixIcon: const Icon(Icons.event),
                        ),
                        onTap: () async {
                          final data = await showDatePicker(
                            context: dialogContext,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (data != null) {
                            setDialogState(() {
                              dataEmissao = '${data.year.toString().padLeft(4, '0')}-'
                                  '${data.month.toString().padLeft(2, '0')}-'
                                  '${data.day.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                      ),
                      TextFormField(
                        initialValue: valorNota?.toStringAsFixed(2).replaceAll('.', ','),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Valor da NFe (opcional)'),
                        onChanged: (v) =>
                            valorNota = double.tryParse(v.replaceAll(',', '.')) ?? 0,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: pedidoId,
                        decoration: const InputDecoration(labelText: 'Pedido de Compra'),
                        validator: (v) => v == null ? 'Selecione o pedido' : null,
                        items: pedidosDisponiveis
                            .map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(
                                    '${p.numero} - ${p.fornecedorNome} '
                                    '(${_moeda.format(p.valorTotal)})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setDialogState(() {
                            pedidoId = v;
                            final pedido = pedidosDisponiveis.firstWhere(
                              (p) => p.id == pedidoId,
                              orElse: () => pedidosDisponiveis.first,
                            );
                            quantidadesRecebidas.clear();
                            for (final item in pedido.itens) {
                              quantidadesRecebidas[item.materialId] = item.quantidadeDisponivel;
                            }
                          });
                        },
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: almoxarifadoId,
                        decoration: const InputDecoration(labelText: 'Almoxarifado de destino'),
                        validator: (v) => v == null ? 'Selecione o almoxarifado' : null,
                        items: estoqueProvider.almoxarifados
                            .map((a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(a.nome),
                                ))
                            .toList(),
                        onChanged: (v) => almoxarifadoId = v,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: tipoTermo,
                        decoration: const InputDecoration(labelText: 'Tipo de Termo'),
                        items: const [
                          DropdownMenuItem(value: 'DEFINITIVO', child: Text('Definitivo')),
                          DropdownMenuItem(value: 'PROVISORIO', child: Text('Provisório')),
                        ],
                        onChanged: (v) => setDialogState(() => tipoTermo = v!),
                      ),
                      if (tipoTermo == 'PROVISORIO')
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Número do Termo'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Informe o número do termo' : null,
                          onChanged: (v) => numeroTermo = v,
                        ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Observações'),
                        maxLines: 2,
                        onChanged: (v) => observacoes = v,
                      ),
                      if (pedidoSelecionado != null) ...[
                        const Divider(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Itens recebidos',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...pedidoSelecionado.itens.map((item) {
                          final receber = quantidadesRecebidas[item.materialId] ??
                              item.quantidadeDisponivel;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.materialDescricao,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Disponível: ${item.quantidadeDisponivel.toStringAsFixed(3)} '
                                        '${item.materialUnidadeMedida}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: TextFormField(
                                    initialValue: receber.toStringAsFixed(3),
                                    keyboardType: const TextInputType
                                        .numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Qtd',
                                      isDense: true,
                                    ),
                                    onChanged: (v) {
                                      final valor = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                                      setDialogState(() {
                                        quantidadesRecebidas[item.materialId] =
                                            valor.clamp(0.0, item.quantidadeDisponivel).toDouble();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
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
                  if (pedidoId == null || almoxarifadoId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selecione pedido e almoxarifado.')),
                    );
                    return;
                  }
                  final itens = <ItemNfeDTO>[];
                  for (final item in pedidoSelecionado!.itens) {
                    final qtd = quantidadesRecebidas[item.materialId] ?? 0;
                    if (qtd > 0.001) {
                      itens.add(ItemNfeDTO(materialId: item.materialId, quantidade: qtd));
                    }
                  }
                  if (itens.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Informe ao menos um item com quantidade.')),
                    );
                    return;
                  }

                  final sucesso = await comprasProvider.receberNfe(
                    ReceberNfeDTO(
                      chaveNfe: chaveNfe,
                      numeroNfe: numeroNfe,
                      serie: serie,
                      dataEmissao: dataEmissao,
                      valorNota: valorNota,
                      fornecedorId: pedidoSelecionado.fornecedorId,
                      pedidoId: pedidoId!,
                      almoxarifadoId: almoxarifadoId!,
                      tipoTermo: tipoTermo,
                      numeroTermo: numeroTermo,
                      observacoes: observacoes,
                      cnpjEmitente: importada?.cnpjEmitente,
                      razaoEmitente: importada?.razaoEmitente,
                      xmlNfe: conteudoXml,
                      itens: itens,
                    ),
                  );

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(sucesso
                            ? 'Recebimento por NFe registrado.'
                            : comprasProvider.errorMessage ?? 'Falha ao registrar recebimento.'),
                      ),
                    );
                  }
                },
                child: const Text('Registrar recebimento'),
              ),
            ],
          );
        },
      ),
    );
  }
}