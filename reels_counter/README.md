# Reels Counter

A Flutter app (Android-first) that counts how many reels/short videos you scroll through, with a floating always-on-top pill overlay showing 🧠👁️ + count.

## Folder structure

```
reels_counter/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   └── counter_data.dart
│   ├── services/
│   │   ├── storage_service.dart      # SharedPreferences persistence + daily reset
│   │   ├── native_bridge.dart        # MethodChannel/EventChannel to Android
│   │   └── alert_service.dart        # vibration + "take a break" notification
│   ├── widgets/
│   │   └── counter_pill.dart         # in-app preview of the overlay pill
│   └── screens/
│       ├── home_screen.dart
│       └── settings_screen.dart
├── android/
│   └── app/src/main/
│       ├── kotlin/com/reelscounter/app/
│       │   ├── MainActivity.kt              # Flutter <-> native bridge
│       │   ├── ReelScrollAccessibilityService.kt  # detects swipes
│       │   ├── OverlayService.kt            # draws the floating pill
│       │   └── CounterBus.kt                # in-process pub/sub
│       ├── res/xml/accessibility_service_config.xml
│       └── AndroidManifest.xml
└── pubspec.yaml
```

## How detection works

`ReelScrollAccessibilityService` listens for window/content-change events from an allow-list of apps (Instagram, TikTok, YouTube, Snapchat) and increments the counter when it detects a new full-screen render — which is what happens each time you swipe to the next reel. It debounces rapid duplicate events so one physical swipe = one count.

**Important caveat:** Android's Accessibility API doesn't expose a clean "user swiped to next reel" event — every app's UI tree is different and these apps update their internals frequently. This heuristic is a reasonable starting point but you'll likely need to test it against the actual current versions of Instagram/TikTok/YouTube on a real device and tune the debounce timing or add more specific view-ID checks (using Android Studio's Layout Inspector) for reliable accuracy. Treat this as the foundation, not a finished, pixel-perfect detector.

**Privacy:** the service never calls screenshot APIs, never reads text content, and never stores anything beyond the integer count.

## Setup instructions

1. **Install Flutter** (if you haven't): https://docs.flutter.dev/get-started/install

2. **Get the project**: unzip this folder, then from inside it run:
   ```bash
   flutter pub get
   ```

3. **Regenerate platform glue** (recommended, since `local.properties` here is just a placeholder):
   ```bash
   flutter create .
   ```
   This will safely fill in `android/local.properties` with your actual SDK paths without overwriting the custom Kotlin files.

4. **Connect an Android device or start an emulator**, then run:
   ```bash
   flutter run
   ```

5. **On first launch**, the app will prompt you to:
   - Enable the **Accessibility Service** (Settings → Accessibility → Reels Counter → On)
   - Grant **"Display over other apps"** permission (for the floating overlay)

6. **Build a release APK**:
   ```bash
   flutter build apk --release
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`

## Permissions required

| Permission | Why |
|---|---|
| Accessibility Service | Detect swipe/scroll events in target apps |
| `SYSTEM_ALERT_WINDOW` | Draw the floating overlay pill |
| `FOREGROUND_SERVICE` | Keep the overlay alive reliably |
| `VIBRATE` | Haptic feedback every 10 reels |
| `POST_NOTIFICATIONS` | "Take a break" alert at daily limit |

## Things to verify/tune on your device

- The exact accessibility event pattern that fires per-swipe can drift between app versions — test on the real apps and adjust `debounceMs` / event filtering in `ReelScrollAccessibilityService.kt` if counts feel off.
- Battery optimization: some OEMs (Samsung, Xiaomi, etc.) aggressively kill background services — you may need to whitelist the app in battery settings for the overlay/accessibility service to stay alive long-term.
