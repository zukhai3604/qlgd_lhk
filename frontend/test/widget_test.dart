import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qlgd_lhk/app/app.dart';
import 'package:qlgd_lhk/features/auth/view/login_page.dart';

void main() {
  testWidgets('App starts and shows LoginPage by default', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: App()));

    // The router starts at /login, so LoginPage should be present.
    await tester.pumpAndSettle();

    // Verify that the LoginPage is found.
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
