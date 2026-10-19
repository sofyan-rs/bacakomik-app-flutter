// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_details.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ComicDetails {

 String get title; String get coverImg; String get alternativeTitle; String get released; String get status; String get totalChapter; String get author; String get type; String get rating; String get synopsis; List<Genre> get genres; List<Chapter> get chapters;
/// Create a copy of ComicDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicDetailsCopyWith<ComicDetails> get copyWith => _$ComicDetailsCopyWithImpl<ComicDetails>(this as ComicDetails, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ComicDetails;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicDetails&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.coverImg, _this.coverImg) || other.coverImg == _this.coverImg)&&(identical(other.alternativeTitle, _this.alternativeTitle) || other.alternativeTitle == _this.alternativeTitle)&&(identical(other.released, _this.released) || other.released == _this.released)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.totalChapter, _this.totalChapter) || other.totalChapter == _this.totalChapter)&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.synopsis, _this.synopsis) || other.synopsis == _this.synopsis)&&const DeepCollectionEquality().equals(other.genres, _this.genres)&&const DeepCollectionEquality().equals(other.chapters, _this.chapters));
}


@override
int get hashCode {
  final _this = this as ComicDetails;
  return Object.hash(runtimeType,_this.title,_this.coverImg,_this.alternativeTitle,_this.released,_this.status,_this.totalChapter,_this.author,_this.type,_this.rating,_this.synopsis,const DeepCollectionEquality().hash(_this.genres),const DeepCollectionEquality().hash(_this.chapters));
}

@override
String toString() {
  final _this = this as ComicDetails;
  return 'ComicDetails(title: ${_this.title}, coverImg: ${_this.coverImg}, alternativeTitle: ${_this.alternativeTitle}, released: ${_this.released}, status: ${_this.status}, totalChapter: ${_this.totalChapter}, author: ${_this.author}, type: ${_this.type}, rating: ${_this.rating}, synopsis: ${_this.synopsis}, genres: ${_this.genres}, chapters: ${_this.chapters})';
}


}

/// @nodoc
abstract mixin class $ComicDetailsCopyWith<$Res>  {
  factory $ComicDetailsCopyWith(ComicDetails value, $Res Function(ComicDetails) _then) = _$ComicDetailsCopyWithImpl;
@useResult
$Res call({
 String title, String coverImg, String alternativeTitle, String released, String status, String totalChapter, String author, String type, String rating, String synopsis, List<Genre> genres, List<Chapter> chapters
});




}
/// @nodoc
class _$ComicDetailsCopyWithImpl<$Res>
    implements $ComicDetailsCopyWith<$Res> {
  _$ComicDetailsCopyWithImpl(this._self, this._then);

  final ComicDetails _self;
  final $Res Function(ComicDetails) _then;

/// Create a copy of ComicDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? coverImg = null,Object? alternativeTitle = null,Object? released = null,Object? status = null,Object? totalChapter = null,Object? author = null,Object? type = null,Object? rating = null,Object? synopsis = null,Object? genres = null,Object? chapters = null,}) {
  return _then(ComicDetails(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,coverImg: null == coverImg ? _self.coverImg : coverImg // ignore: cast_nullable_to_non_nullable
as String,alternativeTitle: null == alternativeTitle ? _self.alternativeTitle : alternativeTitle // ignore: cast_nullable_to_non_nullable
as String,released: null == released ? _self.released : released // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,totalChapter: null == totalChapter ? _self.totalChapter : totalChapter // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as String,synopsis: null == synopsis ? _self.synopsis : synopsis // ignore: cast_nullable_to_non_nullable
as String,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<Genre>,chapters: null == chapters ? _self.chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<Chapter>,
  ));
}

}


