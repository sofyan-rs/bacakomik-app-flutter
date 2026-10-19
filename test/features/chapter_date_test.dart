import 'package:bacakomik_app/features/comic_detail/presentation/widgets/chapter_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chapters from the last 24 hours are new', () {
    expect(ChapterDate.isNew('Baru saja'), isTrue);
    expect(ChapterDate.isNew('12 menit lalu'), isTrue);
    expect(ChapterDate.isNew('23 jam lalu'), isTrue);
    expect(ChapterDate.isNew('1 hari lalu'), isFalse);
    expect(ChapterDate.isNew('01/02/2025'), isFalse);
    expect(ChapterDate.isNew('-'), isFalse);
  });

  test('short dates', () {
    expect(ChapterDate.short('12 menit lalu'), '12 mnt');
    expect(ChapterDate.short('3 jam lalu'), '3 jam');
    expect(ChapterDate.short('7 hari lalu'), '7 hari');
    expect(ChapterDate.short('01/02/2025'), '01/02/2025');
  });
}
