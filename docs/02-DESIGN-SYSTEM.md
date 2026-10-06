# 02 — Design System

**Direction:** Premium clay-3D fintech
**Base:** Material 3 (Flutter) — overridden so nothing looks default

---

## 1. Design principles

1. **Depth over flat.** Cards float, elements have soft shadow + subtle gradient. Never a hairline-border-only card.
2. **One hero per screen.** Ekta boro 3D illustration ya ekta boro number — baki sob shanto.
3. **Motion with meaning.** State change hole animate kore; decoration er jonno animate kore na.
4. **Negative space is a feature.** Screen 30% faka thakle premium lage.
5. **Dark-first.** Default dark theme; light theme derived, not the other way.

## 2. Color tokens

### Brand ramp

| Token | Hex | Use |
|---|---|---|
| `brandIndigo900` | `#1A1050` | Dark bg foundation |
| `brandIndigo800` | `#241A6B` | Card bg (dark) |
| `brandIndigo600` | `#4C3BD1` | Primary |
| `brandViolet500` | `#7B4DFF` | Primary bright / gradient start |
| `brandViolet400` | `#9B6BFF` | Gradient mid |
| `accentTeal400` | `#2FD4C4` | Accent / positive |
| `accentGold400` | `#F5B843` | Money / highlight / Pro |
| `accentRose400` | `#FF6B8A` | Expense / negative |

### Semantic

| Token | Dark | Light | Meaning |
|---|---|---|---|
| `bg` | `#0E0A2A` | `#F7F6FC` | Screen background |
| `surface` | `#1A1450` | `#FFFFFF` | Card |
| `surfaceElev` | `#241A6B` | `#FFFFFF` | Raised card / sheet |
| `textPrimary` | `#F3F1FF` | `#14102E` | Body |
| `textSecondary` | `#A9A3D0` | `#6B6690` | Caption |
| `income` | `#2FD4C4` | `#00998C` | Credit |
| `expense` | `#FF6B8A` | `#D82F52` | Debit |
| `warning` | `#F5B843` | `#B07908` | 80% budget |
| `danger` | `#FF4D6D` | `#C41E3A` | Over budget |
| `divider` | `rgba(255,255,255,.08)` | `rgba(20,16,46,.08)` | Separator |

### Gradients

```dart
// Hero gradient — splash, paywall, onboarding bg
const heroGradient = LinearGradient(
  begin: Alignment.topLeft, end: Alignment.bottomRight,
  colors: [Color(0xFF1A1050), Color(0xFF4C3BD1), Color(0xFF7B4DFF)],
  stops: [0.0, 0.55, 1.0],
);

// Ambient glow — behind 3D illustrations
const ambientGlow = RadialGradient(
  colors: [Color(0x332FD4C4), Color(0x000E0A2A)],
);

// Money card — balance hero
const moneyGradient = LinearGradient(
  begin: Alignment.topLeft, end: Alignment.bottomRight,
  colors: [Color(0xFF7B4DFF), Color(0xFF4C3BD1)],
);

// Pro / gold
const proGradient = LinearGradient(
  colors: [Color(0xFFF5B843), Color(0xFFFF8A3D)],
);
```

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
// Floating card (default) — soft, wide, low opacity
BoxShadow(color: Color(0x40000000), blurRadius: 28, offset: Offset(0, 12))

// Glass card — onboarding, paywall, hero areas
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.07),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.12)),
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
| Illustration + glow + generous space | Full-bleed photo with text on top |
| One gradient hero per screen | Three gradients competing |
| Tabular money numbers | Proportional digits (kãpe) |
| Animate state change | Animate decoration on loop (battery) |
| Dark-first contrast tuning | Pure black `#000` bg |
| Blur glass on hero surfaces | Blur on list rows (perf killer) |
