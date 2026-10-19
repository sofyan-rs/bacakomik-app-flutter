// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_release.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppRelease {

/// Without the leading `v`, e.g. `1.2.0`.
 String get version;/// Release body in Markdown.
 String get notes;/// Release page on GitHub.
 String get pageUrl; List<ReleaseApk> get apks;
/// Create a copy of AppRelease
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppReleaseCopyWith<AppRelease> get copyWith => _$AppReleaseCopyWithImpl<AppRelease>(this as AppRelease, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppRelease;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppRelease&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.pageUrl, _this.pageUrl) || other.pageUrl == _this.pageUrl)&&const DeepCollectionEquality().equals(other.apks, _this.apks));
}


@override
int get hashCode {
  final _this = this as AppRelease;
  return Object.hash(runtimeType,_this.version,_this.notes,_this.pageUrl,const DeepCollectionEquality().hash(_this.apks));
}

@override
String toString() {
  final _this = this as AppRelease;
  return 'AppRelease(version: ${_this.version}, notes: ${_this.notes}, pageUrl: ${_this.pageUrl}, apks: ${_this.apks})';
}


}

/// @nodoc
abstract mixin class $AppReleaseCopyWith<$Res>  {
  factory $AppReleaseCopyWith(AppRelease value, $Res Function(AppRelease) _then) = _$AppReleaseCopyWithImpl;
@useResult
$Res call({
 String version, String notes, String pageUrl, List<ReleaseApk> apks
});




}
/// @nodoc
class _$AppReleaseCopyWithImpl<$Res>
    implements $AppReleaseCopyWith<$Res> {
  _$AppReleaseCopyWithImpl(this._self, this._then);

  final AppRelease _self;
  final $Res Function(AppRelease) _then;

/// Create a copy of AppRelease
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? notes = null,Object? pageUrl = null,Object? apks = null,}) {
  return _then(AppRelease(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,pageUrl: null == pageUrl ? _self.pageUrl : pageUrl // ignore: cast_nullable_to_non_nullable
as String,apks: null == apks ? _self.apks : apks // ignore: cast_nullable_to_non_nullable
as List<ReleaseApk>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppRelease].
extension AppReleasePatterns on AppRelease {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppRelease value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppRelease() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppRelease value)  $default,){
final _that = this;
switch (_that) {
case _AppRelease():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppRelease value)?  $default,){
final _that = this;
switch (_that) {
case _AppRelease() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  String notes,  String pageUrl,  List<ReleaseApk> apks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppRelease() when $default != null:
return $default(_that.version,_that.notes,_that.pageUrl,_that.apks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  String notes,  String pageUrl,  List<ReleaseApk> apks)  $default,) {final _that = this;
switch (_that) {
case _AppRelease():
return $default(_that.version,_that.notes,_that.pageUrl,_that.apks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  String notes,  String pageUrl,  List<ReleaseApk> apks)?  $default,) {final _that = this;
switch (_that) {
case _AppRelease() when $default != null:
return $default(_that.version,_that.notes,_that.pageUrl,_that.apks);case _:
  return null;

}
}

}

/// @nodoc


class _AppRelease extends AppRelease {
  const _AppRelease({required this.version, this.notes = '', required this.pageUrl,  List<ReleaseApk> apks = const []}): _apks = apks,super._();
  

/// Without the leading `v`, e.g. `1.2.0`.
@override final  String version;
/// Release body in Markdown.
@override@JsonKey() final  String notes;
/// Release page on GitHub.
@override final  String pageUrl;
 final  List<ReleaseApk> _apks;
@override@JsonKey() List<ReleaseApk> get apks {
  if (_apks is EqualUnmodifiableListView) return _apks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_apks);
}


/// Create a copy of AppRelease
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppReleaseCopyWith<_AppRelease> get copyWith => __$AppReleaseCopyWithImpl<_AppRelease>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppRelease&&(identical(other.version, version) || other.version == version)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.pageUrl, pageUrl) || other.pageUrl == pageUrl)&&const DeepCollectionEquality().equals(other.apks, _apks));
}


@override
int get hashCode {
    return Object.hash(runtimeType,version,notes,pageUrl,const DeepCollectionEquality().hash(_apks));
}

@override
String toString() {
    return 'AppRelease(version: $version, notes: $notes, pageUrl: $pageUrl, apks: $apks)';
}


}

