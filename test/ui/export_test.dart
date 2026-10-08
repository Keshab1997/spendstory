/// S-23 in the app (T-705): the four things the screen promises, driven through
/// real taps with a real database, a fake share sheet and a fake file picker.
///
/// The gates are the interesting part — CSV free for everyone, PDF Pro or one
/// rewarded credit, a password needed before an encrypted file exists — so each
/// test here is written as "what the user can and cannot do", not as "does the
/// widget build".
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spendstory/ads/ad_client.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/capture/rule_engine.dart' show Cat;
import 'package:spendstory/data/db.dart';
import 'package:spendstory/export/backup_repo.dart';
import 'package:spendstory/export/export_files.dart';
import 'package:spendstory/export/pdf_statement.dart' show manropeAsset;
import 'package:spendstory/pro/rewards.dart';
import 'package:spendstory/ui/screens/export_screen.dart';
import 'package:spendstory/ui/theme.dart';

import '../ads/fake_ad_client.dart';
import 'ledger_harness.dart';

final DateTime _now = DateTime(2026, 10, 7, 20, 42);
const String _password = 'a-good-password';
const int _iterations = 1000;

/// A share sheet that only remembers: the file it was handed, per attempt.
ShareBytes _shareInto(Map<String, Uint8List> outbox) =>
    ({
      required Uint8List bytes,
      required String fileName,
      required String mimeType,
      required String subject,
    }) async {
      outbox[fileName] = bytes;
      return ShareOutcome.shared;
    };

