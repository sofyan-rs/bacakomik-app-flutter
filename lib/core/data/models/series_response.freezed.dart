// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'series_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SeriesResponse {

 String get title; String get slug; String? get cover; String? get format; String? get status; num? get rating; num? get totalChapters;/// Optional in the contract; only some lists have them.
 List<String>? get altTitles;
/// Create a copy of SeriesResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeriesResponseCopyWith<SeriesResponse> get copyWith => _$SeriesResponseCopyWithImpl<SeriesResponse>(this as SeriesResponse, _$identity);

  /// Serializes this SeriesResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SeriesResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeriesResponse&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.slug, _this.slug) || other.slug == _this.slug)&&(identical(other.cover, _this.cover) || other.cover == _this.cover)&&(identical(other.format, _this.format) || other.format == _this.format)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.totalChapters, _this.totalChapters) || other.totalChapters == _this.totalChapters)&&const DeepCollectionEquality().equals(other.altTitles, _this.altTitles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SeriesResponse;
  return Object.hash(runtimeType,_this.title,_this.slug,_this.cover,_this.format,_this.status,_this.rating,_this.totalChapters,const DeepCollectionEquality().hash(_this.altTitles));
}

@override
String toString() {
  final _this = this as SeriesResponse;
  return 'SeriesResponse(title: ${_this.title}, slug: ${_this.slug}, cover: ${_this.cover}, format: ${_this.format}, status: ${_this.status}, rating: ${_this.rating}, totalChapters: ${_this.totalChapters}, altTitles: ${_this.altTitles})';
}


}

