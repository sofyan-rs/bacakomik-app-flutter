// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Home {

 List<Comic> get popular; List<Comic> get latest;
/// Create a copy of Home
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeCopyWith<Home> get copyWith => _$HomeCopyWithImpl<Home>(this as Home, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Home;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Home&&const DeepCollectionEquality().equals(other.popular, _this.popular)&&const DeepCollectionEquality().equals(other.latest, _this.latest));
}


@override
int get hashCode {
  final _this = this as Home;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.popular),const DeepCollectionEquality().hash(_this.latest));
}

@override
String toString() {
  final _this = this as Home;
  return 'Home(popular: ${_this.popular}, latest: ${_this.latest})';
}


}

/// @nodoc
abstract mixin class $HomeCopyWith<$Res>  {
  factory $HomeCopyWith(Home value, $Res Function(Home) _then) = _$HomeCopyWithImpl;
@useResult
$Res call({
 List<Comic> popular, List<Comic> latest
});




}
/// @nodoc
class _$HomeCopyWithImpl<$Res>
    implements $HomeCopyWith<$Res> {
  _$HomeCopyWithImpl(this._self, this._then);

  final Home _self;
  final $Res Function(Home) _then;

/// Create a copy of Home
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? popular = null,Object? latest = null,}) {
  return _then(Home(
popular: null == popular ? _self.popular : popular // ignore: cast_nullable_to_non_nullable
as List<Comic>,latest: null == latest ? _self.latest : latest // ignore: cast_nullable_to_non_nullable
as List<Comic>,
  ));
}

}


/// Adds pattern-matching-related methods to [Home].
extension HomePatterns on Home {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Home value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Home() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Home value)  $default,){
final _that = this;
switch (_that) {
case _Home():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Home value)?  $default,){
final _that = this;
switch (_that) {
case _Home() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Comic> popular,  List<Comic> latest)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Home() when $default != null:
return $default(_that.popular,_that.latest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Comic> popular,  List<Comic> latest)  $default,) {final _that = this;
switch (_that) {
case _Home():
return $default(_that.popular,_that.latest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Comic> popular,  List<Comic> latest)?  $default,) {final _that = this;
switch (_that) {
case _Home() when $default != null:
return $default(_that.popular,_that.latest);case _:
  return null;

}
}

}

/// @nodoc


class _Home implements Home {
  const _Home({required  List<Comic> popular, required  List<Comic> latest}): _popular = popular,_latest = latest;
  

 final  List<Comic> _popular;
@override List<Comic> get popular {
  if (_popular is EqualUnmodifiableListView) return _popular;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_popular);
}

 final  List<Comic> _latest;
@override List<Comic> get latest {
  if (_latest is EqualUnmodifiableListView) return _latest;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_latest);
}


/// Create a copy of Home
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeCopyWith<_Home> get copyWith => __$HomeCopyWithImpl<_Home>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Home&&const DeepCollectionEquality().equals(other.popular, _popular)&&const DeepCollectionEquality().equals(other.latest, _latest));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_popular),const DeepCollectionEquality().hash(_latest));
}

@override
String toString() {
    return 'Home(popular: $popular, latest: $latest)';
}


}

/// @nodoc
abstract mixin class _$HomeCopyWith<$Res> implements $HomeCopyWith<$Res> {
  factory _$HomeCopyWith(_Home value, $Res Function(_Home) _then) = __$HomeCopyWithImpl;
@override @useResult
$Res call({
 List<Comic> popular, List<Comic> latest
});




}
/// @nodoc
class __$HomeCopyWithImpl<$Res>
    implements _$HomeCopyWith<$Res> {
  __$HomeCopyWithImpl(this._self, this._then);

  final _Home _self;
  final $Res Function(_Home) _then;

/// Create a copy of Home
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? popular = null,Object? latest = null,}) {
  return _then(_Home(
popular: null == popular ? _self._popular : popular // ignore: cast_nullable_to_non_nullable
as List<Comic>,latest: null == latest ? _self._latest : latest // ignore: cast_nullable_to_non_nullable
as List<Comic>,
  ));
}


}

// dart format on
