import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/data/models/user_profile.dart';

/// Serialización de lifetime/membresía/packs en UserProfile.
void main() {
  test('default: sin lifetime, sin membresía y sin packs', () {
    final profile = UserProfile(
      id: 'u1',
      email: 'a@b.com',
      nombre: 'Ana',
      fechaRegistro: DateTime.utc(2026, 1, 1),
    );

    expect(profile.lifetime, isFalse);
    expect(profile.premiumUntil, isNull);
    expect(profile.packs, isEmpty);
  });

  test('toJson/fromJson redondea lifetime, premiumUntil y packs', () {
    final hasta = DateTime.utc(2026, 3, 1);
    final profile = UserProfile(
      id: 'u1',
      email: 'a@b.com',
      nombre: 'Ana',
      fechaRegistro: DateTime.utc(2026, 1, 1),
      lifetime: true,
      premiumUntil: hasta,
      packs: ['jugos', 'kefir'],
    );

    final json = profile.toJson();
    final restored = UserProfile.fromJson(json);

    expect(restored.lifetime, isTrue);
    expect(restored.premiumUntil, hasta);
    expect(restored.packs, ['jugos', 'kefir']);
  });

  test('fromJson tolera JSON sin lifetime/membresía/packs (datos viejos)',
      () {
    final restored = UserProfile.fromJson({
      'id': 'u1',
      'email': 'a@b.com',
      'nombre': 'Ana',
      'fechaRegistro': '2026-01-01T00:00:00.000Z',
      'favoritos': [],
      'historial': [],
    });

    expect(restored.lifetime, isFalse);
    expect(restored.premiumUntil, isNull);
    expect(restored.packs, isEmpty);
  });

  test('copyWith cambia lifetime, premiumUntil y packs sin mutar el original',
      () {
    final base = UserProfile(
      id: 'u1',
      email: 'a@b.com',
      nombre: 'Ana',
      fechaRegistro: DateTime.utc(2026, 1, 1),
    );

    final premium = base.copyWith(
      lifetime: true,
      premiumUntil: DateTime.utc(2026, 3, 1),
      packs: ['jugos'],
    );

    expect(premium.lifetime, isTrue);
    expect(premium.premiumUntil, DateTime.utc(2026, 3, 1));
    expect(premium.packs, ['jugos']);
    expect(base.lifetime, isFalse);
    expect(base.premiumUntil, isNull);
    expect(base.packs, isEmpty);
  });
}
