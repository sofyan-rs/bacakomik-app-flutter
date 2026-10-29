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
 String get pageUrl; List<ReleaseAsset> get assets;
/// Create a copy of AppRelease
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppReleaseCopyWith<AppRelease> get copyWith => _$AppReleaseCopyWithImpl<AppRelease>(this as AppRelease, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppRelease;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppRelease&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.pageUrl, _this.pageUrl) || other.pageUrl == _this.pageUrl)&&const DeepCollectionEquality().equals(other.assets, _this.assets));
}


@override
int get hashCode {
  final _this = this as AppRelease;
  return Object.hash(runtimeType,_this.version,_this.notes,_this.pageUrl,const DeepCollectionEquality().hash(_this.assets));
}

@override
String toString() {
  final _this = this as AppRelease;
  return 'AppRelease(version: ${_this.version}, notes: ${_this.notes}, pageUrl: ${_this.pageUrl}, assets: ${_this.assets})';
}


}

/// @nodoc
abstract mixin class $AppReleaseCopyWith<$Res>  {
  factory $AppReleaseCopyWith(AppRelease value, $Res Function(AppRelease) _then) = _$AppReleaseCopyWithImpl;
@useResult
$Res call({
 String version, String notes, String pageUrl, List<ReleaseAsset> assets
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
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? notes = null,Object? pageUrl = null,Object? assets = null,}) {
  return _then(AppRelease(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,pageUrl: null == pageUrl ? _self.pageUrl : pageUrl // ignore: cast_nullable_to_non_nullable
as String,assets: null == assets ? _self.assets : assets // ignore: cast_nullable_to_non_nullable
as List<ReleaseAsset>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  String notes,  String pageUrl,  List<ReleaseAsset> assets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppRelease() when $default != null:
return $default(_that.version,_that.notes,_that.pageUrl,_that.assets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  String notes,  String pageUrl,  List<ReleaseAsset> assets)  $default,) {final _that = this;
switch (_that) {
case _AppRelease():
return $default(_that.version,_that.notes,_that.pageUrl,_that.assets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  String notes,  String pageUrl,  List<ReleaseAsset> assets)?  $default,) {final _that = this;
switch (_that) {
case _AppRelease() when $default != null:
return $default(_that.version,_that.notes,_that.pageUrl,_that.assets);case _:
  return null;

}
}

}

/// @nodoc


class _AppRelease extends AppRelease {
  const _AppRelease({required this.version, this.notes = '', required this.pageUrl,  List<ReleaseAsset> assets = const []}): _assets = assets,super._();
  

/// Without the leading `v`, e.g. `1.2.0`.
@override final  String version;
/// Release body in Markdown.
@override@JsonKey() final  String notes;
/// Release page on GitHub.
@override final  String pageUrl;
 final  List<ReleaseAsset> _assets;
@override@JsonKey() List<ReleaseAsset> get assets {
  if (_assets is EqualUnmodifiableListView) return _assets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assets);
}


/// Create a copy of AppRelease
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppReleaseCopyWith<_AppRelease> get copyWith => __$AppReleaseCopyWithImpl<_AppRelease>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppRelease&&(identical(other.version, version) || other.version == version)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.pageUrl, pageUrl) || other.pageUrl == pageUrl)&&const DeepCollectionEquality().equals(other.assets, _assets));
}


@override
int get hashCode {
    return Object.hash(runtimeType,version,notes,pageUrl,const DeepCollectionEquality().hash(_assets));
}

@override
String toString() {
    return 'AppRelease(version: $version, notes: $notes, pageUrl: $pageUrl, assets: $assets)';
}


}

/// @nodoc
abstract mixin class _$AppReleaseCopyWith<$Res> implements $AppReleaseCopyWith<$Res> {
  factory _$AppReleaseCopyWith(_AppRelease value, $Res Function(_AppRelease) _then) = __$AppReleaseCopyWithImpl;
@override @useResult
$Res call({
 String version, String notes, String pageUrl, List<ReleaseAsset> assets
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
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? notes = null,Object? pageUrl = null,Object? assets = null,}) {
  return _then(_AppRelease(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,pageUrl: null == pageUrl ? _self.pageUrl : pageUrl // ignore: cast_nullable_to_non_nullable
as String,assets: null == assets ? _self._assets : assets // ignore: cast_nullable_to_non_nullable
as List<ReleaseAsset>,
  ));
}


}

