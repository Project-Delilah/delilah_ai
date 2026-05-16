import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delilah/main.dart';

void main() {
  testWidgets('Delilah app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DelilahApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Delilah'), findsOneWidget);
  });
}