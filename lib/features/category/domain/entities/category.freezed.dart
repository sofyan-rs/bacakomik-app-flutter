// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LibraryCategory {

/// Random id; stays the same when the category is renamed.
 String get id; String get name;/// Position among the categories, lowest first.
 int get order;/// Last time it was created, renamed or moved; the newest wins in sync.
 DateTime get updatedDate;
/// Create a copy of LibraryCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryCategoryCopyWith<LibraryCategory> get copyWith => _$LibraryCategoryCopyWithImpl<LibraryCategory>(this as LibraryCategory, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LibraryCategory;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryCategory&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.order, _this.order) || other.order == _this.order)&&(identical(other.updatedDate, _this.updatedDate) || other.updatedDate == _this.updatedDate));
}


@override
int get hashCode {
  final _this = this as LibraryCategory;
  return Object.hash(runtimeType,_this.id,_this.name,_this.order,_this.updatedDate);
}

@override
String toString() {
  final _this = this as LibraryCategory;
  return 'LibraryCategory(id: ${_this.id}, name: ${_this.name}, order: ${_this.order}, updatedDate: ${_this.updatedDate})';
}


}

/// @nodoc
abstract mixin class $LibraryCategoryCopyWith<$Res>  {
  factory $LibraryCategoryCopyWith(LibraryCategory value, $Res Function(LibraryCategory) _then) = _$LibraryCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, int order, DateTime updatedDate
});




}
/// @nodoc
class _$LibraryCategoryCopyWithImpl<$Res>
    implements $LibraryCategoryCopyWith<$Res> {
  _$LibraryCategoryCopyWithImpl(this._self, this._then);

  final LibraryCategory _self;
  final $Res Function(LibraryCategory) _then;

/// Create a copy of LibraryCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? order = null,Object? updatedDate = null,}) {
  return _then(LibraryCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,updatedDate: null == updatedDate ? _self.updatedDate : updatedDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [LibraryCategory].
extension LibraryCategoryPatterns on LibraryCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryCategory value)  $default,){
final _that = this;
switch (_that) {
case _LibraryCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryCategory value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int order,  DateTime updatedDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryCategory() when $default != null:
return $default(_that.id,_that.name,_that.order,_that.updatedDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int order,  DateTime updatedDate)  $default,) {final _that = this;
switch (_that) {
case _LibraryCategory():
return $default(_that.id,_that.name,_that.order,_that.updatedDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int order,  DateTime updatedDate)?  $default,) {final _that = this;
switch (_that) {
case _LibraryCategory() when $default != null:
return $default(_that.id,_that.name,_that.order,_that.updatedDate);case _:
  return null;

}
}

}

/// @nodoc


class _LibraryCategory implements LibraryCategory {
  const _LibraryCategory({required this.id, required this.name, required this.order, required this.updatedDate});
  

/// Random id; stays the same when the category is renamed.
@override final  String id;
@override final  String name;
/// Position among the categories, lowest first.
@override final  int order;
/// Last time it was created, renamed or moved; the newest wins in sync.
@override final  DateTime updatedDate;

/// Create a copy of LibraryCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryCategoryCopyWith<_LibraryCategory> get copyWith => __$LibraryCategoryCopyWithImpl<_LibraryCategory>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.order, order) || other.order == order)&&(identical(other.updatedDate, updatedDate) || other.updatedDate == updatedDate));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,order,updatedDate);
}

@override
String toString() {
    return 'LibraryCategory(id: $id, name: $name, order: $order, updatedDate: $updatedDate)';
}


}

