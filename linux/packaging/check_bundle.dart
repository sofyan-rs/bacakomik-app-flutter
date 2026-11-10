import 'dart:ffi';
import 'dart:io';

/// Match only libraries shipped in the bundle, including Flutter plugin SONAMEs.
/// RPM still scans every ELF file for dependencies on system libraries.
String privateLibraryRequires(Directory libraries) {
  final names = <String>{};
  for (final entry in libraries.listSync(recursive: true)) {
    if (entry is! File) continue;
    final name = entry.uri.pathSegments.last;
    if (RegExp(r'\.so(?:\..+)?$').hasMatch(name)) names.add(name);
  }
  final sorted = names.toList()..sort();
  return sorted.isEmpty
      ? r'^$'
      : '^(${sorted.map(RegExp.escape).join('|')})'
            r'(\(.*\))?$';
}

/// Check the native engine that source extensions load on Linux before shipping.
void main(List<String> args) {
  final printRequires =
      args.isNotEmpty && args.first == '--private-library-requires';
  final paths = printRequires ? args.skip(1).toList() : args;
  final bundle = Directory(
    paths.isEmpty ? 'build/linux/x64/release/bundle' : paths.single,
  ).absolute.path;
  if (printRequires) {
    stdout.writeln(privateLibraryRequires(Directory('$bundle/lib')));
    return;
  }
  final path = '$bundle/lib/libquickjs_c_bridge_plugin.so';
  try {
    final quickjs = DynamicLibrary.open(path);
    for (final symbol in ['jsNewRuntime', 'jsNewContext', 'jsEval']) {
      quickjs.lookup<Void>(symbol);
    }
    stdout.writeln('Bundled QuickJS library loads successfully: $path');
  } catch (error) {
    stderr.writeln('Cannot load the bundled QuickJS engine: $error');
    exitCode = 1;
  }
}