/// Adds pattern-matching-related methods to [ComicDetails].
extension ComicDetailsPatterns on ComicDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicDetails value)  $default,){
final _that = this;
switch (_that) {
case _ComicDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicDetails value)?  $default,){
final _that = this;
switch (_that) {
case _ComicDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String coverImg,  String alternativeTitle,  String released,  String status,  String totalChapter,  String author,  String type,  String rating,  String synopsis,  List<Genre> genres,  List<Chapter> chapters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicDetails() when $default != null:
return $default(_that.title,_that.coverImg,_that.alternativeTitle,_that.released,_that.status,_that.totalChapter,_that.author,_that.type,_that.rating,_that.synopsis,_that.genres,_that.chapters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String coverImg,  String alternativeTitle,  String released,  String status,  String totalChapter,  String author,  String type,  String rating,  String synopsis,  List<Genre> genres,  List<Chapter> chapters)  $default,) {final _that = this;
switch (_that) {
case _ComicDetails():
return $default(_that.title,_that.coverImg,_that.alternativeTitle,_that.released,_that.status,_that.totalChapter,_that.author,_that.type,_that.rating,_that.synopsis,_that.genres,_that.chapters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String coverImg,  String alternativeTitle,  String released,  String status,  String totalChapter,  String author,  String type,  String rating,  String synopsis,  List<Genre> genres,  List<Chapter> chapters)?  $default,) {final _that = this;
switch (_that) {
case _ComicDetails() when $default != null:
return $default(_that.title,_that.coverImg,_that.alternativeTitle,_that.released,_that.status,_that.totalChapter,_that.author,_that.type,_that.rating,_that.synopsis,_that.genres,_that.chapters);case _:
  return null;

}
}

}

/// @nodoc


class _ComicDetails implements ComicDetails {
  const _ComicDetails({required this.title, required this.coverImg, required this.alternativeTitle, required this.released, required this.status, required this.totalChapter, required this.author, required this.type, required this.rating, required this.synopsis, required  List<Genre> genres, required  List<Chapter> chapters}): _genres = genres,_chapters = chapters;
  

@override final  String title;
@override final  String coverImg;
@override final  String alternativeTitle;
@override final  String released;
@override final  String status;
@override final  String totalChapter;
@override final  String author;
@override final  String type;
@override final  String rating;
@override final  String synopsis;
 final  List<Genre> _genres;
@override List<Genre> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

 final  List<Chapter> _chapters;
@override List<Chapter> get chapters {
  if (_chapters is EqualUnmodifiableListView) return _chapters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chapters);
}


/// Create a copy of ComicDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicDetailsCopyWith<_ComicDetails> get copyWith => __$ComicDetailsCopyWithImpl<_ComicDetails>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicDetails&&(identical(other.title, title) || other.title == title)&&(identical(other.coverImg, coverImg) || other.coverImg == coverImg)&&(identical(other.alternativeTitle, alternativeTitle) || other.alternativeTitle == alternativeTitle)&&(identical(other.released, released) || other.released == released)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalChapter, totalChapter) || other.totalChapter == totalChapter)&&(identical(other.author, author) || other.author == author)&&(identical(other.type, type) || other.type == type)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.synopsis, synopsis) || other.synopsis == synopsis)&&const DeepCollectionEquality().equals(other.genres, _genres)&&const DeepCollectionEquality().equals(other.chapters, _chapters));
}


@override
int get hashCode {
    return Object.hash(runtimeType,title,coverImg,alternativeTitle,released,status,totalChapter,author,type,rating,synopsis,const DeepCollectionEquality().hash(_genres),const DeepCollectionEquality().hash(_chapters));
}

@override
String toString() {
    return 'ComicDetails(title: $title, coverImg: $coverImg, alternativeTitle: $alternativeTitle, released: $released, status: $status, totalChapter: $totalChapter, author: $author, type: $type, rating: $rating, synopsis: $synopsis, genres: $genres, chapters: $chapters)';
}


}

