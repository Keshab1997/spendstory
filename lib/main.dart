/// Entry point.
///
/// Synchronous on purpose: there is no splash-hiding dance and no async work
/// before `runApp`, because the *router* already holds the user on `/splash`
/// until `bootProvider` resolves. Anything slow — opening SQLite, seeding 195
/// merchant rules on first launch — therefore happens behind a screen the user
/// expects to see anyway.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // The app is light-first; the status bar has to match, and it has to be able
  // to change with the theme, so both bar styles are declared as translucent.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: SpendStoryApp()));
}
