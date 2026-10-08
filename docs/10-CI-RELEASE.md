# 10 — CI, Build & Release

**Repo:** `Keshab1997/spendstory` (public → unlimited Actions minutes)
**Builder:** `Keshab1997/flutter-builder@v1.14.1` (reusable workflows)

---

## 1. Installed workflows

| File | Actions name | Trigger | Does |
|---|---|---|---|
| `.github/workflows/ci.yml` | Flutter CI — Format, Analyze & Test | **manual only** | format check + analyze + test + coverage; **no APK/AAB** |
| `.github/workflows/manual-build.yml` | Build Android APK or AAB (Manual) | manual | builds artifact on demand |
| `.github/workflows/publish-release.yml` | Publish Signed Android Release | manual | signed APK/AAB → GitHub Release; optional Play internal upload |
| `.github/workflows/web-preview.yml` | Deploy Flutter Web Preview (GitHub Pages) | manual | branch-based Pages preview |

**Nothing runs on push.** Batch changes → one manual run. → `AGENTS.md` §Rule #1.

**CI is the source of truth.** Local Flutter (3.47.6 here) is indicative only; CI pins its own version.

## 2. Local check policy (from AGENTS.md §4 — do not exceed)

| Change | Check |
|---|---|
| anything | `python3 tool/preflight.py` (~1s) |
| a Dart edit | `flutter test test/<name>_test.dart` — that one file |
| shared surface / risky / human asks | `flutter analyze` + full `flutter test` |
| **never** | `flutter build apk\|aab\|web` or `gradlew` locally |

## 3. Flutter setup in the sandbox (~40s, reinstalls every session)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Keshab1997/flutter-bootstrap/main/setup.sh) \
  --root /var/tmp/flutter --quiet --json
export PATH=/var/tmp/flutter/bin:$PATH PUB_CACHE=/var/tmp/pub-cache
```
`/var/tmp` is **not** persisted between turns — the 40s reinstall is normal, not a bug.

## 4. Android signing

**Never commit:** `*.jks`, `*.keystore`, `key.properties`, `google-services.json`, any token. `tool/agent_loop.py` blocks these at commit time.

### One-time keystore creation (run once, locally, NOT in this sandbox)

```bash
keytool -genkey -v -keystore ~/spendstory-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Repo secrets to add (Settings → Secrets → Actions)

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 ~/spendstory-upload.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | key password |
| `PLAY_SERVICE_ACCOUNT_JSON` | Play Console → API access → service account (only if publishing to Play from CI) |
| `ADMOB_APP_ID` | `ca-app-pub-…~…` (production App ID) |

⚠️ **Play Console App Signing:** enable it. Upload key different hoy from app signing key — upload key harale Play support theke reset kora jay.

## 5. `build.gradle.kts` — release config

```kotlin
android {
  namespace = "com.keshabstudios.spendstory"
  compileSdk = 36

  defaultConfig {
    applicationId = "com.keshabstudios.spendstory"
    minSdk = 26          // Android 8.0 — covers 96%+ Indian devices
    targetSdk = 36
    versionCode = flutterVersionCode.toInt()
    versionName = flutterVersionName
  }

  signingConfigs {
    create("release") {
      storeFile = file(System.getenv("ANDROID_KEYSTORE_PATH") ?: "upload.jks")
      storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
      keyAlias = System.getenv("ANDROID_KEY_ALIAS")
      keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
    }
  }

  buildTypes {
    release {
      signingConfig = signingConfigs.getByName("release")
      isMinifyEnabled = true
      isShrinkResources = true
      proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
  }
}
```

**ProGuard/R8 keep rules** (`android/app/proguard-rules.pro`) — ad SDK + drift reflection:
```proguard
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.ump.** { *; }
-keep class io.flutter.plugins.** { *; }
-keepclassmembers class * extends androidx.work.Worker { <init>(...); }
```

## 6. Version bump

```bash
python3 ../flutter-builder/scripts/bump-pubspec-version.py   # if available in repo
# or manual:
# pubspec.yaml:  version: 1.0.0+1   →   1.0.1+2
```
`versionCode` must increase on **every** Play upload. `versionName` = user-facing.

## 7. Release runbook (per Play release)

```
[ ] 1  flutter-builder ref up to date?  → bump-ref.sh (if a new tag exists)
[ ] 2  Update distribution/whatsnew/{en-US,hi-IN,bn-IN}
[ ] 3  Bump version in pubspec.yaml
[ ] 4  python3 tool/preflight.py
[ ] 5  Push to main (agent_loop.py -m "chore(release): v1.x.x")
[ ] 6  Ask Keshab: dispatch "Flutter CI" — read result (ci_watch.py)
[ ] 7  Ask Keshab: dispatch "Publish Signed Android Release" → choose AAB
[ ] 8  Play Console → Internal testing → verify on real device
[ ] 9  Play Console → Closed testing (12+ testers, 14 days) — new personal accounts
[ ] 10 Play Console → Production → staged rollout 10% → 50% → 100%
```

