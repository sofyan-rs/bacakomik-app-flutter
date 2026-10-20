// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'downloaded_chapter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DownloadedChapter {

/// Chapter slug (`seriesSlug/number`).
 String get slug; String get comicSlug; String get chapterNumber; DownloadStatus get status;/// When the chapter was added to the queue; orders the queue.
 DateTime get addedAt;/// 0 until the chapter's page list has been fetched.
 int get pageCount; int get savedPages; int get sizeBytes; DateTime? get downloadedAt;
/// Create a copy of DownloadedChapter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadedChapterCopyWith<DownloadedChapter> get copyWith => _$DownloadedChapterCopyWithImpl<DownloadedChapter>(this as DownloadedChapter, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DownloadedChapter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadedChapter&&(identical(other.slug, _this.slug) || other.slug == _this.slug)&&(identical(other.comicSlug, _this.comicSlug) || other.comicSlug == _this.comicSlug)&&(identical(other.chapterNumber, _this.chapterNumber) || other.chapterNumber == _this.chapterNumber)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.addedAt, _this.addedAt) || other.addedAt == _this.addedAt)&&(identical(other.pageCount, _this.pageCount) || other.pageCount == _this.pageCount)&&(identical(other.savedPages, _this.savedPages) || other.savedPages == _this.savedPages)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&(identical(other.downloadedAt, _this.downloadedAt) || other.downloadedAt == _this.downloadedAt));
}


@override
int get hashCode {
  final _this = this as DownloadedChapter;
  return Object.hash(runtimeType,_this.slug,_this.comicSlug,_this.chapterNumber,_this.status,_this.addedAt,_this.pageCount,_this.savedPages,_this.sizeBytes,_this.downloadedAt);
}

@override
String toString() {
  final _this = this as DownloadedChapter;
  return 'DownloadedChapter(slug: ${_this.slug}, comicSlug: ${_this.comicSlug}, chapterNumber: ${_this.chapterNumber}, status: ${_this.status}, addedAt: ${_this.addedAt}, pageCount: ${_this.pageCount}, savedPages: ${_this.savedPages}, sizeBytes: ${_this.sizeBytes}, downloadedAt: ${_this.downloadedAt})';
}


}