/// @nodoc
mixin _$ReleaseAsset {

 String get name; String get url;/// Hex SHA-256 from GitHub's asset digest, when available.
 String? get sha256;
/// Create a copy of ReleaseAsset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReleaseAssetCopyWith<ReleaseAsset> get copyWith => _$ReleaseAssetCopyWithImpl<ReleaseAsset>(this as ReleaseAsset, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReleaseAsset;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReleaseAsset&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256));
}


@override
int get hashCode {
  final _this = this as ReleaseAsset;
  return Object.hash(runtimeType,_this.name,_this.url,_this.sha256);
}

@override
String toString() {
  final _this = this as ReleaseAsset;
  return 'ReleaseAsset(name: ${_this.name}, url: ${_this.url}, sha256: ${_this.sha256})';
}


}

/// @nodoc
abstract mixin class $ReleaseAssetCopyWith<$Res>  {
  factory $ReleaseAssetCopyWith(ReleaseAsset value, $Res Function(ReleaseAsset) _then) = _$ReleaseAssetCopyWithImpl;
@useResult
$Res call({
 String name, String url, String? sha256
});




}
/// @nodoc
class _$ReleaseAssetCopyWithImpl<$Res>
    implements $ReleaseAssetCopyWith<$Res> {
  _$ReleaseAssetCopyWithImpl(this._self, this._then);

  final ReleaseAsset _self;
  final $Res Function(ReleaseAsset) _then;

/// Create a copy of ReleaseAsset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? url = null,Object? sha256 = freezed,}) {
  return _then(ReleaseAsset(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,sha256: freezed == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReleaseAsset].
extension ReleaseAssetPatterns on ReleaseAsset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReleaseAsset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReleaseAsset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReleaseAsset value)  $default,){
final _that = this;
switch (_that) {
case _ReleaseAsset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReleaseAsset value)?  $default,){
final _that = this;
switch (_that) {
case _ReleaseAsset() when $default != null:
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
case _ReleaseAsset() when $default != null:
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
case _ReleaseAsset():
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
case _ReleaseAsset() when $default != null:
return $default(_that.name,_that.url,_that.sha256);case _:
  return null;

}
}

}

/// @nodoc


class _ReleaseAsset implements ReleaseAsset {
  const _ReleaseAsset({required this.name, required this.url, this.sha256});
  

@override final  String name;
@override final  String url;
/// Hex SHA-256 from GitHub's asset digest, when available.
@override final  String? sha256;

/// Create a copy of ReleaseAsset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReleaseAssetCopyWith<_ReleaseAsset> get copyWith => __$ReleaseAssetCopyWithImpl<_ReleaseAsset>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReleaseAsset&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.sha256, sha256) || other.sha256 == sha256));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,url,sha256);
}

@override
String toString() {
    return 'ReleaseAsset(name: $name, url: $url, sha256: $sha256)';
}


}

/// @nodoc
abstract mixin class _$ReleaseAssetCopyWith<$Res> implements $ReleaseAssetCopyWith<$Res> {
  factory _$ReleaseAssetCopyWith(_ReleaseAsset value, $Res Function(_ReleaseAsset) _then) = __$ReleaseAssetCopyWithImpl;
@override @useResult
$Res call({
 String name, String url, String? sha256
});




}
/// @nodoc
class __$ReleaseAssetCopyWithImpl<$Res>
    implements _$ReleaseAssetCopyWith<$Res> {
  __$ReleaseAssetCopyWithImpl(this._self, this._then);

  final _ReleaseAsset _self;
  final $Res Function(_ReleaseAsset) _then;

/// Create a copy of ReleaseAsset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? url = null,Object? sha256 = freezed,}) {
  return _then(_ReleaseAsset(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,sha256: freezed == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
