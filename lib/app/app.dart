/// The application widget: theme wiring, the router, and the two app-level
/// events neither of them owns.
///
/// Nothing else lives here on purpose. Both themes are always built, and
/// `themeMode` decides which one is used, so switching between light and dark is
/// a rebuild rather than a change of widget tree — the same layout, two token
/// sets, exactly as `docs/02-DESIGN-SYSTEM.md` requires.
///
/// The two events are the app lock's edges (T-706): boot, which is where a
/// stored "on" becomes a locked screen, and the lifecycle, which is how an app
/// that was away for a while comes back locked. Both are one call into
/// `lib/app/lock.dart`; neither touches a plugin.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../ui/theme.dart';
import 'lock.dart';
import 'providers.dart';
import 'router.dart';

class SpendStoryApp extends ConsumerStatefulWidget {
  const SpendStoryApp({super.key});

  @override
  ConsumerState<SpendStoryApp> createState() => _SpendStoryAppState();
}

class _SpendStoryAppState extends ConsumerState<SpendStoryApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Away, and back. The decision — including the grace period that keeps a
    // share sheet from re-prompting — is in `LockActions`, because a widget
    // cannot be unit-tested and that decision can.
    _lifecycle = AppLifecycleListener(
      onPause: () => ref.read(lockActionsProvider).noteAway(DateTime.now()),
      onResume: () => ref.read(lockActionsProvider).noteBack(DateTime.now()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<BootState>>(bootProvider, (_, next) {
      final boot = next.valueOrNull;
      if (boot == null) return;
      if (ref.read(localeProvider) != boot.locale) {
        ref.read(localeProvider.notifier).state = boot.locale;
      }
      // A stored "on" means the first thing this launch shows is the lock.
      if (boot.appLock) ref.read(lockActionsProvider).arm();
    });

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      // The title is copy too, so it comes from the ARB files like everything
      // else — `onGenerateTitle` runs inside the Localizations scope, `title:`
      // does not.
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      // `AppLocalizations` carries the copy Flutter's own widgets use — the
      // date picker, text-selection menus, tooltips, the back button label.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Sorted by gen-l10n; `en` first is what a device with none of the three
      // languages falls back to (l10n.yaml, preferred-supported-locales).
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(locale),
      routerConfig: router,
      themeMode: themeMode,
      theme: buildSsTheme(Brightness.light),
      darkTheme: buildSsTheme(Brightness.dark),
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        // Bengali and Hindi set taller than Latin; letting a system font scale of
        // 2.0 through unclamped breaks every row. 1.3 is the ceiling the layout
        // is tested against (docs/09-LOCALIZATION.md).
        minScaleFactor: 0.9,
        maxScaleFactor: 1.3,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
