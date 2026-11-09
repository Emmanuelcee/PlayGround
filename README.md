# PlayGround

<!-- omgithub:readme:start -->
## 🚀 Build, play, and remix with OMGithub

**Created using [OMGithub.com](https://go.ondev.store/).**

[![OMGithub](https://img.shields.io/badge/OMGithub-Open%20project-orange?style=for-the-badge)](https://go.ondev.store/Emmanuelcee/PlayGround)
[![GitHub](https://img.shields.io/badge/GitHub-Source-181717?logo=github&style=for-the-badge)](https://github.com/Emmanuelcee/PlayGround)

- 🎮 [Open the project](https://go.ondev.store/Emmanuelcee/PlayGround).
- ✨ [Remix this project](https://go.ondev.store/Emmanuelcee/PlayGround?remix=1).
- 💻 [Explore the source](https://github.com/Emmanuelcee/PlayGround).
- 🛠️ [Check build runs](https://github.com/Emmanuelcee/PlayGround/actions).
- 🐛 [Report an issue](https://github.com/Emmanuelcee/PlayGround/issues).
- 👤 [Explore the creator's projects](https://go.ondev.store/Emmanuelcee).
- 🌍 [Create with OMGithub](https://go.ondev.store/).
<!-- omgithub:readme:end -->

# ULTIMATE STREET RACERS 2026

A procedural 3D street-racing prototype made with Godot 4 and the GL Compatibility renderer. Cars and tracks are generated from built-in meshes; no external art assets are required.

## Play on desktop

1. Install **Godot 4.2 or newer**.
2. Open this repository's `project.godot` in Godot (or import the project from the Project Manager).
3. Press **F6** to run the current scene or **F5** to run the project.

**Keyboard controls:** W / ↑ accelerate, S / ↓ brake/reverse, A / ← and D / → steer, Space drift, Shift nitro, Esc pause/resume. On a touch device, use the on-screen controls. The game is designed for landscape orientation.

Choose a mode and track from the home screen. The garage includes 10 unlockable cars, paint choices, engine upgrades, and wheel-style selection. Race progress and credits are saved locally. Online multiplayer is not implemented; it is shown as a future-update option.

## Export an Android APK or Google Play AAB

You need Godot 4.2+, the matching Godot export templates, and the Android export toolchain. Install Android Studio or the Android command-line tools, an Android SDK platform/build tools version supported by your Godot release, and a compatible JDK (Godot's current Android export documentation lists the supported versions). In Godot, configure **Editor → Editor Settings → Export → Android** with the paths to the Java SDK and Android SDK, then install templates through **Editor → Manage Export Templates**.

1. Open the project and choose **Project → Export**.
2. Add an **Android** preset. Set a unique reverse-DNS package name (for example, `com.yourstudio.ultimatestreetracers`), app name, version, and any signing details required for your distribution. Keep landscape orientation enabled.
3. For a directly installable build, select the Android preset and click **Export Project** to create an `.apk`. For local testing, a debug APK is usually sufficient; enable/install the debug keystore as prompted.
4. For Google Play, enable **Gradle Build** in the Android preset if the Godot version/toolchain requires it, then export a **release `.aab`** with your own release keystore. Keep the keystore and passwords private and backed up; do not commit them to this repository.
5. Test the exported build on a physical Android device, especially touch controls, safe-area/layout behavior, and performance on the intended device range.

The repository currently contains the Godot project but no committed Android export preset or signing key. Export setting names and SDK/JDK requirements can vary slightly by Godot version; refer to the official [Godot Android export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html) and Android's [Play App Signing](https://developer.android.com/studio/publish/app-signing) guidance for current release requirements.

## Project layout

- `project.godot` — display, renderer, and project settings.
- `scenes/main.tscn` — main scene.
- `scripts/main.gd` — menus, procedural tracks, race flow, AI, HUD, progression, and results.
- `scripts/car.gd` — procedural car visuals and arcade driving behavior.

Headless startup and race-flow smoke checks passed with Godot 4.7.2. Android APK/AAB export and on-device testing remain pending.
