import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class CsvExport {
  const CsvExport._();

  static const String separador = ';';

  static String gerarConteudo({
    required List<String> cabecalho,
    required List<List<String>> linhas,
  }) {
    final buffer = StringBuffer('\uFEFF');
    buffer.writeln(_montarLinha(cabecalho));
    for (final linha in linhas) {
      buffer.writeln(_montarLinha(linha));
    }
    return buffer.toString();
  }

  static Future<bool> exportar({
    required String arquivoNome,
    required List<String> cabecalho,
    required List<List<String>> linhas,
  }) async {
    final conteudo = gerarConteudo(cabecalho: cabecalho, linhas: linhas);
    final destino = await FilePicker.saveFile(
      dialogTitle: 'Exportar $arquivoNome',
      fileName: arquivoNome,
      bytes: Uint8List.fromList(utf8.encode(conteudo)),
    );
    return destino != null;
  }

  static String _montarLinha(List<String> campos) {
    return campos.map(_escapar).join(separador);
  }

  static String _escapar(String campo) {
    final precisaAspas = campo.contains(separador) ||
        campo.contains('"') ||
        campo.contains('\n') ||
        campo.contains('\r');
    if (!precisaAspas) return campo;
    return '"${campo.replaceAll('"', '""')}"';
  }
}