import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic.freezed.dart';

/// Comic summary shown in lists (home, latest, search, explore).
@freezed
abstract class Comic with _$Comic {
  const factory Comic({
    required String title,
    required String coverImg,
    required String slug,
    required String type,
    required bool completed,
    required String rating,
    required String latestChapter,
  }) = _Comic;
}
