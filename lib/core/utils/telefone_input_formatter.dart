import 'package:flutter/services.dart';

/// Formatador automático de máscara e limitador de telefones/celulares
/// brasileiros com 10 (fixo) ou 11 (celular) dígitos: (11) 99999-9999.
class TelefoneInputFormatter extends TextInputFormatter {
  TelDigitCount digitCount = TelDigitCount.celular;

  TelefoneInputFormatter({this.digitCount = TelDigitCount.celular});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limit = maxDigits(digitCount);
    final truncated =
        digitsOnly.length > limit ? digitsOnly.substring(0, limit) : digitsOnly;
    final formatted = formatTelefone(truncated);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static int maxDigits(TelDigitCount digitCount) =>
      digitCount == TelDigitCount.celular ? 11 : 10;

  /// Aplica a máscara '(00) 0000-0000' ou '(00) 00000-0000'.
  static String formatTelefone(String digits) {
    final clean = digits.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return '';
    if (clean.length <= 2) return clean;
    var out = '(${clean.substring(0, 2)}) ';
    final rest = clean.substring(2);

    if (rest.length <= 4) return out + rest;

    final bloco = rest.length > 9 ? 5 : (rest.length == 9 ? 5 : 4);
    if (bloco == 5) {
      if (rest.length <= 5) return out + rest;
      return '$out${rest.substring(0, 5)}-${rest.substring(5)}';
    }

    if (rest.length <= 4) return out + rest;
    return '$out${rest.substring(0, 4)}-${rest.substring(4)}';
  }

  /// Remove qualquer caractere não numérico
  static String clean(String telefone) {
    return telefone.replaceAll(RegExp(r'\D'), '');
  }

  /// Valida se possui a quantidade de dígitos esperada
  static bool isValidLength(String? telefone) {
    if (telefone == null) return false;
    final length = clean(telefone).length;
    return length == 10 || length == 11;
  }
}

enum TelDigitCount { fixo, celular }