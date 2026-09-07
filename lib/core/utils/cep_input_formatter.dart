import 'package:flutter/services.dart';

/// Formatador automático de máscara e limitador de CEP (8 dígitos no padrão
/// brasileiro: 00000-000).
class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final truncated =
        digitsOnly.length > 8 ? digitsOnly.substring(0, 8) : digitsOnly;
    final formatted = formatCep(truncated);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Aplica a máscara '00000-000' a uma sequência de dígitos
  static String formatCep(String digits) {
    final clean = digits.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return '';
    if (clean.length <= 5) return clean;
    return '${clean.substring(0, 5)}-${clean.substring(5)}';
  }

  /// Remove qualquer caractere não numérico
  static String clean(String cep) {
    return cep.replaceAll(RegExp(r'\D'), '');
  }

  /// Valida se possui exatamente 8 dígitos
  static bool isValidLength(String? cep) {
    if (cep == null) return false;
    return clean(cep).length == 8;
  }
}