/// @nodoc
abstract mixin class $SeriesResponseCopyWith<$Res>  {
  factory $SeriesResponseCopyWith(SeriesResponse value, $Res Function(SeriesResponse) _then) = _$SeriesResponseCopyWithImpl;
@useResult
$Res call({
 String title, String slug, String? cover, String? format, String? status, num? rating, num? totalChapters, List<String>? altTitles
});




}
/// @nodoc
class _$SeriesResponseCopyWithImpl<$Res>
    implements $SeriesResponseCopyWith<$Res> {
  _$SeriesResponseCopyWithImpl(this._self, this._then);

  final SeriesResponse _self;
  final $Res Function(SeriesResponse) _then;

/// Create a copy of SeriesResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? slug = null,Object? cover = freezed,Object? format = freezed,Object? status = freezed,Object? rating = freezed,Object? totalChapters = freezed,Object? altTitles = freezed,}) {
  return _then(SeriesResponse(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String?,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as num?,totalChapters: freezed == totalChapters ? _self.totalChapters : totalChapters // ignore: cast_nullable_to_non_nullable
as num?,altTitles: freezed == altTitles ? _self.altTitles : altTitles // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [SeriesResponse].
extension SeriesResponsePatterns on SeriesResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeriesResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeriesResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeriesResponse value)  $default,){
final _that = this;
switch (_that) {
case _SeriesResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeriesResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SeriesResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String slug,  String? cover,  String? format,  String? status,  num? rating,  num? totalChapters,  List<String>? altTitles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeriesResponse() when $default != null:
return $default(_that.title,_that.slug,_that.cover,_that.format,_that.status,_that.rating,_that.totalChapters,_that.altTitles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String slug,  String? cover,  String? format,  String? status,  num? rating,  num? totalChapters,  List<String>? altTitles)  $default,) {final _that = this;
switch (_that) {
case _SeriesResponse():
return $default(_that.title,_that.slug,_that.cover,_that.format,_that.status,_that.rating,_that.totalChapters,_that.altTitles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String slug,  String? cover,  String? format,  String? status,  num? rating,  num? totalChapters,  List<String>? altTitles)?  $default,) {final _that = this;
switch (_that) {
case _SeriesResponse() when $default != null:
return $default(_that.title,_that.slug,_that.cover,_that.format,_that.status,_that.rating,_that.totalChapters,_that.altTitles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeriesResponse extends SeriesResponse {
  const _SeriesResponse({required this.title, required this.slug, this.cover, this.format, this.status, this.rating, this.totalChapters,  List<String>? altTitles}): _altTitles = altTitles,super._();
  factory _SeriesResponse.fromJson(Map<String, dynamic> json) => _$SeriesResponseFromJson(json);

@override final  String title;
@override final  String slug;
@override final  String? cover;
@override final  String? format;
@override final  String? status;
@override final  num? rating;
@override final  num? totalChapters;
/// Optional in the contract; only some lists have them.
 final  List<String>? _altTitles;
/// Optional in the contract; only some lists have them.
@override List<String>? get altTitles {
  final value = _altTitles;
  if (value == null) return null;
  if (_altTitles is EqualUnmodifiableListView) return _altTitles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of SeriesResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeriesResponseCopyWith<_SeriesResponse> get copyWith => __$SeriesResponseCopyWithImpl<_SeriesResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeriesResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeriesResponse&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.format, format) || other.format == format)&&(identical(other.status, status) || other.status == status)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.totalChapters, totalChapters) || other.totalChapters == totalChapters)&&const DeepCollectionEquality().equals(other.altTitles, _altTitles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,slug,cover,format,status,rating,totalChapters,const DeepCollectionEquality().hash(_altTitles));
}

@override
String toString() {
    return 'SeriesResponse(title: $title, slug: $slug, cover: $cover, format: $format, status: $status, rating: $rating, totalChapters: $totalChapters, altTitles: $altTitles)';
}


}

/// @nodoc
abstract mixin class _$SeriesResponseCopyWith<$Res> implements $SeriesResponseCopyWith<$Res> {
  factory _$SeriesResponseCopyWith(_SeriesResponse value, $Res Function(_SeriesResponse) _then) = __$SeriesResponseCopyWithImpl;
@override @useResult
$Res call({
 String title, String slug, String? cover, String? format, String? status, num? rating, num? totalChapters, List<String>? altTitles
});




}
/// @nodoc
class __$SeriesResponseCopyWithImpl<$Res>
    implements _$SeriesResponseCopyWith<$Res> {
  __$SeriesResponseCopyWithImpl(this._self, this._then);

  final _SeriesResponse _self;
  final $Res Function(_SeriesResponse) _then;

/// Create a copy of SeriesResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? slug = null,Object? cover = freezed,Object? format = freezed,Object? status = freezed,Object? rating = freezed,Object? totalChapters = freezed,Object? altTitles = freezed,}) {
  return _then(_SeriesResponse(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String?,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as num?,totalChapters: freezed == totalChapters ? _self.totalChapters : totalChapters // ignore: cast_nullable_to_non_nullable
as num?,altTitles: freezed == altTitles ? _self._altTitles : altTitles // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}


/// @nodoc
mixin _$SeriesDetailResponse {

 String get title; String get slug; String? get cover; String? get nativeTitle;/// Every alternative title, already split. Optional in the contract; older
/// extensions send only [nativeTitle].
 List<String>? get altTitles; String? get releaseDate; String? get status; String? get author; String? get format; num? get rating; String? get synopsis; List<GenreResponse> get genres;
/// Create a copy of SeriesDetailResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeriesDetailResponseCopyWith<SeriesDetailResponse> get copyWith => _$SeriesDetailResponseCopyWithImpl<SeriesDetailResponse>(this as SeriesDetailResponse, _$identity);

  /// Serializes this SeriesDetailResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SeriesDetailResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeriesDetailResponse&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.slug, _this.slug) || other.slug == _this.slug)&&(identical(other.cover, _this.cover) || other.cover == _this.cover)&&(identical(other.nativeTitle, _this.nativeTitle) || other.nativeTitle == _this.nativeTitle)&&const DeepCollectionEquality().equals(other.altTitles, _this.altTitles)&&(identical(other.releaseDate, _this.releaseDate) || other.releaseDate == _this.releaseDate)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.format, _this.format) || other.format == _this.format)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.synopsis, _this.synopsis) || other.synopsis == _this.synopsis)&&const DeepCollectionEquality().equals(other.genres, _this.genres));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SeriesDetailResponse;
  return Object.hash(runtimeType,_this.title,_this.slug,_this.cover,_this.nativeTitle,const DeepCollectionEquality().hash(_this.altTitles),_this.releaseDate,_this.status,_this.author,_this.format,_this.rating,_this.synopsis,const DeepCollectionEquality().hash(_this.genres));
}

@override
String toString() {
  final _this = this as SeriesDetailResponse;
  return 'SeriesDetailResponse(title: ${_this.title}, slug: ${_this.slug}, cover: ${_this.cover}, nativeTitle: ${_this.nativeTitle}, altTitles: ${_this.altTitles}, releaseDate: ${_this.releaseDate}, status: ${_this.status}, author: ${_this.author}, format: ${_this.format}, rating: ${_this.rating}, synopsis: ${_this.synopsis}, genres: ${_this.genres})';
}


}

/// @nodoc
abstract mixin class $SeriesDetailResponseCopyWith<$Res>  {
  factory $SeriesDetailResponseCopyWith(SeriesDetailResponse value, $Res Function(SeriesDetailResponse) _then) = _$SeriesDetailResponseCopyWithImpl;
@useResult
$Res call({
 String title, String slug, String? cover, String? nativeTitle, List<String>? altTitles, String? releaseDate, String? status, String? author, String? format, num? rating, String? synopsis, List<GenreResponse> genres
});




}
/// @nodoc
class _$SeriesDetailResponseCopyWithImpl<$Res>
    implements $SeriesDetailResponseCopyWith<$Res> {
  _$SeriesDetailResponseCopyWithImpl(this._self, this._then);

  final SeriesDetailResponse _self;
  final $Res Function(SeriesDetailResponse) _then;

/// Create a copy of SeriesDetailResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? slug = null,Object? cover = freezed,Object? nativeTitle = freezed,Object? altTitles = freezed,Object? releaseDate = freezed,Object? status = freezed,Object? author = freezed,Object? format = freezed,Object? rating = freezed,Object? synopsis = freezed,Object? genres = null,}) {
  return _then(SeriesDetailResponse(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String?,nativeTitle: freezed == nativeTitle ? _self.nativeTitle : nativeTitle // ignore: cast_nullable_to_non_nullable
as String?,altTitles: freezed == altTitles ? _self.altTitles : altTitles // ignore: cast_nullable_to_non_nullable
as List<String>?,releaseDate: freezed == releaseDate ? _self.releaseDate : releaseDate // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as num?,synopsis: freezed == synopsis ? _self.synopsis : synopsis // ignore: cast_nullable_to_non_nullable
as String?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<GenreResponse>,
  ));
}

}


/// Adds pattern-matching-related methods to [SeriesDetailResponse].
extension SeriesDetailResponsePatterns on SeriesDetailResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeriesDetailResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeriesDetailResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeriesDetailResponse value)  $default,){
final _that = this;
switch (_that) {
case _SeriesDetailResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeriesDetailResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SeriesDetailResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String slug,  String? cover,  String? nativeTitle,  List<String>? altTitles,  String? releaseDate,  String? status,  String? author,  String? format,  num? rating,  String? synopsis,  List<GenreResponse> genres)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeriesDetailResponse() when $default != null:
return $default(_that.title,_that.slug,_that.cover,_that.nativeTitle,_that.altTitles,_that.releaseDate,_that.status,_that.author,_that.format,_that.rating,_that.synopsis,_that.genres);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String slug,  String? cover,  String? nativeTitle,  List<String>? altTitles,  String? releaseDate,  String? status,  String? author,  String? format,  num? rating,  String? synopsis,  List<GenreResponse> genres)  $default,) {final _that = this;
switch (_that) {
case _SeriesDetailResponse():
return $default(_that.title,_that.slug,_that.cover,_that.nativeTitle,_that.altTitles,_that.releaseDate,_that.status,_that.author,_that.format,_that.rating,_that.synopsis,_that.genres);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String slug,  String? cover,  String? nativeTitle,  List<String>? altTitles,  String? releaseDate,  String? status,  String? author,  String? format,  num? rating,  String? synopsis,  List<GenreResponse> genres)?  $default,) {final _that = this;
switch (_that) {
case _SeriesDetailResponse() when $default != null:
return $default(_that.title,_that.slug,_that.cover,_that.nativeTitle,_that.altTitles,_that.releaseDate,_that.status,_that.author,_that.format,_that.rating,_that.synopsis,_that.genres);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeriesDetailResponse extends SeriesDetailResponse {
  const _SeriesDetailResponse({required this.title, required this.slug, this.cover, this.nativeTitle,  List<String>? altTitles, this.releaseDate, this.status, this.author, this.format, this.rating, this.synopsis,  List<GenreResponse> genres = const []}): _altTitles = altTitles,_genres = genres,super._();
  factory _SeriesDetailResponse.fromJson(Map<String, dynamic> json) => _$SeriesDetailResponseFromJson(json);

@override final  String title;
@override final  String slug;
@override final  String? cover;
@override final  String? nativeTitle;
/// Every alternative title, already split. Optional in the contract; older
/// extensions send only [nativeTitle].
 final  List<String>? _altTitles;
/// Every alternative title, already split. Optional in the contract; older
/// extensions send only [nativeTitle].
@override List<String>? get altTitles {
  final value = _altTitles;
  if (value == null) return null;
  if (_altTitles is EqualUnmodifiableListView) return _altTitles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? releaseDate;
@override final  String? status;
@override final  String? author;
@override final  String? format;
@override final  num? rating;
@override final  String? synopsis;
 final  List<GenreResponse> _genres;
@override@JsonKey() List<GenreResponse> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}


/// Create a copy of SeriesDetailResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeriesDetailResponseCopyWith<_SeriesDetailResponse> get copyWith => __$SeriesDetailResponseCopyWithImpl<_SeriesDetailResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeriesDetailResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeriesDetailResponse&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.nativeTitle, nativeTitle) || other.nativeTitle == nativeTitle)&&const DeepCollectionEquality().equals(other.altTitles, _altTitles)&&(identical(other.releaseDate, releaseDate) || other.releaseDate == releaseDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.author, author) || other.author == author)&&(identical(other.format, format) || other.format == format)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.synopsis, synopsis) || other.synopsis == synopsis)&&const DeepCollectionEquality().equals(other.genres, _genres));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,slug,cover,nativeTitle,const DeepCollectionEquality().hash(_altTitles),releaseDate,status,author,format,rating,synopsis,const DeepCollectionEquality().hash(_genres));
}

@override
String toString() {
    return 'SeriesDetailResponse(title: $title, slug: $slug, cover: $cover, nativeTitle: $nativeTitle, altTitles: $altTitles, releaseDate: $releaseDate, status: $status, author: $author, format: $format, rating: $rating, synopsis: $synopsis, genres: $genres)';
}


}

/// @nodoc
abstract mixin class _$SeriesDetailResponseCopyWith<$Res> implements $SeriesDetailResponseCopyWith<$Res> {
  factory _$SeriesDetailResponseCopyWith(_SeriesDetailResponse value, $Res Function(_SeriesDetailResponse) _then) = __$SeriesDetailResponseCopyWithImpl;
@override @useResult
$Res call({
 String title, String slug, String? cover, String? nativeTitle, List<String>? altTitles, String? releaseDate, String? status, String? author, String? format, num? rating, String? synopsis, List<GenreResponse> genres
});




}
/// @nodoc
class __$SeriesDetailResponseCopyWithImpl<$Res>
    implements _$SeriesDetailResponseCopyWith<$Res> {
  __$SeriesDetailResponseCopyWithImpl(this._self, this._then);

  final _SeriesDetailResponse _self;
  final $Res Function(_SeriesDetailResponse) _then;

/// Create a copy of SeriesDetailResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? slug = null,Object? cover = freezed,Object? nativeTitle = freezed,Object? altTitles = freezed,Object? releaseDate = freezed,Object? status = freezed,Object? author = freezed,Object? format = freezed,Object? rating = freezed,Object? synopsis = freezed,Object? genres = null,}) {
  return _then(_SeriesDetailResponse(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String?,nativeTitle: freezed == nativeTitle ? _self.nativeTitle : nativeTitle // ignore: cast_nullable_to_non_nullable
as String?,altTitles: freezed == altTitles ? _self._altTitles : altTitles // ignore: cast_nullable_to_non_nullable
as List<String>?,releaseDate: freezed == releaseDate ? _self.releaseDate : releaseDate // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as num?,synopsis: freezed == synopsis ? _self.synopsis : synopsis // ignore: cast_nullable_to_non_nullable
as String?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<GenreResponse>,
  ));
}


}


