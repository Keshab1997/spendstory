/// The S-09 headline amount counts up on load and on ledger changes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/ui/components/money.dart';
import 'package:spendstory/ui/theme.dart';
import 'package:spendstory/ui/tokens.dart';

void main() {
  testWidgets('counts from zero and refreshes from the last displayed value', (
    tester,
  ) async {
    var targetPaise = 1240000;
    late void Function(int value) setTarget;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildSsTheme(Brightness.light),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setTarget = (value) => setState(() => targetPaise = value);
                return CountUpMoney(
                  targetPaise,
                  style: SsText.displayMoney,
                  color: Colors.black,
                );
              },
            ),
          ),
        ),
      ),
    );

    MoneyText headline() => tester.widget<MoneyText>(find.byType(MoneyText));

    expect(headline().paise, 0);
    await tester.pump(const Duration(milliseconds: 600));
    expect(headline().paise, 1240000);

    setTarget(2500000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(headline().paise, greaterThan(1240000));
    expect(headline().paise, lessThan(2500000));

    await tester.pump(const Duration(milliseconds: 400));
    expect(headline().paise, 2500000);
  });

  testWidgets('reduced motion shows the final value without counting', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: buildSsTheme(Brightness.light),
            home: const Scaffold(
              body: CountUpMoney(
                9876500,
                style: SsText.displayMoney,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.widget<MoneyText>(find.byType(MoneyText)).paise, 9876500);
  });
}
