// android/src/main/cpp/force_link.c
//
// R132 scaffold — Android equivalent of iOS's SymEngineBridge.m
// + DummySymbols.c trick. Declares every `flutter_symengine_*` C
// entry point as `extern`, and `forceLinkSymbols()` returns the
// sum of their addresses (modulo a volatile sink) so the
// compiler can't constant-fold the references away and the
// linker can't dead-code-strip them.
//
// Real symbol resolution still happens through dart:ffi
// DynamicLibrary.open + DynamicLibrary.lookup at runtime. This
// file's only job is to convince the static linker that the
// wrapper archive's object files are reachable.
//
// Until the prebuilt libsymengine_flutter_wrapper.a lands in
// src/main/jniLibs/<abi>/, every extern below is unresolved at
// link time. The CMakeLists.txt detects the missing archive and
// drops the --whole-archive link line so the .so still assembles;
// in that mode forceLinkSymbols() compiles but its function body
// references are dropped by the linker (the function returns 0
// since the addresses fold to constants).

// jni.h is only available when the NDK sysroot is on the include
// path — that's the case for the Gradle externalNativeBuild flow but
// NOT for the vcpkg-driven standalone CMake CI build (vcpkg's Android
// triplet sets the NDK toolchain but doesn't add jni.h to the include
// search path, since cross-compiled C libraries don't usually need
// it). Make the JNI binding conditional so both modes compile.
#if defined(__has_include) && __has_include(<jni.h>)
#include <jni.h>
#define SYMBOLIC_MATH_BRIDGE_HAVE_JNI 1
#else
#define SYMBOLIC_MATH_BRIDGE_HAVE_JNI 0
#endif

#include <stddef.h>

// === Core symbolic ops =================================================
extern char* flutter_symengine_evaluate(const char*);
extern char* flutter_symengine_solve(const char*, const char*);
extern char* flutter_symengine_expand(const char*);
extern char* flutter_symengine_factor(const char*);
extern char* flutter_symengine_differentiate(const char*, const char*);
extern char* flutter_symengine_substitute(const char*, const char*, const char*);
extern void  flutter_symengine_free_string(char*);

// === Math functions ====================================================
extern char* flutter_symengine_abs(const char*);
extern char* flutter_symengine_sin(const char*);
extern char* flutter_symengine_cos(const char*);
extern char* flutter_symengine_tan(const char*);
extern char* flutter_symengine_asin(const char*);
extern char* flutter_symengine_acos(const char*);
extern char* flutter_symengine_atan(const char*);
extern char* flutter_symengine_sinh(const char*);
extern char* flutter_symengine_cosh(const char*);
extern char* flutter_symengine_tanh(const char*);
extern char* flutter_symengine_asinh(const char*);
extern char* flutter_symengine_acosh(const char*);
extern char* flutter_symengine_atanh(const char*);
extern char* flutter_symengine_exp(const char*);
extern char* flutter_symengine_log(const char*);
extern char* flutter_symengine_sqrt(const char*);
extern char* flutter_symengine_gamma(const char*);

// === Number theory =====================================================
extern char* flutter_symengine_gcd(const char*, const char*);
extern char* flutter_symengine_lcm(const char*, const char*);
extern char* flutter_symengine_factorial(int);
extern char* flutter_symengine_fibonacci(int);

// === Constants =========================================================
extern char* flutter_symengine_get_pi(void);
extern char* flutter_symengine_get_e(void);
extern char* flutter_symengine_get_euler_gamma(void);

// === Arbitrary-precision (MPFR) ========================================
extern char* flutter_symengine_pi_with_precision(int);
extern char* flutter_symengine_e_with_precision(int);
extern char* flutter_symengine_euler_gamma_with_precision(int);
extern char* flutter_symengine_sqrt2_with_precision(int);

// === Number-theory primitives (FLINT) ==================================
extern char* flutter_symengine_isprime(const char*);
extern char* flutter_symengine_nextprime(const char*);
extern char* flutter_symengine_prevprime(const char*);
extern char* flutter_symengine_factorint(const char*);

// === Matrix functions ==================================================
extern void* flutter_symengine_matrix_new(int, int);
extern void  flutter_symengine_matrix_free(void*);
extern int   flutter_symengine_matrix_set_element(void*, int, int, const char*);
extern char* flutter_symengine_matrix_get_element(void*, int, int);
extern char* flutter_symengine_matrix_to_string(void*);