**Steps 7, 9, 10 = Keshab's button.** Never dispatch a release without asking (AGENTS.md §6: irreversible/public actions need a human).

## 8. Play Console — first-time setup

| Item | Value |
|---|---|
| App name | `SpendStory: Expense Tracker` |
| Package | `com.keshabstudios.spendstory` |
| Default language | English (US) — en-US |
| Free/Paid | **Free** (irreversible choice) |
| Category | Finance |
| Content rating | Everyone |
| Ads declaration | **Yes, contains ads** (AdMob) |
| Target audience | 18+ |
| Privacy policy URL | GitHub Pages link |
| Data safety | per `07-PERMISSIONS-POLICY.md` §4 |
| SMS declaration | per `07` §2 |

### New-account reality (personal developer accounts)

If the account is new/personal, Play requires **closed testing with ≥12 testers for 14 continuous days** before production. Plan the timeline: docs → build → internal → closed (14 days) → production.
Recruiting testers: friends/family + r/androidapps + your own contacts. **Do not** buy testers (policy risk).

## 9. GitHub Pages (privacy policy + web preview)

- `web-preview.yml` deploys a Flutter web build to a branch-based Pages preview.
- **Privacy policy** needs its own public URL — simplest: put `docs/privacy-policy.md` (to be written in M2) in the repo and enable Pages on `/docs`, or use a `privacypolicy` repo like the existing `Keshab1997/privacy_policy`.
- Enable Pages: Settings → Pages → Source → Deploy from branch (after the first web-preview run).

## 10. Monitoring after release

| Signal | Where | Response |
|---|---|---|
| Crash-free rate < 99% | Play Console → Vitals | fix → hotfix patch |
| ANR | Play Console → Vitals | look for main-thread DB work |
| AdMob eCPM / fill | AdMob console | adjust placement, never add intrusive units |
| Reviews < 4.0 | Play Console | read every 1–3 ★ review; reply |
| SMS parse failures | in-app `parse_log` → user-reported JSON | bump `ruleVersion`, ship parser fix |

---

## 11. What the first APK build taught us (2026-10-08)

`ci.yml` runs format + analyze + tests and **deliberately does not build
Android** (`build-apk: false`, `build-aab: false`), so nothing had ever compiled
`android/` on CI. The first-ever dispatch of `manual-build.yml` (while landing
T-706, whose app lock touches `MainActivity`, the manifest and the launch themes)
failed before reaching a single Kotlin file. Two pre-existing faults, both fixed
and both worth remembering:

1. **`android/app/build.gradle.kts` did not compile.** Inside the Android DSL
   block the name `java` resolves to the Java plugin's extension, so a
   fully-qualified `java.util.Properties()` is an unresolved reference — and the
   errors around it made Gradle also report the DSL accessor as deprecated. The
   fix is one explicit `import java.util.Properties`. (The AdMob app-id lookup
   that needed `Properties` is from T-601; it had never been compiled.)
2. **`permission_handler` 13 pulls `permission_handler_android` 14**, whose AAR
   is built against `compileSdk 37` — newer than Flutter 3.47's default (36) and
   than the maximum AGP 9.1.0 recommends, so
   `:app:checkReleaseAarMetadata` fails. `pubspec.yaml` now pins
   `permission_handler: ^12.0.3` (resolves `permission_handler_android` 13.0.1,
   `compileSdk 35`); the Dart API the app uses is unchanged. Lift the pin when
   the toolchain moves to AGP 9.2 + compileSdk 37.

3. **`integration_test` in `dev_dependencies` broke the release build.** With
   it listed, the Flutter tool writes an Android `GeneratedPluginRegistrant` that
   registers `IntegrationTestPlugin`, while the Gradle side does not put the
   module on the classpath — `:app:compileReleaseJavaWithJavac` then fails with
   "package dev.flutter.plugins.integration_test does not exist". The repo has no
   `integration_test/` suite, so the dependency was removed; put the directory
   and the dependency back together when a suite exists.

**Suggestion for Keshab (workflow change, his call):** give `ci.yml`
`build-apk: true`, or add a nightly dispatch of `manual-build.yml`. A Dart-green
repo that cannot assemble an APK is the failure mode nobody sees until release
day — today's run took 5 minutes and found two of them.
