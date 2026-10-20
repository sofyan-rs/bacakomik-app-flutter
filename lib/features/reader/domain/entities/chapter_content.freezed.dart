// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chapter_content.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChapterContent {

 String get chapterTitle; String get chapterNumber; String get seriesSlug; String? get previousChapterSlug; String? get nextChapterSlug; List<String> get images;/// True when [images] are file paths of a downloaded chapter.
 bool get isOffline;
/// Create a copy of ChapterContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChapterContentCopyWith<ChapterContent> get copyWith => _$ChapterContentCopyWithImpl<ChapterContent>(this as ChapterContent, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChapterContent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChapterContent&&(identical(other.chapterTitle, _this.chapterTitle) || other.chapterTitle == _this.chapterTitle)&&(identical(other.chapterNumber, _this.chapterNumber) || other.chapterNumber == _this.chapterNumber)&&(identical(other.seriesSlug, _this.seriesSlug) || other.seriesSlug == _this.seriesSlug)&&(identical(other.previousChapterSlug, _this.previousChapterSlug) || other.previousChapterSlug == _this.previousChapterSlug)&&(identical(other.nextChapterSlug, _this.nextChapterSlug) || other.nextChapterSlug == _this.nextChapterSlug)&&const DeepCollectionEquality().equals(other.images, _this.images)&&(identical(other.isOffline, _this.isOffline) || other.isOffline == _this.isOffline));
}


@override
int get hashCode {
  final _this = this as ChapterContent;
  return Object.hash(runtimeType,_this.chapterTitle,_this.chapterNumber,_this.seriesSlug,_this.previousChapterSlug,_this.nextChapterSlug,const DeepCollectionEquality().hash(_this.images),_this.isOffline);
}

@override
String toString() {
  final _this = this as ChapterContent;
  return 'ChapterContent(chapterTitle: ${_this.chapterTitle}, chapterNumber: ${_this.chapterNumber}, seriesSlug: ${_this.seriesSlug}, previousChapterSlug: ${_this.previousChapterSlug}, nextChapterSlug: ${_this.nextChapterSlug}, images: ${_this.images}, isOffline: ${_this.isOffline})';
}


}

/// @nodoc
abstract mixin class $ChapterContentCopyWith<$Res>  {
  factory $ChapterContentCopyWith(ChapterContent value, $Res Function(ChapterContent) _then) = _$ChapterContentCopyWithImpl;
@useResult
$Res call({
 String chapterTitle, String chapterNumber, String seriesSlug, String? previousChapterSlug, String? nextChapterSlug, List<String> images, bool isOffline
});




}
/// @nodoc
class _$ChapterContentCopyWithImpl<$Res>
    implements $ChapterContentCopyWith<$Res> {
  _$ChapterContentCopyWithImpl(this._self, this._then);

  final ChapterContent _self;
  final $Res Function(ChapterContent) _then;

/// Create a copy of ChapterContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? chapterTitle = null,Object? chapterNumber = null,Object? seriesSlug = null,Object? previousChapterSlug = freezed,Object? nextChapterSlug = freezed,Object? images = null,Object? isOffline = null,}) {
  return _then(ChapterContent(
chapterTitle: null == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String,chapterNumber: null == chapterNumber ? _self.chapterNumber : chapterNumber // ignore: cast_nullable_to_non_nullable
as String,seriesSlug: null == seriesSlug ? _self.seriesSlug : seriesSlug // ignore: cast_nullable_to_non_nullable
as String,previousChapterSlug: freezed == previousChapterSlug ? _self.previousChapterSlug : previousChapterSlug // ignore: cast_nullable_to_non_nullable
as String?,nextChapterSlug: freezed == nextChapterSlug ? _self.nextChapterSlug : nextChapterSlug // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<String>,isOffline: null == isOffline ? _self.isOffline : isOffline // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChapterContent].
extension ChapterContentPatterns on ChapterContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChapterContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChapterContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChapterContent value)  $default,){
final _that = this;
switch (_that) {
case _ChapterContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChapterContent value)?  $default,){
final _that = this;
switch (_that) {
case _ChapterContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String chapterTitle,  String chapterNumber,  String seriesSlug,  String? previousChapterSlug,  String? nextChapterSlug,  List<String> images,  bool isOffline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChapterContent() when $default != null:
return $default(_that.chapterTitle,_that.chapterNumber,_that.seriesSlug,_that.previousChapterSlug,_that.nextChapterSlug,_that.images,_that.isOffline);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String chapterTitle,  String chapterNumber,  String seriesSlug,  String? previousChapterSlug,  String? nextChapterSlug,  List<String> images,  bool isOffline)  $default,) {final _that = this;
switch (_that) {
case _ChapterContent():
return $default(_that.chapterTitle,_that.chapterNumber,_that.seriesSlug,_that.previousChapterSlug,_that.nextChapterSlug,_that.images,_that.isOffline);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String chapterTitle,  String chapterNumber,  String seriesSlug,  String? previousChapterSlug,  String? nextChapterSlug,  List<String> images,  bool isOffline)?  $default,) {final _that = this;
switch (_that) {
case _ChapterContent() when $default != null:
return $default(_that.chapterTitle,_that.chapterNumber,_that.seriesSlug,_that.previousChapterSlug,_that.nextChapterSlug,_that.images,_that.isOffline);case _:
  return null;

}
}

}

