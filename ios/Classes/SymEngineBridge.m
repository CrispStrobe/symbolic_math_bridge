// symbolic_math_bridge/ios/Classes/SymEngineBridge.m
//
//  SymEngineBridge.m
//  Forces the linker to include SymEngine wrapper symbols
//

#import <Foundation/Foundation.h>

// Declare the external C functions from our static library
extern char* symengine_evaluate(const char* expression);
extern char* symengine_solve(const char* expression, const char* symbol);
extern char* symengine_factor(const char* expression);
extern char* symengine_expand(const char* expression);
extern void symengine_free_string(char* str);

@interface SymEngineBridge : NSObject
@end

@implementation SymEngineBridge

// This function forces the linker to include our symbols
// by creating references to them
+ (void)load {
    // These function pointers ensure the symbols are linked
    // even though we never call this code
    void* refs[] = {
        symengine_evaluate,
        symengine_solve,
        symengine_factor,
        symengine_expand,
        symengine_free_string
    };
    
    // Prevent the compiler from optimizing away the array
    if (refs[0] == NULL) {
        NSLog(@"SymEngine symbols loaded");
    }
}

@end