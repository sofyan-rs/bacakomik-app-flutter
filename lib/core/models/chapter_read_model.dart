import 'dart:convert';
import 'package:flutter/foundation.dart';

class ChapterReadModel {
  final String chapterTitle;
  final String chapterNumber;
  final String seriesTitle;
  final String seriesSlug;
  final String? previousChapterSlug;
  final String? nextChapterSlug;
  final List<dynamic> imageChapters;
  ChapterReadModel({
    required this.chapterTitle,
    required this.chapterNumber,
    required this.seriesTitle,
    required this.seriesSlug,
    this.previousChapterSlug,
    this.nextChapterSlug,
    required this.imageChapters,
  });

  ChapterReadModel copyWith({
    String? chapterTitle,
    String? chapterNumber,
    String? seriesTitle,
    String? seriesSlug,
    String? previousChapterSlug,
    String? nextChapterSlug,
    List<dynamic>? imageChapters,
  }) {
    return ChapterReadModel(
      chapterTitle: chapterTitle ?? this.chapterTitle,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      seriesTitle: seriesTitle ?? this.seriesTitle,
      seriesSlug: seriesSlug ?? this.seriesSlug,
      previousChapterSlug: previousChapterSlug ?? this.previousChapterSlug,
      nextChapterSlug: nextChapterSlug ?? this.nextChapterSlug,
      imageChapters: imageChapters ?? this.imageChapters,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'chapterTitle': chapterTitle,
      'chapterNumber': chapterNumber,
      'seriesTitle': seriesTitle,
      'seriesSlug': seriesSlug,
      'previousChapterSlug': previousChapterSlug,
      'nextChapterSlug': nextChapterSlug,
      'imageChapters': imageChapters,
    };
  }

  factory ChapterReadModel.fromMap(Map<String, dynamic> map) {
    return ChapterReadModel(
      chapterTitle: map['chapterTitle'] as String,
      chapterNumber: map['chapterNumber'] as String,
      seriesTitle: map['seriesTitle'] as String,
      seriesSlug: map['seriesSlug'] as String,
      previousChapterSlug: map['previousChapterSlug'] != null
          ? map['previousChapterSlug'] as String
          : null,
      nextChapterSlug: map['nextChapterSlug'] != null
          ? map['nextChapterSlug'] as String
          : null,
      imageChapters: List<dynamic>.from(
        (map['imageChapters'] as List<dynamic>),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory ChapterReadModel.fromJson(String source) =>
      ChapterReadModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ChapterReadModel(chapterTitle: $chapterTitle, chapterNumber: $chapterNumber, seriesTitle: $seriesTitle, seriesSlug: $seriesSlug, previousChapterSlug: $previousChapterSlug, nextChapterSlug: $nextChapterSlug, imageChapters: $imageChapters)';
  }

  @override
  bool operator ==(covariant ChapterReadModel other) {
    if (identical(this, other)) return true;

    return other.chapterTitle == chapterTitle &&
        other.chapterNumber == chapterNumber &&
        other.seriesTitle == seriesTitle &&
        other.seriesSlug == seriesSlug &&
        other.previousChapterSlug == previousChapterSlug &&
        other.nextChapterSlug == nextChapterSlug &&
        listEquals(other.imageChapters, imageChapters);
  }

  @override
  int get hashCode {
    return chapterTitle.hashCode ^
        chapterNumber.hashCode ^
        seriesTitle.hashCode ^
        seriesSlug.hashCode ^
        previousChapterSlug.hashCode ^
        nextChapterSlug.hashCode ^
        imageChapters.hashCode;
  }
}
