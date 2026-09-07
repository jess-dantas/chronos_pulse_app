import 'package:flutter/services.dart';

/// Formatador automático de máscara e limitador de CNPJ (14 caracteres
/// alfanuméricos no padrão da Receita Federal: 12.ABC.345/01DE-45).
class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final alfanumerico = clean(newValue.text);
    final truncated = alfanumerico.length > 14
        ? alfanumerico.substring(0, 14)
        : alfanumerico;
    final formatted = formatCnpj(truncated);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Aplica a máscara '99.999.999/9999-99' a uma sequência alfanumérica.
  static String formatCnpj(String value) {
    final c = clean(value);
    if (c.isEmpty) return '';
    if (c.length <= 2) return c;

    var out = '${c.substring(0, 2)}.';
    if (c.length <= 5) return out + c.substring(2);
    out += '${c.substring(2, 5)}.';
    if (c.length <= 8) return out + c.substring(5);
    out += '${c.substring(5, 8)}/';
    if (c.length <= 12) return out + c.substring(8);
    out += '${c.substring(8, 12)}-';
    out += c.substring(12);

    return out;
  }

  /// Remove pontuação e mantém somente alfanuméricos, em maiúsculas.
  static String clean(String value) {
    return value.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase();
  }

  /// Valida se possui exatamente 14 caracteres.
  static bool isValidLength(String? cnpj) {
    if (cnpj == null) return false;
    return clean(cnpj).length == 14;
  }
}