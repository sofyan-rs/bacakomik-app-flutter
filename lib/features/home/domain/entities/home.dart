import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home.freezed.dart';

@freezed
abstract class Home with _$Home {
  const factory Home({
    required List<Comic> newSeries,
    required List<Comic> latest,
  }) = _Home;
}
