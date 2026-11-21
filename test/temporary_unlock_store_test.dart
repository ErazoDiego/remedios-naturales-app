import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/core/services/payments/temporary_unlock.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Store de desbloqueos temporales: reloj inyectado, sin sleeps.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime ahora;
  late TemporaryUnlockStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ahora = DateTime.utc(2026, 11, 19, 12);
    store = TemporaryUnlockStore(now: () => ahora);
  });

  test('init: arranca vacío', () async {
    await store.init();

    expect(store.activos, isEmpty);
    expect(store.tieneAcceso('digestivo_01'), isFalse);
  });

  test('registrar: da acceso durante 24 h y después vence', () async {
    await store.init();
    expect(await store.registrar('digestivo_01'), isTrue);

    expect(store.tieneAcceso('digestivo_01'), isTrue);
    ahora = ahora.add(const Duration(hours: 23, minutes: 59));
    expect(store.tieneAcceso('digestivo_01'), isTrue);

    ahora = ahora.add(const Duration(minutes: 1));
    expect(store.tieneAcceso('digestivo_01'), isFalse);
    expect(store.activos, isEmpty);
  });

  test('cap de 3 activos: el cuarto se rechaza y repetir no cuenta', () async {
    await store.init();

    expect(await store.registrar('digestivo_01'), isTrue);
    expect(await store.registrar('digestivo_02'), isTrue);
    expect(await store.registrar('digestivo_03'), isTrue);
    expect(store.puedeRegistrar('digestivo_04'), isFalse,
        reason: 'el cap se chequea ANTES de mostrar anuncios');
    expect(store.puedeRegistrar('digestivo_01'), isFalse,
        reason: 'ya está activa: no es un unlock nuevo');
    expect(await store.registrar('digestivo_04'), isFalse);
    expect(await store.registrar('digestivo_01'), isTrue,
        reason: 're-registrar la misma receta es idempotente');
    expect(store.activos, hasLength(3));
  });

  test('re-registrar una receta activa NO extiende su vencimiento', () async {
    await store.init();
    await store.registrar('digestivo_01');

    ahora = ahora.add(const Duration(hours: 23));
    expect(await store.registrar('digestivo_01'), isTrue);

    ahora = ahora.add(const Duration(hours: 1));
    expect(store.tieneAcceso('digestivo_01'), isFalse,
        reason: 'el vencimiento original no se movió');
  });

  test('persiste entre instancias (simula reinicio de la app)', () async {
    await store.init();
    await store.registrar('digestivo_01');

    final reinicio = TemporaryUnlockStore(now: () => ahora);
    await reinicio.init();

    expect(reinicio.tieneAcceso('digestivo_01'), isTrue);
  });

  test('init: descarta vencidos y conserva vigentes', () async {
    SharedPreferences.setMockInitialValues({
      TemporaryUnlockStore.key: json.encode({
        'digestivo_01':
            ahora.subtract(const Duration(hours: 25)).toIso8601String(),
        'digestivo_02': ahora.add(const Duration(hours: 1)).toIso8601String(),
      }),
    });

    await store.init();

    expect(store.tieneAcceso('digestivo_01'), isFalse);
    expect(store.tieneAcceso('digestivo_02'), isTrue);
    expect(store.activos, {'digestivo_02'});
  });

  test('init: JSON corrupto arranca vacío sin lanzar', () async {
    SharedPreferences.setMockInitialValues({
      TemporaryUnlockStore.key: '{esto-no-es-json',
    });

    await store.init();

    expect(store.activos, isEmpty);
  });

  test('clear: limpia memoria y persistencia', () async {
    await store.init();
    await store.registrar('digestivo_01');

    await store.clear();

    final reinicio = TemporaryUnlockStore(now: () => ahora);
    await reinicio.init();
    expect(reinicio.activos, isEmpty);
  });
}
