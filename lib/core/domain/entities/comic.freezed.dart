// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Comic {

 String get title; String get coverImg; String get slug; String get type; bool get completed; String get rating; String get latestChapter;
/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicCopyWith<Comic> get copyWith => _$ComicCopyWithImpl<Comic>(this as Comic, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Comic;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Comic&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.coverImg, _this.coverImg) || other.coverImg == _this.coverImg)&&(identical(other.slug, _this.slug) || other.slug == _this.slug)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.completed, _this.completed) || other.completed == _this.completed)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.latestChapter, _this.latestChapter) || other.latestChapter == _this.latestChapter));
}


@override
int get hashCode {
  final _this = this as Comic;
  return Object.hash(runtimeType,_this.title,_this.coverImg,_this.slug,_this.type,_this.completed,_this.rating,_this.latestChapter);
}

@override
String toString() {
  final _this = this as Comic;
  return 'Comic(title: ${_this.title}, coverImg: ${_this.coverImg}, slug: ${_this.slug}, type: ${_this.type}, completed: ${_this.completed}, rating: ${_this.rating}, latestChapter: ${_this.latestChapter})';
}


}

/// @nodoc
abstract mixin class $ComicCopyWith<$Res>  {
  factory $ComicCopyWith(Comic value, $Res Function(Comic) _then) = _$ComicCopyWithImpl;
@useResult
$Res call({
 String title, String coverImg, String slug, String type, bool completed, String rating, String latestChapter
});




}
/// @nodoc
class _$ComicCopyWithImpl<$Res>
    implements $ComicCopyWith<$Res> {
  _$ComicCopyWithImpl(this._self, this._then);

  final Comic _self;
  final $Res Function(Comic) _then;

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? coverImg = null,Object? slug = null,Object? type = null,Object? completed = null,Object? rating = null,Object? latestChapter = null,}) {
  return _then(Comic(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,coverImg: null == coverImg ? _self.coverImg : coverImg // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as String,latestChapter: null == latestChapter ? _self.latestChapter : latestChapter // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Comic].
extension ComicPatterns on Comic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Comic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Comic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Comic value)  $default,){
final _that = this;
switch (_that) {
case _Comic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Comic value)?  $default,){
final _that = this;
switch (_that) {
case _Comic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String coverImg,  String slug,  String type,  bool completed,  String rating,  String latestChapter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Comic() when $default != null:
return $default(_that.title,_that.coverImg,_that.slug,_that.type,_that.completed,_that.rating,_that.latestChapter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String coverImg,  String slug,  String type,  bool completed,  String rating,  String latestChapter)  $default,) {final _that = this;
switch (_that) {
case _Comic():
return $default(_that.title,_that.coverImg,_that.slug,_that.type,_that.completed,_that.rating,_that.latestChapter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String coverImg,  String slug,  String type,  bool completed,  String rating,  String latestChapter)?  $default,) {final _that = this;
switch (_that) {
case _Comic() when $default != null:
return $default(_that.title,_that.coverImg,_that.slug,_that.type,_that.completed,_that.rating,_that.latestChapter);case _:
  return null;

}
}

}

/// @nodoc


class _Comic implements Comic {
  const _Comic({required this.title, required this.coverImg, required this.slug, required this.type, required this.completed, required this.rating, required this.latestChapter});
  

@override final  String title;
@override final  String coverImg;
@override final  String slug;
@override final  String type;
@override final  bool completed;
@override final  String rating;
@override final  String latestChapter;

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicCopyWith<_Comic> get copyWith => __$ComicCopyWithImpl<_Comic>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Comic&&(identical(other.title, title) || other.title == title)&&(identical(other.coverImg, coverImg) || other.coverImg == coverImg)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.type, type) || other.type == type)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.latestChapter, latestChapter) || other.latestChapter == latestChapter));
}


@override
int get hashCode {
    return Object.hash(runtimeType,title,coverImg,slug,type,completed,rating,latestChapter);
}

@override
String toString() {
    return 'Comic(title: $title, coverImg: $coverImg, slug: $slug, type: $type, completed: $completed, rating: $rating, latestChapter: $latestChapter)';
}


}

/// @nodoc
abstract mixin class _$ComicCopyWith<$Res> implements $ComicCopyWith<$Res> {
  factory _$ComicCopyWith(_Comic value, $Res Function(_Comic) _then) = __$ComicCopyWithImpl;
@override @useResult
$Res call({
 String title, String coverImg, String slug, String type, bool completed, String rating, String latestChapter
});




}
/// @nodoc
class __$ComicCopyWithImpl<$Res>
    implements _$ComicCopyWith<$Res> {
  __$ComicCopyWithImpl(this._self, this._then);

  final _Comic _self;
  final $Res Function(_Comic) _then;

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? coverImg = null,Object? slug = null,Object? type = null,Object? completed = null,Object? rating = null,Object? latestChapter = null,}) {
  return _then(_Comic(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,coverImg: null == coverImg ? _self.coverImg : coverImg // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as String,latestChapter: null == latestChapter ? _self.latestChapter : latestChapter // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
