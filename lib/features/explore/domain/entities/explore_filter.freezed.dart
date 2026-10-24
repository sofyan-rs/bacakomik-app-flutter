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

 String get source; Map<String, List<String>> get values;/// Title search.
 String get query;
/// Create a copy of ExploreFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExploreFilterCopyWith<ExploreFilter> get copyWith => _$ExploreFilterCopyWithImpl<ExploreFilter>(this as ExploreFilter, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ExploreFilter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExploreFilter&&(identical(other.source, _this.source) || other.source == _this.source)&&const DeepCollectionEquality().equals(other.values, _this.values)&&(identical(other.query, _this.query) || other.query == _this.query));
}


@override
int get hashCode {
  final _this = this as ExploreFilter;
  return Object.hash(runtimeType,_this.source,const DeepCollectionEquality().hash(_this.values),_this.query);
}

@override
String toString() {
  final _this = this as ExploreFilter;
  return 'ExploreFilter(source: ${_this.source}, values: ${_this.values}, query: ${_this.query})';
}


}

/// @nodoc
abstract mixin class $ExploreFilterCopyWith<$Res>  {
  factory $ExploreFilterCopyWith(ExploreFilter value, $Res Function(ExploreFilter) _then) = _$ExploreFilterCopyWithImpl;
@useResult
$Res call({
 String source, Map<String, List<String>> values, String query
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
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? values = null,Object? query = null,}) {
  return _then(ExploreFilter(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String source,  Map<String, List<String>> values,  String query)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExploreFilter() when $default != null:
return $default(_that.source,_that.values,_that.query);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String source,  Map<String, List<String>> values,  String query)  $default,) {final _that = this;
switch (_that) {
case _ExploreFilter():
return $default(_that.source,_that.values,_that.query);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String source,  Map<String, List<String>> values,  String query)?  $default,) {final _that = this;
switch (_that) {
case _ExploreFilter() when $default != null:
return $default(_that.source,_that.values,_that.query);case _:
  return null;

}
}

}

/// @nodoc


class _ExploreFilter implements ExploreFilter {
  const _ExploreFilter({this.source = '',  Map<String, List<String>> values = const {}, this.query = ''}): _values = values;
  

@override@JsonKey() final  String source;
 final  Map<String, List<String>> _values;
@override@JsonKey() Map<String, List<String>> get values {
  if (_values is EqualUnmodifiableMapView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_values);
}

/// Title search.
@override@JsonKey() final  String query;

/// Create a copy of ExploreFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExploreFilterCopyWith<_ExploreFilter> get copyWith => __$ExploreFilterCopyWithImpl<_ExploreFilter>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExploreFilter&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.values, _values)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode {
    return Object.hash(runtimeType,source,const DeepCollectionEquality().hash(_values),query);
}

@override
String toString() {
    return 'ExploreFilter(source: $source, values: $values, query: $query)';
}


}

/// @nodoc
abstract mixin class _$ExploreFilterCopyWith<$Res> implements $ExploreFilterCopyWith<$Res> {
  factory _$ExploreFilterCopyWith(_ExploreFilter value, $Res Function(_ExploreFilter) _then) = __$ExploreFilterCopyWithImpl;
@override @useResult
$Res call({
 String source, Map<String, List<String>> values, String query
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
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? values = null,Object? query = null,}) {
  return _then(_ExploreFilter(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,values: null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
