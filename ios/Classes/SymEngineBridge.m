// symbolic_math_bridge/ios/Classes/SymEngineBridge.m
//
//  SymEngineBridge.m
//  Forces the linker to include SymEngine wrapper symbols + all math library symbols
//

#import <Foundation/Foundation.h>

// symbolic_math_bridge/ios/Classes/SymEngineBridge.m
//
//  SymEngineBridge.m
//  Forces the linker to include SymEngine wrapper symbols + all math library symbols
//

#import <Foundation/Foundation.h>

// Declare the external C functions from our static library (SymEngine wrapper)
extern char* symengine_evaluate(const char* expression);
extern char* symengine_solve(const char* expression, const char* symbol);
extern char* symengine_factor(const char* expression);
extern char* symengine_expand(const char* expression);
extern void symengine_free_string(char* str);

// Declare external functions from GMP (only the ones we know exist and work)
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

// MPFR functions (core ones that should exist)
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

// MPC functions (core ones that should exist)
extern void mpc_init2(void* z, long prec);
extern void mpc_clear(void* z);
extern int mpc_set_ui_ui(void* rop, unsigned long int op1, unsigned long int op2, int rnd);
extern char* mpc_get_str(int base, size_t n, const void* op, int rnd);
extern int mpc_add(void* rop, const void* op1, const void* op2, int rnd);
extern int mpc_mul(void* rop, const void* op1, const void* op2, int rnd);
extern int mpc_sqrt(void* rop, const void* op, int rnd);

// FLINT functions (core ones that should exist)
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

// This function forces the linker to include symbols from all math libraries
+ (void)load {
    // Create references to ensure symbols are linked and available for dlsym()
    static void* refs[] = {
        // === SymEngine C Wrapper Symbols ===
        symengine_evaluate,
        symengine_solve,
        symengine_factor,
        symengine_expand,
        symengine_free_string,
        
        // === GMP Core Symbols (only ones we know work) ===
        (void *)__gmpz_init,
        (void *)__gmpz_init_set_str,
        (void *)__gmpz_clear,
        (void *)__gmpz_get_str,
        (void *)__gmpz_set_ui,
        (void *)__gmpz_set_si,
        (void *)__gmpz_add,
        (void *)__gmpz_add_ui,
        (void *)__gmpz_sub,
        (void *)__gmpz_mul,
        (void *)__gmpz_mul_ui,
        (void *)__gmpz_pow_ui,
        (void *)__gmpz_gcd,
        (void *)__gmpz_cmp,
        (void *)__gmpz_cmp_ui,
        (void *)__gmpz_abs,
        (void *)__gmpz_neg,
        (void *)__gmpz_sqrt,
        (void *)__gmpz_fac_ui,
        
        // === MPFR Core Symbols ===
        (void *)mpfr_init2,
        (void *)mpfr_clear,
        (void *)mpfr_set_ui,
        (void *)mpfr_set_d,
        (void *)mpfr_get_str,
        (void *)mpfr_get_d,
        (void *)mpfr_add,
        (void *)mpfr_mul,
        (void *)mpfr_sqrt,
        (void *)mpfr_const_pi,
        (void *)mpfr_sin,
        (void *)mpfr_cos,
        
        // === MPC Core Symbols ===
        (void *)mpc_init2,
        (void *)mpc_clear,
        (void *)mpc_set_ui_ui,
        (void *)mpc_get_str,
        (void *)mpc_add,
        (void *)mpc_mul,
        (void *)mpc_sqrt,
        
        // === FLINT Core Symbols ===
        (void *)fmpz_init,
        (void *)fmpz_clear,
        (void *)fmpz_set_ui,
        (void *)fmpz_get_str,
        (void *)fmpz_add,
        (void *)fmpz_mul,
        (void *)fmpz_pow_ui,
        (void *)fmpz_cmp,
        (void *)fmpz_abs,
        (void *)fmpz_fac_ui
    };
    
    // Prevent the compiler from optimizing away the array
    // This ensures all symbols are linked and available for dlsym()
    if (refs[0] == NULL) {
        NSLog(@"[SYMBOLIC_MATH] All math library symbols loaded");
    } else {
        NSLog(@"[SYMBOLIC_MATH] Successfully loaded %lu symbols from math libraries", 
              (unsigned long)(sizeof(refs) / sizeof(void*)));
    }
}

@end

// Additional C function that can be called from Swift if needed
void force_all_math_symbols_linking(void) {
    // This function ensures the SymEngineBridge class is loaded
    // which triggers the +load method above
    [SymEngineBridge class];
}