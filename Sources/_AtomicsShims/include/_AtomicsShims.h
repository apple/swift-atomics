//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020-2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#ifndef SWIFTATOMIC_HEADER_INCLUDED
#define SWIFTATOMIC_HEADER_INCLUDED 1

// Swift-importable shims for C atomics.
//
// Swift cannot import C's atomic types or any operations over them, so we need
// to meticulously wrap all of them in tiny importable types and functions.
//
// This file defines an atomic storage representation and 56 atomic operations
// for each of the 10 standard integer types in the Standard Library, as well as
// Bool and a double-word integer type. To prevent us from having to manually
// write/maintain a thousand or so functions, we use the C preprocessor to stamp
// these out.
//
// Supporting double-wide integers is tricky, because neither Swift nor C has
// standard integer representations for these on platforms where `Int` has a bit
// width of 64. Standard C can model 128-bit atomics through `_Atomic(struct
// pair)` where `pair` is a struct of two `intptr_t`s, but current Swift
// compilers (as of version 5.3) get confused by atomic structs
// (https://reviews.llvm.org/D86218). To work around that, we need to use the
// nonstandard `__uint128_t` type. The Swift compiler does seem to be able to
// deal with `_Atomic(__uint128_t)`, but it refuses to directly import
// `__uint128_t`, so that too needs to be wrapped in a dummy struct (which we
// call `_sa_dword`). We want to stamp out 128-bit atomics from the same code as
// regular atomics, so this requires all atomic operations to distinguish
// between the "exported" C type and the corresponding "internal"
// representation, and to explicitly convert between them as needed. This is
// done using the `SWIFTATOMIC_ENCODE_<swiftType>` and
// `SWIFTATOMIC_DECODE_<swiftType>` family of macros.
//
// In the case of compare-and-exchange, the conversion of the `expected`
// argument needs to go through a temporary stack variable that would result in
// slightly worse codegen for the regular single-word case, so we distinguish
// between `SIMPLE` and `COMPLEX` cmpxchg variants. The single variant assumes
// that the internal representation is identical to the exported type, and does
// away with the comparisons.
//
// FIXME: Upgrading from the preprocessor to gyb would perhaps make things more
// readable here.
//
// FIXME: Eliminate the encoding/decoding mechanism once the package requires a
// compiler that includes https://reviews.llvm.org/D86218.


#include <stdbool.h>
#include <stdint.h>
#include <assert.h>
// The atomic primitives are only needed when this is compiled using Swift's
// Clang Importer. This allows us to continue reling on some Clang extensions
// (see https://github.com/apple/swift-atomics/issues/37).
#if defined(__swift__)
#  include <stdatomic.h>
#endif

// For now, assume double-wide atomics are available everywhere,
// except on Linux/x86_64, where they need to be manually enabled
// by the `cx16` target attribute. (Unfortunately we cannot currently
// turn that on in our package description.)
#ifdef __APPLE__
#  define ENABLE_DOUBLEWIDE_ATOMICS 1
#elif defined(_WIN32)
#  define ENABLE_DOUBLEWIDE_ATOMICS 1
#elif defined(__linux__)
#  if !defined(__x86_64__) || defined(__GCC_HAVE_SYNC_COMPARE_AND_SWAP_16)
#    define ENABLE_DOUBLEWIDE_ATOMICS 1
#  endif
#endif

#if defined(__swift__)

#define SWIFTATOMIC_INLINE static inline __attribute__((__always_inline__))
#define SWIFTATOMIC_SWIFT_NAME(name) __attribute__((swift_name(#name)))

