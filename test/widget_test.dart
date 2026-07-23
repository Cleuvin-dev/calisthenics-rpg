import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calisthenics_rpg/app/app.dart';

void main() {
  testWidgets('App boots and shows scaffold placeholder', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CalisthenicsRpgApp()),
    );

    expect(find.textContaining('Calisthenics RPG'), findsOneWidget);
  });
}
