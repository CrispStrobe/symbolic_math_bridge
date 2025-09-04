// symbolic_math_bridge/ios/Classes/SymEngineBridge.m
//
//  SymEngineBridge.m
//  Forces the linker to include all symbols from the math libraries.
//  THIS IS THE COMPLETE AND CORRECTED VERSION.
//

#import <Foundation/Foundation.h>

// --- Declare ALL external C functions from the wrapper ---
extern char* flutter_symengine_evaluate(const char* expression);
extern char* flutter_symengine_solve(const char* expression, const char* symbol);
extern char* flutter_symengine_expand(const char* expression);
extern char* flutter_symengine_factor(const char* expression);
extern char* flutter_symengine_differentiate(const char* expression, const char* symbol);
extern char* flutter_symengine_substitute(const char* expression, const char* symbol, const char* value);
extern void flutter_symengine_free_string(char* str);
// Math Functions
extern char* flutter_symengine_abs(const char* expression);
extern char* flutter_symengine_sin(const char* expression);
extern char* flutter_symengine_cos(const char* expression);
extern char* flutter_symengine_tan(const char* expression);
extern char* flutter_symengine_asin(const char* expression);
extern char* flutter_symengine_acos(const char* expression);
extern char* flutter_symengine_atan(const char* expression);
extern char* flutter_symengine_sinh(const char* expression);
extern char* flutter_symengine_cosh(const char* expression);
extern char* flutter_symengine_tanh(const char* expression);
extern char* flutter_symengine_asinh(const char* expression);
extern char* flutter_symengine_acosh(const char* expression);
extern char* flutter_symengine_atanh(const char* expression);
extern char* flutter_symengine_exp(const char* expression);
extern char* flutter_symengine_log(const char* expression);
extern char* flutter_symengine_sqrt(const char* expression);
extern char* flutter_symengine_gamma(const char* expression);
// Number Theory
extern char* flutter_symengine_gcd(const char* a, const char* b);
extern char* flutter_symengine_lcm(const char* a, const char* b);
extern char* flutter_symengine_factorial(int n);
extern char* flutter_symengine_fibonacci(int n);
// Constants
extern char* flutter_symengine_get_pi(void);
extern char* flutter_symengine_get_e(void);
extern char* flutter_symengine_get_euler_gamma(void);
// Matrix Functions
extern void* flutter_symengine_matrix_new(int rows, int cols);
extern void flutter_symengine_matrix_free(void* matrix);
extern int flutter_symengine_matrix_set_element(void* matrix, int row, int col, const char* value);
extern char* flutter_symengine_matrix_get_element(void* matrix, int row, int col);
extern char* flutter_symengine_matrix_to_string(void* matrix);
extern char* flutter_symengine_matrix_det(void* matrix);
extern void* flutter_symengine_matrix_inv(void* matrix);
extern void* flutter_symengine_matrix_add(void* a, void* b);
extern void* flutter_symengine_matrix_mul(void* a, void* b);

// --- Declare external functions from underlying libraries (Exhaustive List) ---
// GMP
extern void __gmpz_init(void* x);
extern int __gmpz_init_set_str(void* x, const char* str, int base);
extern char* __gmpz_get_str(char* str, int base, const void* x);
extern void __gmpz_clear(void* x);
extern void __gmpz_set_ui(void* rop, unsigned long int op);
extern void __gmpz_set_si(void* rop, signed long int op);
extern void __gmpz_add(void* rop, const void* op1, const void* op2);
extern void __gmpz_add_ui(void* rop, const void* op1, unsigned long int op2);
extern void __gmpz_sub(void* rop, const void* op1, const void* op2);
extern void __gmpz_mul(void* rop, const void* op1, const void* op2);
extern void __gmpz_mul_ui(void* rop, const void* op1, unsigned long int op2);
extern void __gmpz_pow_ui(void* rop, const void* base, unsigned long int exp);
extern void __gmpz_gcd(void* rop, const void* op1, const void* op2);
extern int __gmpz_cmp(const void* op1, const void* op2);
extern int __gmpz_cmp_ui(const void* op1, unsigned long int op2);
extern void __gmpz_abs(void* rop, const void* op);
extern void __gmpz_neg(void* rop, const void* op);
extern void __gmpz_sqrt(void* rop, const void* op);
extern void __gmpz_fac_ui(void* rop, unsigned long int n);

// MPFR
extern void mpfr_init2(void* x, long prec);
extern void mpfr_clear(void* x);
extern int mpfr_set_ui(void* rop, unsigned long int op, int rnd);
extern int mpfr_set_d(void* rop, double op, int rnd);
extern char* mpfr_get_str(char* str, long* expptr, int base, size_t n, const void* op, int rnd);
extern double mpfr_get_d(const void* op, int rnd);
extern int mpfr_add(void* rop, const void* op1, const void* op2, int rnd);
extern int mpfr_mul(void* rop, const void* op1, const void* op2, int rnd);
extern int mpfr_sqrt(void* rop, const void* op, int rnd);
extern int mpfr_const_pi(void* rop, int rnd);
extern int mpfr_sin(void* rop, const void* op, int rnd);
extern int mpfr_cos(void* rop, const void* op, int rnd);

