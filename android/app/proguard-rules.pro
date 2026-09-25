# R8 strips constructors that are only reached via reflection, which made
# release builds crash on launch:
#  - ML Kit discovers its component registrars reflectively (no-arg <init>).
#  - WorkManager (pulled in by the Google Mobile Ads SDK) instantiates its
#    Room database implementation reflectively.
-keep class com.google.mlkit.** { *; }
-keep class * implements com.google.firebase.components.ComponentRegistrar { <init>(); }
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.** { *; }