/// @nodoc
abstract mixin class $DownloadedChapterCopyWith<$Res>  {
  factory $DownloadedChapterCopyWith(DownloadedChapter value, $Res Function(DownloadedChapter) _then) = _$DownloadedChapterCopyWithImpl;
@useResult
$Res call({
 String slug, String comicSlug, String chapterNumber, DownloadStatus status, DateTime addedAt, int pageCount, int savedPages, int sizeBytes, DateTime? downloadedAt
});




}
/// @nodoc
class _$DownloadedChapterCopyWithImpl<$Res>
    implements $DownloadedChapterCopyWith<$Res> {
  _$DownloadedChapterCopyWithImpl(this._self, this._then);

  final DownloadedChapter _self;
  final $Res Function(DownloadedChapter) _then;

/// Create a copy of DownloadedChapter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? comicSlug = null,Object? chapterNumber = null,Object? status = null,Object? addedAt = null,Object? pageCount = null,Object? savedPages = null,Object? sizeBytes = null,Object? downloadedAt = freezed,}) {
  return _then(DownloadedChapter(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,comicSlug: null == comicSlug ? _self.comicSlug : comicSlug // ignore: cast_nullable_to_non_nullable
as String,chapterNumber: null == chapterNumber ? _self.chapterNumber : chapterNumber // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DownloadStatus,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,savedPages: null == savedPages ? _self.savedPages : savedPages // ignore: cast_nullable_to_non_nullable
as int,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,downloadedAt: freezed == downloadedAt ? _self.downloadedAt : downloadedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [DownloadedChapter].
extension DownloadedChapterPatterns on DownloadedChapter {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadedChapter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadedChapter() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadedChapter value)  $default,){
final _that = this;
switch (_that) {
case _DownloadedChapter():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadedChapter value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadedChapter() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  String comicSlug,  String chapterNumber,  DownloadStatus status,  DateTime addedAt,  int pageCount,  int savedPages,  int sizeBytes,  DateTime? downloadedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadedChapter() when $default != null:
return $default(_that.slug,_that.comicSlug,_that.chapterNumber,_that.status,_that.addedAt,_that.pageCount,_that.savedPages,_that.sizeBytes,_that.downloadedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  String comicSlug,  String chapterNumber,  DownloadStatus status,  DateTime addedAt,  int pageCount,  int savedPages,  int sizeBytes,  DateTime? downloadedAt)  $default,) {final _that = this;
switch (_that) {
case _DownloadedChapter():
return $default(_that.slug,_that.comicSlug,_that.chapterNumber,_that.status,_that.addedAt,_that.pageCount,_that.savedPages,_that.sizeBytes,_that.downloadedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  String comicSlug,  String chapterNumber,  DownloadStatus status,  DateTime addedAt,  int pageCount,  int savedPages,  int sizeBytes,  DateTime? downloadedAt)?  $default,) {final _that = this;
switch (_that) {
case _DownloadedChapter() when $default != null:
return $default(_that.slug,_that.comicSlug,_that.chapterNumber,_that.status,_that.addedAt,_that.pageCount,_that.savedPages,_that.sizeBytes,_that.downloadedAt);case _:
  return null;

}
}

}

/// @nodoc


class _DownloadedChapter extends DownloadedChapter {
  const _DownloadedChapter({required this.slug, required this.comicSlug, required this.chapterNumber, required this.status, required this.addedAt, this.pageCount = 0, this.savedPages = 0, this.sizeBytes = 0, this.downloadedAt}): super._();
  

/// Chapter slug (`seriesSlug/number`).
@override final  String slug;
@override final  String comicSlug;
@override final  String chapterNumber;
@override final  DownloadStatus status;
/// When the chapter was added to the queue; orders the queue.
@override final  DateTime addedAt;
/// 0 until the chapter's page list has been fetched.
@override@JsonKey() final  int pageCount;
@override@JsonKey() final  int savedPages;
@override@JsonKey() final  int sizeBytes;
@override final  DateTime? downloadedAt;

/// Create a copy of DownloadedChapter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadedChapterCopyWith<_DownloadedChapter> get copyWith => __$DownloadedChapterCopyWithImpl<_DownloadedChapter>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadedChapter&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.comicSlug, comicSlug) || other.comicSlug == comicSlug)&&(identical(other.chapterNumber, chapterNumber) || other.chapterNumber == chapterNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.savedPages, savedPages) || other.savedPages == savedPages)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.downloadedAt, downloadedAt) || other.downloadedAt == downloadedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,slug,comicSlug,chapterNumber,status,addedAt,pageCount,savedPages,sizeBytes,downloadedAt);
}

@override
String toString() {
    return 'DownloadedChapter(slug: $slug, comicSlug: $comicSlug, chapterNumber: $chapterNumber, status: $status, addedAt: $addedAt, pageCount: $pageCount, savedPages: $savedPages, sizeBytes: $sizeBytes, downloadedAt: $downloadedAt)';
}


}

/// @nodoc
abstract mixin class _$DownloadedChapterCopyWith<$Res> implements $DownloadedChapterCopyWith<$Res> {
  factory _$DownloadedChapterCopyWith(_DownloadedChapter value, $Res Function(_DownloadedChapter) _then) = __$DownloadedChapterCopyWithImpl;
@override @useResult
$Res call({
 String slug, String comicSlug, String chapterNumber, DownloadStatus status, DateTime addedAt, int pageCount, int savedPages, int sizeBytes, DateTime? downloadedAt
});




}
/// @nodoc
class __$DownloadedChapterCopyWithImpl<$Res>
    implements _$DownloadedChapterCopyWith<$Res> {
  __$DownloadedChapterCopyWithImpl(this._self, this._then);

  final _DownloadedChapter _self;
  final $Res Function(_DownloadedChapter) _then;

/// Create a copy of DownloadedChapter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? comicSlug = null,Object? chapterNumber = null,Object? status = null,Object? addedAt = null,Object? pageCount = null,Object? savedPages = null,Object? sizeBytes = null,Object? downloadedAt = freezed,}) {
  return _then(_DownloadedChapter(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,comicSlug: null == comicSlug ? _self.comicSlug : comicSlug // ignore: cast_nullable_to_non_nullable
as String,chapterNumber: null == chapterNumber ? _self.chapterNumber : chapterNumber // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DownloadStatus,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,savedPages: null == savedPages ? _self.savedPages : savedPages // ignore: cast_nullable_to_non_nullable
as int,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,downloadedAt: freezed == downloadedAt ? _self.downloadedAt : downloadedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
