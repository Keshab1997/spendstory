/// The application widget: theme wiring and the router.
///
/// Nothing else lives here on purpose. Both themes are always built, and
/// `themeMode` decides which one is used, so switching between light and dark is
/// a rebuild rather than a change of widget tree — the same layout, two token
/// sets, exactly as `docs/02-DESIGN-SYSTEM.md` requires.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../ui/theme.dart';
import 'providers.dart';
import 'router.dart';

class SpendStoryApp extends ConsumerWidget {
  const SpendStoryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<BootState>>(bootProvider, (_, next) {
      final boot = next.valueOrNull;
      if (boot != null && ref.read(localeProvider) != boot.locale) {
        ref.read(localeProvider.notifier).state = boot.locale;
      }
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
