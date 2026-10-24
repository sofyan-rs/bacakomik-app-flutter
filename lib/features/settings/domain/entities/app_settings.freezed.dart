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

 AppThemeMode get themeMode; ReadingDirection get readingDirection; PageFit get pageFit;/// Keep the screen awake while a chapter is open.
 bool get keepScreenOn;/// 8px gap between pages.
 bool get pageGap;/// Auto-scroll speed level, [autoScrollMin] to [autoScrollMax].
 int get autoScrollSpeed; BookmarkGrouping get bookmarkGrouping;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.themeMode, _this.themeMode) || other.themeMode == _this.themeMode)&&(identical(other.readingDirection, _this.readingDirection) || other.readingDirection == _this.readingDirection)&&(identical(other.pageFit, _this.pageFit) || other.pageFit == _this.pageFit)&&(identical(other.keepScreenOn, _this.keepScreenOn) || other.keepScreenOn == _this.keepScreenOn)&&(identical(other.pageGap, _this.pageGap) || other.pageGap == _this.pageGap)&&(identical(other.autoScrollSpeed, _this.autoScrollSpeed) || other.autoScrollSpeed == _this.autoScrollSpeed)&&(identical(other.bookmarkGrouping, _this.bookmarkGrouping) || other.bookmarkGrouping == _this.bookmarkGrouping));
}


@override
int get hashCode {
  final _this = this as AppSettings;
  return Object.hash(runtimeType,_this.themeMode,_this.readingDirection,_this.pageFit,_this.keepScreenOn,_this.pageGap,_this.autoScrollSpeed,_this.bookmarkGrouping);
}

@override
String toString() {
  final _this = this as AppSettings;
  return 'AppSettings(themeMode: ${_this.themeMode}, readingDirection: ${_this.readingDirection}, pageFit: ${_this.pageFit}, keepScreenOn: ${_this.keepScreenOn}, pageGap: ${_this.pageGap}, autoScrollSpeed: ${_this.autoScrollSpeed}, bookmarkGrouping: ${_this.bookmarkGrouping})';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 AppThemeMode themeMode, ReadingDirection readingDirection, PageFit pageFit, bool keepScreenOn, bool pageGap, int autoScrollSpeed, BookmarkGrouping bookmarkGrouping
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
@pragma('vm:prefer-inline') @override $Res call({Object? themeMode = null,Object? readingDirection = null,Object? pageFit = null,Object? keepScreenOn = null,Object? pageGap = null,Object? autoScrollSpeed = null,Object? bookmarkGrouping = null,}) {
  return _then(AppSettings(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,readingDirection: null == readingDirection ? _self.readingDirection : readingDirection // ignore: cast_nullable_to_non_nullable
as ReadingDirection,pageFit: null == pageFit ? _self.pageFit : pageFit // ignore: cast_nullable_to_non_nullable
as PageFit,keepScreenOn: null == keepScreenOn ? _self.keepScreenOn : keepScreenOn // ignore: cast_nullable_to_non_nullable
as bool,pageGap: null == pageGap ? _self.pageGap : pageGap // ignore: cast_nullable_to_non_nullable
as bool,autoScrollSpeed: null == autoScrollSpeed ? _self.autoScrollSpeed : autoScrollSpeed // ignore: cast_nullable_to_non_nullable
as int,bookmarkGrouping: null == bookmarkGrouping ? _self.bookmarkGrouping : bookmarkGrouping // ignore: cast_nullable_to_non_nullable
as BookmarkGrouping,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppThemeMode themeMode,  ReadingDirection readingDirection,  PageFit pageFit,  bool keepScreenOn,  bool pageGap,  int autoScrollSpeed,  BookmarkGrouping bookmarkGrouping)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.readingDirection,_that.pageFit,_that.keepScreenOn,_that.pageGap,_that.autoScrollSpeed,_that.bookmarkGrouping);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppThemeMode themeMode,  ReadingDirection readingDirection,  PageFit pageFit,  bool keepScreenOn,  bool pageGap,  int autoScrollSpeed,  BookmarkGrouping bookmarkGrouping)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.themeMode,_that.readingDirection,_that.pageFit,_that.keepScreenOn,_that.pageGap,_that.autoScrollSpeed,_that.bookmarkGrouping);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppThemeMode themeMode,  ReadingDirection readingDirection,  PageFit pageFit,  bool keepScreenOn,  bool pageGap,  int autoScrollSpeed,  BookmarkGrouping bookmarkGrouping)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.readingDirection,_that.pageFit,_that.keepScreenOn,_that.pageGap,_that.autoScrollSpeed,_that.bookmarkGrouping);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings implements AppSettings {
  const _AppSettings({this.themeMode = AppThemeMode.system, this.readingDirection = ReadingDirection.vertical, this.pageFit = PageFit.width, this.keepScreenOn = true, this.pageGap = false, this.autoScrollSpeed = 3, this.bookmarkGrouping = BookmarkGrouping.status});
  

@override@JsonKey() final  AppThemeMode themeMode;
@override@JsonKey() final  ReadingDirection readingDirection;
@override@JsonKey() final  PageFit pageFit;
/// Keep the screen awake while a chapter is open.
@override@JsonKey() final  bool keepScreenOn;
/// 8px gap between pages.
@override@JsonKey() final  bool pageGap;
/// Auto-scroll speed level, [autoScrollMin] to [autoScrollMax].
@override@JsonKey() final  int autoScrollSpeed;
@override@JsonKey() final  BookmarkGrouping bookmarkGrouping;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.readingDirection, readingDirection) || other.readingDirection == readingDirection)&&(identical(other.pageFit, pageFit) || other.pageFit == pageFit)&&(identical(other.keepScreenOn, keepScreenOn) || other.keepScreenOn == keepScreenOn)&&(identical(other.pageGap, pageGap) || other.pageGap == pageGap)&&(identical(other.autoScrollSpeed, autoScrollSpeed) || other.autoScrollSpeed == autoScrollSpeed)&&(identical(other.bookmarkGrouping, bookmarkGrouping) || other.bookmarkGrouping == bookmarkGrouping));
}


