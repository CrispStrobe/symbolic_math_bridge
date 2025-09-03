/*

#include <gmp.h>
#include <mpfr.h>
#include <mpc.h>
#include <flint/fmpz.h>
#include <symengine/cwrapper.h>

// Force inclusion of symbols from all libraries
__attribute__((used))
void *force_symbolic_math_stack_linking(void) {
    volatile __attribute__((used)) void *dummy_references[] = {
        // GMP symbols (we know these work)
        (void *)__gmpz_init,
        (void *)__gmpz_init_set_str,
        (void *)__gmpz_get_str,
        (void *)__gmpz_clear,
        (void *)__gmpz_pow_ui,
        (void *)__gmpz_add,
        (void *)__gmpz_mul,
        
        // MPFR symbols - try different function names
        (void *)mpfr_init2,
        (void *)mpfr_set_prec,
        (void *)mpfr_const_pi,
        (void *)mpfr_get_str,
        (void *)mpfr_clear,
        (void *)mpfr_add,
        (void *)mpfr_mul,
        
        // MPC symbols
        (void *)mpc_init2,
        (void *)mpc_set_ui_ui,
        (void *)mpc_add,
        (void *)mpc_mul,
        (void *)mpc_clear,
        (void *)mpc_get_str,
        
        // FLINT symbols  
        (void *)fmpz_init,
        (void *)fmpz_set_ui,
        (void *)fmpz_add,
        (void *)fmpz_mul,
        (void *)fmpz_clear,
        (void *)fmpz_get_str,
        
        // SymEngine C wrapper symbols
        (void *)basic_new_heap,
        (void *)basic_const_pi,
        (void *)basic_str,
        (void *)basic_free_stack
    };
    (void)dummy_references;
    return NULL;
}
*/