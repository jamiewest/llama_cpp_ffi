# llama_cpp_ffi

Low-level Dart FFI bindings for [llama.cpp](https://github.com/ggml-org/llama.cpp).
Bindings are generated with `ffigen` from llama.cpp headers. This package does not
ship native binaries; you must build or provide a llama.cpp dynamic library.

## What This Is

- Auto-generated Dart bindings to the C API in `llama.h` (and `mtmd.h`).
- Intended as a thin, low-level layer to build higher-level wrappers on top.
- Includes a small loader utility (`LlamaLibraryLoader`) to simplify dynamic
  library lookup and error reporting.

## Getting Started

Requires Dart 3.0 or newer.

Add the dependency:

```bash
dart pub add llama_cpp_ffi
```

Build or obtain a dynamic library for llama.cpp, then point to it with
`LLAMA_CPP_LIBRARY_PATH`.

## Usage

```dart
import 'dart:ffi' as ffi;

import 'package:llama_cpp_ffi/llama_cpp_ffi.dart';

void main() {
  final ffi.DynamicLibrary dylib;
  try {
    dylib = LlamaLibraryLoader.open();
  } on LlamaLibraryLoadException catch (error) {
    print(error);
    return;
  }

  final bindings = llama_cpp(dylib);
  bindings.llama_backend_init();
  bindings.llama_backend_free();
}
```

### Library Loading Notes

`LlamaLibraryLoader.open()` tries these candidates in order:

1. `LLAMA_CPP_LIBRARY_PATH` (if set)
2. Platform defaults:
   - macOS: `libllama.dylib`, `llama.dylib`
   - Linux: `libllama.so`, `libllama.so.1`
   - Windows: `llama.dll`, `libllama.dll`

This pattern helps examples/tests work in local development, CI, and system
installations without hand-written platform checks.

If loading fails, print the thrown `LlamaLibraryLoadException`; it includes the
full list of attempted library paths/names so you can quickly diagnose path issues.

## Updating Bindings

This repo includes llama.cpp as a submodule and a helper script to sync to the
latest release and regenerate bindings:

```bash
bash tools/update_llama_cpp.sh
```

You can also regenerate bindings directly:

```bash
dart run ffigen
```

## Testing

`dart test` includes unit tests for the loader utility and a smoke test for
`llama_backend_init()`/`llama_backend_free()`. The smoke test is skipped if no
llama.cpp dynamic library can be loaded.

```bash
dart test
```

To force a specific library in smoke tests:

```bash
LLAMA_CPP_LIBRARY_PATH=/path/to/libllama.dylib dart test
```
