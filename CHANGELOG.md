## 1.0.15-android-scaffold (2026-05-27, branch `r132-android-scaffold`)

* **Android scaffold (R132)**. Adds the Flutter plugin's `android/`
  directory: Gradle module with externalNativeBuild, CMakeLists.txt
  that links per-ABI prebuilt static archives into a single
  `libsymbolic_math_bridge.so`, Kotlin plugin glue that pins the
  wrapper symbols via a JNI force-link entry point, AndroidManifest,
  and a `scripts/build_android.sh` orchestration script (currently
  prints next-step instructions; the real cross-compile chain lives
  in the not-yet-created `math-stack-android-builder` sibling repo).
  The per-ABI `.a` archives (gmp, mpfr, mpc, flint, symengine,
  symengine_flutter_wrapper) are **not yet produced** — until they
  land, Android consumers fall through to the same "bridge
  unavailable" path that today's Linux / Windows builds take. See
  `ANDROID_STATUS.md` for the full roadmap. Not yet merged to main.
* `pubspec.yaml`: declares the `android` platform with
  `ffiPlugin: true` and `package: be.crispstro.symbolic_math_bridge`.
  Version bumped to `1.0.15-android-scaffold`.
* `README.md`: platform badge updated to include Android (with a
  star noting scaffold-only status).

## 0.0.1

* TODO: Describe initial release.
