// symbolic_math_bridge/ios/Headers/symengine_c_wrapper.h:

#ifndef SYMENGINE_C_WRAPPER_H
#define SYMENGINE_C_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// === Core Functions (main initial 5) ===
char* symengine_evaluate(const char* expression);
char* symengine_solve(const char* expression, const char* symbol);
char* symengine_factor(const char* expression);
char* symengine_expand(const char* expression);
void symengine_free_string(char* str);

// === Extended Mathematical Functions ===

// Calculus operations
char* symengine_differentiate(const char* expression, const char* symbol);
char* symengine_integrate(const char* expression, const char* symbol);
char* symengine_limit(const char* expression, const char* symbol, const char* value);
char* symengine_series(const char* expression, const char* symbol, const char* point, int terms);

// Simplification and manipulation
char* symengine_simplify(const char* expression);
char* symengine_substitute(const char* expression, const char* symbol, const char* value);
char* symengine_collect(const char* expression, const char* symbol);
char* symengine_cancel(const char* expression);

// Trigonometric functions
char* symengine_sin(const char* expression);
char* symengine_cos(const char* expression);
char* symengine_tan(const char* expression);
char* symengine_asin(const char* expression);
char* symengine_acos(const char* expression);
char* symengine_atan(const char* expression);

// Hyperbolic functions
char* symengine_sinh(const char* expression);
char* symengine_cosh(const char* expression);
char* symengine_tanh(const char* expression);

// Exponential and logarithmic functions
char* symengine_exp(const char* expression);
char* symengine_log(const char* expression);
char* symengine_ln(const char* expression);
char* symengine_sqrt(const char* expression);
char* symengine_power(const char* base, const char* exponent);

// Constants
char* symengine_get_pi(void);
char* symengine_get_e(void);
char* symengine_get_euler_gamma(void);
char* symengine_get_golden_ratio(void);
char* symengine_get_catalan(void);

// Number theory functions
char* symengine_gcd(const char* a, const char* b);
char* symengine_lcm(const char* a, const char* b);
char* symengine_factorial(int n);
char* symengine_fibonacci(int n);
char* symengine_prime_nth(int n);
int symengine_is_prime(int n);

// Complex number functions
char* symengine_real_part(const char* complex_expr);
char* symengine_imag_part(const char* complex_expr);
char* symengine_conjugate(const char* complex_expr);
char* symengine_abs(const char* expression);
char* symengine_arg(const char* complex_expr);

// Matrix operations (basic 2x2)
char* symengine_matrix_det_2x2(const char* a11, const char* a12, const char* a21, const char* a22);
char* symengine_matrix_add_2x2(const char* m1[4], const char* m2[4]); // Returns comma-separated result
char* symengine_matrix_mul_2x2(const char* m1[4], const char* m2[4]);

// Polynomial operations
char* symengine_degree(const char* polynomial, const char* symbol);
char* symengine_coeff(const char* polynomial, const char* symbol, int degree);
char* symengine_roots(const char* polynomial, const char* symbol);

// Equation solving (extended)
char* symengine_solve_system(const char* equations[], const char* symbols[], int count);
char* symengine_solve_ode(const char* equation, const char* function, const char* variable);

// Expression analysis
int symengine_is_polynomial(const char* expression, const char* symbol);
int symengine_is_rational(const char* expression);
int symengine_is_integer(const char* expression);
int symengine_has_symbol(const char* expression, const char* symbol);
char* symengine_free_symbols(const char* expression); // Returns comma-separated list

// Numerical evaluation
char* symengine_evalf(const char* expression, int precision);
double symengine_eval_double(const char* expression);
int symengine_eval_int(const char* expression);

// Conversion functions
char* symengine_to_latex(const char* expression);
char* symengine_to_mathml(const char* expression);
char* symengine_from_latex(const char* latex_expr);

// Special functions
char* symengine_gamma(const char* expression);
char* symengine_beta(const char* a, const char* b);
char* symengine_zeta(const char* expression);
char* symengine_erf(const char* expression);
char* symengine_erfc(const char* expression);

// Utility functions
char* symengine_version(void);
char* symengine_get_error_message(void);
int symengine_set_precision(int precision);
int symengine_get_precision(void);

// Testing functions
char* symengine_test_basic_ops(void);
char* symengine_test_calculus(void);
char* symengine_test_symbols(void);
char* symengine_test_constants(void);

#ifdef __cplusplus
}
#endif

#endif