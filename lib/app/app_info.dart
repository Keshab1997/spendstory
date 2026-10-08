/// The three facts about this build that a screen must not invent (T-704).
///
/// `docs/07 §5` makes the grievance contact a DPDP obligation, and `docs/03
/// §S-21` puts the source repo and the version on the same screen. All three are
/// *values*, not copy: they are the same in every language and they change
/// without a translator. So they live here, once, instead of being spelled out
/// inside a screen — the version is already read by Settings and by About.
///
/// The grievance address is Keshab's to fill in (`docs/08 §8b`). Until it is
/// set, [grievanceEmail] is empty and the About screen says so and points at
/// the repository instead: an address that bounces is worse than a stated gap,
/// and a placeholder like `support@example.com` would be a lie in a compliance
/// screen.
library;

class AppInfo {
  const AppInfo._();

  /// Matches `pubspec.yaml`'s `version: 1.0.0+1`, as the About screen shows it.
  static const String version = '1.0.0 (1)';

  /// Public source repository, linked from S-21.
  static const String sourceRepo = 'https://github.com/Keshab1997/spendstory';

  /// TODO(Keshab): the address users write to for support and grievances, kept
  /// for 30 days per `docs/07 §5`. Empty means "not live yet" — the About
  /// screen then shows the repository instead and the address is never invented.
  static const String grievanceEmail = '';

  /// Whether the About screen can show a real address.
  static bool get hasGrievanceEmail => grievanceEmail.isNotEmpty;
}
