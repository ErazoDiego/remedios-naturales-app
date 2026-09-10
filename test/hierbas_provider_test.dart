import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/presentation/providers/hierbas_provider.dart';

/// HierbasProvider.aplicarFiltros: el buscador del herbolario debe matchear
/// alias y normalizar tildes/ñ, igual que el repositorio.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HierbasProvider provider;

  setUp(() async {
    provider = HierbasProvider();
    await provider.loadHierbas();
  });

  test('buscar por alias encuentra Amargón (Diente de león)', () async {
    await provider.aplicarFiltros(busqueda: 'diente de león');

    expect(provider.resultados.map((h) => h.id), contains('amargon'));
  });

  test('buscar por alias sin tilde también encuentra', () async {
    await provider.aplicarFiltros(busqueda: 'diente de leon');

    expect(provider.resultados.map((h) => h.id), contains('amargon'));
  });

  test('buscar sin tilde encuentra texto con tilde', () async {
    // "Distensión" tiene tilde en el uso tradicional de Alcachofa;
    // el usuario escribe "distension".
    await provider.aplicarFiltros(busqueda: 'distension');

    expect(provider.resultados.map((h) => h.id), contains('alcachofa'));
  });

  test('buscar en uso tradicional normalizado', () async {
    await provider.aplicarFiltros(busqueda: 'diuresis');

    expect(provider.resultados, isNotEmpty);
    expect(provider.resultados.map((h) => h.id), contains('amargon'));
  });

  test('sin texto devuelve todas las hierbas', () async {
    await provider.aplicarFiltros(busqueda: '');

    expect(provider.resultados.length, 89);
  });
}