// MPC
extern void mpc_init2(void* z, long prec);
extern void mpc_clear(void* z);
extern int mpc_set_ui_ui(void* rop, unsigned long int op1, unsigned long int op2, int rnd);
extern char* mpc_get_str(int base, size_t n, const void* op, int rnd);
extern int mpc_add(void* rop, const void* op1, const void* op2, int rnd);
extern int mpc_mul(void* rop, const void* op1, const void* op2, int rnd);
extern int mpc_sqrt(void* rop, const void* op, int rnd);

// FLINT
extern void fmpz_init(void* f);
extern void fmpz_clear(void* f);
extern void fmpz_set_ui(void* f, unsigned long val);
extern char* fmpz_get_str(char* str, int b, const void* f);
extern void fmpz_add(void* f, const void* g, const void* h);
extern void fmpz_mul(void* f, const void* g, const void* h);
extern void fmpz_pow_ui(void* f, const void* g, unsigned long exp);
extern int fmpz_cmp(const void* f, const void* g);
extern void fmpz_abs(void* f1, const void* f2);
extern void fmpz_fac_ui(void* f, unsigned long n);


@interface SymEngineBridge : NSObject
@end

@implementation SymEngineBridge

// This method is automatically called by the Objective-C runtime when the library is loaded.
// Its purpose is to create a reference to every single C function we need, forcing the
// Xcode linker to include them in the final app binary. Without this, the symbols
// would be stripped and Dart FFI would fail at runtime.
+ (void)load {
    static void* refs[] = {
        // === SymEngine C Wrapper Symbols (Complete List) ===
        flutter_symengine_evaluate,
        flutter_symengine_solve,
        flutter_symengine_expand,
        flutter_symengine_factor,
        flutter_symengine_differentiate,
        flutter_symengine_substitute,
        flutter_symengine_free_string,
        flutter_symengine_abs,
        flutter_symengine_sin,
        flutter_symengine_cos,
        flutter_symengine_tan,
        flutter_symengine_asin,
        flutter_symengine_acos,
        flutter_symengine_atan,
        flutter_symengine_sinh,
        flutter_symengine_cosh,
        flutter_symengine_tanh,
        flutter_symengine_asinh,
        flutter_symengine_acosh,
        flutter_symengine_atanh,
        flutter_symengine_exp,
        flutter_symengine_log,
        flutter_symengine_sqrt,
        flutter_symengine_gamma,
        flutter_symengine_gcd,
        flutter_symengine_lcm,
        flutter_symengine_factorial,
        flutter_symengine_fibonacci,
        flutter_symengine_get_pi,
        flutter_symengine_get_e,
        flutter_symengine_get_euler_gamma,
        flutter_symengine_matrix_new,
        flutter_symengine_matrix_free,
        flutter_symengine_matrix_set_element,
        flutter_symengine_matrix_get_element,
        flutter_symengine_matrix_to_string,
        flutter_symengine_matrix_det,
        flutter_symengine_matrix_inv,
        flutter_symengine_matrix_add,
        flutter_symengine_matrix_mul,
        
        // === Core Symbols from Underlying Libraries (Exhaustive List) ===
        (void *)__gmpz_init, (void *)__gmpz_init_set_str, (void *)__gmpz_clear, (void *)__gmpz_get_str, (void *)__gmpz_set_ui, (void *)__gmpz_set_si, (void *)__gmpz_add, (void *)__gmpz_add_ui, (void *)__gmpz_sub, (void *)__gmpz_mul, (void *)__gmpz_mul_ui, (void *)__gmpz_pow_ui, (void *)__gmpz_gcd, (void *)__gmpz_cmp, (void *)__gmpz_cmp_ui, (void *)__gmpz_abs, (void *)__gmpz_neg, (void *)__gmpz_sqrt, (void *)__gmpz_fac_ui,
        (void *)mpfr_init2, (void *)mpfr_clear, (void *)mpfr_set_ui, (void *)mpfr_set_d, (void *)mpfr_get_str, (void *)mpfr_get_d, (void *)mpfr_add, (void *)mpfr_mul, (void *)mpfr_sqrt, (void *)mpfr_const_pi, (void *)mpfr_sin, (void *)mpfr_cos,
        (void *)mpc_init2, (void *)mpc_clear, (void *)mpc_set_ui_ui, (void *)mpc_get_str, (void *)mpc_add, (void *)mpc_mul, (void *)mpc_sqrt,
        (void *)fmpz_init, (void *)fmpz_clear, (void *)fmpz_set_ui, (void *)fmpz_get_str, (void *)fmpz_add, (void *)fmpz_mul, (void *)fmpz_pow_ui, (void *)fmpz_cmp, (void *)fmpz_abs, (void *)fmpz_fac_ui
    };
    
    // This check prevents the compiler from optimizing away the `refs` array.
    if (refs[0] == NULL) {
        NSLog(@"[SYMBOLIC_MATH] Math library symbols loaded (dummy check)");
    } else {
        NSLog(@"[SYMBOLIC_MATH] Successfully loaded %lu symbols from math libraries", (unsigned long)(sizeof(refs) / sizeof(void*)));
    }
}

@end

// C function that can be called from Swift to ensure the +load method is triggered.
void force_all_math_symbols_linking(void) {
    [SymEngineBridge class];
}
