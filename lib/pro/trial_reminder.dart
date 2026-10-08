/// The trial reminder (`docs/03 §S-22`: "trial reminder 1 day before").
///
/// A yearly purchase starts a seven-day trial, and Play will take the money on
/// the eighth day unless the user cancels. The app says so — once, on the last
/// day of the trial, the next time it is opened. There is no background service
/// in this product and no server to push from, so "the next time it is opened"
/// is the honest version of a scheduled reminder, and it is the same bargain
/// the budget alerts (T-505) and recurring reminders (T-506) already make.
///
/// Deliberately absent: a price. The store's price is the store's to state, and
/// a notification is not a place to guess at one; it says where to cancel, which
/// is the thing the user actually needs.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import 'entitlement.dart';
import 'product_ids.dart';

/// One reminder, as the notification host sees it.
class TrialReminder {
  const TrialReminder({required this.title, required this.body});

  /// Fixed, so a second delivery replaces the first rather than stacking up.
  static const int notificationId = 6047;
  static const String key = 'proTrialReminder';

  final String title;
  final String body;
}

/// The reminder this install is owed right now, or null.
///
/// It exists only on the last day of a trial that came from a purchase in this
/// app: a restore is not a new trial, a monthly plan has no trial, and a trial
/// that has already ended is Play's business, not a notification's.
TrialReminder? trialReminderFor({
  required ProEntitlement? entitlement,
  required DateTime now,
  required bool alreadySent,
  required Map<String, String> strings,
}) {
  if (alreadySent || entitlement == null) return null;
  if (entitlement.source != ProSource.purchase) return null;

  final trial = trialFor(entitlement.plan);
  if (trial == null) return null;

  final endsAtMs = entitlement.confirmedAtMs + trial.inMilliseconds;
  final nowMs = now.millisecondsSinceEpoch;
  // The last day of the trial, and only that day: opening the app on day two
  // is not a reason to talk about money.
  if (nowMs < endsAtMs - const Duration(days: 1).inMilliseconds) return null;
  if (nowMs >= endsAtMs) return null;

  return TrialReminder(
    title: strings['trialEndsTitle'] ?? '',
    body: strings['trialEndsBody'] ?? '',
  );
}

/// Posts the reminder if one is owed, and records that it went out. Called from
/// the shell after the entitlement has been read, so it can only ever see the
/// record this install actually has.
final trialReminderRunnerProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final db = ref.read(appDbProvider);
    final entry = ref.read(stringsProvider);

    final alreadySent = db == null
        ? ref.read(sessionTrialReminderSentProvider)
        : (await db.meta(TrialReminder.key)) != null;
    if (alreadySent) return false;

    final reminder = trialReminderFor(
      entitlement: ref.read(proEntitlementProvider),
      now: ref.read(nowProvider),
      alreadySent: false,
      strings: {
        'trialEndsTitle': entry['trialEndsTitle'],
        'trialEndsBody': entry['trialEndsBody'],
      },
    );
    if (reminder == null) return false;

    var posted = false;
    try {
      posted = await ref.read(notificationPosterProvider)(
        TrialReminder.notificationId,
        reminder.title,
        reminder.body,
      );
    } catch (_) {
      posted = false;
    }
    // A notification the host refused is still owed: the day is not recorded,
    // exactly like a budget alert.
    if (!posted) return false;

    if (db == null) {
      ref.read(sessionTrialReminderSentProvider.notifier).state = true;
    } else {
      await db.setMeta(TrialReminder.key, 'sent');
    }
    return true;
  };
});

/// The stand-in record for the web preview and the widget tests.
final sessionTrialReminderSentProvider = StateProvider<bool>((ref) => false);
