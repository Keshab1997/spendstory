/// S-02 … S-04 Onboarding.
///
/// Three pages, one idea each, in the order a new user needs them:
/// **it captures by itself → you can see where the money goes → your data never
/// leaves the phone.** The third page is not filler: for an app that asks to read
/// bank SMS, the privacy answer has to arrive *before* the permission prompt, not
/// after it.
///
/// The parallax is a single [PageController] feeding an [AnimatedBuilder]: the
/// illustration moves at 40% of the page offset and the text at 18%, which reads
/// as depth without costing a second animation controller.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../components/controls.dart';
import '../components/surfaces.dart';
import '../tokens.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.page});

  /// 1-based, straight from the route (`/onboarding/2`).
  final int page;

  static const int pageCount = 3;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.page - 1);
  }

  @override
  void didUpdateWidget(OnboardingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The URL is the source of truth. A `PageView` keeps its own page across a
    // rebuild, so without this a link to `/onboarding/3` opens page 2 for anyone
    // who is already inside the flow — and `onPageChanged` would then write page
    // 2 straight back into the URL, hiding the fact that the link was ignored.
    final target = (widget.page - 1).clamp(0, OnboardingScreen.pageCount - 1);
    final current =
        _controller.hasClients && _controller.position.haveDimensions
        ? _controller.page?.round()
        : _controller.initialPage;
    if (current != target) {
      _controller.jumpToPage(target);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (page > OnboardingScreen.pageCount) {
      context.go('/permission/sms');
      return;
    }
    _controller.animateToPage(
      page - 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);

    final pages = <_ObPage>[
      _ObPage(
        asset: 'assets/3d/onboard-auto-capture.jpg',
        title: s['ob1Title'],
        body: s['ob1Body'],
        bullets: <String>[s['ob1B1'], s['ob1B2'], s['ob1B3']],
        tint: c.violet600,
      ),
      _ObPage(
        asset: 'assets/3d/onboard-insights.jpg',
        title: s['ob2Title'],
        body: s['ob2Body'],
        bullets: <String>[s['ob2B1'], s['ob2B2'], s['ob2B3']],
        tint: c.teal500,
      ),
      _ObPage(
        asset: 'assets/3d/onboard-privacy.jpg',
        title: s['ob3Title'],
        body: s['ob3Body'],
        bullets: <String>[s['ob3B1'], s['ob3B2'], s['ob3B3']],
        tint: c.gold500,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(color: c.bg, gradient: c.screenWash),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final raw =
                  _controller.hasClients && _controller.position.haveDimensions
                  ? _controller.page ?? (_controller.initialPage.toDouble())
                  : _controller.initialPage.toDouble();
              final index = raw.round().clamp(0, pages.length - 1);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SsSpace.screen,
                      SsSpace.x3,
                      SsSpace.screen,
                      0,
                    ),
                    child: Row(
                      children: [
                        _Dots(count: pages.length, active: index),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.go('/permission/sms'),
                          style: TextButton.styleFrom(
                            foregroundColor: c.textSecondary,
                          ),
                          child: Text(
                            s['obSkip'],
                            style: SsText.bodyStrong.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      physics: const BouncingScrollPhysics(),
                      itemCount: pages.length,
                      onPageChanged: (i) {
                        // Keep the URL honest so a reload lands on the same page.
                        if (widget.page != i + 1) {
                          context.go('/onboarding/${i + 1}');
                        }
                      },
                      itemBuilder: (context, i) =>
                          _ObPageView(page: pages[i], pageDelta: i - raw),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SsSpace.screen,
                      SsSpace.x3,
                      SsSpace.screen,
                      SsSpace.x5,
                    ),
                    child: Row(
                      children: [
                        if (index > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: SsSpace.x3),
                            child: SsActionButton(
                              label: s['obBack'],
                              tone: SsButtonTone.secondary,
                              expanded: false,
                              onPressed: () => _goTo(index),
                            ),
                          ),
                        Expanded(
                          child: SsActionButton(
                            label: index == pages.length - 1
                                ? s['obStart']
                                : s['obNext'],
                            onPressed: () => _goTo(index + 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ObPage {
  const _ObPage({
    required this.asset,
    required this.title,
    required this.body,
    required this.bullets,
    required this.tint,
  });

  final String asset;
  final String title;
  final String body;
  final List<String> bullets;
  final Color tint;
}

class _ObPageView extends StatelessWidget {
  const _ObPageView({required this.page, required this.pageDelta});

  final _ObPage page;

  /// How far this page sits from the current scroll position, in pages.
  final double pageDelta;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    // Two rates: the artwork moves faster than the text.
    final artShift = -pageDelta * 42;
    final textShift = -pageDelta * 20;
    final fade = (1 - pageDelta.abs() * 0.6).clamp(0.25, 1.0);

    return Opacity(
      opacity: fade,
      child: SingleChildScrollView(
        // A `PageView` gives its child a fixed height, and a Column that does
        // not fit does not spill — it overflows. Bengali and Hindi are the
        // tallest of the three languages here, and at 1.3× text scale on a
        // 360×640 phone the copy is taller than the space between the dots and
        // the buttons. Scrolling inside the page is the honest fix: nothing is
        // clipped, nothing is shrunk to an unreadable size, and on a normal
        // phone at 1.0× there is nothing to scroll and no scrollbar appears.
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: SsSpace.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: SsSpace.x4),
            Transform.translate(
              offset: Offset(artShift, 0),
              child: HeroIllustration(
                asset: page.asset,
                height: 216,
                glowTint: page.tint,
              ),
            ),
            const SizedBox(height: SsSpace.x6),
            Transform.translate(
              offset: Offset(textShift, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(page.title, style: SsText.h1),
                  const SizedBox(height: SsSpace.x3),
                  Text(
                    page.body,
                    style: SsText.body.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: SsSpace.x5),
                  for (final b in page.bullets) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.tintOf(page.tint),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: page.tint,
                          ),
                        ),
                        const SizedBox(width: SsSpace.x3),
                        Expanded(
                          child: Text(
                            b,
                            style: SsText.body.copyWith(color: c.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SsSpace.x3),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return Row(
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(right: 6),
            height: 6,
            width: i == active ? 22 : 6,
            decoration: BoxDecoration(
              color: i == active ? c.violet600 : c.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}