/// @nodoc
abstract mixin class _$AppReleaseCopyWith<$Res> implements $AppReleaseCopyWith<$Res> {
  factory _$AppReleaseCopyWith(_AppRelease value, $Res Function(_AppRelease) _then) = __$AppReleaseCopyWithImpl;
@override @useResult
$Res call({
 String version, String notes, String pageUrl, List<ReleaseApk> apks
});




}
/// @nodoc
class __$AppReleaseCopyWithImpl<$Res>
    implements _$AppReleaseCopyWith<$Res> {
  __$AppReleaseCopyWithImpl(this._self, this._then);

  final _AppRelease _self;
  final $Res Function(_AppRelease) _then;

/// Create a copy of AppRelease
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? notes = null,Object? pageUrl = null,Object? apks = null,}) {
  return _then(_AppRelease(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,pageUrl: null == pageUrl ? _self.pageUrl : pageUrl // ignore: cast_nullable_to_non_nullable
as String,apks: null == apks ? _self._apks : apks // ignore: cast_nullable_to_non_nullable
as List<ReleaseApk>,
  ));
}


}

/// @nodoc
mixin _$ReleaseApk {

 String get name; String get url;/// Hex SHA-256 from GitHub's asset digest, when available.
 String? get sha256;
/// Create a copy of ReleaseApk
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReleaseApkCopyWith<ReleaseApk> get copyWith => _$ReleaseApkCopyWithImpl<ReleaseApk>(this as ReleaseApk, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReleaseApk;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReleaseApk&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256));
}


@override
int get hashCode {
  final _this = this as ReleaseApk;
  return Object.hash(runtimeType,_this.name,_this.url,_this.sha256);
}

@override
String toString() {
  final _this = this as ReleaseApk;
  return 'ReleaseApk(name: ${_this.name}, url: ${_this.url}, sha256: ${_this.sha256})';
}


}

/// @nodoc
abstract mixin class $ReleaseApkCopyWith<$Res>  {
  factory $ReleaseApkCopyWith(ReleaseApk value, $Res Function(ReleaseApk) _then) = _$ReleaseApkCopyWithImpl;
@useResult
$Res call({
 String name, String url, String? sha256
});




}
/// @nodoc
class _$ReleaseApkCopyWithImpl<$Res>
    implements $ReleaseApkCopyWith<$Res> {
  _$ReleaseApkCopyWithImpl(this._self, this._then);

  final ReleaseApk _self;
  final $Res Function(ReleaseApk) _then;

/// Create a copy of ReleaseApk
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? url = null,Object? sha256 = freezed,}) {
  return _then(ReleaseApk(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,sha256: freezed == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReleaseApk].
extension ReleaseApkPatterns on ReleaseApk {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReleaseApk value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReleaseApk() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReleaseApk value)  $default,){
final _that = this;
switch (_that) {
case _ReleaseApk():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReleaseApk value)?  $default,){
final _that = this;
switch (_that) {
case _ReleaseApk() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String url,  String? sha256)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReleaseApk() when $default != null:
return $default(_that.name,_that.url,_that.sha256);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String url,  String? sha256)  $default,) {final _that = this;
switch (_that) {
case _ReleaseApk():
return $default(_that.name,_that.url,_that.sha256);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String url,  String? sha256)?  $default,) {final _that = this;
switch (_that) {
case _ReleaseApk() when $default != null:
return $default(_that.name,_that.url,_that.sha256);case _:
  return null;

}
}

}

/// @nodoc


class _ReleaseApk implements ReleaseApk {
  const _ReleaseApk({required this.name, required this.url, this.sha256});
  

@override final  String name;
@override final  String url;
/// Hex SHA-256 from GitHub's asset digest, when available.
@override final  String? sha256;

/// Create a copy of ReleaseApk
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReleaseApkCopyWith<_ReleaseApk> get copyWith => __$ReleaseApkCopyWithImpl<_ReleaseApk>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReleaseApk&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.sha256, sha256) || other.sha256 == sha256));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,url,sha256);
}

@override
String toString() {
    return 'ReleaseApk(name: $name, url: $url, sha256: $sha256)';
}


}

/// @nodoc
abstract mixin class _$ReleaseApkCopyWith<$Res> implements $ReleaseApkCopyWith<$Res> {
  factory _$ReleaseApkCopyWith(_ReleaseApk value, $Res Function(_ReleaseApk) _then) = __$ReleaseApkCopyWithImpl;
@override @useResult
$Res call({
 String name, String url, String? sha256
});




}
/// @nodoc
class __$ReleaseApkCopyWithImpl<$Res>
    implements _$ReleaseApkCopyWith<$Res> {
  __$ReleaseApkCopyWithImpl(this._self, this._then);

  final _ReleaseApk _self;
  final $Res Function(_ReleaseApk) _then;

/// Create a copy of ReleaseApk
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? url = null,Object? sha256 = freezed,}) {
  return _then(_ReleaseApk(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,sha256: freezed == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