/// @nodoc
abstract mixin class _$ComicDetailsCopyWith<$Res> implements $ComicDetailsCopyWith<$Res> {
  factory _$ComicDetailsCopyWith(_ComicDetails value, $Res Function(_ComicDetails) _then) = __$ComicDetailsCopyWithImpl;
@override @useResult
$Res call({
 String title, String coverImg, String alternativeTitle, String released, String status, String totalChapter, String author, String type, String rating, String synopsis, List<Genre> genres, List<Chapter> chapters
});




}
/// @nodoc
class __$ComicDetailsCopyWithImpl<$Res>
    implements _$ComicDetailsCopyWith<$Res> {
  __$ComicDetailsCopyWithImpl(this._self, this._then);

  final _ComicDetails _self;
  final $Res Function(_ComicDetails) _then;

/// Create a copy of ComicDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? coverImg = null,Object? alternativeTitle = null,Object? released = null,Object? status = null,Object? totalChapter = null,Object? author = null,Object? type = null,Object? rating = null,Object? synopsis = null,Object? genres = null,Object? chapters = null,}) {
  return _then(_ComicDetails(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,coverImg: null == coverImg ? _self.coverImg : coverImg // ignore: cast_nullable_to_non_nullable
as String,alternativeTitle: null == alternativeTitle ? _self.alternativeTitle : alternativeTitle // ignore: cast_nullable_to_non_nullable
as String,released: null == released ? _self.released : released // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,totalChapter: null == totalChapter ? _self.totalChapter : totalChapter // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as String,synopsis: null == synopsis ? _self.synopsis : synopsis // ignore: cast_nullable_to_non_nullable
as String,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<Genre>,chapters: null == chapters ? _self._chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<Chapter>,
  ));
}


}

/// @nodoc
mixin _$Genre {

 String get name; String get slug;
/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenreCopyWith<Genre> get copyWith => _$GenreCopyWithImpl<Genre>(this as Genre, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Genre;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Genre&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.slug, _this.slug) || other.slug == _this.slug));
}


@override
int get hashCode {
  final _this = this as Genre;
  return Object.hash(runtimeType,_this.name,_this.slug);
}

@override
String toString() {
  final _this = this as Genre;
  return 'Genre(name: ${_this.name}, slug: ${_this.slug})';
}


}

/// @nodoc
abstract mixin class $GenreCopyWith<$Res>  {
  factory $GenreCopyWith(Genre value, $Res Function(Genre) _then) = _$GenreCopyWithImpl;
@useResult
$Res call({
 String name, String slug
});




}
/// @nodoc
class _$GenreCopyWithImpl<$Res>
    implements $GenreCopyWith<$Res> {
  _$GenreCopyWithImpl(this._self, this._then);

  final Genre _self;
  final $Res Function(Genre) _then;

/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? slug = null,}) {
  return _then(Genre(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Genre].
extension GenrePatterns on Genre {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Genre value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Genre() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Genre value)  $default,){
final _that = this;
switch (_that) {
case _Genre():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Genre value)?  $default,){
final _that = this;
switch (_that) {
case _Genre() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String slug)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Genre() when $default != null:
return $default(_that.name,_that.slug);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String slug)  $default,) {final _that = this;
switch (_that) {
case _Genre():
return $default(_that.name,_that.slug);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String slug)?  $default,) {final _that = this;
switch (_that) {
case _Genre() when $default != null:
return $default(_that.name,_that.slug);case _:
  return null;

}
}

}

/// @nodoc


class _Genre implements Genre {
  const _Genre({required this.name, required this.slug});
  

@override final  String name;
@override final  String slug;

/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GenreCopyWith<_Genre> get copyWith => __$GenreCopyWithImpl<_Genre>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Genre&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,slug);
}

@override
String toString() {
    return 'Genre(name: $name, slug: $slug)';
}


}