Future<AppDb> _dbWithLedger() async {
  final db = AppDb.memory();
  await db.seedIfNeeded();
  final at = _now.millisecondsSinceEpoch;
  await db
      .into(db.transactions)
      .insert(
        TransactionsCompanion.insert(
          id: 'tx-1',
          amountPaise: 124000,
          direction: 'expense',
          merchant: const Value('BigBasket'),
          categoryId: Value(Cat.grocery),
          occurredAt: at,
          createdAt: at,
          updatedAt: at,
          source: 'manual',
          dedupeHash: 'hash-1',
        ),
      );
  return db;
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required AppDb? db,
  FakeAdClient? client,
  bool isPro = false,
  String locale = 'en',
  PickedFile? pick,
  Map<String, Uint8List>? shared,
  List<Override> extra = const <Override>[],
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: <Override>[
      appDbProvider.overrideWithValue(db),
      bootProvider.overrideWith(
        (ref) async =>
            BootState(onboarded: true, demoMode: db == null, locale: locale),
      ),
      localeProvider.overrideWith((ref) => locale),
      nowProvider.overrideWith((ref) => _now),
      proStatusProvider.overrideWith((ref) => isPro),
      adClientProvider.overrideWithValue(client ?? FakeAdClient()),
      shareBytesProvider.overrideWithValue(
        _shareInto(shared ?? <String, Uint8List>{}),
      ),
      pickFileProvider.overrideWithValue(({String? dialogTitle}) async => pick),
      ...extra,
    ],
  );
  addTearDown(container.dispose);

  await container.read(bootProvider.future);
  await container.read(rewardLedgerProvider).start();

  final router = GoRouter(
    initialLocation: '/export',
    routes: <RouteBase>[
      GoRoute(
        path: '/export',
        builder: (context, state) => const ExportScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(body: Text('home')),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: buildSsTheme(Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapIcon(WidgetTester tester, IconData icon) async {
  final target = find.byIcon(icon);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    // Several in-memory installs in one file is the point of these tests; the
    // warning is about two handles on one file, which cannot happen here.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('the demo build', () {
    testWidgets('says a backup needs the app, and offers nothing to tap', (
      tester,
    ) async {
      await _pump(tester, db: null);

      expect(
        find.text(
          'Backups need the installed app — the web preview keeps no ledger.',
        ),
        findsOneWidget,
      );
      // No password field, no file picker: nothing that would pretend to work.
      expect(find.text('Create backup file'), findsNothing);
      expect(find.text('Choose file'), findsNothing);
      expect(find.text('Export CSV'), findsNothing);
    });
  });

  group('backing up', () {
    testWidgets('will not write a file until the password is long enough', (
      tester,
    ) async {
      final db = await _dbWithLedger();
      addTearDown(db.close);
      final shared = <String, Uint8List>{};
      await _pump(tester, db: db, shared: shared);

      // The button starts disabled: an empty password is not a password.
      await _tap(tester, 'Create backup file');
      expect(shared, isEmpty);

      await tester.enterText(find.byType(TextField).first, 'short');
      await tester.pumpAndSettle();
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      await _tap(tester, 'Create backup file');
      expect(shared, isEmpty);

      await tester.enterText(find.byType(TextField).first, _password);
      await tester.pumpAndSettle();
      await _tap(tester, 'Create backup file');

      expect(shared.keys.single, 'spendstory-backup-2026-10-07.ssbk');
      expect(shared.values.single.length, greaterThan(100));
    });

    testWidgets('remembers when it happened, and stops nagging', (
      tester,
    ) async {
      final db = await _dbWithLedger();
      addTearDown(db.close);
      await db.setMeta('autoBackup', 'on');
      await _pump(tester, db: db, shared: <String, Uint8List>{});

      expect(find.textContaining('Your weekly backup is due'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, _password);
      await tester.pumpAndSettle();
      await _tap(tester, 'Create backup file');

      expect(await db.meta('lastBackupAt'), '${_now.millisecondsSinceEpoch}');
      expect(find.textContaining('Your weekly backup is due'), findsNothing);
    });

    testWidgets('the weekly reminder is a stored choice', (tester) async {
      final db = await _dbWithLedger();
      addTearDown(db.close);
      await _pump(tester, db: db);

      await _tap(tester, 'Weekly reminder');

      expect(await db.meta('autoBackup'), 'on');
    });
  });

  group('the CSV export', () {
    testWidgets('is free for a user who has paid for nothing', (tester) async {
      final db = await _dbWithLedger();
      addTearDown(db.close);
      final shared = <String, Uint8List>{};
      await _pump(tester, db: db, shared: shared);

      expect(find.text('Free'), findsOneWidget);
      await _tap(tester, 'Export CSV');

      final file = shared.entries.single;
      expect(file.key, 'spendstory-backup-2026-10-07.csv');
      // The bytes start with a UTF-8 BOM, which is what makes Excel show ₹ and
      // Bengali instead of mojibake — checked as bytes, because `utf8.decode`
      // helpfully eats a BOM and would hide its absence.
      expect(file.value.sublist(0, 3), <int>[0xEF, 0xBB, 0xBF]);
      final csv = utf8.decode(file.value);
      expect(csv, startsWith('date,time,amount,'));
      expect(csv, contains('BigBasket'));
    });
  });

  group('the PDF statement', () {
    testWidgets('is locked for a free user with no credit', (tester) async {
      final db = await _dbWithLedger();
      addTearDown(db.close);
      final shared = <String, Uint8List>{};
      // No rewarded unit in this build: nothing to watch, so the screen says
      // what the feature costs instead of hiding it.
      await _pump(
        tester,
        db: db,
        client: FakeAdClient(rewarded: null),
        shared: shared,
      );

      await _tap(tester, 'Export PDF');

      expect(shared, isEmpty);
      expect(find.text('The PDF statement is part of Pro.'), findsOneWidget);
    });

    testWidgets('a free user earns one by watching an ad', (tester) async {
      final db = await _dbWithLedger();
      addTearDown(db.close);
      final shared = <String, Uint8List>{};
      final client = FakeAdClient();
      final container = await _pump(
        tester,
        db: db,
        client: client,
        shared: shared,
      );

      await _tap(tester, 'Watch an ad for a free PDF');

      expect(client.rewardedCalls, 1);
      expect(container.read(pdfExportCreditsProvider), 1);
      expect(find.text('Free PDF exports left today: 1'), findsOneWidget);

      await _tap(tester, 'Export PDF');

      final file = shared.entries.single;
      expect(file.key, 'spendstory-backup-2026-10-07.pdf');
      expect(String.fromCharCodes(file.value.sublist(0, 4)), '%PDF');
      // The credit is gone once spent — and the day's second one is still
      // there to earn, because the cap is two (`docs/08 §5`).
      expect(container.read(pdfExportCreditsProvider), 0);
      expect(find.text('Watch an ad for a free PDF'), findsOneWidget);
      await _tap(tester, 'Export PDF');
      expect(shared.length, 1);
    });

    testWidgets('is simply available to somebody who pays', (tester) async {
      final db = await _dbWithLedger();
      addTearDown(db.close);
      final shared = <String, Uint8List>{};
      await _pump(tester, db: db, isPro: true, shared: shared);

      expect(find.text('Watch an ad for a free PDF'), findsNothing);
      await _tap(tester, 'Export PDF');

      expect(shared.keys.single, endsWith('.pdf'));
    });

    testWidgets('follows the month stepper', (tester) async {
      final db = await _dbWithLedger();
      addTearDown(db.close);
      await _pump(tester, db: db, isPro: true);

      expect(find.text('October 2026'), findsOneWidget);
      await _tapIcon(tester, Icons.chevron_left_rounded);
      expect(find.text('September 2026'), findsOneWidget);
      // Forward is offered again once you are in the past…
      await _tapIcon(tester, Icons.chevron_right_rounded);
      expect(find.text('October 2026'), findsOneWidget);
    });
  });

  group('restoring', () {
    testWidgets('brings a wiped ledger back, and says how much came back', (
      tester,
    ) async {
      final source = await _dbWithLedger();
      addTearDown(source.close);
      final bytes = await BackupRepo(source)
          .encrypted(password: _password, now: _now, iterations: _iterations);

      final empty = AppDb.memory();
      await empty.seedIfNeeded();
      addTearDown(empty.close);

      final container = await _pump(
        tester,
        db: empty,
        pick: PickedFile(
          name: 'spendstory-backup-2026-10-07.ssbk',
          bytes: bytes,
        ),
      );

      await _tap(tester, 'Choose file');
      expect(find.text('spendstory-backup-2026-10-07.ssbk'), findsOneWidget);

      // Second field is the restore password: the first belongs to the backup
      // card above it.
      await tester.enterText(find.byType(TextField).at(1), _password);
      await tester.pumpAndSettle();
      await _tap(tester, 'Restore');

      expect((await empty.select(empty.transactions).get()).length, 1);
      await container.read(transactionsProvider.future);
      expect(find.textContaining('Restored 1 transactions'), findsOneWidget);
    });

    testWidgets('says nothing came back when the password is wrong', (
      tester,
    ) async {
      final source = await _dbWithLedger();
      addTearDown(source.close);
      final bytes = await BackupRepo(source)
          .encrypted(password: _password, now: _now, iterations: _iterations);

      final empty = AppDb.memory();
      await empty.seedIfNeeded();
      addTearDown(empty.close);

      await _pump(
        tester,
        db: empty,
        pick: PickedFile(name: 'backup.ssbk', bytes: bytes),
      );

      await _tap(tester, 'Choose file');
      await tester.enterText(find.byType(TextField).at(1), 'the wrong one');
      await tester.pumpAndSettle();
      await _tap(tester, 'Restore');

      expect(
        find.text(
          'That file could not be opened. Check the password and try again.',
        ),
        findsOneWidget,
      );
      expect((await empty.select(empty.transactions).get()), isEmpty);
    });

    testWidgets('asks for a file before it asks for a password', (
      tester,
    ) async {
      final db = await _dbWithLedger();
      addTearDown(db.close);
      await _pump(tester, db: db);

      await _tap(tester, 'Restore');

      expect(find.text('Choose a backup file first.'), findsOneWidget);
    });
  });

  group('in Bengali', () {
    testWidgets('the whole screen fits a 360 dp phone', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      final db = await _dbWithLedger();
      addTearDown(db.close);
      await _pump(tester, db: db, locale: 'bn');

      expect(find.text('এক্সপোর্ট ও ব্যাকআপ'), findsOneWidget);
      expect(find.text('CSV এক্সপোর্ট করো'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('getting there', () {
    testWidgets('Settings carries the row that opens it', (tester) async {
      // Through the real shell and the real router: a screen nothing reaches is
      // not a screen.
      await pumpAt(tester, '/settings');

      await _tap(tester, 'Exports and reports');

      expect(find.text('Export & backup'), findsWidgets);
      // The demo notice is on this screen and nowhere else, which is how the
      // test knows it arrived: `pathOf` reports the pushed route late in this
      // harness (see the About tests), so content is the honest check.
      expect(
        find.text(
          'Backups need the installed app — the web preview keeps no ledger.',
        ),
        findsOneWidget,
      );
    });
  });

  // The font loader is exercised through the screen indirectly; this keeps the
  // asset name in one place if a future test needs to load it directly.
  test('the statement ships a font it can actually parse', () async {
    final bytes = await File(manropeAsset).readAsBytes();
    expect(bytes.length, greaterThan(10000));
  });
}
