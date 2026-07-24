import 'package:calisthenics_rpg/core/database/app_database.dart';
import 'package:calisthenics_rpg/features/rpg/data/xp_ledger_repository.dart';
import 'package:calisthenics_rpg/features/rpg/domain/xp_events.dart';
import 'package:calisthenics_rpg/features/rpg/domain/xp_rules.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late XpLedgerRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = XpLedgerRepository(db);
  });

  tearDown(() => db.close());

  const nonRepeatableAward = XpAward(
    eventType: XpEventType.masteryConfirmed,
    amount: 80,
    sourceId: 'push_horizontal-level-1',
    idempotencyKey: 'mastery-push_horizontal-level-1',
    repeatable: false,
  );

  test('totalXp começa em zero', () async {
    expect(await repository.totalXp(), 0);
  });

  test('grant credita e soma no total', () async {
    final granted =
        await repository.grant(nonRepeatableAward, now: DateTime(2026, 1, 1));
    expect(granted, isTrue);
    expect(await repository.totalXp(), 80);
  });

  test('grant é idempotente pela idempotencyKey', () async {
    await repository.grant(nonRepeatableAward, now: DateTime(2026, 1, 1));
    final secondAttempt =
        await repository.grant(nonRepeatableAward, now: DateTime(2026, 1, 2));

    expect(secondAttempt, isFalse);
    expect(await repository.totalXp(), 80); // não duplicou
  });

  test('grantRepeatable concede o valor cheio dentro do teto', () async {
    const award = XpAward(
      eventType: XpEventType.sessionCompleted,
      amount: 40,
      sourceId: '1',
      idempotencyKey: 'session-completed-1',
      repeatable: true,
    );

    final granted =
        await repository.grantRepeatable(award, now: DateTime(2026, 1, 1));
    expect(granted, 40);
    expect(await repository.totalXp(), 40);
  });

  test('grantRepeatable recorta pelo teto diário', () async {
    final now = DateTime(2026, 1, 1, 8);
    // Esgota quase todo o teto diário com créditos anteriores.
    for (var i = 0; i < 5; i++) {
      await repository.grantRepeatable(
        XpAward(
          eventType: XpEventType.sessionCompleted,
          amount: 40,
          sourceId: '$i',
          idempotencyKey: 'session-completed-$i',
          repeatable: true,
        ),
        now: now,
      );
    }
    expect(await repository.xpGrantedToday(now), 200); // == dailyRepeatableXpCap

    final blocked = await repository.grantRepeatable(
      const XpAward(
        eventType: XpEventType.sessionCompleted,
        amount: 40,
        sourceId: '999',
        idempotencyKey: 'session-completed-999',
        repeatable: true,
      ),
      now: now,
    );
    expect(blocked, 0);
    expect(await repository.totalXp(), dailyRepeatableXpCap);
  });

  test('grantRepeatable concede parcial quando falta pouco para o teto',
      () async {
    final now = DateTime(2026, 1, 1, 8);
    await repository.grantRepeatable(
      const XpAward(
        eventType: XpEventType.sessionCompleted,
        amount: 190,
        sourceId: '1',
        idempotencyKey: 'session-completed-1',
        repeatable: true,
      ),
      now: now,
    );

    final granted = await repository.grantRepeatable(
      const XpAward(
        eventType: XpEventType.allSetsLogged,
        amount: 40,
        sourceId: '1',
        idempotencyKey: 'all-sets-logged-1',
        repeatable: true,
      ),
      now: now,
    );

    expect(granted, 10); // só sobrava 10 de headroom
    expect(await repository.totalXp(), dailyRepeatableXpCap);
  });

  test('teto diário não afeta créditos de dias diferentes', () async {
    final day1 = DateTime(2026, 1, 1, 8);
    final day2 = DateTime(2026, 1, 2, 8);

    for (var i = 0; i < 5; i++) {
      await repository.grantRepeatable(
        XpAward(
          eventType: XpEventType.sessionCompleted,
          amount: 40,
          sourceId: '$i',
          idempotencyKey: 'session-completed-day1-$i',
          repeatable: true,
        ),
        now: day1,
      );
    }

    final grantedDay2 = await repository.grantRepeatable(
      const XpAward(
        eventType: XpEventType.sessionCompleted,
        amount: 40,
        sourceId: '99',
        idempotencyKey: 'session-completed-day2',
        repeatable: true,
      ),
      now: day2,
    );

    expect(grantedDay2, 40);
    expect(await repository.totalXp(), dailyRepeatableXpCap + 40);
  });

  test('grantAwards roteia repetível e não-repetível corretamente',
      () async {
    final total = await repository.grantAwards(
      const [
        XpAward(
          eventType: XpEventType.sessionCompleted,
          amount: 40,
          sourceId: '1',
          idempotencyKey: 'session-completed-1',
          repeatable: true,
        ),
        XpAward(
          eventType: XpEventType.masteryConfirmed,
          amount: 80,
          sourceId: 'push_horizontal-level-1',
          idempotencyKey: 'mastery-push_horizontal-level-1',
          repeatable: false,
        ),
      ],
      now: DateTime(2026, 1, 1),
    );

    expect(total, 120);
    expect(await repository.totalXp(), 120);
  });
}
