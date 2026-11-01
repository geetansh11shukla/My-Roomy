import 'package:flutter_test/flutter_test.dart';
import 'package:room_wala/main.dart';

void main() {
  testWidgets('My Roomy app opens to Splash Screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyRoomyApp());

    expect(find.text('My Roomy'), findsOneWidget);
    expect(find.text('YOUR STAY, YOUR WAY'), findsOneWidget);

    // Fast-forward animation and splash timer
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
