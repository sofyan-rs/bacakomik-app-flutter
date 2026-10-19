// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'explore_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExploreFilter {

 String get sortBy; String get type; String get status; List<String> get genres;/// Title search, sent as `q`.
 String get query;
/// Create a copy of ExploreFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExploreFilterCopyWith<ExploreFilter> get copyWith => _$ExploreFilterCopyWithImpl<ExploreFilter>(this as ExploreFilter, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ExploreFilter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExploreFilter&&(identical(other.sortBy, _this.sortBy) || other.sortBy == _this.sortBy)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.genres, _this.genres)&&(identical(other.query, _this.query) || other.query == _this.query));
}


@override
int get hashCode {
  final _this = this as ExploreFilter;
  return Object.hash(runtimeType,_this.sortBy,_this.type,_this.status,const DeepCollectionEquality().hash(_this.genres),_this.query);
}

@override
String toString() {
  final _this = this as ExploreFilter;
  return 'ExploreFilter(sortBy: ${_this.sortBy}, type: ${_this.type}, status: ${_this.status}, genres: ${_this.genres}, query: ${_this.query})';
}


}

/// @nodoc
abstract mixin class $ExploreFilterCopyWith<$Res>  {
  factory $ExploreFilterCopyWith(ExploreFilter value, $Res Function(ExploreFilter) _then) = _$ExploreFilterCopyWithImpl;
@useResult
$Res call({
 String sortBy, String type, String status, List<String> genres, String query
});




}
/// @nodoc
class _$ExploreFilterCopyWithImpl<$Res>
    implements $ExploreFilterCopyWith<$Res> {
  _$ExploreFilterCopyWithImpl(this._self, this._then);

  final ExploreFilter _self;
  final $Res Function(ExploreFilter) _then;

/// Create a copy of ExploreFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sortBy = null,Object? type = null,Object? status = null,Object? genres = null,Object? query = null,}) {
  return _then(ExploreFilter(
sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ExploreFilter].
extension ExploreFilterPatterns on ExploreFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExploreFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExploreFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExploreFilter value)  $default,){
final _that = this;
switch (_that) {
case _ExploreFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExploreFilter value)?  $default,){
final _that = this;
switch (_that) {
case _ExploreFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sortBy,  String type,  String status,  List<String> genres,  String query)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExploreFilter() when $default != null:
return $default(_that.sortBy,_that.type,_that.status,_that.genres,_that.query);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sortBy,  String type,  String status,  List<String> genres,  String query)  $default,) {final _that = this;
switch (_that) {
case _ExploreFilter():
return $default(_that.sortBy,_that.type,_that.status,_that.genres,_that.query);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sortBy,  String type,  String status,  List<String> genres,  String query)?  $default,) {final _that = this;
switch (_that) {
case _ExploreFilter() when $default != null:
return $default(_that.sortBy,_that.type,_that.status,_that.genres,_that.query);case _:
  return null;

}
}

}

/// @nodoc


class _ExploreFilter implements ExploreFilter {
  const _ExploreFilter({this.sortBy = 'latest', this.type = 'all', this.status = 'all',  List<String> genres = const [], this.query = ''}): _genres = genres;
  

@override@JsonKey() final  String sortBy;
@override@JsonKey() final  String type;
@override@JsonKey() final  String status;
 final  List<String> _genres;
@override@JsonKey() List<String> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

/// Title search, sent as `q`.
@override@JsonKey() final  String query;

/// Create a copy of ExploreFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExploreFilterCopyWith<_ExploreFilter> get copyWith => __$ExploreFilterCopyWithImpl<_ExploreFilter>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExploreFilter&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.genres, _genres)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sortBy,type,status,const DeepCollectionEquality().hash(_genres),query);
}

@override
String toString() {
    return 'ExploreFilter(sortBy: $sortBy, type: $type, status: $status, genres: $genres, query: $query)';
}


}

/// @nodoc
abstract mixin class _$ExploreFilterCopyWith<$Res> implements $ExploreFilterCopyWith<$Res> {
  factory _$ExploreFilterCopyWith(_ExploreFilter value, $Res Function(_ExploreFilter) _then) = __$ExploreFilterCopyWithImpl;
@override @useResult
$Res call({
 String sortBy, String type, String status, List<String> genres, String query
});




}
/// @nodoc
class __$ExploreFilterCopyWithImpl<$Res>
    implements _$ExploreFilterCopyWith<$Res> {
  __$ExploreFilterCopyWithImpl(this._self, this._then);

  final _ExploreFilter _self;
  final $Res Function(_ExploreFilter) _then;

/// Create a copy of ExploreFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sortBy = null,Object? type = null,Object? status = null,Object? genres = null,Object? query = null,}) {
  return _then(_ExploreFilter(
sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