/// @nodoc
mixin _$GenreResponse {

@JsonKey(fromJson: _idToString) String get id; String get name;
/// Create a copy of GenreResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenreResponseCopyWith<GenreResponse> get copyWith => _$GenreResponseCopyWithImpl<GenreResponse>(this as GenreResponse, _$identity);

  /// Serializes this GenreResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GenreResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GenreResponse&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GenreResponse;
  return Object.hash(runtimeType,_this.id,_this.name);
}

@override
String toString() {
  final _this = this as GenreResponse;
  return 'GenreResponse(id: ${_this.id}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $GenreResponseCopyWith<$Res>  {
  factory $GenreResponseCopyWith(GenreResponse value, $Res Function(GenreResponse) _then) = _$GenreResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _idToString) String id, String name
});




}
/// @nodoc
class _$GenreResponseCopyWithImpl<$Res>
    implements $GenreResponseCopyWith<$Res> {
  _$GenreResponseCopyWithImpl(this._self, this._then);

  final GenreResponse _self;
  final $Res Function(GenreResponse) _then;

/// Create a copy of GenreResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(GenreResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GenreResponse].
extension GenreResponsePatterns on GenreResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GenreResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GenreResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GenreResponse value)  $default,){
final _that = this;
switch (_that) {
case _GenreResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GenreResponse value)?  $default,){
final _that = this;
switch (_that) {
case _GenreResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _idToString)  String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GenreResponse() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _idToString)  String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _GenreResponse():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: _idToString)  String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _GenreResponse() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GenreResponse extends GenreResponse {
  const _GenreResponse({@JsonKey(fromJson: _idToString) required this.id, required this.name}): super._();
  factory _GenreResponse.fromJson(Map<String, dynamic> json) => _$GenreResponseFromJson(json);

@override@JsonKey(fromJson: _idToString) final  String id;
@override final  String name;

/// Create a copy of GenreResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GenreResponseCopyWith<_GenreResponse> get copyWith => __$GenreResponseCopyWithImpl<_GenreResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GenreResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GenreResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name);
}

