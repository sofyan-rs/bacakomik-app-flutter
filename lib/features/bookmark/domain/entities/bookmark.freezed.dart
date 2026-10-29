// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookmark.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Bookmark {

/// Series slug.
 String get slug; ComicDetails get comicDetails;/// Last time the bookmark was added or found new chapters.
 DateTime get updatedDate;/// When the comic was bookmarked. Null for bookmarks saved before this
/// was stored; sorting uses [updatedDate] for them.
 DateTime? get addedDate;/// Series keys merged into this entry, [slug] among them, in the order
/// chapters are taken from: each chapter number comes from the first
/// that has it, and the details from the first. Empty when the entry
/// has one source. See [sourceKeys].
 List<String> get mergedKeys;/// A merged entry lists the chapters of every source, also the numbers
/// several have, instead of one per number.
 bool get keepDuplicates;
/// Create a copy of Bookmark
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookmarkCopyWith<Bookmark> get copyWith => _$BookmarkCopyWithImpl<Bookmark>(this as Bookmark, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Bookmark;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Bookmark&&(identical(other.slug, _this.slug) || other.slug == _this.slug)&&(identical(other.comicDetails, _this.comicDetails) || other.comicDetails == _this.comicDetails)&&(identical(other.updatedDate, _this.updatedDate) || other.updatedDate == _this.updatedDate)&&(identical(other.addedDate, _this.addedDate) || other.addedDate == _this.addedDate)&&const DeepCollectionEquality().equals(other.mergedKeys, _this.mergedKeys)&&(identical(other.keepDuplicates, _this.keepDuplicates) || other.keepDuplicates == _this.keepDuplicates));
}


@override
int get hashCode {
  final _this = this as Bookmark;
  return Object.hash(runtimeType,_this.slug,_this.comicDetails,_this.updatedDate,_this.addedDate,const DeepCollectionEquality().hash(_this.mergedKeys),_this.keepDuplicates);
}

@override
String toString() {
  final _this = this as Bookmark;
  return 'Bookmark(slug: ${_this.slug}, comicDetails: ${_this.comicDetails}, updatedDate: ${_this.updatedDate}, addedDate: ${_this.addedDate}, mergedKeys: ${_this.mergedKeys}, keepDuplicates: ${_this.keepDuplicates})';
}


}

/// @nodoc
abstract mixin class $BookmarkCopyWith<$Res>  {
  factory $BookmarkCopyWith(Bookmark value, $Res Function(Bookmark) _then) = _$BookmarkCopyWithImpl;
@useResult
$Res call({
 String slug, ComicDetails comicDetails, DateTime updatedDate, DateTime? addedDate, List<String> mergedKeys, bool keepDuplicates
});


$ComicDetailsCopyWith<$Res> get comicDetails;

}
/// @nodoc
class _$BookmarkCopyWithImpl<$Res>
    implements $BookmarkCopyWith<$Res> {
  _$BookmarkCopyWithImpl(this._self, this._then);

  final Bookmark _self;
  final $Res Function(Bookmark) _then;

/// Create a copy of Bookmark
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? comicDetails = null,Object? updatedDate = null,Object? addedDate = freezed,Object? mergedKeys = null,Object? keepDuplicates = null,}) {
  return _then(Bookmark(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,comicDetails: null == comicDetails ? _self.comicDetails : comicDetails // ignore: cast_nullable_to_non_nullable
as ComicDetails,updatedDate: null == updatedDate ? _self.updatedDate : updatedDate // ignore: cast_nullable_to_non_nullable
as DateTime,addedDate: freezed == addedDate ? _self.addedDate : addedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,mergedKeys: null == mergedKeys ? _self.mergedKeys : mergedKeys // ignore: cast_nullable_to_non_nullable
as List<String>,keepDuplicates: null == keepDuplicates ? _self.keepDuplicates : keepDuplicates // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Bookmark
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicDetailsCopyWith<$Res> get comicDetails {
  
  return $ComicDetailsCopyWith<$Res>(_self.comicDetails, (value) {
    return _then(_self.copyWith(comicDetails: value));
  });
}
}


/// Adds pattern-matching-related methods to [Bookmark].
extension BookmarkPatterns on Bookmark {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Bookmark value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Bookmark() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Bookmark value)  $default,){
final _that = this;
switch (_that) {
case _Bookmark():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Bookmark value)?  $default,){
final _that = this;
switch (_that) {
case _Bookmark() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  ComicDetails comicDetails,  DateTime updatedDate,  DateTime? addedDate,  List<String> mergedKeys,  bool keepDuplicates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Bookmark() when $default != null:
return $default(_that.slug,_that.comicDetails,_that.updatedDate,_that.addedDate,_that.mergedKeys,_that.keepDuplicates);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  ComicDetails comicDetails,  DateTime updatedDate,  DateTime? addedDate,  List<String> mergedKeys,  bool keepDuplicates)  $default,) {final _that = this;
switch (_that) {
case _Bookmark():
return $default(_that.slug,_that.comicDetails,_that.updatedDate,_that.addedDate,_that.mergedKeys,_that.keepDuplicates);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  ComicDetails comicDetails,  DateTime updatedDate,  DateTime? addedDate,  List<String> mergedKeys,  bool keepDuplicates)?  $default,) {final _that = this;
switch (_that) {
case _Bookmark() when $default != null:
return $default(_that.slug,_that.comicDetails,_that.updatedDate,_that.addedDate,_that.mergedKeys,_that.keepDuplicates);case _:
  return null;

}
}

}