// Atomic fences
#define SWIFTATOMIC_THREAD_FENCE_FN(order)                              \
  SWIFTATOMIC_INLINE void _sa_thread_fence_##order(void)                \
  {                                                                     \
    atomic_thread_fence(memory_order_##order);                          \
  }

SWIFTATOMIC_THREAD_FENCE_FN(acquire)
SWIFTATOMIC_THREAD_FENCE_FN(release)
SWIFTATOMIC_THREAD_FENCE_FN(acq_rel)
SWIFTATOMIC_THREAD_FENCE_FN(seq_cst)

// Definition of an atomic storage type.
#define SWIFTATOMIC_STORAGE_TYPE(swiftType, cType, storageType)         \
  typedef struct {                                                      \
    _Atomic(storageType) value;                                         \
  } _sa_##swiftType                                                     \
  SWIFTATOMIC_SWIFT_NAME(_Atomic##swiftType##Storage);

// Storage value initializer
#define SWIFTATOMIC_PREPARE_FN(swiftType, cType, storageType)           \
  SWIFTATOMIC_INLINE                                                    \
  _sa_##swiftType _sa_prepare_##swiftType(cType value)                  \
  {                                                                     \
    _sa_##swiftType storage = { SWIFTATOMIC_ENCODE_##swiftType(value) }; \
    assert(atomic_is_lock_free(&storage.value));                        \
    return storage;                                                     \
  }

// Storage value disposal function
#define SWIFTATOMIC_DISPOSE_FN(swiftType, cType, storageType)           \
  SWIFTATOMIC_INLINE                                                    \
  cType _sa_dispose_##swiftType(_sa_##swiftType storage)                \
  {                                                                     \
    return SWIFTATOMIC_DECODE_##swiftType(storage.value);               \
  }

// Atomic load
#define SWIFTATOMIC_LOAD_FN(swiftType, cType, storageType, order)       \
  SWIFTATOMIC_INLINE                                                    \
  cType _sa_load_##order##_##swiftType(                                 \
    _sa_##swiftType *ptr)                                               \
  {                                                                     \
    return SWIFTATOMIC_DECODE_##swiftType(                              \
      atomic_load_explicit(&ptr->value,                                 \
                           memory_order_##order));                      \
  }

// Atomic store
#define SWIFTATOMIC_STORE_FN(swiftType, cType, storageType, order)      \
  SWIFTATOMIC_INLINE                                                    \
  void _sa_store_##order##_##swiftType(                                 \
    _sa_##swiftType *ptr,                                               \
    cType desired)                                                      \
  {                                                                     \
    atomic_store_explicit(&ptr->value,                                  \
                          SWIFTATOMIC_ENCODE_##swiftType(desired),      \
                          memory_order_##order);                        \
  }

// Atomic exchange
#define SWIFTATOMIC_EXCHANGE_FN(swiftType, cType, storageType, order)   \
  SWIFTATOMIC_INLINE                                                    \
  cType _sa_exchange_##order##_##swiftType(                             \
    _sa_##swiftType *ptr,                                               \
    cType desired)                                                      \
  {                                                                     \
    return SWIFTATOMIC_DECODE_##swiftType(                              \
      atomic_exchange_explicit(                                         \
        &ptr->value,                                                    \
        SWIFTATOMIC_ENCODE_##swiftType(desired),                        \
        memory_order_##order));                                         \
  }

// Atomic compare/exchange
#define SWIFTATOMIC_CMPXCHG_FN_SIMPLE(_kind, swiftType, cType, storageType, succ, fail) \
  SWIFTATOMIC_INLINE                                                    \
  bool                                                                  \
  _sa_cmpxchg_##_kind##_##succ##_##fail##_##swiftType(                  \
    _sa_##swiftType *ptr,                                               \
    cType *expected,                                                    \
    cType desired)                                                      \
  {                                                                     \
    return atomic_compare_exchange_##_kind##_explicit(                  \
      &ptr->value,                                                      \
      expected,                                                         \
      desired,                                                          \
      memory_order_##succ,                                              \
      memory_order_##fail);                                             \
  }

#define SWIFTATOMIC_CMPXCHG_FN_COMPLEX(_kind, swiftType, cType, storageType, succ, fail) \
  SWIFTATOMIC_INLINE                                                    \
  bool                                                                  \
  _sa_cmpxchg_##_kind##_##succ##_##fail##_##swiftType(                  \
    _sa_##swiftType *ptr,                                               \
    cType *expected,                                                    \
    cType desired)                                                      \
  {                                                                     \
    storageType _expected = SWIFTATOMIC_ENCODE_##swiftType(*expected);  \
    bool result = atomic_compare_exchange_##_kind##_explicit(           \
        &ptr->value,                                                    \
        &_expected,                                                     \
        SWIFTATOMIC_ENCODE_##swiftType(desired),                        \
        memory_order_##succ,                                            \
        memory_order_##fail);                                           \
    *expected = SWIFTATOMIC_DECODE_##swiftType(_expected);              \
    return result;                                                      \
  }

// Atomic integer operations
#define SWIFTATOMIC_INTEGER_FN(op, swiftType, cType, storageType, order) \
  SWIFTATOMIC_INLINE                                                    \
  cType _sa_fetch_##op##_##order##_##swiftType(                         \
    _sa_##swiftType *ptr,                                               \
    cType operand)                                                      \
  {                                                                     \
    return SWIFTATOMIC_DECODE_##swiftType(                              \
      atomic_fetch_##op##_explicit(                                     \
        &ptr->value,                                                    \
        SWIFTATOMIC_ENCODE_##swiftType(operand),                        \
        memory_order_##order));                                         \
    }

