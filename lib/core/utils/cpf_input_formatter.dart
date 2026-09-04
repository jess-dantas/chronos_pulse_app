import 'package:flutter/services.dart';

/// Formatador automático de máscara e limitador de CPF (11 dígitos no padrão brasileiro: 000.000.000-00).
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');

    // Limita estritamente a 11 dígitos numéricos
    final truncated = digitsOnly.length > 11 ? digitsOnly.substring(0, 11) : digitsOnly;
    final formatted = formatCpf(truncated);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Aplica a máscara '000.000.000-00' a uma sequência de dígitos
  static String formatCpf(String digits) {
    final clean = digits.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return '';
    if (clean.length <= 3) return clean;
    if (clean.length <= 6) {
      return '${clean.substring(0, 3)}.${clean.substring(3)}';
    }
    if (clean.length <= 9) {
      return '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6)}';
    }
    final fim = clean.length > 11 ? 11 : clean.length;
    return '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6, 9)}-${clean.substring(9, fim)}';
  }

  /// Remove qualquer caractere não numérico
  static String clean(String cpf) {
    return cpf.replaceAll(RegExp(r'\D'), '');
  }

  /// Valida se possui exatamente 11 dígitos
  static bool isValidLength(String? cpf) {
    if (cpf == null) return false;
    return clean(cpf).length == 11;
  }
}
