/*
 * symengine_minimal_wrapper.h
 * Minimal C wrapper for SymEngine - proven working implementation
 * Single source of truth for math-stack-ios-builder
 */
#ifndef SYMENGINE_MINIMAL_WRAPPER_H
#define SYMENGINE_MINIMAL_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// Core 5 functions that are proven to work
char* symengine_evaluate(const char* expression);
char* symengine_solve(const char* expression, const char* symbol);
char* symengine_factor(const char* expression);
char* symengine_expand(const char* expression);
void symengine_free_string(char* str);

#ifdef __cplusplus
}
#endif

#endif /* SYMENGINE_MINIMAL_WRAPPER_H */