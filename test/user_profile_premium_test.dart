import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/data/models/user_profile.dart';

/// Serialización de premium/packs en UserProfile.
void main() {
  test('default: no premium y sin packs', () {
    final profile = UserProfile(
      id: 'u1',
      email: 'a@b.com',
      nombre: 'Ana',
      fechaRegistro: DateTime.utc(2026, 1, 1),
    );

    expect(profile.premium, isFalse);
    expect(profile.packs, isEmpty);
  });

  test('toJson/fromJson redondea premium y packs', () {
    final profile = UserProfile(
      id: 'u1',
      email: 'a@b.com',
      nombre: 'Ana',
      fechaRegistro: DateTime.utc(2026, 1, 1),
      premium: true,
      packs: ['jugos', 'kefir'],
    );

    final json = profile.toJson();
    final restored = UserProfile.fromJson(json);

    expect(restored.premium, isTrue);
    expect(restored.packs, ['jugos', 'kefir']);
  });

  test('fromJson tolera JSON sin premium/packs (datos viejos)', () {
    final restored = UserProfile.fromJson({
      'id': 'u1',
      'email': 'a@b.com',
      'nombre': 'Ana',
      'fechaRegistro': '2026-01-01T00:00:00.000Z',
      'favoritos': [],
      'historial': [],
    });

    expect(restored.premium, isFalse);
    expect(restored.packs, isEmpty);
  });

  test('copyWith cambia premium y packs sin mutar el original', () {
    final base = UserProfile(
      id: 'u1',
      email: 'a@b.com',
      nombre: 'Ana',
      fechaRegistro: DateTime.utc(2026, 1, 1),
    );

    final premium = base.copyWith(premium: true, packs: ['jugos']);

    expect(premium.premium, isTrue);
    expect(premium.packs, ['jugos']);
    expect(base.premium, isFalse);
    expect(base.packs, isEmpty);
  });
}
