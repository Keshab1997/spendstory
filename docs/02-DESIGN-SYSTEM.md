# 02 — Design System

**Direction:** 🅰 **Light & Clean** — LOCKED (light-first, with full dark mode)
**Base:** Material 3 (Flutter) — overridden so nothing looks default
**Theme:** ek-i layout, duটো token set · `ThemeMode.system` default · Settings-e user override
**Reference mockups:** `assets/mockups/*` · board: `docs/design-board.html`

---

## 1. Design principles

1. **Depth over flat.** Cards float, elements have soft shadow + subtle gradient. Never a hairline-border-only card.
2. **One hero per screen.** Ekta boro 3D illustration ya ekta boro number — baki sob shanto.
3. **Motion with meaning.** State change hole animate kore; decoration er jonno animate kore na.
4. **Negative space is a feature.** Screen 30% faka thakle premium lage.
5. **Light-first, dual-theme.** Light is the default (Direction A). Dark is the *same layout* with a dark token set — never a separate design, never a separate widget tree.

## 2. Color tokens

### Accent ramp (shared by both themes)

| Token | Light | Dark | Use |
|---|---|---|---|
| `violet600` | `#6C4CF1` | `#8B6BFF` | Primary — buttons, active state |
| `violet400` | `#8B6BFF` | `#9B6BFF` | Gradient partner, chips |
| `violet100` | `#EFEAFE` | `#2A2450` | Tinted surface |
| `teal500` | `#14C8B8` | `#2FD4C4` | Accent — income, success, progress |
| `teal100` | `#E4FBF7` | `#103A36` | Tinted surface |
| `rose500` | `#FF5A7A` | `#FF6B8A` | Expense, over budget |
| `rose100` | `#FFE8EE` | `#3A1220` | Tinted surface |
| `gold500` | `#F5B843` | `#FFC662` | Money highlight, Pro, 80% warning |

### Semantic

| Token | ☀️ Light (default) | 🌙 Dark | Meaning |
|---|---|---|---|
| `bg` | `#F7F6FC` | `#0E0A2A` | Screen background |
| `surface` | `#FFFFFF` | `#161139` | Card |
| `surfaceElev` | `#FFFFFF` | `#1E1848` | Raised card / sheet |
| `surfaceTint` | `#FAF9FF` | `#1A1450` | Subtle inset area |
| `textPrimary` | `#14102E` | `#F3F1FF` | Body |
| `textSecondary` | `#6B6690` | `#A9A3D0` | Caption |
| `textTertiary` | `#9E99BE` | `#7C76A8` | Disabled / meta |
| `income` | `#0E9E90` | `#2FD4C4` | Credit |
| `expense` | `#E03356` | `#FF6B8A` | Debit |
| `warning` | `#B07908` | `#F5B843` | 80% budget |
| `danger` | `#C41E3A` | `#FF4D6D` | Over budget |
| `border` | `#E7E2F8` | `rgba(255,255,255,.10)` | Card hairline |
| `divider` | `rgba(20,16,46,.07)` | `rgba(255,255,255,.08)` | Separator |
| `shadow` | `rgba(76,59,209,.10)` | `rgba(0,0,0,.45)` | Card shadow |

### Gradients

```dart
// Hero money card — Home (S-09). Light on top, dark below.
const moneyGradientLight = LinearGradient(
  begin: Alignment.topLeft, end: Alignment.bottomRight,
  colors: [Color(0xFF8B6BFF), Color(0xFF6C4CF1)],   // soft violet
);
const moneyGradientDark = LinearGradient(
  begin: Alignment.topLeft, end: Alignment.bottomRight,
  colors: [Color(0xFF8B6BFF), Color(0xFF5B3FE0)],
);

// Ambient glow behind 3D illustrations — soft in light, stronger in dark
const ambientGlowLight = RadialGradient(
  colors: [Color(0x2214C8B8), Color(0x00F7F6FC)],
);
const ambientGlowDark = RadialGradient(
  colors: [Color(0x332FD4C4), Color(0x000E0A2A)],
);

// Pro / gold — paywall CTA, Pro badges
const proGradient = LinearGradient(
  begin: Alignment.topLeft, end: Alignment.bottomRight,
  colors: [Color(0xFFF5B843), Color(0xFFFF8A3D)],
);

// Screen wash — subtle tint at the top of Home / Insights (light theme)
const screenWashLight = LinearGradient(
  begin: Alignment.topCenter, end: Alignment.bottomCenter,
  colors: [Color(0xFFF3F0FF), Color(0xFFF7F6FC)],
  stops: [0.0, 0.32],
);
```

