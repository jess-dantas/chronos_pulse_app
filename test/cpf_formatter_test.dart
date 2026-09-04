import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/utils/cpf_input_formatter.dart';

void main() {
  group('CpfInputFormatter & CpfUtils', () {
    final formatter = CpfInputFormatter();

    test('Formata CPF progressivamente até 11 dígitos', () {
      expect(CpfInputFormatter.formatCpf('123'), '123');
      expect(CpfInputFormatter.formatCpf('1234'), '123.4');
      expect(CpfInputFormatter.formatCpf('123456'), '123.456');
      expect(CpfInputFormatter.formatCpf('1234567'), '123.456.7');
      expect(CpfInputFormatter.formatCpf('123456789'), '123.456.789');
      expect(CpfInputFormatter.formatCpf('1234567890'), '123.456.789-0');
      expect(CpfInputFormatter.formatCpf('12345678901'), '123.456.789-01');
    });

    test('Limita estritamente a 11 dígitos caso o usuário digite ou cole mais', () {
      expect(CpfInputFormatter.formatCpf('1234567890199999'), '123.456.789-01');
    });

    test('Limpa pontuação e caracteres não numéricos corretamente', () {
      expect(CpfInputFormatter.clean('123.456.789-01'), '12345678901');
      expect(CpfInputFormatter.clean('123-abc.456-789/01'), '12345678901');
      expect(CpfInputFormatter.clean(''), '');
    });

    test('Valida comprimento de 11 dígitos com isValidLength', () {
      expect(CpfInputFormatter.isValidLength('12345678901'), isTrue);
      expect(CpfInputFormatter.isValidLength('123.456.789-01'), isTrue);
      expect(CpfInputFormatter.isValidLength('1234567890'), isFalse);
      expect(CpfInputFormatter.isValidLength('123456789012'), isFalse);
      expect(CpfInputFormatter.isValidLength(null), isFalse);
    });

    test('formatEditUpdate limita e formata TextEditingValue na digitação', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '123456789019999',
        selection: TextSelection.collapsed(offset: 15),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '123.456.789-01');
      expect(result.selection.baseOffset, 14);
    });
  });
}
