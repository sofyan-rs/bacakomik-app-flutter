/// Whether [candidate] is a higher `major.minor.patch` than [current].
///
/// A leading `v` and any `-prerelease` or `+build` suffix are ignored, and
/// missing parts count as 0 (`1.2` == `1.2.0`).
bool isNewerVersion(String candidate, String current) {
  final a = _parts(candidate);
  final b = _parts(current);
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] > b[i];
  }
  return false;
}

List<int> _parts(String version) {
  final core = version
      .trim()
      .replaceFirst(RegExp('^v'), '')
      .split(RegExp('[-+]'))[0];
  final parts = core.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  return [for (var i = 0; i < 3; i++) i < parts.length ? parts[i] : 0];
}
