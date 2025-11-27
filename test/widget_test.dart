import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:fyncee/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('es_MX');
  });

  testWidgets('Shows the home page with empty state on launch',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FynceeApp());
    await tester.pumpAndSettle();

    // Verify header with user name is present
    expect(find.text('Carlos Plata'), findsOneWidget);

    // Verify Saldo section is shown
    expect(find.text('Saldo'), findsWidgets);

    // Verify balance card shows \$0.00
    expect(find.text('\$0.00'), findsOneWidget);

    // Verify sections are present
    expect(find.text('Metas de ahorro'), findsOneWidget);
    expect(find.text('Movimientos'), findsWidgets);

    // Verify bottom navigation exists
    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_rounded), findsWidgets);
    expect(find.text('Metas'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });
}
