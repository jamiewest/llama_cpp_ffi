import 'dart:ffi' as ffi;

import 'package:llama_cpp_ffi/llama_cpp_ffi.dart';
import 'package:test/test.dart';

void main() {
  group('LlamaLibraryLoader', () {
    test('places LLAMA_CPP_LIBRARY_PATH before platform defaults', () {
      final candidates = LlamaLibraryLoader.candidatePaths(
        environment: const {
          LlamaLibraryLoader.libraryPathEnv: '/custom/libllama.so',
        },
        isLinux: true,
      );

      expect(candidates.first, '/custom/libllama.so');
      expect(candidates, contains('libllama.so'));
    });

    test('tries candidates in order until one loads', () {
      final attempted = <String>[];

      final loaded = LlamaLibraryLoader.open(
        environment: const {
          LlamaLibraryLoader.libraryPathEnv: 'missing-first',
        },
        isLinux: true,
        opener: (path) {
          attempted.add(path);
          if (path == 'libllama.so') {
            return ffi.DynamicLibrary.process();
          }
          throw ArgumentError('cannot load $path');
        },
      );

      expect(loaded, isNotNull);
      expect(attempted, ['missing-first', 'libllama.so']);
    });

    test('includes attempted paths in error metadata', () {
      expect(
        () => LlamaLibraryLoader.open(
          environment: const {LlamaLibraryLoader.libraryPathEnv: 'nope'},
          isLinux: true,
          opener: (_) => throw ArgumentError('failed'),
        ),
        throwsA(
          isA<LlamaLibraryLoadException>().having(
            (error) => error.attemptedPaths,
            'attemptedPaths',
            ['nope', 'libllama.so', 'libllama.so.1'],
          ),
        ),
      );
    });
  });

  final ffi.DynamicLibrary? smokeLibrary;
  String? smokeSkipReason;
  try {
    smokeLibrary = LlamaLibraryLoader.open();
  } on LlamaLibraryLoadException catch (error) {
    smokeLibrary = null;
    smokeSkipReason = error.toString();
  }

  test(
    'llama_backend_init/free smoke test',
    () {
      final bindings = llama_cpp(smokeLibrary!);
      expect(
        () {
          bindings.llama_backend_init();
          bindings.llama_backend_free();
        },
        returnsNormally,
      );
    },
    skip: smokeSkipReason,
  );
}
