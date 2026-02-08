import 'dart:ffi' as ffi;
import 'dart:io';

/// Signature used to open a dynamic library path.
typedef DynamicLibraryOpener = ffi.DynamicLibrary Function(String path);

/// Helper for loading a llama.cpp dynamic library with predictable fallbacks.
///
/// The loader tries candidates in this order:
/// 1. `LLAMA_CPP_LIBRARY_PATH` environment variable, if set.
/// 2. Platform-specific default library names (`.dylib`, `.so`, `.dll`).
///
/// This utility keeps startup code in apps/tests concise and provides clearer
/// error messages when loading fails.
class LlamaLibraryLoader {
  /// Name of the environment variable used to override the library path.
  static const String libraryPathEnv = 'LLAMA_CPP_LIBRARY_PATH';

  /// Returns platform-specific default dynamic library names.
  static List<String> defaultLibraryNames({
    bool? isMacOS,
    bool? isLinux,
    bool? isWindows,
  }) {
    final macOS = isMacOS ?? Platform.isMacOS;
    final linux = isLinux ?? Platform.isLinux;
    final windows = isWindows ?? Platform.isWindows;

    if (macOS) {
      return const ['libllama.dylib', 'llama.dylib'];
    }

    if (linux) {
      return const ['libllama.so', 'libllama.so.1'];
    }

    if (windows) {
      return const ['llama.dll', 'libllama.dll'];
    }

    return const ['libllama'];
  }

  /// Returns ordered candidate paths for loading llama.cpp.
  static List<String> candidatePaths({
    Map<String, String>? environment,
    bool? isMacOS,
    bool? isLinux,
    bool? isWindows,
  }) {
    final env = environment ?? Platform.environment;
    final candidates = <String>[];
    final envPath = env[libraryPathEnv]?.trim();

    if (envPath != null && envPath.isNotEmpty) {
      candidates.add(envPath);
    }

    candidates.addAll(
      defaultLibraryNames(
        isMacOS: isMacOS,
        isLinux: isLinux,
        isWindows: isWindows,
      ),
    );

    return candidates;
  }

  /// Opens llama.cpp dynamic library from [candidatePaths] fallback order.
  ///
  /// Throws [LlamaLibraryLoadException] if none of the candidates can be
  /// loaded.
  static ffi.DynamicLibrary open({
    Map<String, String>? environment,
    DynamicLibraryOpener opener = ffi.DynamicLibrary.open,
    bool? isMacOS,
    bool? isLinux,
    bool? isWindows,
  }) {
    final candidates = candidatePaths(
      environment: environment,
      isMacOS: isMacOS,
      isLinux: isLinux,
      isWindows: isWindows,
    );

    final errors = <String>[];

    for (final candidate in candidates) {
      try {
        return opener(candidate);
      } catch (error) {
        errors.add('$candidate: $error');
      }
    }

    throw LlamaLibraryLoadException(
      attemptedPaths: candidates,
      errors: errors,
    );
  }
}

/// Error thrown when no llama.cpp dynamic library candidate could be loaded.
class LlamaLibraryLoadException implements Exception {
  final List<String> attemptedPaths;
  final List<String> errors;

  const LlamaLibraryLoadException({
    required this.attemptedPaths,
    required this.errors,
  });

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeln('Could not load llama.cpp dynamic library.')
      ..writeln('Set ${LlamaLibraryLoader.libraryPathEnv} or install the library on your system path.')
      ..writeln('Attempted: ${attemptedPaths.join(', ')}');

    if (errors.isNotEmpty) {
      buffer.writeln('Errors: ${errors.join(' | ')}');
    }

    return buffer.toString().trim();
  }
}
