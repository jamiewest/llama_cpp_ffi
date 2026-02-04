# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Dart FFI wrapper for [llama.cpp](https://github.com/ggml-org/llama.cpp), providing Dart bindings for high-performance LLM inference. Uses `ffigen` to auto-generate Dart bindings from C headers.

## Common Commands

```bash
# Get dependencies
dart pub get

# Generate FFI bindings from C headers (llama.h, mtmd.h)
dart run ffigen

# Update llama.cpp submodule to latest release and regenerate bindings
bash tools/update_llama_cpp.sh

# Run static analysis
dart analyze

# Run tests
dart test

# Smoke test expects a llama.cpp dynamic library
# Set LLAMA_CPP_LIBRARY_PATH to the built library path if needed

# Run a single test file
dart test test/llama_cpp_ffi_test.dart
```

## Architecture

```
Dart Application
    ↓
lib/llama_cpp_ffi.dart          # Public API exports
    ↓
lib/src/llama_cpp_base.dart     # Wrapper classes (to be implemented)
    ↓
lib/src/core/llama_cpp.dart     # Auto-generated FFI bindings (23K lines, DO NOT EDIT)
    ↓
src/llama.cpp/                  # Native C/C++ library (git submodule)
```

**Key files:**
- `pubspec.yaml` - Contains ffigen configuration under `ffigen:` section
- `lib/src/core/llama_cpp.dart` - Auto-generated, regenerate with `dart run ffigen`
- `src/llama.cpp/include/llama.h` - Main C header for bindings
- `src/llama.cpp/tools/mtmd/mtmd.h` - MTMD support header

## FFI Binding Generation

The ffigen configuration in pubspec.yaml specifies:
- Entry points: `llama.h` and `mtmd.h`
- Include paths for clang and ggml headers
- Output to `lib/src/core/llama_cpp.dart`

When llama.cpp headers change, regenerate bindings with `dart run ffigen`.

## llama.cpp Contribution Policy

The embedded `src/llama.cpp/` has strict AI usage policies (see `src/llama.cpp/AGENTS.md`):
- Pull requests to llama.cpp that are fully/predominantly AI-generated are **not accepted**
- AI may only be used in an assistive capacity
- All AI usage requires explicit disclosure
- Code must be majority human-authored

This policy applies when contributing changes upstream to llama.cpp, not to this Dart wrapper project.