/// @nodoc


class _Bookmark extends Bookmark {
  const _Bookmark({required this.slug, required this.comicDetails, required this.updatedDate, this.addedDate,  List<String> mergedKeys = const <String>[], this.keepDuplicates = false}): _mergedKeys = mergedKeys,super._();
  

/// Series slug.
@override final  String slug;
@override final  ComicDetails comicDetails;
/// Last time the bookmark was added or found new chapters.
@override final  DateTime updatedDate;
/// When the comic was bookmarked. Null for bookmarks saved before this
/// was stored; sorting uses [updatedDate] for them.
@override final  DateTime? addedDate;
/// Series keys merged into this entry, [slug] among them, in the order
/// chapters are taken from: each chapter number comes from the first
/// that has it, and the details from the first. Empty when the entry
/// has one source. See [sourceKeys].
 final  List<String> _mergedKeys;
/// Series keys merged into this entry, [slug] among them, in the order
/// chapters are taken from: each chapter number comes from the first
/// that has it, and the details from the first. Empty when the entry
/// has one source. See [sourceKeys].
@override@JsonKey() List<String> get mergedKeys {
  if (_mergedKeys is EqualUnmodifiableListView) return _mergedKeys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mergedKeys);
}

/// A merged entry lists the chapters of every source, also the numbers
/// several have, instead of one per number.
@override@JsonKey() final  bool keepDuplicates;

/// Create a copy of Bookmark
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookmarkCopyWith<_Bookmark> get copyWith => __$BookmarkCopyWithImpl<_Bookmark>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Bookmark&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.comicDetails, comicDetails) || other.comicDetails == comicDetails)&&(identical(other.updatedDate, updatedDate) || other.updatedDate == updatedDate)&&(identical(other.addedDate, addedDate) || other.addedDate == addedDate)&&const DeepCollectionEquality().equals(other.mergedKeys, _mergedKeys)&&(identical(other.keepDuplicates, keepDuplicates) || other.keepDuplicates == keepDuplicates));
}


@override
int get hashCode {
    return Object.hash(runtimeType,slug,comicDetails,updatedDate,addedDate,const DeepCollectionEquality().hash(_mergedKeys),keepDuplicates);
}

@override
String toString() {
    return 'Bookmark(slug: $slug, comicDetails: $comicDetails, updatedDate: $updatedDate, addedDate: $addedDate, mergedKeys: $mergedKeys, keepDuplicates: $keepDuplicates)';
}


}

/// @nodoc
abstract mixin class _$BookmarkCopyWith<$Res> implements $BookmarkCopyWith<$Res> {
  factory _$BookmarkCopyWith(_Bookmark value, $Res Function(_Bookmark) _then) = __$BookmarkCopyWithImpl;
@override @useResult
$Res call({
 String slug, ComicDetails comicDetails, DateTime updatedDate, DateTime? addedDate, List<String> mergedKeys, bool keepDuplicates
});


@override $ComicDetailsCopyWith<$Res> get comicDetails;

}
/// @nodoc
class __$BookmarkCopyWithImpl<$Res>
    implements _$BookmarkCopyWith<$Res> {
  __$BookmarkCopyWithImpl(this._self, this._then);

  final _Bookmark _self;
  final $Res Function(_Bookmark) _then;

/// Create a copy of Bookmark
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? comicDetails = null,Object? updatedDate = null,Object? addedDate = freezed,Object? mergedKeys = null,Object? keepDuplicates = null,}) {
  return _then(_Bookmark(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,comicDetails: null == comicDetails ? _self.comicDetails : comicDetails // ignore: cast_nullable_to_non_nullable
as ComicDetails,updatedDate: null == updatedDate ? _self.updatedDate : updatedDate // ignore: cast_nullable_to_non_nullable
as DateTime,addedDate: freezed == addedDate ? _self.addedDate : addedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,mergedKeys: null == mergedKeys ? _self._mergedKeys : mergedKeys // ignore: cast_nullable_to_non_nullable
as List<String>,keepDuplicates: null == keepDuplicates ? _self.keepDuplicates : keepDuplicates // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Bookmark
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicDetailsCopyWith<$Res> get comicDetails {
  
  return $ComicDetailsCopyWith<$Res>(_self.comicDetails, (value) {
    return _then(_self.copyWith(comicDetails: value));
  });
}
}

// dart format on
