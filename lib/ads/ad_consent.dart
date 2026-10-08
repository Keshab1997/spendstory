/// Consent, before the first ad request (T-607, `docs/08 §7`).
///
/// Two questions live here, and they are different questions:
///
/// * **May the app request an ad at all?** Google's UMP SDK answers that, and
///   the answer is enforced at the seam that builds requests
///   (`ad_client_mobile.dart`) — not in a screen, and not in a hope. A user who
///   was asked in the EEA and did not say yes gets no ads, full stop.
/// * **Personalized or not?** This app's default is *not*, in India, because
///   that is where almost all of its users are and the honest default for an app
///   about somebody's spending is the one that gives Google less. The choice is
///   the user's, it is stored, and T-610 puts the switch in Settings.
///
/// The pure parts (region default, consent → allowed) are here so they can be
/// tested without a phone; the controller is the thing the shell calls once per
/// launch, after the first frame.
library;

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import 'ad_client.dart';

// The flag every request carries, re-exported so a screen that only offers the
// choice does not have to import the ads seam — `docs/03 §S-20` keeps the ad
// client out of Settings, and the audit test holds that line.
export 'ad_client.dart' show nonPersonalizedAdsProvider;

/// Whether personalized ads would be the default for this country.
///
/// India: **no**. Everywhere else: yes, which is what the store listings and the
/// consent form already assume — and which the user can turn off in Settings.
/// A missing country code (a simulator, a device with the region unset) counts
/// as "not India", so a user who has asked for personalized ads elsewhere is not
/// silently downgraded.
bool personalizedAdsDefaultFor(String? countryCode) =>
    countryCode?.toUpperCase() != 'IN';

/// The stored choice, or the default for the region.
///
/// Only an explicit `on`/`off` in `app_meta` counts as a choice; anything else
/// (never asked, a corrupt line) falls back to the region default.
bool personalizedChoiceFrom(String? stored, {required String? countryCode}) {
  if (stored == 'on') return true;
  if (stored == 'off') return false;
  return personalizedAdsDefaultFor(countryCode);
}

/// Whether an ad may be requested, given what the consent flow found.
///
/// `required` is the only state that forbids it outright, and `unknown` allows
/// it because `unknown` means the flow has not run on this platform at all — the
/// mobile client starts closed and opens only on a real answer, so this function
/// is the readable form of that rule rather than a second gate.
bool adsAllowedFor(ConsentState state) => state != ConsentState.required;

/// The app's consent state for this launch, and the switch T-610 will move.
class ConsentController {
  ConsentController(this._ref);

  final Ref _ref;

  /// The key the choice is stored under in `app_meta`.
  static const String metaKey = 'personalizedAds';

  bool _personalized = false;
  ConsentState _state = ConsentState.unknown;
  bool _privacyOptionsRequired = false;

  ConsentState get state => _state;
  bool get personalized => _personalized;

  /// Whether the platform makes the app offer a way to change this choice later
  /// (the UMP privacy-options requirement). Settings shows the row only when
  /// this is true, because a door that leads nowhere is worse than no door.
  bool get privacyOptionsRequiredNow => _privacyOptionsRequired;

  /// Called once per launch, from the shell, after the first frame.
  ///
  /// Order matters and is the whole point of this method: read the stored
  /// choice, set the flag every request will carry, then let Google ask the user
  /// if they need to be asked — and only then start the SDK.
  ///
  /// [showConsent] is false for a user who pays: they will never be shown an ad,
  /// so they are not asked to consent to one (`docs/05 §6`, and the same reason
  /// their phone never starts the SDK). Their app still learns whether it owes
  /// them a privacy-options door, because that obligation outlives a
  /// subscription.
  Future<void> start({bool showConsent = true, String? countryCode}) async {
    final db = _ref.read(appDbProvider);
    final stored = db == null
        ? _ref.read(sessionPersonalizedAdsProvider)
        : await db.meta(metaKey);
    _personalized = personalizedChoiceFrom(
      stored,
      countryCode: countryCode ?? _deviceCountry(),
    );
    _ref.read(nonPersonalizedAdsProvider.notifier).state = !_personalized;

    final client = _ref.read(adClientProvider);

    // Asked here rather than when Settings is opened: it costs one call at a
    // moment the app is already talking to the consent SDK, and it lets the row
    // decide whether to exist without an async build.
    _privacyOptionsRequired = await client.privacyOptionsRequired();
    _ref.read(privacyOptionsRequiredProvider.notifier).state =
        _privacyOptionsRequired;

    if (!showConsent) return;

    _state = await client.ensureConsent();
    _ref.read(consentStateProvider.notifier).state = _state;

    // The SDK is started only when consent says it may be. On a phone where the
    // user declined, nothing about AdMob is ever started.
    if (client.hasAds && adsAllowedFor(_state)) {
      await client.initialize();
    }
  }

  /// Records the user's own choice (T-610's switch, and today the value the
  /// region default wrote).
  Future<void> setPersonalized(bool personalized) async {
    _personalized = personalized;
    _ref.read(nonPersonalizedAdsProvider.notifier).state = !personalized;

    final db = _ref.read(appDbProvider);
    if (db == null) {
      _ref.read(sessionPersonalizedAdsProvider.notifier).state = personalized
          ? 'on'
          : 'off';
      return;
    }
    await db.setMeta(metaKey, personalized ? 'on' : 'off');
  }

  /// Whether the platform requires the app to offer a "privacy options" door,
  /// read fresh rather than from the launch's answer.
  Future<bool> privacyOptionsRequired() async =>
      _ref.read(adClientProvider).privacyOptionsRequired();

  /// Opens that door (T-610). False when there was no form to show.
  Future<bool> showPrivacyOptions() async {
    final shown = await _ref.read(adClientProvider).showPrivacyOptions();
    // The user may have changed their mind in the form; the flag every request
    // carries is re-read from the store rather than assumed.
    if (shown) {
      final db = _ref.read(appDbProvider);
      final stored = db == null
          ? _ref.read(sessionPersonalizedAdsProvider)
          : await db.meta(metaKey);
      _personalized = personalizedChoiceFrom(
        stored,
        countryCode: _deviceCountry(),
      );
      _ref.read(nonPersonalizedAdsProvider.notifier).state = !_personalized;
    }
    return shown;
  }

  String? _deviceCountry() {
    try {
      return PlatformDispatcher.instance.locale.countryCode;
    } catch (_) {
      // A platform without a locale is not a reason to fail a launch.
      return null;
    }
  }
}

final consentControllerProvider = Provider<ConsentController>(
  (ref) => ConsentController(ref),
);

/// What the consent flow reported, so a screen (or a test) can read it without
/// reaching for the client again.
final consentStateProvider = StateProvider<ConsentState>(
  (ref) => ConsentState.unknown,
);

/// Whether the app has to offer a privacy-options door (T-610). False until the
/// launch's consent flow says otherwise.
final privacyOptionsRequiredProvider = StateProvider<bool>((ref) => false);

/// The stored personalized-ads choice for the demo/web build, where there is no
/// `app_meta` to write it to. The same overlay pattern as the rest of the app.
final sessionPersonalizedAdsProvider = StateProvider<String?>((ref) => null);
