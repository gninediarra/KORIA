import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gabeseye/main.dart';
import 'package:gabeseye/providers/auth_provider.dart';
import 'package:gabeseye/providers/app_provider.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AppProvider()),
        ],
        child: const GabesEyeApp(),
      ),
    );
    expect(find.byType(GabesEyeApp), findsOneWidget);
  });
}