**Rule:** no full-bleed dark gradient in light mode. Light theme uses *tints and washes*, dark theme uses *gradient depth*. Same widget, different token.

## 3. Typography

**Family:** `Manrope` (Latin) + `Noto Sans Bengali` + `Noto Sans Devanagari`
Bundle in `assets/fonts/` — **no Google Fonts network fetch** (on-device principle).

| Style | Size / Line / Weight | Use |
|---|---|---|
| `displayMoney` | 44 / 52 / w800 | Balance number |
| `h1` | 28 / 34 / w700 | Screen title |
| `h2` | 22 / 28 / w700 | Section |
| `h3` | 18 / 24 / w600 | Card title |
| `body` | 15 / 22 / w400 | Default |
| `bodyStrong` | 15 / 22 / w600 | Emphasised row |
| `caption` | 13 / 18 / w400 | Meta |
| `micro` | 11 / 14 / w500 + 0.4 tracking | Label, tab |

**Money rendering rule:** always `fontFeatures: [FontFeature.tabularFigures()]` — number gulo jate na kãpe.

## 4. Spacing & radius

```
space:  4, 8, 12, 16, 20, 24, 32, 40, 56, 72
radius: sm 12 · md 18 · lg 24 · xl 32 · pill 999
screen padding: 20 horizontal
card padding: 18
```

## 5. Elevation / glass

```dart
// Floating card — light: soft violet-tinted; dark: deep black
BoxShadow(
  color: isDark ? const Color(0x66000000) : const Color(0x1A4C3BD1),
  blurRadius: isDark ? 28 : 22,
  offset: const Offset(0, 10),
)

// Glass card — onboarding, paywall, hero areas
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
  child: Container(
    decoration: BoxDecoration(
      color: isDark
          ? Colors.white.withOpacity(0.07)
          : Colors.white.withOpacity(0.72),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFE7E2F8),
      ),
    ),
  ),
)
```

## 6. 3D illustration system

**Files:** `assets/3d/*.jpg|png` · **Style:** clay-3D, indigo→violet→teal, soft rim light, floating props, no text.

| Asset | Screen | Role | Notes |
|---|---|---|---|
| `app-icon.png` | Launcher / store | 1024² icon | Regenerate adaptive icon from this |
| `splash-hero.jpg` | 1. Splash | Center hero | Ken-Burns zoom 1.0→1.08 over 1.4s |
| `onboard-auto-capture.jpg` | 2. Onboarding | Page 1 hero | Parallax on page scroll |
| `onboard-privacy.jpg` | 3. Onboarding | Page 2 hero | Slow float loop |
| `onboard-insights.jpg` | 4. Onboarding | Page 3 hero | Coin orbit micro-loop |
| `permission-sms.jpg` | 6. Permission SMS | Explainer | Static + glow pulse |
| `permission-notification.jpg` | 7. Permission notif | Explainer | Static + glow pulse |
| `empty-transactions.jpg` | 10. Tx empty | Empty state | Fade+scale in |
| `empty-budget.jpg` | 14. Budget empty | Empty state | Fade+scale in |
| `pro-hero.jpg` | 22. Paywall | Hero | Sparkle particle overlay |

**Usage rule:**
- Illustration width = `min(screenWidth * 0.78, 320)`
- Aspect ratio preserve; `BoxFit.contain`
- Always behind it: `ambientGlow` radial, opacity 0.35
- `cacheWidth` set to 2× display width (memory)

**Optimization:** ship `.webp` at 2× (`flutter_image_compress` or `cwebp`), target **< 120 KB each**.

## 7. Motion

| Interaction | Spec |
|---|---|
| Screen enter | `fadeThrough` 260ms (Material motion) |
| Hero illustration | fade + slide-up 24px, 420ms, `easeOutCubic` |
| Card press | scale 0.98, 90ms |
| Number change | count-up 600ms, `easeOutExpo` |
| Budget bar fill | width 0→value, 700ms, `easeOutCubic` |
| Donut chart | sweep 0→360° 900ms + stagger per segment |
| Paywall open | bottom-sheet slide + hero scale 0.94→1.0 |
| Success action | haptic `lightImpact` + tick draw 320ms |
| **Reduced motion** | `MediaQuery.disableAnimations` hole sob 0ms, sudhu opacity |

**Package:** `flutter_animate` (declarative) — no hand-rolled `AnimationController` unless reusable.

## 8. Components (build once, use everywhere)