@override
String toString() {
    return 'GenreResponse(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$GenreResponseCopyWith<$Res> implements $GenreResponseCopyWith<$Res> {
  factory _$GenreResponseCopyWith(_GenreResponse value, $Res Function(_GenreResponse) _then) = __$GenreResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _idToString) String id, String name
});




}
/// @nodoc
class __$GenreResponseCopyWithImpl<$Res>
    implements _$GenreResponseCopyWith<$Res> {
  __$GenreResponseCopyWithImpl(this._self, this._then);

  final _GenreResponse _self;
  final $Res Function(_GenreResponse) _then;

/// Create a copy of GenreResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_GenreResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ChapterResponse {

 num get number; String? get createdAt;/// The site's name for a chapter whose [number] the source made up
/// (a Mihon "Extra" between numbered ones); null otherwise.
 String? get title;
/// Create a copy of ChapterResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChapterResponseCopyWith<ChapterResponse> get copyWith => _$ChapterResponseCopyWithImpl<ChapterResponse>(this as ChapterResponse, _$identity);

  /// Serializes this ChapterResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChapterResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChapterResponse&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.title, _this.title) || other.title == _this.title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChapterResponse;
  return Object.hash(runtimeType,_this.number,_this.createdAt,_this.title);
}

