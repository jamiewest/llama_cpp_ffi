#ifndef FFIGEN_SHIM_H
#define FFIGEN_SHIM_H

// Ensure fixed-width integer types are available when libclang runs without
// full system headers (e.g., CI).
#if defined(__has_include)
#  if __has_include(<stdint.h>)
#    include <stdint.h>
#  endif
#else
#  include <stdint.h>
#endif

#ifndef UINT8_MAX
typedef __INT8_TYPE__ int8_t;
typedef __UINT8_TYPE__ uint8_t;
typedef __INT16_TYPE__ int16_t;
typedef __UINT16_TYPE__ uint16_t;
typedef __INT32_TYPE__ int32_t;
typedef __UINT32_TYPE__ uint32_t;
typedef __INT64_TYPE__ int64_t;
typedef __UINT64_TYPE__ uint64_t;
#endif

#endif  // FFIGEN_SHIM_H