| Component | File | Notes |
|---|---|---|
| `SsScaffold` | `lib/ui/ss_scaffold.dart` | Gradient bg + safe area + glow layer |
| `GlassCard` | `lib/ui/glass_card.dart` | Blur + border + radius lg |
| `MoneyText` | `lib/ui/money_text.dart` | Tabular figures, currency symbol, color by sign |
| `HeroIllustration` | `lib/ui/hero_illustration.dart` | Asset + ambient glow + entrance animation |
| `SsButton` | `lib/ui/ss_button.dart` | primary / secondary / ghost / gold (Pro) |
| `CategoryChip` | `lib/ui/category_chip.dart` | Icon + label + color |
| `BudgetBar` | `lib/ui/budget_bar.dart` | Animated fill + threshold color |
| `DonutChart` | `lib/ui/donut_chart.dart` | Wraps `fl_chart`, brand palette |
| `EmptyState` | `lib/ui/empty_state.dart` | Illustration + title + CTA |
| `PermissionCard` | `lib/ui/permission_card.dart` | Why-we-need-it explainer |
| `AdSlot` | `lib/ui/ad_slot.dart` | AdMob wrapper + reserved height |

## 9. Accessibility

- Contrast ≥ 4.5:1 for body text (verify tokens in both themes)
- Touch target ≥ 48×48dp
- Semantics label sob icon-only button e
- Money screen-reader announce: "spent 450 rupees" not "4 5 0"
- Font scale 2.0x porjonto layout break hobe na
- Color-alone meaning nei — income/expense e ↑↓ arrow + sign

## 10. Do / Don't

| ✅ Do | ❌ Don't |
|---|---|
| Illustration + soft glow + generous space | Full-bleed photo with text on top |
| One hero card per screen | Three gradients competing |
| Tabular money numbers | Proportional digits (kãpe) |
| Animate state change | Animate decoration on loop (battery) |
| Light theme = tint + wash; dark = gradient depth | Light theme with dark-heavy gradients |
| Same layout in both themes | Separate widget tree per theme |
| Blur glass on hero surfaces only | Blur on list rows (perf killer) |
| Soft violet-tinted shadows (light) | Pure black shadows in light mode |

---

## Addendum — Design decision locked (Direction A)

**Decided:** Light & Clean, **light-first with full dark mode**. Reference: `assets/mockups/`, board at `docs/design-board.html`.

### What the mockups established

| Element | Locked decision |
|---|---|
| Background | Light `#F7F6FC` with a soft violet wash at the top; dark `#0E0A2A` |
| Cards | White, radius 22–24, soft violet-tinted shadow, **no hard borders** |
| Hero card | Violet gradient, one huge balance number, two stat pills (teal income / rose spending) |
| Quick actions | 4 rounded square buttons with line icons + labels underneath |
| Budget bar | Slim, rounded, gradient fill teal→violet; amber at 80%, rose at 100% |
| Transaction row | 40dp pastel circular icon · merchant bold · category+time caption · tabular right amount |
| Amount colours | teal `+` income, rose `−` expense — **sign always visible**, never colour-only |
| Bottom nav | Floating rounded bar, 4 items, icon + label, active = teal |
| Typography | Clean geometric sans; money in tabular figures |
| Motion | Gentle: count-up, bar fill, list stagger — nothing flashy |

### Theme implementation rules

```dart
// lib/ui/tokens.dart — one source, two sets
class SsTheme {
  static ThemeData light() => _base(Brightness.light, _lightTokens);
  static ThemeData dark()  => _base(Brightness.dark,  _darkTokens);
}
```
- `MaterialApp(themeMode: ref.watch(themeModeProvider))` — values: `system | light | dark`, **default `system`**
- Settings → থিম (ডার্ক ডিফল্ট / লাইট / সিস্টেম) — default label is honest: it follows the system
- **No screen may read a hardcoded colour.** Every colour comes from `Theme.of(context).extension<SsColors>()!`
- Golden tests must render **every** screen in both brightnesses — one test file per screen, two goldens

### Asset follow-up (important)

The first 10 illustrations in `assets/3d/` were generated **on a dark indigo background** — they suit dark mode. For light mode we need the same 10 props rendered **on a light / transparent-feeling background** with the soft violet-teal glow.

**Task for the next image batch (T-806):** generate light-mode variants → `assets/3d/light/*`, keep dark set in `assets/3d/dark/*`, and let `HeroIllustration` pick by brightness. Until then, wrap the dark assets in the `ambientGlowLight` container — acceptable, not final.
