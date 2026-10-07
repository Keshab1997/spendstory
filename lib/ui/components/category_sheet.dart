/// The "which category?" picker.
///
/// One widget, three callers — the transaction list's swipe action, the detail
/// screen's *Change* button and the add/edit sheet. A picker that looks
/// different depending on how you reached it is how an app starts feeling like
/// three apps.
library;

import 'package:flutter/material.dart';

import '../../domain/view_models.dart';
import '../tokens.dart';
import 'lists.dart';

/// Shows the picker and returns the chosen category id, or null if dismissed.
Future<String?> showCategorySheet(
  BuildContext context, {
  required String title,
  required List<CategoryView> categories,
  required String locale,
  String? selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => CategorySheet(
      title: title,
      categories: categories,
      locale: locale,
      selectedId: selectedId,
    ),
  );
}

class CategorySheet extends StatelessWidget {
  const CategorySheet({
    super.key,
    required this.title,
    required this.categories,
    required this.locale,
    this.selectedId,
  });

  final String title;
  final List<CategoryView> categories;
  final String locale;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SsSpace.x4,
          0,
          SsSpace.x4,
          SsSpace.x4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: SsText.h2),
            const SizedBox(height: SsSpace.x3),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: SsSpace.x2,
                  runSpacing: SsSpace.x2,
                  children: [
                    for (final cat in categories)
                      CategoryChip(
                        label: cat.label(locale),
                        icon: cat.icon,
                        color: cat.color,
                        selected: cat.id == selectedId,
                        onTap: () => Navigator.of(context).pop(cat.id),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
