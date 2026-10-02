The full Linux CAS wrapper is vendored from CrispStrobe/math-stack-ios-builder
commit 167ecfe01d87f84dc1874575ed06c5b511d0efa1 (src/). It includes the C++
implementation used by the Apple and FLINT WebAssembly builds, including
factorization, rational cancellation and Taylor series.

Linux compiles these sources against its vcpkg math stack. The historical
shared src/ C-only wrapper remains unchanged for other platform build recipes.
Update all three files together when importing upstream changes.