// Functions for each supported operation + memory ordering combination
#define SWIFTATOMIC_STORE_FNS(swiftType, cType, storageType)           \
  SWIFTATOMIC_STORE_FN(swiftType, cType, storageType, relaxed)         \
  SWIFTATOMIC_STORE_FN(swiftType, cType, storageType, release)         \
  SWIFTATOMIC_STORE_FN(swiftType, cType, storageType, seq_cst)

#define SWIFTATOMIC_LOAD_FNS(swiftType, cType, storageType)            \
  SWIFTATOMIC_LOAD_FN(swiftType, cType, storageType, relaxed)          \
  SWIFTATOMIC_LOAD_FN(swiftType, cType, storageType, acquire)          \
  SWIFTATOMIC_LOAD_FN(swiftType, cType, storageType, seq_cst)

#define SWIFTATOMIC_EXCHANGE_FNS(swiftType, cType, storageType)        \
  SWIFTATOMIC_EXCHANGE_FN(swiftType, cType, storageType, relaxed)      \
  SWIFTATOMIC_EXCHANGE_FN(swiftType, cType, storageType, acquire)      \
  SWIFTATOMIC_EXCHANGE_FN(swiftType, cType, storageType, release)      \
  SWIFTATOMIC_EXCHANGE_FN(swiftType, cType, storageType, acq_rel)      \
  SWIFTATOMIC_EXCHANGE_FN(swiftType, cType, storageType, seq_cst)

#define SWIFTATOMIC_CMPXCHG_FNS(variant, kind, swiftType, cType, storageType) \
  SWIFTATOMIC_CMPXCHG_FN_##variant(kind, swiftType, cType, storageType, relaxed, relaxed) \
  SWIFTATOMIC_CMPXCHG_FN_##variant(kind, swiftType, cType, storageType, acquire, relaxed) \
  SWIFTATOMIC_CMPXCHG_FN_##variant(kind, swiftType, cType, storageType, release, relaxed) \
  SWIFTATOMIC_CMPXCHG_FN_##variant(kind, swiftType, cType, storageType, acq_rel, relaxed) \
  SWIFTATOMIC_CMPXCHG_FN_##variant(kind, swiftType, cType, storageType, seq_cst, relaxed) \
  SWIFTATOMIC_CMPXCHG_FN_##variant(kind, swiftType, cType, storageType, acquire, acquire) \
  SWIFTATOMIC_CMPXCHG_FN_##variant(kind, swiftType, cType, storageType, acq_rel, acquire) \
  SWIFTATOMIC_CMPXCHG_FN_##variant(kind, swiftType, cType, storageType, seq_cst, acquire) \
  SWIFTATOMIC_CMPXCHG_FN_##variant(kind, swiftType, cType, storageType, seq_cst, seq_cst)

