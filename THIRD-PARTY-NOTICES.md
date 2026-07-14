# Third-Party Notices

`symbolic_math_bridge`'s own Dart, Swift, Objective-C and C wrapper code is
MIT-licensed (see LICENSE). This package also bundles native mathematics
libraries as prebuilt binaries under `ios/`, `macos/`, `android/`, `linux/`,
and `windows/`. Those binaries are not MIT-licensed by this repository; each
component keeps its upstream license.

The Apple frameworks currently shipped here are the **static** build of the
native stack. If you distribute an app that links those LGPL libraries, you must
provide the notices, source/build information, and practical rebuild or relink
path required by the relevant LGPL versions. See `math-stack-ios-builder`'s
`LGPL-COMPLIANCE.md`:
https://github.com/CrispStrobe/math-stack-ios-builder/blob/master/LGPL-COMPLIANCE.md

## Bundled native libraries

| Library   | License                                      | Upstream |
|-----------|----------------------------------------------|----------|
| SymEngine | MIT                                          | https://github.com/symengine/symengine |
| GMP       | LGPL-3.0-or-later / GPL-2.0-or-later         | https://gmplib.org/ |
| MPFR      | LGPL-3.0-or-later                            | https://www.mpfr.org/ |
| MPC       | LGPL-3.0-or-later                            | https://multiprecision.org/mpc/ |
| FLINT     | LGPL-2.1-or-later                            | https://flintlib.org/ |
| cereal    | BSD-3-Clause (bundled in SymEngine headers)  | https://github.com/USCiLab/cereal |
| Bison parser skeletons in generated SymEngine parser headers | GPL text with the standard GNU Bison special exception | https://www.gnu.org/software/bison/ |

The full license texts are obtainable at the upstream URLs above and from the
FSF for the LGPL/GPL-family texts. The Flutter/FFI glue and SymEngine wrapper C
entry points written in this repository are covered by this repo's MIT LICENSE.

## Dart dependencies

`ffi` and `plugin_platform_interface` (declared in `pubspec.yaml`) are
BSD-3-Clause, published by the Dart/Flutter team. Flutter's built-in
`showLicensePage()` surfaces these in a consuming app automatically; the
native stack above does not appear there unless the app registers it (see
CrispCalc's `native_licenses.dart` for the pattern).
