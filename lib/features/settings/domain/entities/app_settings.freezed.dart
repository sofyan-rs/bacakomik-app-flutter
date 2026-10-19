// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppSettings {

/// One of [AppText.system], [AppText.light] or [AppText.dark].
 String get darkMode; ReadingDirection get readingDirection; PageFit get pageFit;/// Keep the screen awake while a chapter is open.
 bool get keepScreenOn;/// 8px gap between pages.
 bool get pageGap;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.darkMode, _this.darkMode) || other.darkMode == _this.darkMode)&&(identical(other.readingDirection, _this.readingDirection) || other.readingDirection == _this.readingDirection)&&(identical(other.pageFit, _this.pageFit) || other.pageFit == _this.pageFit)&&(identical(other.keepScreenOn, _this.keepScreenOn) || other.keepScreenOn == _this.keepScreenOn)&&(identical(other.pageGap, _this.pageGap) || other.pageGap == _this.pageGap));
}


@override
int get hashCode {
  final _this = this as AppSettings;
  return Object.hash(runtimeType,_this.darkMode,_this.readingDirection,_this.pageFit,_this.keepScreenOn,_this.pageGap);
}

@override
String toString() {
  final _this = this as AppSettings;
  return 'AppSettings(darkMode: ${_this.darkMode}, readingDirection: ${_this.readingDirection}, pageFit: ${_this.pageFit}, keepScreenOn: ${_this.keepScreenOn}, pageGap: ${_this.pageGap})';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 String darkMode, ReadingDirection readingDirection, PageFit pageFit, bool keepScreenOn, bool pageGap
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? darkMode = null,Object? readingDirection = null,Object? pageFit = null,Object? keepScreenOn = null,Object? pageGap = null,}) {
  return _then(AppSettings(
darkMode: null == darkMode ? _self.darkMode : darkMode // ignore: cast_nullable_to_non_nullable
as String,readingDirection: null == readingDirection ? _self.readingDirection : readingDirection // ignore: cast_nullable_to_non_nullable
as ReadingDirection,pageFit: null == pageFit ? _self.pageFit : pageFit // ignore: cast_nullable_to_non_nullable
as PageFit,keepScreenOn: null == keepScreenOn ? _self.keepScreenOn : keepScreenOn // ignore: cast_nullable_to_non_nullable
as bool,pageGap: null == pageGap ? _self.pageGap : pageGap // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String darkMode,  ReadingDirection readingDirection,  PageFit pageFit,  bool keepScreenOn,  bool pageGap)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.darkMode,_that.readingDirection,_that.pageFit,_that.keepScreenOn,_that.pageGap);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String darkMode,  ReadingDirection readingDirection,  PageFit pageFit,  bool keepScreenOn,  bool pageGap)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.darkMode,_that.readingDirection,_that.pageFit,_that.keepScreenOn,_that.pageGap);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String darkMode,  ReadingDirection readingDirection,  PageFit pageFit,  bool keepScreenOn,  bool pageGap)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.darkMode,_that.readingDirection,_that.pageFit,_that.keepScreenOn,_that.pageGap);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings implements AppSettings {
  const _AppSettings({this.darkMode = AppText.system, this.readingDirection = ReadingDirection.vertical, this.pageFit = PageFit.width, this.keepScreenOn = true, this.pageGap = false});
  

/// One of [AppText.system], [AppText.light] or [AppText.dark].
@override@JsonKey() final  String darkMode;
@override@JsonKey() final  ReadingDirection readingDirection;
@override@JsonKey() final  PageFit pageFit;
/// Keep the screen awake while a chapter is open.
@override@JsonKey() final  bool keepScreenOn;
/// 8px gap between pages.
@override@JsonKey() final  bool pageGap;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.darkMode, darkMode) || other.darkMode == darkMode)&&(identical(other.readingDirection, readingDirection) || other.readingDirection == readingDirection)&&(identical(other.pageFit, pageFit) || other.pageFit == pageFit)&&(identical(other.keepScreenOn, keepScreenOn) || other.keepScreenOn == keepScreenOn)&&(identical(other.pageGap, pageGap) || other.pageGap == pageGap));
}


@override
int get hashCode {
    return Object.hash(runtimeType,darkMode,readingDirection,pageFit,keepScreenOn,pageGap);
}

@override
String toString() {
    return 'AppSettings(darkMode: $darkMode, readingDirection: $readingDirection, pageFit: $pageFit, keepScreenOn: $keepScreenOn, pageGap: $pageGap)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 String darkMode, ReadingDirection readingDirection, PageFit pageFit, bool keepScreenOn, bool pageGap
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? darkMode = null,Object? readingDirection = null,Object? pageFit = null,Object? keepScreenOn = null,Object? pageGap = null,}) {
  return _then(_AppSettings(
darkMode: null == darkMode ? _self.darkMode : darkMode // ignore: cast_nullable_to_non_nullable
as String,readingDirection: null == readingDirection ? _self.readingDirection : readingDirection // ignore: cast_nullable_to_non_nullable
as ReadingDirection,pageFit: null == pageFit ? _self.pageFit : pageFit // ignore: cast_nullable_to_non_nullable
as PageFit,keepScreenOn: null == keepScreenOn ? _self.keepScreenOn : keepScreenOn // ignore: cast_nullable_to_non_nullable
as bool,pageGap: null == pageGap ? _self.pageGap : pageGap // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
