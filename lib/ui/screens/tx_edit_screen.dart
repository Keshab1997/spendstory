/// A full-page host for [TxEditSheet], so `/transactions/edit` is a real route.
///
/// In the app the add/edit form is a bottom sheet, which is how the spec draws
/// it and how it should feel. But a route that only exists as a sheet cannot be
/// deep-linked, reloaded in the web preview, or reached by the back button, and
/// `docs/04-NAVIGATION.md` lists it as a route. One form widget, two hosts —
/// not two forms. The host says how to leave, because a page reached with
/// `go()` has nothing to pop and the form must not be left spinning on it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../tokens.dart';
import 'tx_edit_sheet.dart';

class TxEditScreen extends ConsumerWidget {
  const TxEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: TxEditSheet(
          onDone: (_) =>
              context.canPop() ? context.pop() : context.go('/transactions'),
        ),
      ),
    );
  }
}
