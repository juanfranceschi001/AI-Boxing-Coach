# AI Boxing Coach

A Flutter app that turns your phone's camera into a personal boxing coach. It tracks your body in real time, calls out form mistakes by voice, counts your punches, and runs a round timer with a bell. All pose processing happens on the device: no account is needed, and no video ever leaves your phone. The app is supported by AdMob banner ads.

## Features

* **Real-time form coaching:** On-device pose detection (Google ML Kit) checks your stance and guard and gives spoken cues like "Chin down", "Tuck your elbows in", "Widen your stance", and "Bend your knees".
* **Three camera angles:** Front, left side, or right side, with a separate rule set tuned for each view.
* **Punch counter:** Counts punches live while you work.
* **Workout modes:** *Round Timer* (timed rounds with bell and rest breaks) or *Free / Shadow Box* (go until you stop).
* **Session summary:** A post-workout recap of what you did well and what to work on.
* **Workout history:** Past sessions are saved locally on the device.

## Tech Stack

* **Framework:** Flutter (Dart)
* **Pose detection:** `google_mlkit_pose_detection` (runs fully on-device, free, no API key)
* **Camera:** `camera`
* **Voice cues:** `flutter_tts` (the device's built-in text-to-speech)
* **Audio:** `audioplayers` (bundled bell sounds)
* **Storage:** `sqflite` (local SQLite database)
* **Ads:** `google_mobile_ads` (AdMob banner on the home, summary, and history screens; never on the live coaching screen)

## Project Structure

```text
lib/
├── main.dart / app.dart          # Entry point and theme
├── screens/                      # Home, mode/angle/round setup, live coaching, summary, history
├── services/
│   ├── pose_analysis/            # Landmark geometry, per-angle rule sets, punch counter, feedback throttling
│   ├── audio/                    # Bell player and text-to-speech
│   └── session/                  # Round timer, session state, local history storage
├── models/                       # Workout mode, camera angle, form issues, round config, session results
├── data/                         # Coaching feedback text and tips
└── widgets/                      # Pose overlay, feedback banner, punch counter, round indicator
```

## Setup

```bash
git clone https://github.com/juanfranceschi001/AI-Boxing-Coach.git
cd AI-Boxing-Coach
flutter pub get
flutter run
```

No API keys or environment variables are needed. Without `android/admob.properties` (git-ignored, containing `ADMOB_APP_ID=...`), builds use Google's test AdMob App ID, and debug builds always show test ads.

### Release builds

Release signing reads `android/key.properties` (git-ignored) with `storeFile`, `storePassword`, `keyAlias`, and `keyPassword`. If the file is missing, release builds fall back to the debug key.

```bash
flutter build appbundle --release
```

## Privacy

See [PRIVACY.md](PRIVACY.md).
