# llama_cpp_ffi

Low-level Dart FFI bindings for [llama.cpp](https://github.com/ggml-org/llama.cpp).
Bindings are generated with `ffigen` from llama.cpp headers. This package does not
ship native binaries; you must build or provide a llama.cpp dynamic library.

## What This Is

- Auto-generated Dart bindings to the C API in `llama.h` (and `mtmd.h`).
- Intended as a thin, low-level layer to build higher-level wrappers on top.

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
import 'dart:io';

import 'package:llama_cpp_ffi/llama_cpp_ffi.dart';

void main() {
  final libPath = Platform.environment['LLAMA_CPP_LIBRARY_PATH'];
  if (libPath == null || libPath.trim().isEmpty) {
    print('Set LLAMA_CPP_LIBRARY_PATH to a built llama.cpp library.');
    return;
  }

  final dylib = ffi.DynamicLibrary.open(libPath);
  final bindings = llama_cpp(dylib);
  bindings.llama_backend_init();
  bindings.llama_backend_free();
}
```

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

The smoke test calls `llama_backend_init()`/`llama_backend_free()` if a dynamic
library is available. Set `LLAMA_CPP_LIBRARY_PATH` before running tests.

```bash
LLAMA_CPP_LIBRARY_PATH=/path/to/libllama.dylib dart test
```
