// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_library.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DownloadedComic {

 String get slug; ComicDetails get comicDetails;/// Absolute path of the saved cover; null until it has been saved.
 String? get coverPath;
/// Create a copy of DownloadedComic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadedComicCopyWith<DownloadedComic> get copyWith => _$DownloadedComicCopyWithImpl<DownloadedComic>(this as DownloadedComic, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DownloadedComic;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadedComic&&(identical(other.slug, _this.slug) || other.slug == _this.slug)&&(identical(other.comicDetails, _this.comicDetails) || other.comicDetails == _this.comicDetails)&&(identical(other.coverPath, _this.coverPath) || other.coverPath == _this.coverPath));
}


@override
int get hashCode {
  final _this = this as DownloadedComic;
  return Object.hash(runtimeType,_this.slug,_this.comicDetails,_this.coverPath);
}

@override
String toString() {
  final _this = this as DownloadedComic;
  return 'DownloadedComic(slug: ${_this.slug}, comicDetails: ${_this.comicDetails}, coverPath: ${_this.coverPath})';
}


}

/// @nodoc
abstract mixin class $DownloadedComicCopyWith<$Res>  {
  factory $DownloadedComicCopyWith(DownloadedComic value, $Res Function(DownloadedComic) _then) = _$DownloadedComicCopyWithImpl;
@useResult
$Res call({
 String slug, ComicDetails comicDetails, String? coverPath
});


$ComicDetailsCopyWith<$Res> get comicDetails;

}
/// @nodoc
class _$DownloadedComicCopyWithImpl<$Res>
    implements $DownloadedComicCopyWith<$Res> {
  _$DownloadedComicCopyWithImpl(this._self, this._then);

  final DownloadedComic _self;
  final $Res Function(DownloadedComic) _then;

/// Create a copy of DownloadedComic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? comicDetails = null,Object? coverPath = freezed,}) {
  return _then(DownloadedComic(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,comicDetails: null == comicDetails ? _self.comicDetails : comicDetails // ignore: cast_nullable_to_non_nullable
as ComicDetails,coverPath: freezed == coverPath ? _self.coverPath : coverPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of DownloadedComic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicDetailsCopyWith<$Res> get comicDetails {
  
  return $ComicDetailsCopyWith<$Res>(_self.comicDetails, (value) {
    return _then(_self.copyWith(comicDetails: value));
  });
}
}


/// Adds pattern-matching-related methods to [DownloadedComic].
extension DownloadedComicPatterns on DownloadedComic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadedComic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadedComic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadedComic value)  $default,){
final _that = this;
switch (_that) {
case _DownloadedComic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadedComic value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadedComic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  ComicDetails comicDetails,  String? coverPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadedComic() when $default != null:
return $default(_that.slug,_that.comicDetails,_that.coverPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  ComicDetails comicDetails,  String? coverPath)  $default,) {final _that = this;
switch (_that) {
case _DownloadedComic():
return $default(_that.slug,_that.comicDetails,_that.coverPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  ComicDetails comicDetails,  String? coverPath)?  $default,) {final _that = this;
switch (_that) {
case _DownloadedComic() when $default != null:
return $default(_that.slug,_that.comicDetails,_that.coverPath);case _:
  return null;

}
}

}

/// @nodoc


class _DownloadedComic implements DownloadedComic {
  const _DownloadedComic({required this.slug, required this.comicDetails, this.coverPath});
  

@override final  String slug;
@override final  ComicDetails comicDetails;
/// Absolute path of the saved cover; null until it has been saved.
@override final  String? coverPath;

/// Create a copy of DownloadedComic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadedComicCopyWith<_DownloadedComic> get copyWith => __$DownloadedComicCopyWithImpl<_DownloadedComic>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadedComic&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.comicDetails, comicDetails) || other.comicDetails == comicDetails)&&(identical(other.coverPath, coverPath) || other.coverPath == coverPath));
}


@override
int get hashCode {
    return Object.hash(runtimeType,slug,comicDetails,coverPath);
}

@override
String toString() {
    return 'DownloadedComic(slug: $slug, comicDetails: $comicDetails, coverPath: $coverPath)';
}


}

/// @nodoc
abstract mixin class _$DownloadedComicCopyWith<$Res> implements $DownloadedComicCopyWith<$Res> {
  factory _$DownloadedComicCopyWith(_DownloadedComic value, $Res Function(_DownloadedComic) _then) = __$DownloadedComicCopyWithImpl;
@override @useResult
$Res call({
 String slug, ComicDetails comicDetails, String? coverPath
});


@override $ComicDetailsCopyWith<$Res> get comicDetails;

}
/// @nodoc
class __$DownloadedComicCopyWithImpl<$Res>
    implements _$DownloadedComicCopyWith<$Res> {
  __$DownloadedComicCopyWithImpl(this._self, this._then);

  final _DownloadedComic _self;
  final $Res Function(_DownloadedComic) _then;

/// Create a copy of DownloadedComic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? comicDetails = null,Object? coverPath = freezed,}) {
  return _then(_DownloadedComic(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,comicDetails: null == comicDetails ? _self.comicDetails : comicDetails // ignore: cast_nullable_to_non_nullable
as ComicDetails,coverPath: freezed == coverPath ? _self.coverPath : coverPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of DownloadedComic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicDetailsCopyWith<$Res> get comicDetails {
  
  return $ComicDetailsCopyWith<$Res>(_self.comicDetails, (value) {
    return _then(_self.copyWith(comicDetails: value));
  });
}
}

/// @nodoc
mixin _$DownloadLibrary {

 Map<String, DownloadedChapter> get chapters; Map<String, DownloadedComic> get comics;
/// Create a copy of DownloadLibrary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadLibraryCopyWith<DownloadLibrary> get copyWith => _$DownloadLibraryCopyWithImpl<DownloadLibrary>(this as DownloadLibrary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DownloadLibrary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadLibrary&&const DeepCollectionEquality().equals(other.chapters, _this.chapters)&&const DeepCollectionEquality().equals(other.comics, _this.comics));
}


@override
int get hashCode {
  final _this = this as DownloadLibrary;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.chapters),const DeepCollectionEquality().hash(_this.comics));
}

