import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:remedios_naturales_app/core/services/payments/mock_payment_service.dart';
import 'package:remedios_naturales_app/data/services/user_service.dart';
import 'package:remedios_naturales_app/presentation/providers/premium_provider.dart';
import 'package:remedios_naturales_app/presentation/widgets/premium/premium_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// showPremiumDialog: CTA premium + compra directa del pack del sistema.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserService().clearAll();
  });

  Future<void> pumpDialog(WidgetTester tester,
      {String? sistemaId}) async {
    // El provider va ARRIBA del MaterialApp (como en main.dart): el
    // diálogo abre una ruta nueva y necesita verlo desde ahí.
    await tester.pumpWidget(
      ChangeNotifierProvider<PremiumProvider>(
        create: (_) => PremiumProvider(payment: MockPaymentService()),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showPremiumDialog(context,
                      sistemaId: sistemaId),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('sin sistemaId: ofrece solo Ahora no y Ver Premium',
      (tester) async {
    await pumpDialog(tester);

    expect(find.text('Ahora no'), findsOneWidget);
    expect(find.text('Ver Premium'), findsOneWidget);
    expect(find.text('Desbloquear sistema'), findsNothing);
  });

  testWidgets('con sistemaId: ofrece Desbloquear sistema', (tester) async {
    await pumpDialog(tester, sistemaId: 'digestivo');

    expect(find.text('Desbloquear sistema'), findsOneWidget);
  });

  testWidgets('Desbloquear sistema compra el pack del sistema',
      (tester) async {
    await pumpDialog(tester, sistemaId: 'digestivo');

    await tester.tap(find.text('Desbloquear sistema'));
    await tester.pumpAndSettle();

    final premium = tester
        .element(find.byType(Scaffold).first)
        .read<PremiumProvider>();
    expect(premium.packs, contains('yuyo_pack_digestivo'));
    expect(premium.isPremium, isFalse);
  });
}
