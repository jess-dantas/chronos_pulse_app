/// Utilitário de validação de CNPJ que aceita o formato tradicional (numérico)
/// e o novo padrão alfanumérico instituído pela Receita Federal
/// (MP 1.151/2022 / IN RFB 2.251), em que a base de 12 posições pode conter
/// letras (A=10 ... Z=35) e os dígitos verificadores usam os mesmos pesos.
class CnpjValidator {
  static const List<int> _pesosPrimeiro = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  static const List<int> _pesosSegundo = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  /// Remove pontuação e mantém somente caracteres alfanuméricos, em maiúsculas.
  static String normalizar(String cnpj) {
    return cnpj.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase();
  }

  /// Valida o CNPJ (numérico ou alfanumérico), incluindo os dígitos verificadores.
  static bool isValid(String? cnpj) {
    if (cnpj == null) return false;
    final c = normalizar(cnpj);
    if (c.length != 14) return false;
    final base = c.substring(0, 12);
    return _digitoVerificador(base, _pesosPrimeiro) == _valor(c[12]) &&
        _digitoVerificador(base + c[12], _pesosSegundo) == _valor(c[13]);
  }

  static int _digitoVerificador(String caracteres, List<int> pesos) {
    var soma = 0;
    for (var i = 0; i < caracteres.length; i++) {
      soma += _valor(caracteres[i]) * pesos[i];
    }
    final resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }

  static int _valor(String ch) {
    if (ch.codeUnitAt(0) >= 0x41) {
      return ch.codeUnitAt(0) - 0x41 + 10;
    }
    return ch.codeUnitAt(0) - 0x30;
  }
}