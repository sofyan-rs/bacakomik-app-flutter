/// Pages grouped two by two for the sideways reader on wide screens, the
/// way a printed book opens: the first page (the cover) alone, then 2–3,
/// 4–5… A last page without a partner is alone too.
///
/// The reader keeps counting pages (progress, resume, the page meter); the
/// page view counts spreads, with the end card after the last one.
class PageSpreads {
  const PageSpreads(this.pageCount);

  final int pageCount;

  /// Spreads, not counting the end card.
  int get count => pageCount == 0 ? 0 : 1 + pageCount ~/ 2;

  /// The spread showing [page]; past the last page, the end card.
  int spreadOf(int page) {
    if (page >= pageCount) return count;
    return page <= 0 ? 0 : (page + 1) ~/ 2;
  }

  int first(int spread) => spread <= 0 ? 0 : spread * 2 - 1;

  /// Its last page: the one read once the spread is shown.
  int last(int spread) =>
      spread <= 0 ? 0 : (spread * 2).clamp(0, pageCount - 1);

  /// Pages in [spread], in reading order.
  List<int> pages(int spread) => [
    for (var page = first(spread); page <= last(spread); page++) page,
  ];

  /// The page before the spread showing [page]: where stepping back from
  /// it lands, the end card stepping back to the last spread.
  int pageBefore(int page) =>
      page >= pageCount ? pageCount - 1 : first(spreadOf(page)) - 1;
}