/// @nodoc
abstract mixin class _$LibraryCategoryCopyWith<$Res> implements $LibraryCategoryCopyWith<$Res> {
  factory _$LibraryCategoryCopyWith(_LibraryCategory value, $Res Function(_LibraryCategory) _then) = __$LibraryCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int order, DateTime updatedDate
});




}
/// @nodoc
class __$LibraryCategoryCopyWithImpl<$Res>
    implements _$LibraryCategoryCopyWith<$Res> {
  __$LibraryCategoryCopyWithImpl(this._self, this._then);

  final _LibraryCategory _self;
  final $Res Function(_LibraryCategory) _then;

/// Create a copy of LibraryCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? order = null,Object? updatedDate = null,}) {
  return _then(_LibraryCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,updatedDate: null == updatedDate ? _self.updatedDate : updatedDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$ComicCategories {

/// Series key, as in [Bookmark.slug].
 String get slug;/// [LibraryCategory.id]s; empty for none.
 List<String> get categoryIds;/// Last time the categories were set; the newest wins in sync.
 DateTime get updatedDate;
/// Create a copy of ComicCategories
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicCategoriesCopyWith<ComicCategories> get copyWith => _$ComicCategoriesCopyWithImpl<ComicCategories>(this as ComicCategories, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ComicCategories;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicCategories&&(identical(other.slug, _this.slug) || other.slug == _this.slug)&&const DeepCollectionEquality().equals(other.categoryIds, _this.categoryIds)&&(identical(other.updatedDate, _this.updatedDate) || other.updatedDate == _this.updatedDate));
}


@override
int get hashCode {
  final _this = this as ComicCategories;
  return Object.hash(runtimeType,_this.slug,const DeepCollectionEquality().hash(_this.categoryIds),_this.updatedDate);
}

@override
String toString() {
  final _this = this as ComicCategories;
  return 'ComicCategories(slug: ${_this.slug}, categoryIds: ${_this.categoryIds}, updatedDate: ${_this.updatedDate})';
}


}

/// @nodoc
abstract mixin class $ComicCategoriesCopyWith<$Res>  {
  factory $ComicCategoriesCopyWith(ComicCategories value, $Res Function(ComicCategories) _then) = _$ComicCategoriesCopyWithImpl;
@useResult
$Res call({
 String slug, List<String> categoryIds, DateTime updatedDate
});




}
/// @nodoc
class _$ComicCategoriesCopyWithImpl<$Res>
    implements $ComicCategoriesCopyWith<$Res> {
  _$ComicCategoriesCopyWithImpl(this._self, this._then);

  final ComicCategories _self;
  final $Res Function(ComicCategories) _then;

/// Create a copy of ComicCategories
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? categoryIds = null,Object? updatedDate = null,}) {
  return _then(ComicCategories(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,categoryIds: null == categoryIds ? _self.categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<String>,updatedDate: null == updatedDate ? _self.updatedDate : updatedDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ComicCategories].
extension ComicCategoriesPatterns on ComicCategories {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicCategories value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicCategories() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicCategories value)  $default,){
final _that = this;
switch (_that) {
case _ComicCategories():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicCategories value)?  $default,){
final _that = this;
switch (_that) {
case _ComicCategories() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  List<String> categoryIds,  DateTime updatedDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicCategories() when $default != null:
return $default(_that.slug,_that.categoryIds,_that.updatedDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  List<String> categoryIds,  DateTime updatedDate)  $default,) {final _that = this;
switch (_that) {
case _ComicCategories():
return $default(_that.slug,_that.categoryIds,_that.updatedDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  List<String> categoryIds,  DateTime updatedDate)?  $default,) {final _that = this;
switch (_that) {
case _ComicCategories() when $default != null:
return $default(_that.slug,_that.categoryIds,_that.updatedDate);case _:
  return null;

}
}

}

/// @nodoc


class _ComicCategories implements ComicCategories {
  const _ComicCategories({required this.slug, required  List<String> categoryIds, required this.updatedDate}): _categoryIds = categoryIds;
  

/// Series key, as in [Bookmark.slug].
@override final  String slug;
/// [LibraryCategory.id]s; empty for none.
 final  List<String> _categoryIds;
/// [LibraryCategory.id]s; empty for none.
@override List<String> get categoryIds {
  if (_categoryIds is EqualUnmodifiableListView) return _categoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryIds);
}

/// Last time the categories were set; the newest wins in sync.
@override final  DateTime updatedDate;

/// Create a copy of ComicCategories
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicCategoriesCopyWith<_ComicCategories> get copyWith => __$ComicCategoriesCopyWithImpl<_ComicCategories>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicCategories&&(identical(other.slug, slug) || other.slug == slug)&&const DeepCollectionEquality().equals(other.categoryIds, _categoryIds)&&(identical(other.updatedDate, updatedDate) || other.updatedDate == updatedDate));
}


@override
int get hashCode {
    return Object.hash(runtimeType,slug,const DeepCollectionEquality().hash(_categoryIds),updatedDate);
}

@override
String toString() {
    return 'ComicCategories(slug: $slug, categoryIds: $categoryIds, updatedDate: $updatedDate)';
}


}

/// @nodoc
abstract mixin class _$ComicCategoriesCopyWith<$Res> implements $ComicCategoriesCopyWith<$Res> {
  factory _$ComicCategoriesCopyWith(_ComicCategories value, $Res Function(_ComicCategories) _then) = __$ComicCategoriesCopyWithImpl;
@override @useResult
$Res call({
 String slug, List<String> categoryIds, DateTime updatedDate
});




}
/// @nodoc
class __$ComicCategoriesCopyWithImpl<$Res>
    implements _$ComicCategoriesCopyWith<$Res> {
  __$ComicCategoriesCopyWithImpl(this._self, this._then);

  final _ComicCategories _self;
  final $Res Function(_ComicCategories) _then;

/// Create a copy of ComicCategories
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? categoryIds = null,Object? updatedDate = null,}) {
  return _then(_ComicCategories(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,categoryIds: null == categoryIds ? _self._categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<String>,updatedDate: null == updatedDate ? _self.updatedDate : updatedDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