/// @nodoc


class _ChapterContent implements ChapterContent {
  const _ChapterContent({required this.chapterTitle, required this.chapterNumber, required this.seriesSlug, this.previousChapterSlug, this.nextChapterSlug, required  List<String> images, this.isOffline = false}): _images = images;
  

@override final  String chapterTitle;
@override final  String chapterNumber;
@override final  String seriesSlug;
@override final  String? previousChapterSlug;
@override final  String? nextChapterSlug;
 final  List<String> _images;
@override List<String> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

/// True when [images] are file paths of a downloaded chapter.
@override@JsonKey() final  bool isOffline;

/// Create a copy of ChapterContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChapterContentCopyWith<_ChapterContent> get copyWith => __$ChapterContentCopyWithImpl<_ChapterContent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChapterContent&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.chapterNumber, chapterNumber) || other.chapterNumber == chapterNumber)&&(identical(other.seriesSlug, seriesSlug) || other.seriesSlug == seriesSlug)&&(identical(other.previousChapterSlug, previousChapterSlug) || other.previousChapterSlug == previousChapterSlug)&&(identical(other.nextChapterSlug, nextChapterSlug) || other.nextChapterSlug == nextChapterSlug)&&const DeepCollectionEquality().equals(other.images, _images)&&(identical(other.isOffline, isOffline) || other.isOffline == isOffline));
}


@override
int get hashCode {
    return Object.hash(runtimeType,chapterTitle,chapterNumber,seriesSlug,previousChapterSlug,nextChapterSlug,const DeepCollectionEquality().hash(_images),isOffline);
}

@override
String toString() {
    return 'ChapterContent(chapterTitle: $chapterTitle, chapterNumber: $chapterNumber, seriesSlug: $seriesSlug, previousChapterSlug: $previousChapterSlug, nextChapterSlug: $nextChapterSlug, images: $images, isOffline: $isOffline)';
}


}

/// @nodoc
abstract mixin class _$ChapterContentCopyWith<$Res> implements $ChapterContentCopyWith<$Res> {
  factory _$ChapterContentCopyWith(_ChapterContent value, $Res Function(_ChapterContent) _then) = __$ChapterContentCopyWithImpl;
@override @useResult
$Res call({
 String chapterTitle, String chapterNumber, String seriesSlug, String? previousChapterSlug, String? nextChapterSlug, List<String> images, bool isOffline
});




}
/// @nodoc
class __$ChapterContentCopyWithImpl<$Res>
    implements _$ChapterContentCopyWith<$Res> {
  __$ChapterContentCopyWithImpl(this._self, this._then);

  final _ChapterContent _self;
  final $Res Function(_ChapterContent) _then;

/// Create a copy of ChapterContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? chapterTitle = null,Object? chapterNumber = null,Object? seriesSlug = null,Object? previousChapterSlug = freezed,Object? nextChapterSlug = freezed,Object? images = null,Object? isOffline = null,}) {
  return _then(_ChapterContent(
chapterTitle: null == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String,chapterNumber: null == chapterNumber ? _self.chapterNumber : chapterNumber // ignore: cast_nullable_to_non_nullable
as String,seriesSlug: null == seriesSlug ? _self.seriesSlug : seriesSlug // ignore: cast_nullable_to_non_nullable
as String,previousChapterSlug: freezed == previousChapterSlug ? _self.previousChapterSlug : previousChapterSlug // ignore: cast_nullable_to_non_nullable
as String?,nextChapterSlug: freezed == nextChapterSlug ? _self.nextChapterSlug : nextChapterSlug // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<String>,isOffline: null == isOffline ? _self.isOffline : isOffline // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
