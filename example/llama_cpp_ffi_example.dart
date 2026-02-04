import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:llama_cpp_ffi/llama_cpp_ffi.dart';

void main() {
  final libPath = Platform.environment['LLAMA_CPP_LIBRARY_PATH'];
  if (libPath == null || libPath.trim().isEmpty) {
    stdout.writeln('Set LLAMA_CPP_LIBRARY_PATH to a built llama.cpp library.');
    stdout.writeln('Example: export LLAMA_CPP_LIBRARY_PATH=/path/to/libllama.dylib');
    return;
  }

  final dylib = ffi.DynamicLibrary.open(libPath);
  final bindings = llama_cpp(dylib);
  bindings.llama_backend_init();
  bindings.llama_backend_free();
  stdout.writeln('llama.cpp backend initialized successfully.');
}
