/* 
 flutter_symengine_wrapper.h
 * Flutter-specific wrapper for SymEngine using cwrapper.h API
 * For symbolic_math_bridge plugin
 */
#ifndef FLUTTER_SYMENGINE_WRAPPER_H
#define FLUTTER_SYMENGINE_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// Core SymEngine wrapper functions for Flutter FFI
char* symengine_evaluate(const char* expression);
char* symengine_solve(const char* expression, const char* symbol);
char* symengine_factor(const char* expression);
char* symengine_expand(const char* expression);
void symengine_free_string(char* str);

// Utility functions
char* symengine_version(void);
char* symengine_test_basic_operations(void);
char* symengine_test_symbolic(void);

// Extended functions (declare but may not implement all immediately)
char* symengine_differentiate(const char* expression, const char* symbol);
char* symengine_integrate(const char* expression, const char* symbol);
char* symengine_simplify(const char* expression);
char* symengine_substitute(const char* expression, const char* symbol, const char* value);

// Number theory functions
char* symengine_gcd(const char* a, const char* b);
char* symengine_lcm(const char* a, const char* b);
char* symengine_factorial(int n);
char* symengine_fibonacci(int n);

// Constants
char* symengine_get_pi(void);
char* symengine_get_e(void);
char* symengine_get_euler_gamma(void);

// Matrix operations (basic)
char* symengine_matrix_det(const char* matrix_str, int rows, int cols);
char* symengine_matrix_inv(const char* matrix_str, int rows, int cols);

#ifdef __cplusplus
}
#endif

#endif /* FLUTTER_SYMENGINE_WRAPPER_H */