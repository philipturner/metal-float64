//
//  Defines.h
//  
//
//  Created by Philip Turner on 11/22/22.
//

#ifndef Defines_h
#define Defines_h

// Apply this to exported symbols.
// Place at the function declaration.
#define EXPORT __attribute__((__visibility__("default")))

// Apply this to functions that shouldn't be inlined internally.
// Place at the function definition.
#define NEVER_INLINE __attribute__((__noinline__))

#endif /* Defines_h */
