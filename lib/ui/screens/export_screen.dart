/// S-23 Export / backup (T-705) — `docs/03 §S-23`, `docs/05 §4`.
///
/// Four things live on this screen, and each one is gated the way the spec asks
/// for it:
///
/// * **Back up now** — the whole ledger, AES-256-GCM under a password the user
///   chooses, handed to the share sheet. Nothing is uploaded; there is still no
///   server to upload it to, and the file goes where the user sends it (their
///   Drive included, which is why there is no Drive SDK here — see the note in
///   `docs/11-TASKS.md`).
/// * **Restore** — pick the file, type the password, and the ledger comes back.
///   It *adds* rather than wipes: the acceptance line in `docs/03 §S-23` is
///   about a fresh install, and guessing wrong about deleting somebody's data
///   is not something the user can undo.
/// * **CSV** — free for everyone, always (`docs/03 §S-23`; the Pro card's copy
///   said otherwise until this task, and was corrected in the same commit).
/// * **PDF statement** — Pro, or one rewarded credit earned on this screen.
///   `spendPdfCredit()` owns the daily cap, so this screen cannot invent one.
///
/// The weekly toggle is a *reminder*, not a silent writer, and the card says so:
/// an automatic backup would have to encrypt itself with a password the app does
/// not have — writing one in plaintext would break `docs/07 §5`'s promise, and
/// storing the password would break it worse. So the app asks once a week
/// instead of writing a file the user could not open.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ads/ad_client.dart';
import '../../app/providers.dart';
import '../../export/backup_codec.dart';
import '../../export/backup_repo.dart';
import '../../export/export_files.dart';
import '../../export/pdf_statement.dart';
import '../../pro/rewards.dart';
import '../components/controls.dart';
import '../components/lists.dart';
import '../components/surfaces.dart';
import '../format.dart';
import '../strings.dart';
import '../tokens.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  /// Short enough to type on a phone, long enough that the file is worth the
  /// encryption. Enforced here, and the field says why.
  static const int _minPasswordLength = 8;

  final TextEditingController _password = TextEditingController();
  final TextEditingController _restorePassword = TextEditingController();

  /// The file the user picked for a restore, held in memory until they ask for
  /// it to be read. Nothing is read from disk twice.
  PickedFile? _restoreFile;

  /// The month the PDF statement covers. Starts on the current one.
  late DateTime _month;

  bool _busyBackup = false;
  bool _busyCsv = false;
  bool _busyPdf = false;
  bool _busyRestore = false;

  @override
  void initState() {
    super.initState();
    final now = ref.read(nowProvider);
    _month = DateTime(now.year, now.month);
  }

  @override
  void dispose() {
    _password.dispose();
    _restorePassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final db = ref.watch(appDbProvider);
    final hasPassword = _password.text.trim().length >= _minPasswordLength;
    // Watching the ledger here is what makes the CSV count and the statement
    // work on the first tap; the shell usually has it warm already.
    ref.watch(transactionsProvider);

    return SsScaffold(
      title: s['exportTitle'],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: SsSpace.x2),
          Text(
            s['exportBody'],
            style: SsText.caption.copyWith(color: c.textSecondary),
          ),

          // Nothing to back up without a database: the web preview runs on the
          // demo ledger, and exporting demo data would be a lie with a file
          // name on it.
          if (db == null)
            _DemoNotice()
          else ...<Widget>[
            // ---- back up now ----------------------------------------------
            const SizedBox(height: SsSpace.x5),
            SectionHeader(
              title: s['exportBackupTitle'],
              padding: EdgeInsets.zero,
            ),
            SsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    s['exportBackupBody'],
                    style: SsText.caption.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: SsSpace.x4),
                  _PasswordField(
                    controller: _password,
                    label: s['exportPassword'],
                    hint: s['exportPasswordHint'],
                    errorText: _password.text.isEmpty || hasPassword
                        ? null
                        : s['exportPasswordTooShort'],
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: SsSpace.x3),
                  SsActionButton(
                    label: s['exportCreateBackup'],
                    icon: Icons.lock_outline_rounded,
                    loading: _busyBackup,
                    onPressed: hasPassword && !_busyBackup ? _backUpNow : null,
                  ),
                  const SizedBox(height: SsSpace.x3),
                  _LastBackupLine(strings: s),
                ],
              ),
            ),

            // ---- weekly reminder -------------------------------------------
            const SizedBox(height: SsSpace.x5),
            const _AutoBackupCard(),

            // ---- restore ----------------------------------------------------
            const SizedBox(height: SsSpace.x5),
            SectionHeader(
              title: s['exportRestoreTitle'],
              padding: EdgeInsets.zero,
            ),
            SsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    s['exportRestoreBody'],
                    style: SsText.caption.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: SsSpace.x4),
                  SsActionButton(
                    label: s['exportPickFile'],
                    tone: SsButtonTone.secondary,
                    height: 44,
                    icon: Icons.folder_open_rounded,
                    onPressed: _busyRestore ? null : _pickFile,
                  ),
                  if (_restoreFile != null) ...<Widget>[
                    const SizedBox(height: SsSpace.x2),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: c.textTertiary,
                        ),
                        const SizedBox(width: SsSpace.x2),
                        Expanded(
                          child: Text(
                            _restoreFile!.name,
                            style: SsText.micro.copyWith(
                              color: c.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: SsSpace.x3),
                  _PasswordField(
                    controller: _restorePassword,
                    label: s['exportPassword'],
                    hint: s['exportPasswordHint'],
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: SsSpace.x3),
                  SsActionButton(
                    label: s['exportRestoreAction'],
                    tone: SsButtonTone.secondary,
                    loading: _busyRestore,
                    icon: Icons.settings_backup_restore_rounded,
                    onPressed: _busyRestore ? null : _restore,
                  ),
                ],
              ),
            ),

            // ---- the exports ------------------------------------------------
            const SizedBox(height: SsSpace.x5),
            _CsvCard(busy: _busyCsv, onExport: _busyCsv ? null : _exportCsv),
            const SizedBox(height: SsSpace.x5),
            _PdfCard(
              month: _month,
              busy: _busyPdf,
              onPreviousMonth: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1),
              ),
              onNextMonth: _isCurrentMonth
                  ? null
                  : () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1),
                    ),
              onExport: _busyPdf ? null : _exportPdf,
              onWatchAd: _watchForPdf,
            ),

            const SizedBox(height: SsSpace.x4),
            Text(
              s['exportShareDrive'],
              style: SsText.micro.copyWith(color: c.textTertiary),
            ),
          ],
          const SizedBox(height: SsSpace.x6),
        ],
      ),
    );
  }

  /// Where the file goes instead of a folder we own: the share sheet, so the
  /// user picks (Drive, a chat with themselves, a cable).
  Future<void> _share({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final s = ref.read(stringsProvider);
    final outcome = await ref.read(shareBytesProvider)(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      subject: s.appName,
    );
    if (!mounted) return;
    _say(switch (outcome) {
      ShareOutcome.shared => s['exportBackupReady'],
      ShareOutcome.dismissed => s['exportBackupDismissed'],
      ShareOutcome.unavailable => s['exportBackupUnavailable'],
      ShareOutcome.failed => s['exportBackupFailed'],
    });
    if (outcome == ShareOutcome.shared) await _noteBackup();
  }

  Future<void> _backUpNow() async {
    final db = ref.read(appDbProvider);
    if (db == null) return;
    final now = ref.read(nowProvider);
    setState(() => _busyBackup = true);
    try {
      final bytes = await BackupRepo(db)
          .encrypted(password: _password.text.trim(), now: now);
      await _share(
        bytes: bytes,
        fileName: BackupRepo.suggestedFileName(now),
        mimeType: 'application/octet-stream',
      );
    } finally {
      if (mounted) setState(() => _busyBackup = false);
    }
  }

  /// Remembers that a backup was taken, which is what the weekly line reads.
  Future<void> _noteBackup() async {
    final db = ref.read(appDbProvider);
    if (db == null) return;
    await db.setMeta(
      'lastBackupAt',
      '${ref.read(nowProvider).millisecondsSinceEpoch}',
    );
    ref.invalidate(lastBackupAtProvider);
  }

  Future<void> _exportCsv() async {
    final db = ref.read(appDbProvider);
    if (db == null) return;
    final s = ref.read(stringsProvider);
    final locale = ref.read(localeProvider);
    final now = ref.read(nowProvider);

    setState(() => _busyCsv = true);
    try {
      final transactions = await ref.read(transactionsProvider.future);
      if (transactions.isEmpty) {
        _say(s['exportCsvEmpty']);
        return;
      }
      final categories = await ref.read(categoriesProvider.future);
      final accounts = await ref.read(accountsProvider.future);
      final csv = await BackupRepo(db).csv(
        categoryNames: {
          for (final category in categories)
            category.id: category.label(locale),
        },
        accountNames: {
          for (final account in accounts) account.id: account.name,
        },
      );
      await _share(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        fileName: BackupRepo.suggestedFileName(now, extension: 'csv'),
        mimeType: 'text/csv',
      );
    } finally {
      if (mounted) setState(() => _busyCsv = false);
    }
  }

  Future<void> _pickFile() async {
    final s = ref.read(stringsProvider);
    final picked = await ref.read(pickFileProvider)(
      dialogTitle: s['exportPickFile'],
    );
    if (!mounted || picked == null) return;
    setState(() => _restoreFile = picked);
  }

  Future<void> _restore() async {
    final db = ref.read(appDbProvider);
    if (db == null) return;
    final s = ref.read(stringsProvider);
    final file = _restoreFile;
    if (file == null) {
      _say(s['exportRestoreNeedFile']);
      return;
    }
    if (_restorePassword.text.isEmpty) {
      _say(s['exportRestoreNeedPassword']);
      return;
    }

    setState(() => _busyRestore = true);
    try {
      final report = await BackupRepo(db)
          .restore(file.bytes, password: _restorePassword.text);
      _refreshLedger();
      _say(
        s.fill('exportRestoreDone', <String, String>{
          'tx': s.digits('${report.transactions}'),
          'cats': s.digits('${report.categories}'),
          'budgets': s.digits('${report.budgets}'),
          'accounts': s.digits('${report.accounts}'),
        }),
      );
    } on BackupFormatException {
      _say(s['exportRestoreFailed']);
    } finally {
      if (mounted) setState(() => _busyRestore = false);
    }
  }

  /// A restore writes rows behind every one of these, so they all have to be
  /// asked again — the ledger the user is looking at is now a different one.
  void _refreshLedger() {
    ref
      ..invalidate(transactionsProvider)
      ..invalidate(categoriesProvider)
      ..invalidate(accountsProvider)
      ..invalidate(budgetsProvider)
      ..invalidate(recurringProvider);
  }

  bool get _isCurrentMonth {
    final now = ref.read(nowProvider);
    return _month.year == now.year && _month.month == now.month;
  }

  Future<void> _exportPdf() async {
    final db = ref.read(appDbProvider);
    if (db == null) return;
    final s = ref.read(stringsProvider);
    final isPro = ref.read(proStatusProvider);
    if (!isPro && ref.read(pdfExportCreditsProvider) <= 0) {
      _say(s['exportPdfProOnly']);
      return;
    }

    setState(() => _busyPdf = true);
    try {
      final bytes = await _statementBytes();
      if (!isPro) {
        // Spent only after the statement is built: a failed build must not cost
        // the user one of the day's two.
        final spent = await ref.read(rewardLedgerProvider).spendPdfCredit();
        if (!spent) {
          _say(s['exportPdfProOnly']);
          return;
        }
      }
      await _share(
        bytes: bytes,
        fileName: BackupRepo.suggestedFileName(
          ref.read(nowProvider),
          extension: 'pdf',
        ),
        mimeType: 'application/pdf',
      );
    } finally {
      if (mounted) setState(() => _busyPdf = false);
    }
  }

  /// The rewarded offer: one ad, one free PDF (`docs/08 §5`). The SDK's word is
  /// what grants the credit — a dismissed ad costs the user nothing, including
  /// the day's two.
  Future<void> _watchForPdf() async {
    final s = ref.read(stringsProvider);
    final outcome = await ref
        .read(rewardLedgerProvider)
        .watch(RewardKind.pdfExport);
    if (!mounted) return;
    _say(switch (outcome) {
      RewardedOutcome.earned => s['exportPdfEarned'],
      RewardedOutcome.dismissed => s['exportPdfMissed'],
      RewardedOutcome.unavailable => s['exportPdfUnavailable'],
    });
  }

  /// Builds the PDF for [_month]. Latin script on purpose — see the file header
  /// of `pdf_statement.dart`.
  Future<Uint8List> _statementBytes() async {
    final now = ref.read(nowProvider);
    final transactions = await ref.read(transactionsProvider.future);
    final categories = await ref.read(categoriesProvider.future);

    final start = _month.millisecondsSinceEpoch;
    final end = DateTime(_month.year, _month.month + 1).millisecondsSinceEpoch;
    final monthRows =
        transactions
            .where((t) => t.occurredAtMs >= start && t.occurredAtMs < end)
            .toList()
          ..sort((a, b) => a.occurredAtMs.compareTo(b.occurredAtMs));

    final categoryNames = <String, String>{
      for (final category in categories) category.id: category.nameEn,
    };
    var income = 0;
    var expense = 0;
    final rows = <StatementRow>[];
    for (final txn in monthRows) {
      if (txn.isIncome) {
        income += txn.amountPaise;
      } else {
        expense += txn.amountPaise;
      }
      rows.add(
        StatementRow(
          date: statementDate(txn.occurredAtMs),
          particulars: txn.merchant ?? txn.sourceLabel('en'),
          category: categoryNames[txn.categoryId] ?? '',
          amountPaise: txn.amountPaise,
          isIncome: txn.isIncome,
        ),
      );
    }

    return buildStatementPdf(
      StatementData(
        // English and Latin digits on purpose: the PDF has no Indic shaping,
        // and a filename is not a sentence the user reads (T-705).
        period: monthLabel(_month.millisecondsSinceEpoch, locale: 'en'),
        rows: rows,
        incomePaise: income,
        expensePaise: expense,
        footnote: statementFootnote(now),
      ),
    );
  }

  void _say(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

/// Shown where the buttons would be on a platform without a database.
class _DemoNotice extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);

    return Padding(
      padding: const EdgeInsets.only(top: SsSpace.x5),
      child: SsCard(
        child: Row(
          children: <Widget>[
            Icon(Icons.info_outline_rounded, color: c.textSecondary, size: 20),
            const SizedBox(width: SsSpace.x3),
            Expanded(
              child: Text(
                s['exportDemoUnavailable'],
                style: SsText.body.copyWith(color: c.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The weekly reminder switch. Its own widget so the one place that reads the
/// stored flag is also the one place that writes it.
class _AutoBackupCard extends ConsumerWidget {
  const _AutoBackupCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final enabled = ref.watch(autoBackupProvider).valueOrNull ?? false;

    Future<void> toggle(bool on) async {
      await ref.read(appDbProvider)?.setMeta('autoBackup', on ? 'on' : 'off');
      ref.invalidate(autoBackupProvider);
    }

    return SsCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SsSpace.x2,
        vertical: SsSpace.x1,
      ),
      child: SettingTile(
        icon: Icons.event_repeat_rounded,
        tint: c.violet600,
        title: s['exportAutoBackup'],
        subtitle: s['exportAutoBackupBody'],
        trailing: Switch(value: enabled, onChanged: (on) => toggle(on)),
        onTap: () => toggle(!enabled),
      ),
    );
  }
}

/// The last-backup line, which is also where the weekly reminder shows.
class _LastBackupLine extends ConsumerWidget {
  const _LastBackupLine({required this.strings});

  final SsStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final last = ref.watch(lastBackupAtProvider).valueOrNull;
    final reminderOn = ref.watch(autoBackupProvider).valueOrNull ?? false;
    final due =
        reminderOn &&
        backupDue(lastBackupAt: last, now: ref.watch(nowProvider));

    final text = last == null
        ? s['exportNeverBackedUp']
        : s.fill('exportLastBackup', <String, String>{
            'when': strings.shortDate(last.millisecondsSinceEpoch),
          });

    return Row(
      children: <Widget>[
        Icon(
          due ? Icons.notification_important_outlined : Icons.history_rounded,
          size: 16,
          color: due ? c.gold500 : c.textTertiary,
        ),
        const SizedBox(width: SsSpace.x2),
        Expanded(
          child: Text(
            due ? '${s['exportDue']} · $text' : text,
            style: SsText.micro.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// The free export. Its own widget so the spec line ("all free") is visible in
/// the code: there is no plan check anywhere near the button.
class _CsvCard extends ConsumerWidget {
  const _CsvCard({required this.busy, required this.onExport});

  final bool busy;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(title: s['exportCsvTitle'], padding: EdgeInsets.zero),
        SsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      s['exportCsvBody'],
                      style: SsText.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                  const SizedBox(width: SsSpace.x2),
                  SsBadge(label: s['exportCsvFree'], color: c.teal500),
                ],
              ),
              const SizedBox(height: SsSpace.x3),
              SsActionButton(
                label: s['exportCsvAction'],
                tone: SsButtonTone.secondary,
                icon: Icons.table_chart_outlined,
                loading: busy,
                onPressed: onExport,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The Pro half: a statement for a month, paid for or earned.
class _PdfCard extends ConsumerWidget {
  const _PdfCard({
    required this.month,
    required this.busy,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onExport,
    required this.onWatchAd,
  });

  final DateTime month;
  final bool busy;
  final VoidCallback onPreviousMonth;
  final VoidCallback? onNextMonth;
  final VoidCallback? onExport;
  final VoidCallback? onWatchAd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final isPro = ref.watch(proStatusProvider);
    final credits = ref.watch(pdfExportCreditsProvider);
    // An offer is only drawn when the ledger says it can be honoured right now:
    // a paid user, no ad unit at all, or the day's two already granted all mean
    // "no offer".
    final offer =
        !isPro && ref.read(rewardLedgerProvider).canOffer(RewardKind.pdfExport);
    final canExport = isPro || credits > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(title: s['exportPdfTitle'], padding: EdgeInsets.zero),
        SsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      s['exportPdfBody'],
                      style: SsText.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                  const SizedBox(width: SsSpace.x2),
                  SsBadge(
                    label: s['exportPdfPro'],
                    color: c.gold500,
                    icon: Icons.workspace_premium_rounded,
                  ),
                ],
              ),
              const SizedBox(height: SsSpace.x3),
              Row(
                children: <Widget>[
                  SsIconButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: s['exportMonthPrev'],
                    onPressed: onPreviousMonth,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        s.monthLabel(month.millisecondsSinceEpoch),
                        style: SsText.h3,
                      ),
                    ),
                  ),
                  SsIconButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: s['exportMonthNext'],
                    onPressed: onNextMonth,
                  ),
                ],
              ),
              const SizedBox(height: SsSpace.x3),
              SsActionButton(
                label: s['exportPdfAction'],
                tone: isPro ? SsButtonTone.primary : SsButtonTone.secondary,
                icon: Icons.picture_as_pdf_outlined,
                loading: busy,
                onPressed: canExport ? onExport : null,
              ),
              if (!isPro && credits > 0) ...<Widget>[
                const SizedBox(height: SsSpace.x2),
                Text(
                  s.fill('exportPdfCredits', <String, String>{
                    'n': s.digits('$credits'),
                  }),
                  style: SsText.micro.copyWith(color: c.textTertiary),
                ),
              ],
              if (!isPro && !canExport && !offer) ...<Widget>[
                const SizedBox(height: SsSpace.x2),
                Text(
                  s['exportPdfProOnly'],
                  style: SsText.micro.copyWith(color: c.textTertiary),
                ),
              ],
              if (offer) ...<Widget>[
                const SizedBox(height: SsSpace.x2),
                // Full width below the paid action, like the taste offer on
                // Insights: the label is a whole sentence, and Bengali wraps it.
                SsActionButton(
                  label: s['exportPdfWatchAd'],
                  tone: SsButtonTone.ghost,
                  height: 40,
                  onPressed: onWatchAd,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A password field: obscured, and the same shape as the app's other inputs.
class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: (_) => onChanged(),
      style: SsText.body,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        errorText: errorText,
      ),
    );
  }
}
