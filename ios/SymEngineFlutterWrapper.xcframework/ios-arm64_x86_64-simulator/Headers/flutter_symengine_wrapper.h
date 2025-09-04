/*
 * flutter_symengine_wrapper.h
 * Complete C wrapper for SymEngine for use in Flutter FFI.
 * Manages symbolic math, number theory, and matrix operations.
 */
#ifndef FLUTTER_SYMENGINE_WRAPPER_H
#define FLUTTER_SYMENGINE_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// Forward declare the opaque struct for matrices.
// The Dart side will only ever see a pointer to this.
typedef struct CDenseMatrix CDenseMatrix;

// Core SymEngine wrapper functions for Flutter FFI
char* flutter_symengine_evaluate(const char* expression);
char* flutter_symengine_solve(const char* expression, const char* symbol);
char* flutter_symengine_expand(const char* expression);
char* flutter_symengine_factor(const char* expression);
char* flutter_symengine_differentiate(const char* expression, const char* symbol);
char* flutter_symengine_integrate(const char* expression, const char* symbol); // NOTE: Not implemented in SymEngine's C API.
char* flutter_symengine_simplify(const char* expression);
char* flutter_symengine_substitute(const char* expression, const char* symbol, const char* value);
void flutter_symengine_free_string(char* str);

// Mathematical Functions
char* flutter_symengine_abs(const char* expression);
char* flutter_symengine_sin(const char* expression);
char* flutter_symengine_cos(const char* expression);
char* flutter_symengine_tan(const char* expression);
char* flutter_symengine_asin(const char* expression);
char* flutter_symengine_acos(const char* expression);
char* flutter_symengine_atan(const char* expression);
char* flutter_symengine_sinh(const char* expression);
char* flutter_symengine_cosh(const char* expression);
char* flutter_symengine_tanh(const char* expression);
char* flutter_symengine_asinh(const char* expression);
char* flutter_symengine_acosh(const char* expression);
char* flutter_symengine_atanh(const char* expression);
char* flutter_symengine_exp(const char* expression);
char* flutter_symengine_log(const char* expression);
char* flutter_symengine_sqrt(const char* expression);
char* flutter_symengine_gamma(const char* expression);

// Number theory functions
char* flutter_symengine_gcd(const char* a, const char* b);
char* flutter_symengine_lcm(const char* a, const char* b);
char* flutter_symengine_factorial(int n);
char* flutter_symengine_fibonacci(int n);

// Constants
char* flutter_symengine_get_pi(void);
char* flutter_symengine_get_e(void);
char* flutter_symengine_get_euler_gamma(void);

// Matrix operations (using opaque pointers for memory safety)
CDenseMatrix* flutter_symengine_matrix_new(int rows, int cols);
void flutter_symengine_matrix_free(CDenseMatrix* matrix);
int flutter_symengine_matrix_set_element(CDenseMatrix* matrix, int row, int col, const char* value);
char* flutter_symengine_matrix_get_element(CDenseMatrix* matrix, int row, int col);
char* flutter_symengine_matrix_to_string(CDenseMatrix* matrix);
char* flutter_symengine_matrix_det(CDenseMatrix* matrix);
CDenseMatrix* flutter_symengine_matrix_inv(CDenseMatrix* matrix);
CDenseMatrix* flutter_symengine_matrix_add(CDenseMatrix* a, CDenseMatrix* b);
CDenseMatrix* flutter_symengine_matrix_mul(CDenseMatrix* a, CDenseMatrix* b);

// Utility functions
const char* flutter_symengine_version(void);
char* flutter_symengine_test_basic_operations(void);
char* flutter_symengine_test_symbolic(void);

#ifdef __cplusplus
}
#endif

#endif /* FLUTTER_SYMENGINE_WRAPPER_H */