@override
String toString() {
  final _this = this as ChapterResponse;
  return 'ChapterResponse(number: ${_this.number}, createdAt: ${_this.createdAt}, title: ${_this.title})';
}


}

/// @nodoc
abstract mixin class $ChapterResponseCopyWith<$Res>  {
  factory $ChapterResponseCopyWith(ChapterResponse value, $Res Function(ChapterResponse) _then) = _$ChapterResponseCopyWithImpl;
@useResult
$Res call({
 num number, String? createdAt, String? title
});




}
/// @nodoc
class _$ChapterResponseCopyWithImpl<$Res>
    implements $ChapterResponseCopyWith<$Res> {
  _$ChapterResponseCopyWithImpl(this._self, this._then);

  final ChapterResponse _self;
  final $Res Function(ChapterResponse) _then;

/// Create a copy of ChapterResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? createdAt = freezed,Object? title = freezed,}) {
  return _then(ChapterResponse(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as num,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChapterResponse].
extension ChapterResponsePatterns on ChapterResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChapterResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChapterResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChapterResponse value)  $default,){
final _that = this;
switch (_that) {
case _ChapterResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChapterResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ChapterResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( num number,  String? createdAt,  String? title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChapterResponse() when $default != null:
return $default(_that.number,_that.createdAt,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( num number,  String? createdAt,  String? title)  $default,) {final _that = this;
switch (_that) {
case _ChapterResponse():
return $default(_that.number,_that.createdAt,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( num number,  String? createdAt,  String? title)?  $default,) {final _that = this;
switch (_that) {
case _ChapterResponse() when $default != null:
return $default(_that.number,_that.createdAt,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChapterResponse extends ChapterResponse {
  const _ChapterResponse({required this.number, this.createdAt, this.title}): super._();
  factory _ChapterResponse.fromJson(Map<String, dynamic> json) => _$ChapterResponseFromJson(json);

@override final  num number;
@override final  String? createdAt;
/// The site's name for a chapter whose [number] the source made up
/// (a Mihon "Extra" between numbered ones); null otherwise.
@override final  String? title;

/// Create a copy of ChapterResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChapterResponseCopyWith<_ChapterResponse> get copyWith => __$ChapterResponseCopyWithImpl<_ChapterResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChapterResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChapterResponse&&(identical(other.number, number) || other.number == number)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,number,createdAt,title);
}

@override
String toString() {
    return 'ChapterResponse(number: $number, createdAt: $createdAt, title: $title)';
}


}

/// @nodoc
abstract mixin class _$ChapterResponseCopyWith<$Res> implements $ChapterResponseCopyWith<$Res> {
  factory _$ChapterResponseCopyWith(_ChapterResponse value, $Res Function(_ChapterResponse) _then) = __$ChapterResponseCopyWithImpl;
@override @useResult
$Res call({
 num number, String? createdAt, String? title
});




}
/// @nodoc
class __$ChapterResponseCopyWithImpl<$Res>
    implements _$ChapterResponseCopyWith<$Res> {
  __$ChapterResponseCopyWithImpl(this._self, this._then);

  final _ChapterResponse _self;
  final $Res Function(_ChapterResponse) _then;

/// Create a copy of ChapterResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? createdAt = freezed,Object? title = freezed,}) {
  return _then(_ChapterResponse(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as num,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ChapterDetailResponse {

 num get number; String? get title; num? get prev; num? get next; List<String> get images;/// Sent with every image request (e.g. a Referer the host requires).
 Map<String, String> get headers;
/// Create a copy of ChapterDetailResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChapterDetailResponseCopyWith<ChapterDetailResponse> get copyWith => _$ChapterDetailResponseCopyWithImpl<ChapterDetailResponse>(this as ChapterDetailResponse, _$identity);

  /// Serializes this ChapterDetailResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChapterDetailResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChapterDetailResponse&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.prev, _this.prev) || other.prev == _this.prev)&&(identical(other.next, _this.next) || other.next == _this.next)&&const DeepCollectionEquality().equals(other.images, _this.images)&&const DeepCollectionEquality().equals(other.headers, _this.headers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChapterDetailResponse;
  return Object.hash(runtimeType,_this.number,_this.title,_this.prev,_this.next,const DeepCollectionEquality().hash(_this.images),const DeepCollectionEquality().hash(_this.headers));
}

@override
String toString() {
  final _this = this as ChapterDetailResponse;
  return 'ChapterDetailResponse(number: ${_this.number}, title: ${_this.title}, prev: ${_this.prev}, next: ${_this.next}, images: ${_this.images}, headers: ${_this.headers})';
}


}

/// @nodoc
abstract mixin class $ChapterDetailResponseCopyWith<$Res>  {
  factory $ChapterDetailResponseCopyWith(ChapterDetailResponse value, $Res Function(ChapterDetailResponse) _then) = _$ChapterDetailResponseCopyWithImpl;
@useResult
$Res call({
 num number, String? title, num? prev, num? next, List<String> images, Map<String, String> headers
});




}
/// @nodoc
class _$ChapterDetailResponseCopyWithImpl<$Res>
    implements $ChapterDetailResponseCopyWith<$Res> {
  _$ChapterDetailResponseCopyWithImpl(this._self, this._then);

  final ChapterDetailResponse _self;
  final $Res Function(ChapterDetailResponse) _then;

/// Create a copy of ChapterDetailResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? title = freezed,Object? prev = freezed,Object? next = freezed,Object? images = null,Object? headers = null,}) {
  return _then(ChapterDetailResponse(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as num,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,prev: freezed == prev ? _self.prev : prev // ignore: cast_nullable_to_non_nullable
as num?,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as num?,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<String>,headers: null == headers ? _self.headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChapterDetailResponse].
extension ChapterDetailResponsePatterns on ChapterDetailResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChapterDetailResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChapterDetailResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChapterDetailResponse value)  $default,){
final _that = this;
switch (_that) {
case _ChapterDetailResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChapterDetailResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ChapterDetailResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( num number,  String? title,  num? prev,  num? next,  List<String> images,  Map<String, String> headers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChapterDetailResponse() when $default != null:
return $default(_that.number,_that.title,_that.prev,_that.next,_that.images,_that.headers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( num number,  String? title,  num? prev,  num? next,  List<String> images,  Map<String, String> headers)  $default,) {final _that = this;
switch (_that) {
case _ChapterDetailResponse():
return $default(_that.number,_that.title,_that.prev,_that.next,_that.images,_that.headers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( num number,  String? title,  num? prev,  num? next,  List<String> images,  Map<String, String> headers)?  $default,) {final _that = this;
switch (_that) {
case _ChapterDetailResponse() when $default != null:
return $default(_that.number,_that.title,_that.prev,_that.next,_that.images,_that.headers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChapterDetailResponse implements ChapterDetailResponse {
  const _ChapterDetailResponse({required this.number, this.title, this.prev, this.next,  List<String> images = const [],  Map<String, String> headers = const {}}): _images = images,_headers = headers;
  factory _ChapterDetailResponse.fromJson(Map<String, dynamic> json) => _$ChapterDetailResponseFromJson(json);

@override final  num number;
@override final  String? title;
@override final  num? prev;
@override final  num? next;
 final  List<String> _images;
@override@JsonKey() List<String> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

/// Sent with every image request (e.g. a Referer the host requires).
 final  Map<String, String> _headers;
/// Sent with every image request (e.g. a Referer the host requires).
@override@JsonKey() Map<String, String> get headers {
  if (_headers is EqualUnmodifiableMapView) return _headers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_headers);
}


/// Create a copy of ChapterDetailResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChapterDetailResponseCopyWith<_ChapterDetailResponse> get copyWith => __$ChapterDetailResponseCopyWithImpl<_ChapterDetailResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChapterDetailResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChapterDetailResponse&&(identical(other.number, number) || other.number == number)&&(identical(other.title, title) || other.title == title)&&(identical(other.prev, prev) || other.prev == prev)&&(identical(other.next, next) || other.next == next)&&const DeepCollectionEquality().equals(other.images, _images)&&const DeepCollectionEquality().equals(other.headers, _headers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,number,title,prev,next,const DeepCollectionEquality().hash(_images),const DeepCollectionEquality().hash(_headers));
}

@override
String toString() {
    return 'ChapterDetailResponse(number: $number, title: $title, prev: $prev, next: $next, images: $images, headers: $headers)';
}


}

/// @nodoc
abstract mixin class _$ChapterDetailResponseCopyWith<$Res> implements $ChapterDetailResponseCopyWith<$Res> {
  factory _$ChapterDetailResponseCopyWith(_ChapterDetailResponse value, $Res Function(_ChapterDetailResponse) _then) = __$ChapterDetailResponseCopyWithImpl;
@override @useResult
$Res call({
 num number, String? title, num? prev, num? next, List<String> images, Map<String, String> headers
});




}
/// @nodoc
class __$ChapterDetailResponseCopyWithImpl<$Res>
    implements _$ChapterDetailResponseCopyWith<$Res> {
  __$ChapterDetailResponseCopyWithImpl(this._self, this._then);

  final _ChapterDetailResponse _self;
  final $Res Function(_ChapterDetailResponse) _then;

/// Create a copy of ChapterDetailResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? title = freezed,Object? prev = freezed,Object? next = freezed,Object? images = null,Object? headers = null,}) {
  return _then(_ChapterDetailResponse(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as num,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,prev: freezed == prev ? _self.prev : prev // ignore: cast_nullable_to_non_nullable
as num?,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as num?,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<String>,headers: null == headers ? _self._headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
