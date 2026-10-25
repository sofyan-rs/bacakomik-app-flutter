import 'package:bacakomik_app/features/comic_detail/presentation/widgets/chapter_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chapters from the last 24 hours are new', () {
    expect(ChapterDate.isNew('Just now'), isTrue);
    expect(ChapterDate.isNew('12 min ago'), isTrue);
    expect(ChapterDate.isNew('23 h ago'), isTrue);
    expect(ChapterDate.isNew('1 day ago'), isFalse);
    expect(ChapterDate.isNew('01/02/2025'), isFalse);
    expect(ChapterDate.isNew('-'), isFalse);
  });

  test('short dates', () {
    expect(ChapterDate.short('12 min ago'), '12 min');
    expect(ChapterDate.short('3 h ago'), '3 h');
    expect(ChapterDate.short('7 days ago'), '7 d');
    expect(ChapterDate.short('1 day ago'), '1 d');
    expect(ChapterDate.short('01/02/2025'), '01/02/2025');
  });
}
