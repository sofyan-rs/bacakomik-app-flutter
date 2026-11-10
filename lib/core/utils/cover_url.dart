/// [cover] as a full URL: some sites give covers as paths on the site
/// (Comix: `/images/covers/…`), which are resolved against the source's
/// [baseUrl]. Anything else is returned as is.
String absoluteCover(String cover, String baseUrl) {
  if (!cover.startsWith('/')) return cover;
  final base = Uri.tryParse(baseUrl);
  if (base == null || !base.hasScheme || base.host.isEmpty) return cover;
  return base.resolve(cover).toString();
}
