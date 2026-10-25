
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_recommendation_engine/main.dart';

void main() {
  testWidgets('Giftly AI app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const GiftApp());

    expect(find.text('Giftly AI'), findsOneWidget);
  });
}
