import 'package:bacakomik_app/core/data/models/series_response.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComicInfo.altTitles', () {
    test('keeps a single native title', () {
      expect(ComicInfo.altTitles('Solo Leveling', '나 혼자만 레벨업'), '나 혼자만 레벨업');
    });

    test('hides placeholders', () {
      for (final alt in ['', '-', '?', 'N/A', 'Field Kosong', '  ']) {
        expect(ComicInfo.altTitles('Infinite Mage', alt), isNull, reason: alt);
      }
    });

    test('hides the main title, also inside a list', () {
      expect(ComicInfo.altTitles('Martial Peak', 'martial peak'), isNull);
      expect(
        ComicInfo.altTitles(
          'Yonshimai wa Yoru wo Omachikane',
          'Elf wa Yoru wo Omachikane, Yonshimai wa Yoru wo Omachikane, '
              '四姉妹〈エルフ〉は夜をおまちかね',
        ),
        'Elf wa Yoru wo Omachikane · 四姉妹〈エルフ〉は夜をおまちかね',
      );
    });

    test('matches the main title across quote styles', () {
      expect(
        ComicInfo.altTitles(
          "The Count's Secret Maid",
          'The Count’s Secret Maid',
        ),
        isNull,
      );
    });

    test('drops repeats and placeholder entries in a list', () {
      expect(ComicInfo.altTitles('X', 'A, -, a, Field Kosong, B'), 'A · B');
    });

    test('keeps commas without a space', () {
      expect(
        ComicInfo.altTitles('X', 'Logging 10,000 Years into the Future'),
        'Logging 10,000 Years into the Future',
      );
    });

    test('splits on bullets and keeps the commas inside titles', () {
      expect(
        ComicInfo.altTitles(
          'I Reincarnated As the Villainous Noble of an Otome Game, so I Tried '
              'Buying the Main Heroine With Money',
          '乙女ゲームの悪役貴族に転生したので、金の力でメインヒロインを買ってみた。 • '
              'Reincarnated as an Otome Game\'s Villain Noble, I Tried Buying '
              'the Main Heroine with Money. • I Reincarnated As the Villainous '
              'Noble of an Otome Game, so I Tried Buying the Main Heroine With '
              'Money',
        ),
        '乙女ゲームの悪役貴族に転生したので、金の力でメインヒロインを買ってみた。 · '
        'Reincarnated as an Otome Game\'s Villain Noble, I Tried Buying the '
        'Main Heroine with Money.',
      );
    });

    test('splits on slashes, pipes and line breaks, trims leftovers', () {
      expect(ComicInfo.altTitles('X', 'A / B | C'), 'A · B · C');
      expect(ComicInfo.altTitles('X', 'X ,\n  科技大佬来修仙'), '科技大佬来修仙');
      expect(ComicInfo.altTitles('X', 'Part 1/2'), 'Part 1/2');
    });

    test('reads a list stored one per line', () {
      expect(
        ComicInfo.altTitles('X', 'A, with a comma\nB'),
        'A, with a comma · B',
      );
    });
  });

  group('SeriesDetailResponse alternative titles', () {
    SeriesDetailResponse parse(Map<String, dynamic> extra) =>
        SeriesDetailResponse.fromJson({'title': 'X', 'slug': 's', ...extra});

    test('stores altTitles one per line', () {
      final details = parse({
        'nativeTitle': 'A',
        'altTitles': ['A', 'B, with a comma'],
      }).toEntity(const []);
      expect(details.alternativeTitle, 'A\nB, with a comma');
    });

    test('falls back to nativeTitle', () {
      expect(
        parse({'nativeTitle': 'A'}).toEntity(const []).alternativeTitle,
        'A',
      );
      expect(
        parse({'nativeTitle': 'A', 'altTitles': <String>[]})
            .toEntity(const [])
            .alternativeTitle,
        'A',
      );
      expect(parse({}).toEntity(const []).alternativeTitle, '-');
    });
  });
}
