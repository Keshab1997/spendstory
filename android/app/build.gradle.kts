// Explicit import, not `java.util.Properties()`: inside the Android DSL block
// `java` resolves to the Java plugin's extension, not to the package, and the
// fully-qualified call fails script compilation (it did — see the T-706 note in
// docs/11).
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload-key signing, read from android/key.properties. That file is
// gitignored because it holds the keystore password; the publish-release and
// manual-build workflows write it — and android/app/upload-keystore.jks — from
// repository secrets just before they build, so CI always has them. On a laptop
// that has not been set up the file is absent and release builds fall back to
// the debug key: installable, but not publishable, which is exactly what the
// release workflow's debug-signing warning is about.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.keshabstudios.spendstory"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        // Declared only when key.properties exists: otherwise getByName("release")
        // would be an error, and the release block below depends on this config
        // being absent to pick its fallback.
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storePassword = keystoreProperties.getProperty("storePassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.keshabstudios.spendstory"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // AdMob app id (T-601). Google's published test id, and only the test
        // id: a live id in a debug build is invalid traffic, and the debug
        // flavor is what gets installed from a laptop.
        manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713"
    }

    buildTypes {
        release {
            // Shrinking is what keeps the release APK small, and it is also what
            // broke it: R8 renames WorkManager's Room-generated database (pulled
            // in transitively by google_mobile_ads), so the app died in
            // androidx.startup before Flutter started. proguard-rules.pro keeps
            // that one package. See the file for the full story.
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )

            // The upload key when android/key.properties is present — the
            // workflows always provide it — and the debug key otherwise, so a
            // fresh checkout can still `flutter run --release`.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // The live app id, read from android/local.properties (machine-
            // local and gitignored, like sdk.dir) or from `-Padmob.appId=...`,
            // so it never lands in the repo. Until Keshab fills it in, the
            // fallback is the test id: the SDK then initializes happily and the
            // app shows no ads at all, because the live *unit* ids in
            // lib/ads/ad_ids.dart are empty and nothing is requested. A missing
            // id must not be a release-day crash.
            val localProps = Properties()
            val localFile = project.rootProject.file("local.properties")
            if (localFile.exists()) {
                localFile.inputStream().use { localProps.load(it) }
            }
            val liveAppId = (project.findProperty("admob.appId") as String?)
                ?: localProps.getProperty("admob.appId")
                ?: ""
            manifestPlaceholders["admobAppId"] = liveAppId.ifEmpty {
                "ca-app-pub-3940256099942544~3347511713"
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