@override
String toString() {
  final _this = this as DownloadLibrary;
  return 'DownloadLibrary(chapters: ${_this.chapters}, comics: ${_this.comics})';
}


}

/// @nodoc
abstract mixin class $DownloadLibraryCopyWith<$Res>  {
  factory $DownloadLibraryCopyWith(DownloadLibrary value, $Res Function(DownloadLibrary) _then) = _$DownloadLibraryCopyWithImpl;
@useResult
$Res call({
 Map<String, DownloadedChapter> chapters, Map<String, DownloadedComic> comics
});




}
/// @nodoc
class _$DownloadLibraryCopyWithImpl<$Res>
    implements $DownloadLibraryCopyWith<$Res> {
  _$DownloadLibraryCopyWithImpl(this._self, this._then);

  final DownloadLibrary _self;
  final $Res Function(DownloadLibrary) _then;

/// Create a copy of DownloadLibrary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? chapters = null,Object? comics = null,}) {
  return _then(DownloadLibrary(
chapters: null == chapters ? _self.chapters : chapters // ignore: cast_nullable_to_non_nullable
as Map<String, DownloadedChapter>,comics: null == comics ? _self.comics : comics // ignore: cast_nullable_to_non_nullable
as Map<String, DownloadedComic>,
  ));
}

}


/// Adds pattern-matching-related methods to [DownloadLibrary].
extension DownloadLibraryPatterns on DownloadLibrary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadLibrary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadLibrary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadLibrary value)  $default,){
final _that = this;
switch (_that) {
case _DownloadLibrary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadLibrary value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadLibrary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, DownloadedChapter> chapters,  Map<String, DownloadedComic> comics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadLibrary() when $default != null:
return $default(_that.chapters,_that.comics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, DownloadedChapter> chapters,  Map<String, DownloadedComic> comics)  $default,) {final _that = this;
switch (_that) {
case _DownloadLibrary():
return $default(_that.chapters,_that.comics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, DownloadedChapter> chapters,  Map<String, DownloadedComic> comics)?  $default,) {final _that = this;
switch (_that) {
case _DownloadLibrary() when $default != null:
return $default(_that.chapters,_that.comics);case _:
  return null;

}
}

}

/// @nodoc


class _DownloadLibrary extends DownloadLibrary {
  const _DownloadLibrary({ Map<String, DownloadedChapter> chapters = const {},  Map<String, DownloadedComic> comics = const {}}): _chapters = chapters,_comics = comics,super._();
  

 final  Map<String, DownloadedChapter> _chapters;
@override@JsonKey() Map<String, DownloadedChapter> get chapters {
  if (_chapters is EqualUnmodifiableMapView) return _chapters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_chapters);
}

 final  Map<String, DownloadedComic> _comics;
@override@JsonKey() Map<String, DownloadedComic> get comics {
  if (_comics is EqualUnmodifiableMapView) return _comics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_comics);
}


/// Create a copy of DownloadLibrary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadLibraryCopyWith<_DownloadLibrary> get copyWith => __$DownloadLibraryCopyWithImpl<_DownloadLibrary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadLibrary&&const DeepCollectionEquality().equals(other.chapters, _chapters)&&const DeepCollectionEquality().equals(other.comics, _comics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_chapters),const DeepCollectionEquality().hash(_comics));
}

@override
String toString() {
    return 'DownloadLibrary(chapters: $chapters, comics: $comics)';
}


}

/// @nodoc
abstract mixin class _$DownloadLibraryCopyWith<$Res> implements $DownloadLibraryCopyWith<$Res> {
  factory _$DownloadLibraryCopyWith(_DownloadLibrary value, $Res Function(_DownloadLibrary) _then) = __$DownloadLibraryCopyWithImpl;
@override @useResult
$Res call({
 Map<String, DownloadedChapter> chapters, Map<String, DownloadedComic> comics
});




}
/// @nodoc
class __$DownloadLibraryCopyWithImpl<$Res>
    implements _$DownloadLibraryCopyWith<$Res> {
  __$DownloadLibraryCopyWithImpl(this._self, this._then);

  final _DownloadLibrary _self;
  final $Res Function(_DownloadLibrary) _then;

/// Create a copy of DownloadLibrary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? chapters = null,Object? comics = null,}) {
  return _then(_DownloadLibrary(
chapters: null == chapters ? _self._chapters : chapters // ignore: cast_nullable_to_non_nullable
as Map<String, DownloadedChapter>,comics: null == comics ? _self._comics : comics // ignore: cast_nullable_to_non_nullable
as Map<String, DownloadedComic>,
  ));
}


}

// dart format on
