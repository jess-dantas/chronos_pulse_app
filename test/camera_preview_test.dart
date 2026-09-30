import 'package:flutter_test/flutter_test.dart';

import 'package:chronos_pulse_app/features/ponto/presentation/screens/camera_screen.dart';

void main() {
  group('normalizarRazaoPreview (captura facial sem esticar)', () {
    test('razão já retrato passa direto', () {
      expect(normalizarRazaoPreview(3 / 4), 3 / 4);
      expect(normalizarRazaoPreview(0.5), 0.5);
      expect(normalizarRazaoPreview(1.0), 1.0);
    });

    test('sensores paisagem viram retrato (16:9 -> 9:16)', () {
      expect(normalizarRazaoPreview(16 / 9), 9 / 16);
      expect(normalizarRazaoPreview(4 / 3), 3 / 4);
    });

    test('valores inválidos caem no 3:4 clássico de selfie', () {
      expect(normalizarRazaoPreview(0), 3 / 4);
      expect(normalizarRazaoPreview(-1.5), 3 / 4);
      expect(normalizarRazaoPreview(double.nan), 3 / 4);
      expect(normalizarRazaoPreview(double.infinity), 3 / 4);
    });
  });
}
