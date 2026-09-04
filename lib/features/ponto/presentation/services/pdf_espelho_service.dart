import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../auth/data/models/usuario_model.dart';
import '../../data/models/registro_ponto_model.dart';

class PdfEspelhoService {
  static Future<void> exportarEspelhoPdf({
    required UsuarioModel usuario,
    required List<RegistroPontoModel> registros,
    required int mes,
    required int ano,
  }) async {
    final pdf = pw.Document();

    final nomeMes = DateFormat('MMMM yyyy', 'pt_BR').format(DateTime(ano, mes, 1)).toUpperCase();

    // Agrupa batidas por dia (1..31)
    final Map<int, List<RegistroPontoModel>> batidasPorDia = {};
    for (var r in registros) {
      final dia = r.dataHoraDispositivo.day;
      batidasPorDia.putIfAbsent(dia, () => []).add(r);
    }

    // Ordena registros dentro de cada dia
    batidasPorDia.forEach((dia, lista) {
      lista.sort((a, b) => a.dataHoraDispositivo.compareTo(b.dataHoraDispositivo));
    });

    final diasNoMes = DateTime(ano, mes + 1, 0).day;
    final List<List<String>> tableData = [];

    int totalMinutosMes = 0;
    int totalAjustesMes = 0;

    for (int d = 1; d <= diasNoMes; d++) {
      final dataAtual = DateTime(ano, mes, d);
      final diaSemana = DateFormat('EEE', 'pt_BR').format(dataAtual).toUpperCase();
      final dataFormatada = DateFormat('dd/MM').format(dataAtual);

      final batidas = batidasPorDia[d] ?? [];

      String e1 = '-', s1 = '-', e2 = '-', s2 = '-';
      final List<String> justificativas = [];

      for (var b in batidas) {
        final hora = DateFormat('HH:mm').format(b.dataHoraDispositivo.toLocal());
        final isAjuste = b.ajusteManual;
        final horaDisplay = isAjuste ? '$hora*' : hora;

        if (b.ajusteManual && b.justificativa != null && b.justificativa!.isNotEmpty) {
          totalAjustesMes++;
          justificativas.add('${b.tipoRegistro}: ${b.justificativa}');
        }

        if (b.tipoRegistro == 'ENTRADA' && e1 == '-') {
          e1 = horaDisplay;
        } else if (b.tipoRegistro == 'INTERVALO' && s1 == '-') {
          s1 = horaDisplay;
        } else if (b.tipoRegistro == 'RETORNO' && e2 == '-') {
          e2 = horaDisplay;
        } else if (b.tipoRegistro == 'SAIDA' && s2 == '-') {
          s2 = horaDisplay;
        } else if (e1 == '-') {
          e1 = horaDisplay;
        } else if (s1 == '-') {
          s1 = horaDisplay;
        } else if (e2 == '-') {
          e2 = horaDisplay;
        } else {
          s2 = horaDisplay;
        }
      }

      // Calcula horas trabalhadas simples se houver marcações aos pares
      int minutosTrabalhadosDia = 0;
      if (batidas.length >= 2) {
        for (int i = 0; i < batidas.length - 1; i += 2) {
          final diff = batidas[i + 1].dataHoraDispositivo.difference(batidas[i].dataHoraDispositivo).inMinutes;
          if (diff > 0 && diff < 900) {
            minutosTrabalhadosDia += diff;
          }
        }
      }
      totalMinutosMes += minutosTrabalhadosDia;

      final horasDiaFormatadas = minutosTrabalhadosDia > 0
          ? '${(minutosTrabalhadosDia ~/ 60).toString().padLeft(2, '0')}:${(minutosTrabalhadosDia % 60).toString().padLeft(2, '0')}'
          : '-';

      tableData.add([
        '$dataFormatada ($diaSemana)',
        e1,
        s1,
        e2,
        s2,
        horasDiaFormatadas,
        justificativas.isNotEmpty ? justificativas.join('; ') : '',
      ]);
    }

    final totalHorasFormatadas =
        '${(totalMinutosMes ~/ 60).toString().padLeft(2, '0')}h ${(totalMinutosMes % 60).toString().padLeft(2, '0')}min';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Cabeçalho Oficial
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey700),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'CHRONOS PULSE • SISTEMA DE PONTO ELETRÔNICO',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                      ),
                      pw.Text(
                        'PORTARIA MTP Nº 671/2021',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'ESPELHO DE PONTO ELETRÔNICO INDIVIDUAL - $nomeMes',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.deepPurple),
                  ),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Colaborador: ${usuario.nome}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('CPF: ${usuario.cpf}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Perfil: ${usuario.role}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Tabela de Marcações
            pw.TableHelper.fromTextArray(
              headers: [
                'Data / Dia',
                'Entrada 1',
                'Saída 1',
                'Entrada 2',
                'Saída 2',
                'Total Horas',
                'Ocorrências / Justificativas (*Ajuste)',
              ],
              data: tableData,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellAlignment: pw.Alignment.center,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                6: pw.Alignment.centerLeft,
              },
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
            ),
            pw.SizedBox(height: 12),

            // Resumo
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('Total de Horas no Mês: $totalHorasFormatadas', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  pw.Text('Ajustes Manuais com Justificativa: $totalAjustesMes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Campo de Assinaturas
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Divider(thickness: 0.8, color: PdfColors.grey700),
                      pw.Text('Assinatura do Colaborador', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(usuario.nome, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 40),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Divider(thickness: 0.8, color: PdfColors.grey700),
                      pw.Text('Gestão de RH / Fiscal de Ponto', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Visto e Aprovado', style: const pw.TextStyle(fontSize: 7)),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Espelho_Ponto_${usuario.cpf}_${mes}_$ano.pdf',
    );
  }
}
