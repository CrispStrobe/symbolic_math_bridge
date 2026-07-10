# Third-Party Notices

`symbolic_math_bridge` (this plugin's own Dart/Swift/wrapper code) is
MIT-licensed (see LICENSE). It bundles, as prebuilt XCFrameworks under
`ios/` and `macos/`, a native mathematics stack whose components keep
their own upstream licenses. **Several are LGPL** -- if you ship an app
that links this plugin, you must comply with them. See
`math-stack-ios-builder`'s `LGPL-COMPLIANCE.md`
(https://github.com/CrispStrobe/math-stack-ios-builder) for the two
routes (AGPL combined-work vs. dynamic relinkable frameworks). The
prebuilt frameworks shipped here are the **static** build, which is
appropriate for the AGPL combined-work route (Route A).

## Bundled native libraries

| Library   | License                       | Upstream |
|-----------|-------------------------------|----------|
| SymEngine | MIT                           | https://github.com/symengine/symengine |
| GMP       | LGPL-3.0-or-later / GPL-2.0+  | https://gmplib.org/ |
| MPFR      | LGPL-3.0-or-later             | https://www.mpfr.org/ |
| MPC       | LGPL-3.0-or-later             | https://multiprecision.org/mpc/ |
| FLINT     | LGPL-2.1-or-later             | https://flintlib.org/ |
| cereal    | BSD-3-Clause (bundled in SymEngine's headers) | https://github.com/USCiLab/cereal |

The full license texts are obtainable at the upstream URLs above and from
the FSF (for the (L)GPL ones). The SymEngine wrapper's C entry points and
the Flutter/FFI glue are covered by this repo's MIT LICENSE.

## Dart dependencies

`ffi` and `plugin_platform_interface` (declared in `pubspec.yaml`) are
BSD-3-Clause, published by the Dart/Flutter team. Flutter's built-in
`showLicensePage()` surfaces these in a consuming app automatically; the
native stack above does not appear there unless the app registers it (see
CrispCalc's `native_licenses.dart` for the pattern).
