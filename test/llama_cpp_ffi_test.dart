import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:llama_cpp_ffi/llama_cpp_ffi.dart';
import 'package:test/test.dart';

class _LibraryLoadResult {
  final ffi.DynamicLibrary? library;
  final String? skipReason;

  const _LibraryLoadResult(this.library, this.skipReason);
}

_LibraryLoadResult _loadLlamaLibrary() {
  final envPath = Platform.environment['LLAMA_CPP_LIBRARY_PATH'];
  final candidates = <String>[];

  if (envPath != null && envPath.trim().isNotEmpty) {
    candidates.add(envPath.trim());
  }

  if (Platform.isMacOS) {
    candidates.addAll(['libllama.dylib', 'llama.dylib']);
  } else if (Platform.isLinux) {
    candidates.addAll(['libllama.so', 'libllama.so.1']);
  } else if (Platform.isWindows) {
    candidates.addAll(['llama.dll', 'libllama.dll']);
  }

  final errors = <String>[];
  for (final candidate in candidates) {
    try {
      return _LibraryLoadResult(ffi.DynamicLibrary.open(candidate), null);
    } catch (err) {
      errors.add('$candidate: $err');
    }
  }

  final skipReason = StringBuffer()
    ..writeln('No llama.cpp dynamic library found.')
    ..writeln('Set LLAMA_CPP_LIBRARY_PATH to the built library, or ensure it is on the system library path.');

  if (errors.isNotEmpty) {
    skipReason.writeln('Tried: ${errors.join(' | ')}');
  }

  return _LibraryLoadResult(null, skipReason.toString().trim());
}

void main() {
  final loadResult = _loadLlamaLibrary();

  test(
    'llama_backend_init/free smoke test',
    () {
      final bindings = llama_cpp(loadResult.library!);
      expect(
        () {
          bindings.llama_backend_init();
          bindings.llama_backend_free();
        },
        returnsNormally,
      );
    },
    skip: loadResult.skipReason,
  );
}