// Plain C entry point. Always present, regardless of whether the build
// has access to jni.h. Takes addresses of every flutter_symengine_*
// entry point through a volatile sink so the compiler can't constant-
// fold them away and the linker can't dead-code-strip them.
int symbolic_math_bridge_force_link_symbols(void) {
    volatile void* sink = NULL;

    sink = (void*)&flutter_symengine_evaluate;       (void)sink;
    sink = (void*)&flutter_symengine_solve;          (void)sink;
    sink = (void*)&flutter_symengine_expand;         (void)sink;
    sink = (void*)&flutter_symengine_factor;         (void)sink;
    sink = (void*)&flutter_symengine_differentiate;  (void)sink;
    sink = (void*)&flutter_symengine_substitute;     (void)sink;
    sink = (void*)&flutter_symengine_free_string;    (void)sink;

    sink = (void*)&flutter_symengine_abs;            (void)sink;
    sink = (void*)&flutter_symengine_sin;            (void)sink;
    sink = (void*)&flutter_symengine_cos;            (void)sink;
    sink = (void*)&flutter_symengine_tan;            (void)sink;
    sink = (void*)&flutter_symengine_asin;           (void)sink;
    sink = (void*)&flutter_symengine_acos;           (void)sink;
    sink = (void*)&flutter_symengine_atan;           (void)sink;
    sink = (void*)&flutter_symengine_sinh;           (void)sink;
    sink = (void*)&flutter_symengine_cosh;           (void)sink;
    sink = (void*)&flutter_symengine_tanh;           (void)sink;
    sink = (void*)&flutter_symengine_asinh;          (void)sink;
    sink = (void*)&flutter_symengine_acosh;          (void)sink;
    sink = (void*)&flutter_symengine_atanh;          (void)sink;
    sink = (void*)&flutter_symengine_exp;            (void)sink;
    sink = (void*)&flutter_symengine_log;            (void)sink;
    sink = (void*)&flutter_symengine_sqrt;           (void)sink;
    sink = (void*)&flutter_symengine_gamma;          (void)sink;

    sink = (void*)&flutter_symengine_gcd;            (void)sink;
    sink = (void*)&flutter_symengine_lcm;            (void)sink;
    sink = (void*)&flutter_symengine_factorial;      (void)sink;
    sink = (void*)&flutter_symengine_fibonacci;      (void)sink;

    sink = (void*)&flutter_symengine_get_pi;         (void)sink;
    sink = (void*)&flutter_symengine_get_e;          (void)sink;
    sink = (void*)&flutter_symengine_get_euler_gamma;(void)sink;

    sink = (void*)&flutter_symengine_pi_with_precision;         (void)sink;
    sink = (void*)&flutter_symengine_e_with_precision;          (void)sink;
    sink = (void*)&flutter_symengine_euler_gamma_with_precision;(void)sink;
    sink = (void*)&flutter_symengine_sqrt2_with_precision;      (void)sink;

    sink = (void*)&flutter_symengine_isprime;        (void)sink;
    sink = (void*)&flutter_symengine_nextprime;      (void)sink;
    sink = (void*)&flutter_symengine_prevprime;      (void)sink;
    sink = (void*)&flutter_symengine_factorint;      (void)sink;

    sink = (void*)&flutter_symengine_matrix_new;             (void)sink;
    sink = (void*)&flutter_symengine_matrix_free;            (void)sink;
    sink = (void*)&flutter_symengine_matrix_set_element;     (void)sink;
    sink = (void*)&flutter_symengine_matrix_get_element;     (void)sink;
    sink = (void*)&flutter_symengine_matrix_to_string;       (void)sink;

    // Return non-zero so the Kotlin side can log "OK". The actual value
    // is unused; we just need a side-effect the compiler can't fold.
    return 1;
}

#if SYMBOLIC_MATH_BRIDGE_HAVE_JNI
// JNI wrapper — only compiled when jni.h is reachable (i.e. inside
// Gradle's externalNativeBuild flow with the NDK sysroot on the
// include path). Lets the Kotlin plugin call into the force-link
// function via `external fun forceLinkSymbols(): Int`.
JNIEXPORT jint JNICALL
Java_be_crispstro_symbolic_1math_1bridge_SymbolicMathBridgePlugin_forceLinkSymbols(
    JNIEnv* env, jobject thiz)
{
    (void)env; (void)thiz;
    return (jint)symbolic_math_bridge_force_link_symbols();
}
#endif
