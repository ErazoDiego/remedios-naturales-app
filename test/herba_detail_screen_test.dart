import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:remedios_naturales_app/core/services/ads_service.dart';
import 'package:remedios_naturales_app/core/services/payments/mock_payment_service.dart';
import 'package:remedios_naturales_app/core/services/payments/premium_rules.dart';
import 'package:remedios_naturales_app/data/models/hierba.dart';
import 'package:remedios_naturales_app/data/models/receta.dart';
import 'package:remedios_naturales_app/data/models/sistema_corporal.dart';
import 'package:remedios_naturales_app/data/repositories/hierbas_repository.dart';
import 'package:remedios_naturales_app/data/repositories/recetas_repository.dart';
import 'package:remedios_naturales_app/data/services/hierbas_service.dart';
import 'package:remedios_naturales_app/data/services/recetas_service.dart';
import 'package:remedios_naturales_app/presentation/providers/hierbas_provider.dart';
import 'package:remedios_naturales_app/presentation/providers/premium_provider.dart';
import 'package:remedios_naturales_app/presentation/screens/herba_detail/herba_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabler_icons/tabler_icons.dart';

/// Ficha de hierba con gating del plan FREE: candado en recetas fuera del
/// muestreo (5 por sistema) + callout ÚNICO de desbloqueo con CTA al pack.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PremiumProvider premium;

  setUp(() {
    // Sin ads en tests: el banner no debe cargar un BannerAd real.
    AdsService.instance.setEnabledForTesting(false);
    AdsService.instance.setPremium(false);
    SharedPreferences.setMockInitialValues({});
  });

  // 'digestivo_03' está en recetasGratisPorSistema (muestreo FREE);
  // 'digestivo_01' NO → bloqueada para usuarios free.
  Receta receta(String id, String nombre) => Receta(
        id: id,
        nombre: nombre,
        descripcion: 'descripción',
        idealPara: const ['acidez'],
        tipo: 'Infusión',
        tipoPreparacion: 'Infusión',
        precaucion: 'precaución',
        ingredientes: const ['1 taza de agua', 'hojas de menta'],
        preparacion: const ['Hervir'],
        dosis: '1 taza',
        almacenamiento: 'Consumir en el día',
      );

  Future<void> pumpFicha(
    WidgetTester tester, {
    required List<Receta> recetas,
    bool startPremium = false,
  }) async {
    final hierba = Hierba(
      id: 'menta',
      nombre: 'Menta',
      propiedades: 'Alivia la digestión',
      tags: const ['digestivo'],
    );
    final sistema = SistemaCorporal(
      id: 'digestivo',
      nombre: 'Sistema Digestivo',
      emoji: '🍃',
      totalRecetas: recetas.length,
      recetas: recetas,
    );

    final hierbasService = HierbasService(
      repository: _InMemoryHierbasRepo([hierba]),
      recetasService: RecetasService(
        repository: _InMemoryRecetasRepo([sistema]),
      ),
    );
    final hierbasProvider = HierbasProvider(service: hierbasService);

    premium = PremiumProvider(
      payment: MockPaymentService(startPremium: startPremium),
    );
    // El provider NO lee el estado del payment en el constructor: hay que
    // comprar (o init) para que _isPremium se entere.
    if (startPremium) {
      await premium.purchasePremium();
    }
    // Precios de la tienda (como en la app real al cargar la tienda).
    await premium.fetchProductsFor(
      [PremiumRules.packIdDeSistema('digestivo')],
    );

    final router = GoRouter(
      initialLocation: '/herba/menta',
      routes: [
        GoRoute(
          path: '/herba/:herbaId',
          builder: (context, state) => HerbaDetailScreen(
            herbaId: state.pathParameters['herbaId']!,
          ),
        ),
        GoRoute(
          path: '/remedy/:recipeId',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('DETALLE RECETA')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HierbasProvider>.value(
            value: hierbasProvider,
          ),
          ChangeNotifierProvider<PremiumProvider>.value(value: premium),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'free con receta bloqueada: candado en tile + callout único con precio',
      (tester) async {
    await pumpFicha(tester, recetas: [
      receta('digestivo_03', 'Te calmante para la acidez'),
      receta('digestivo_01', 'Infusión de manzanilla'),
    ]);

    // Texto honesto: no dice "disponibles" si hay premium bloqueadas.
    expect(find.text('2 recetas, 1 premium'), findsOneWidget);

    // Candado pasivo en la receta bloqueada + candado del callout = 2.
    expect(find.byIcon(TablerIcons.lock), findsNWidgets(2));
    expect(find.text('Infusión de manzanilla'), findsOneWidget);

    // Callout ÚNICO: título + subtítulo con el precio del pack.
    expect(find.text('1 receta premium con Menta'), findsOneWidget);
    expect(find.text('Desbloquear sistema · USD 1.99'), findsOneWidget);
  });

  testWidgets('tocar receta bloqueada abre el diálogo premium (no navega)',
      (tester) async {
    await pumpFicha(tester, recetas: [
      receta('digestivo_03', 'Te calmante para la acidez'),
      receta('digestivo_01', 'Infusión de manzanilla'),
    ]);

    await tester.tap(find.text('Infusión de manzanilla'));
    await tester.pumpAndSettle();

    expect(find.text('Receta Premium'), findsOneWidget);
    expect(find.text('Ahora no'), findsOneWidget);
    // No navegó al detalle de la receta.
    expect(find.text('DETALLE RECETA'), findsNothing);
  });

  testWidgets('tocar el callout abre el diálogo con el pack del sistema',
      (tester) async {
    await pumpFicha(tester, recetas: [
      receta('digestivo_03', 'Te calmante para la acidez'),
      receta('digestivo_01', 'Infusión de manzanilla'),
    ]);

    // El callout vive al final del scroll: hay que hacerlo visible.
    await tester.ensureVisible(find.text('1 receta premium con Menta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 receta premium con Menta'));
    await tester.pumpAndSettle();

    expect(find.text('Recetas premium'), findsOneWidget);
    expect(find.text('Ahora no'), findsOneWidget);
  });

  testWidgets('free con todas las recetas gratis: sin candados ni callout',
      (tester) async {
    await pumpFicha(tester, recetas: [
      receta('digestivo_03', 'Te calmante para la acidez'),
    ]);

    expect(find.text('1 receta disponible'), findsOneWidget);
    expect(find.byIcon(TablerIcons.lock), findsNothing);
    expect(find.textContaining('premium con'), findsNothing);
  });

  testWidgets('premium: sin candados ni callout, todo disponible',
      (tester) async {
    await pumpFicha(tester, startPremium: true, recetas: [
      receta('digestivo_03', 'Te calmante para la acidez'),
      receta('digestivo_01', 'Infusión de manzanilla'),
    ]);

    expect(find.text('2 recetas disponibles'), findsOneWidget);
    expect(find.byIcon(TablerIcons.lock), findsNothing);
    expect(find.textContaining('premium con'), findsNothing);
  });

  testWidgets('receta gratis navega al detalle', (tester) async {
    await pumpFicha(tester, recetas: [
      receta('digestivo_03', 'Te calmante para la acidez'),
    ]);

    await tester.tap(find.text('Te calmante para la acidez'));
    await tester.pumpAndSettle();

    expect(find.text('DETALLE RECETA'), findsOneWidget);
  });

  testWidgets(
      'flujo completo: callout → comprar pack → el candado desaparece',
      (tester) async {
    await pumpFicha(tester, recetas: [
      receta('digestivo_03', 'Te calmante para la acidez'),
      receta('digestivo_01', 'Infusión de manzanilla'),
    ]);
    expect(find.text('2 recetas, 1 premium'), findsOneWidget);

    // Callout → diálogo → comprar el pack del sistema.
    await tester.ensureVisible(find.text('1 receta premium con Menta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 receta premium con Menta'));
    await tester.pumpAndSettle();
    // Botón del diálogo por tipo: el callout (detrás) comparte el texto.
    await tester.tap(
      find.widgetWithText(
        FilledButton,
        'Desbloquear sistema · USD 1.99',
      ),
    );
    await tester.pumpAndSettle();

    // Pack comprado: el sistema queda desbloqueado para siempre.
    expect(premium.packs, contains('yuyo_pack_digestivo'));
    expect(find.text('2 recetas disponibles'), findsOneWidget);
    expect(find.byIcon(TablerIcons.lock), findsNothing);
    expect(find.textContaining('premium con'), findsNothing);
  });
}

/// Repos en memoria (mismo patrón que hierbas_service_test.dart).
/// `implements` (no `extends`): los repos reales son singletons con
/// constructor privado.
class _InMemoryHierbasRepo implements HierbasRepository {
  final List<Hierba> hierbas;

  _InMemoryHierbasRepo(this.hierbas);

  @override
  Future<List<Hierba>> getHierbas() async => hierbas;

  @override
  Future<Hierba?> getHierbaById(String id) async {
    for (final h in hierbas) {
      if (h.id == id) return h;
    }
    return null;
  }

  @override
  Future<List<Hierba>> buscarHierbas(String query) async {
    if (query.trim().isEmpty) return hierbas;
    final queryLower = query.toLowerCase().trim();
    return hierbas
        .where((h) =>
            h.nombre.toLowerCase().contains(queryLower) ||
            h.propiedades.toLowerCase().contains(queryLower) ||
            h.tags.any((t) => t.toLowerCase().contains(queryLower)))
        .toList();
  }

  @override
  Future<List<Hierba>> getHierbasByTag(String tag) async =>
      hierbas.where((h) => h.tags.contains(tag)).toList();

  @override
  Future<List<String>> getTagsPopulares() async =>
      hierbas.expand((h) => h.tags).toSet().toList();
}

class _InMemoryRecetasRepo implements RecetasRepository {
  final List<SistemaCorporal> sistemas;

  _InMemoryRecetasRepo(this.sistemas);

  @override
  Future<List<SistemaCorporal>> getSistemas() async => sistemas;

  @override
  Future<SistemaCorporal?> getSistemaById(String id) async {
    for (final s in sistemas) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<Receta?> getRecetaById(String id) async {
    for (final sistema in sistemas) {
      for (final receta in sistema.recetas) {
        if (receta.id == id) return receta;
      }
    }
    return null;
  }

  @override
  Future<List<Receta>> getRecetasByCondicion(String condicion) async =>
      <Receta>[];

  @override
  Future<List<Receta>> getRecetasBySistema(String sistemaId) async =>
      getSistemaById(sistemaId).then((s) => s?.recetas ?? []);

  @override
  Future<List<Receta>> buscarRecetas(String query) async => <Receta>[];

  @override
  Future<Set<String>> getCondicionesIndex() async => <String>{};

  @override
  Future<List<Receta>> searchByCondition(String condition) async =>
      <Receta>[];
}
