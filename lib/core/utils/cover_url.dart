/// [cover] as a full URL: some sites give covers as paths on the site
/// (Comix: `/images/covers/…`), which are resolved against the source's
/// [baseUrl]. Anything else is returned as is.
String absoluteCover(String cover, String baseUrl) {
  if (!cover.startsWith('/')) return cover;
  final base = Uri.tryParse(baseUrl);
  if (base == null || !base.hasScheme || base.host.isEmpty) return cover;
  return base.resolve(cover).toString();
}

/// Whether [url] is a presigned S3 URL (`X-Amz-Date` + `X-Amz-Expires`)
/// that expired, or expires within [margin] of [now]. VoraToon's covers on
/// cvr.voratoon.id are such URLs, valid for 6 days: one stored in the
/// library then answers 403 for good, so its comic needs its details
/// again. False for any other URL.
bool presignedUrlExpired(
  String url,
  DateTime now, {
  Duration margin = const Duration(hours: 12),
}) {
  final query = Uri.tryParse(url)?.queryParameters ?? const {};
  final date = RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z$')
      .firstMatch(query['X-Amz-Date'] ?? '');
  final seconds = int.tryParse(query['X-Amz-Expires'] ?? '');
  if (date == null || seconds == null) return false;
  final part = [for (var i = 1; i <= 6; i++) int.parse(date.group(i)!)];
  final signed = DateTime.utc(
    part[0],
    part[1],
    part[2],
    part[3],
    part[4],
    part[5],
  );
  final expires = signed.add(Duration(seconds: seconds));
  return !now.toUtc().add(margin).isBefore(expires);
}