@override
int get hashCode {
    return Object.hash(runtimeType,themeMode,readingDirection,pageFit,keepScreenOn,pageGap,autoScrollSpeed,bookmarkGrouping);
}

@override
String toString() {
    return 'AppSettings(themeMode: $themeMode, readingDirection: $readingDirection, pageFit: $pageFit, keepScreenOn: $keepScreenOn, pageGap: $pageGap, autoScrollSpeed: $autoScrollSpeed, bookmarkGrouping: $bookmarkGrouping)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 AppThemeMode themeMode, ReadingDirection readingDirection, PageFit pageFit, bool keepScreenOn, bool pageGap, int autoScrollSpeed, BookmarkGrouping bookmarkGrouping
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
@override @pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? readingDirection = null,Object? pageFit = null,Object? keepScreenOn = null,Object? pageGap = null,Object? autoScrollSpeed = null,Object? bookmarkGrouping = null,}) {
  return _then(_AppSettings(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,readingDirection: null == readingDirection ? _self.readingDirection : readingDirection // ignore: cast_nullable_to_non_nullable
as ReadingDirection,pageFit: null == pageFit ? _self.pageFit : pageFit // ignore: cast_nullable_to_non_nullable
as PageFit,keepScreenOn: null == keepScreenOn ? _self.keepScreenOn : keepScreenOn // ignore: cast_nullable_to_non_nullable
as bool,pageGap: null == pageGap ? _self.pageGap : pageGap // ignore: cast_nullable_to_non_nullable
as bool,autoScrollSpeed: null == autoScrollSpeed ? _self.autoScrollSpeed : autoScrollSpeed // ignore: cast_nullable_to_non_nullable
as int,bookmarkGrouping: null == bookmarkGrouping ? _self.bookmarkGrouping : bookmarkGrouping // ignore: cast_nullable_to_non_nullable
as BookmarkGrouping,
  ));
}


}

// dart format on
