#ifndef SYMENGINE_C_WRAPPER_H
#define SYMENGINE_C_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

char* symengine_evaluate(const char* expression);
char* symengine_solve(const char* expression, const char* symbol);
char* symengine_factor(const char* expression);
char* symengine_expand(const char* expression);
void symengine_free_string(char* str);

#ifdef __cplusplus
}
#endif

#endif