#define SWIFTATOMIC_INTEGER_FNS(op, swiftType, cType, storageType)     \
  SWIFTATOMIC_INTEGER_FN(op, swiftType, cType, storageType, relaxed)   \
  SWIFTATOMIC_INTEGER_FN(op, swiftType, cType, storageType, acquire)   \
  SWIFTATOMIC_INTEGER_FN(op, swiftType, cType, storageType, release)   \
  SWIFTATOMIC_INTEGER_FN(op, swiftType, cType, storageType, acq_rel)   \
  SWIFTATOMIC_INTEGER_FN(op, swiftType, cType, storageType, seq_cst)

#define SWIFTATOMIC_DEFINE_TYPE(variant, swiftType, cType, storageType) \
  SWIFTATOMIC_STORAGE_TYPE(swiftType, cType, storageType)              \
  SWIFTATOMIC_PREPARE_FN(swiftType, cType, storageType)                \
  SWIFTATOMIC_DISPOSE_FN(swiftType, cType, storageType)                \
  SWIFTATOMIC_LOAD_FNS(swiftType, cType, storageType)                  \
  SWIFTATOMIC_STORE_FNS(swiftType, cType, storageType)                 \
  SWIFTATOMIC_EXCHANGE_FNS(swiftType, cType, storageType)              \
  SWIFTATOMIC_CMPXCHG_FNS(variant, strong, swiftType, cType, storageType) \
  SWIFTATOMIC_CMPXCHG_FNS(variant, weak, swiftType, cType, storageType)

#define SWIFTATOMIC_DEFINE_INTEGER_TYPE(variant, swiftType, cType, storageType) \
  SWIFTATOMIC_DEFINE_TYPE(variant, swiftType, cType, storageType)      \
  SWIFTATOMIC_INTEGER_FNS(add, swiftType, cType, storageType)          \
  SWIFTATOMIC_INTEGER_FNS(sub, swiftType, cType, storageType)          \
  SWIFTATOMIC_INTEGER_FNS(or, swiftType, cType, storageType)           \
  SWIFTATOMIC_INTEGER_FNS(xor, swiftType, cType, storageType)          \
  SWIFTATOMIC_INTEGER_FNS(and, swiftType, cType, storageType)

// All known integer types
#define SWIFTATOMIC_ENCODE_Int(value) (value)
#define SWIFTATOMIC_DECODE_Int(value) (value)
SWIFTATOMIC_DEFINE_INTEGER_TYPE(SIMPLE, Int, intptr_t, intptr_t)

#define SWIFTATOMIC_ENCODE_Int8(value) (value)
#define SWIFTATOMIC_DECODE_Int8(value) (value)
SWIFTATOMIC_DEFINE_INTEGER_TYPE(SIMPLE, Int8, int8_t, int8_t)

#define SWIFTATOMIC_ENCODE_Int16(value) (value)
#define SWIFTATOMIC_DECODE_Int16(value) (value)
SWIFTATOMIC_DEFINE_INTEGER_TYPE(SIMPLE, Int16, int16_t, int16_t)

#define SWIFTATOMIC_ENCODE_Int32(value) (value)
#define SWIFTATOMIC_DECODE_Int32(value) (value)
SWIFTATOMIC_DEFINE_INTEGER_TYPE(SIMPLE, Int32, int32_t, int32_t)

#define SWIFTATOMIC_ENCODE_Int64(value) (value)
#define SWIFTATOMIC_DECODE_Int64(value) (value)
SWIFTATOMIC_DEFINE_INTEGER_TYPE(SIMPLE, Int64, int64_t, int64_t)

#define SWIFTATOMIC_ENCODE_UInt(value) (value)
#define SWIFTATOMIC_DECODE_UInt(value) (value)
SWIFTATOMIC_DEFINE_INTEGER_TYPE(SIMPLE, UInt, uintptr_t, uintptr_t)