/// @nodoc
abstract mixin class _$GenreCopyWith<$Res> implements $GenreCopyWith<$Res> {
  factory _$GenreCopyWith(_Genre value, $Res Function(_Genre) _then) = __$GenreCopyWithImpl;
@override @useResult
$Res call({
 String name, String slug
});




}
/// @nodoc
class __$GenreCopyWithImpl<$Res>
    implements _$GenreCopyWith<$Res> {
  __$GenreCopyWithImpl(this._self, this._then);

  final _Genre _self;
  final $Res Function(_Genre) _then;

/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? slug = null,}) {
  return _then(_Genre(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$Chapter {

 String get number;/// Chapter slug in the form `seriesSlug/number`.
 String get slug; String get date;
/// Create a copy of Chapter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChapterCopyWith<Chapter> get copyWith => _$ChapterCopyWithImpl<Chapter>(this as Chapter, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Chapter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Chapter&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.slug, _this.slug) || other.slug == _this.slug)&&(identical(other.date, _this.date) || other.date == _this.date));
}


@override
int get hashCode {
  final _this = this as Chapter;
  return Object.hash(runtimeType,_this.number,_this.slug,_this.date);
}

@override
String toString() {
  final _this = this as Chapter;
  return 'Chapter(number: ${_this.number}, slug: ${_this.slug}, date: ${_this.date})';
}


}

/// @nodoc
abstract mixin class $ChapterCopyWith<$Res>  {
  factory $ChapterCopyWith(Chapter value, $Res Function(Chapter) _then) = _$ChapterCopyWithImpl;
@useResult
$Res call({
 String number, String slug, String date
});




}
/// @nodoc
class _$ChapterCopyWithImpl<$Res>
    implements $ChapterCopyWith<$Res> {
  _$ChapterCopyWithImpl(this._self, this._then);

  final Chapter _self;
  final $Res Function(Chapter) _then;

/// Create a copy of Chapter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? slug = null,Object? date = null,}) {
  return _then(Chapter(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Chapter].
extension ChapterPatterns on Chapter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Chapter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Chapter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Chapter value)  $default,){
final _that = this;
switch (_that) {
case _Chapter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Chapter value)?  $default,){
final _that = this;
switch (_that) {
case _Chapter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String number,  String slug,  String date)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Chapter() when $default != null:
return $default(_that.number,_that.slug,_that.date);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String number,  String slug,  String date)  $default,) {final _that = this;
switch (_that) {
case _Chapter():
return $default(_that.number,_that.slug,_that.date);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String number,  String slug,  String date)?  $default,) {final _that = this;
switch (_that) {
case _Chapter() when $default != null:
return $default(_that.number,_that.slug,_that.date);case _:
  return null;

}
}

}

/// @nodoc


class _Chapter implements Chapter {
  const _Chapter({required this.number, required this.slug, required this.date});
  

@override final  String number;
/// Chapter slug in the form `seriesSlug/number`.
@override final  String slug;
@override final  String date;

/// Create a copy of Chapter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChapterCopyWith<_Chapter> get copyWith => __$ChapterCopyWithImpl<_Chapter>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Chapter&&(identical(other.number, number) || other.number == number)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.date, date) || other.date == date));
}


@override
int get hashCode {
    return Object.hash(runtimeType,number,slug,date);
}

@override
String toString() {
    return 'Chapter(number: $number, slug: $slug, date: $date)';
}


}

/// @nodoc
abstract mixin class _$ChapterCopyWith<$Res> implements $ChapterCopyWith<$Res> {
  factory _$ChapterCopyWith(_Chapter value, $Res Function(_Chapter) _then) = __$ChapterCopyWithImpl;
@override @useResult
$Res call({
 String number, String slug, String date
});




}
/// @nodoc
class __$ChapterCopyWithImpl<$Res>
    implements _$ChapterCopyWith<$Res> {
  __$ChapterCopyWithImpl(this._self, this._then);

  final _Chapter _self;
  final $Res Function(_Chapter) _then;

/// Create a copy of Chapter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? slug = null,Object? date = null,}) {
  return _then(_Chapter(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
