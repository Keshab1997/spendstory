# SpendStory release shrinker rules.
#
# google_mobile_ads 9.1.0 -> play-services-ads 25.4.0 -> androidx.work:work-runtime
# 2.7.0 -> androidx.room:room-runtime 2.2.5. That work-runtime is from 2022, and
# R8 (which the release build always runs) renames WorkDatabase_Impl, so Room's
# reflective lookup of the generated implementation fails. The failure happens
# inside WorkManagerInitializer during androidx.startup, which runs from a
# ContentProvider *before* Flutter's main() — so the process is killed on a cold
# start and the user sees a blank app that immediately dies. Debug builds never
# minify, which is why this only ever reproduced on release.
#
# Keeping the whole impl package (both WorkDatabase and WorkDatabase_Impl, and
# anything else in there) is the fix the googleads-mobile-flutter maintainers
# pointed at — see googleads-mobile-flutter#1444. Delete this once the Google
# Mobile Ads SDK ships a current work-runtime and the crash stops reproducing on
# a release build without it.
-keep class androidx.work.impl.** { *; }
-dontwarn androidx.work.impl.**