#define SWIFTATOMIC_ENCODE_UInt8(value) (value)
#define SWIFTATOMIC_DECODE_UInt8(value) (value)
SWIFTATOMIC_DEFINE_INTEGER_TYPE(SIMPLE, UInt8, uint8_t, uint8_t)

#define SWIFTATOMIC_ENCODE_UInt16(value) (value)
#define SWIFTATOMIC_DECODE_UInt16(value) (value)
SWIFTATOMIC_DEFINE_INTEGER_TYPE(SIMPLE, UInt16, uint16_t, uint16_t)

#define SWIFTATOMIC_ENCODE_UInt32(value) (value)
#define SWIFTATOMIC_DECODE_UInt32(value) (value)
SWIFTATOMIC_DEFINE_INTEGER_TYPE(SIMPLE, UInt32, uint32_t, uint32_t)

#define SWIFTATOMIC_ENCODE_UInt64(value) (value)
#define SWIFTATOMIC_DECODE_UInt64(value) (value)
SWIFTATOMIC_DEFINE_INTEGER_TYPE(SIMPLE, UInt64, uint64_t, uint64_t)

// Atomic boolean
#define SWIFTATOMIC_ENCODE_Bool(value) (value)
#define SWIFTATOMIC_DECODE_Bool(value) (value)
SWIFTATOMIC_DEFINE_TYPE(SIMPLE, Bool, bool, bool)
SWIFTATOMIC_INTEGER_FNS(or, Bool, bool, bool)
SWIFTATOMIC_INTEGER_FNS(xor, Bool, bool, bool)
SWIFTATOMIC_INTEGER_FNS(and, Bool, bool, bool)

// Double wide atomics (__uint128_t on 64-bit platforms, uint64_t elsewhere)

#if __SIZEOF_POINTER__ == 8
# if !defined(__SIZEOF_INT128__)
#   error "Double wide atomics need __uint128_t"
# endif
# define _sa_double_word_ctype __uint128_t
#elif __SIZEOF_POINTER__ == 4
# define _sa_double_word_ctype uint64_t
#else
# error "Unsupported Pointer Size"
#endif

typedef struct {
  _sa_double_word_ctype value;
} _sa_dword SWIFTATOMIC_SWIFT_NAME(DoubleWord);

SWIFTATOMIC_INLINE
_sa_dword _sa_dword_create(uintptr_t high, uintptr_t low) {
  return (_sa_dword){ ((_sa_double_word_ctype)high << __INTPTR_WIDTH__) | (_sa_double_word_ctype)low };
}

SWIFTATOMIC_INLINE
uintptr_t _sa_dword_extract_high(_sa_dword value) {
  return (uintptr_t)(value.value >> __INTPTR_WIDTH__);
}

SWIFTATOMIC_INLINE
uintptr_t _sa_dword_extract_low(_sa_dword value) {
  return (uintptr_t)value.value;
}

SWIFTATOMIC_INLINE
_sa_dword _sa_decode_dword(_sa_double_word_ctype value) {
  return (_sa_dword){ value };
}

#if ENABLE_DOUBLEWIDE_ATOMICS
#define SWIFTATOMIC_ENCODE_DoubleWord(_value) (_value).value
#define SWIFTATOMIC_DECODE_DoubleWord(_value) _sa_decode_dword(_value)
SWIFTATOMIC_DEFINE_TYPE(COMPLEX, DoubleWord, _sa_dword, _sa_double_word_ctype)
#else
SWIFTATOMIC_STORAGE_TYPE(DoubleWord, _sa_dword, _sa_double_word_ctype)
#endif

#endif // __swift__

#if ENABLE_DOUBLEWIDE_ATOMICS
extern void _sa_retain_n(void *object, uint32_t n);
extern void _sa_release_n(void *object, uint32_t n);
#endif

#endif //SWIFTATOMIC_HEADER_INCLUDED
