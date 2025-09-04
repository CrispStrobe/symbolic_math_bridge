/*
 * flutter_symengine_wrapper.h
 * Flutter-specific wrapper for SymEngine using cwrapper.h API
 * For symbolic_math_bridge plugin
 */
#ifndef FLUTTER_SYMENGINE_WRAPPER_H
#define FLUTTER_SYMENGINE_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// Core SymEngine wrapper functions for Flutter FFI  
// NOTE: These use cwrapper.h API internally but provide simplified Flutter interface
char* flutter_symengine_evaluate(const char* expression);
char* flutter_symengine_solve(const char* expression, const char* symbol);
char* flutter_symengine_factor(const char* expression);
char* flutter_symengine_expand(const char* expression);
void flutter_symengine_free_string(char* str);

// Utility functions (renamed to avoid conflicts)
char* flutter_symengine_version(void);
char* flutter_symengine_test_basic_operations(void);
char* flutter_symengine_test_symbolic(void);

// Extended functions (declare but may not implement all immediately)
char* flutter_symengine_differentiate(const char* expression, const char* symbol);
char* flutter_symengine_integrate(const char* expression, const char* symbol);
char* flutter_symengine_simplify(const char* expression);
char* flutter_symengine_substitute(const char* expression, const char* symbol, const char* value);

// Number theory functions
char* flutter_symengine_gcd(const char* a, const char* b);
char* flutter_symengine_lcm(const char* a, const char* b);
char* flutter_symengine_factorial(int n);
char* flutter_symengine_fibonacci(int n);

// Constants
char* flutter_symengine_get_pi(void);
char* flutter_symengine_get_e(void);
char* flutter_symengine_get_euler_gamma(void);

// Matrix operations (basic)
char* flutter_symengine_matrix_det(const char* matrix_str, int rows, int cols);
char* flutter_symengine_matrix_inv(const char* matrix_str, int rows, int cols);

#ifdef __cplusplus
}
#endif

#endif /* FLUTTER_SYMENGINE_WRAPPER_H */