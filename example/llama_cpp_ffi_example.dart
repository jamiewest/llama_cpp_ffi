import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:llama_cpp_ffi/llama_cpp_ffi.dart';

void main() {
  // Prefer LLAMA_CPP_LIBRARY_PATH for local development and CI.
  // Otherwise, the loader tries common system library names.
  final ffi.DynamicLibrary dylib;
  try {
    dylib = LlamaLibraryLoader.open();
  } on LlamaLibraryLoadException catch (error) {
    stdout.writeln(error);
    stdout.writeln(
      'Example: export ${LlamaLibraryLoader.libraryPathEnv}=/path/to/libllama.dylib',
    );
    return;
  }

  final bindings = llama_cpp(dylib);

  // Always pair backend init/free to avoid leaking global backend state.
  bindings.llama_backend_init();
  bindings.llama_backend_free();

  stdout.writeln('llama.cpp backend initialized successfully.');
}
