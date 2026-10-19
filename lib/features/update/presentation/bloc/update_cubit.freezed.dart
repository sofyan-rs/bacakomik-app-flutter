// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UpdateState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'UpdateState'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'UpdateState()';
}


}

/// @nodoc
class $UpdateStateCopyWith<$Res>  {
$UpdateStateCopyWith(UpdateState _, $Res Function(UpdateState) __);
}


/// Adds pattern-matching-related methods to [UpdateState].
extension UpdateStatePatterns on UpdateState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UpdateIdle value)?  idle,TResult Function( UpdateChecking value)?  checking,TResult Function( UpdateUpToDate value)?  upToDate,TResult Function( UpdateCheckFailed value)?  checkFailed,TResult Function( UpdateAvailable value)?  available,TResult Function( UpdateDownloadingState value)?  downloading,TResult Function( UpdateInstallFailedState value)?  installFailed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UpdateIdle() when idle != null:
return idle(_that);case UpdateChecking() when checking != null:
return checking(_that);case UpdateUpToDate() when upToDate != null:
return upToDate(_that);case UpdateCheckFailed() when checkFailed != null:
return checkFailed(_that);case UpdateAvailable() when available != null:
return available(_that);case UpdateDownloadingState() when downloading != null:
return downloading(_that);case UpdateInstallFailedState() when installFailed != null:
return installFailed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UpdateIdle value)  idle,required TResult Function( UpdateChecking value)  checking,required TResult Function( UpdateUpToDate value)  upToDate,required TResult Function( UpdateCheckFailed value)  checkFailed,required TResult Function( UpdateAvailable value)  available,required TResult Function( UpdateDownloadingState value)  downloading,required TResult Function( UpdateInstallFailedState value)  installFailed,}){
final _that = this;
switch (_that) {
case UpdateIdle():
return idle(_that);case UpdateChecking():
return checking(_that);case UpdateUpToDate():
return upToDate(_that);case UpdateCheckFailed():
return checkFailed(_that);case UpdateAvailable():
return available(_that);case UpdateDownloadingState():
return downloading(_that);case UpdateInstallFailedState():
return installFailed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UpdateIdle value)?  idle,TResult? Function( UpdateChecking value)?  checking,TResult? Function( UpdateUpToDate value)?  upToDate,TResult? Function( UpdateCheckFailed value)?  checkFailed,TResult? Function( UpdateAvailable value)?  available,TResult? Function( UpdateDownloadingState value)?  downloading,TResult? Function( UpdateInstallFailedState value)?  installFailed,}){
final _that = this;
switch (_that) {
case UpdateIdle() when idle != null:
return idle(_that);case UpdateChecking() when checking != null:
return checking(_that);case UpdateUpToDate() when upToDate != null:
return upToDate(_that);case UpdateCheckFailed() when checkFailed != null:
return checkFailed(_that);case UpdateAvailable() when available != null:
return available(_that);case UpdateDownloadingState() when downloading != null:
return downloading(_that);case UpdateInstallFailedState() when installFailed != null:
return installFailed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  checking,TResult Function()?  upToDate,TResult Function()?  checkFailed,TResult Function( AppRelease release)?  available,TResult Function( AppRelease release,  int percent)?  downloading,TResult Function( AppRelease release)?  installFailed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UpdateIdle() when idle != null:
return idle();case UpdateChecking() when checking != null:
return checking();case UpdateUpToDate() when upToDate != null:
return upToDate();case UpdateCheckFailed() when checkFailed != null:
return checkFailed();case UpdateAvailable() when available != null:
return available(_that.release);case UpdateDownloadingState() when downloading != null:
return downloading(_that.release,_that.percent);case UpdateInstallFailedState() when installFailed != null:
return installFailed(_that.release);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  checking,required TResult Function()  upToDate,required TResult Function()  checkFailed,required TResult Function( AppRelease release)  available,required TResult Function( AppRelease release,  int percent)  downloading,required TResult Function( AppRelease release)  installFailed,}) {final _that = this;
switch (_that) {
case UpdateIdle():
return idle();case UpdateChecking():
return checking();case UpdateUpToDate():
return upToDate();case UpdateCheckFailed():
return checkFailed();case UpdateAvailable():
return available(_that.release);case UpdateDownloadingState():
return downloading(_that.release,_that.percent);case UpdateInstallFailedState():
return installFailed(_that.release);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  checking,TResult? Function()?  upToDate,TResult? Function()?  checkFailed,TResult? Function( AppRelease release)?  available,TResult? Function( AppRelease release,  int percent)?  downloading,TResult? Function( AppRelease release)?  installFailed,}) {final _that = this;
switch (_that) {
case UpdateIdle() when idle != null:
return idle();case UpdateChecking() when checking != null:
return checking();case UpdateUpToDate() when upToDate != null:
return upToDate();case UpdateCheckFailed() when checkFailed != null:
return checkFailed();case UpdateAvailable() when available != null:
return available(_that.release);case UpdateDownloadingState() when downloading != null:
return downloading(_that.release,_that.percent);case UpdateInstallFailedState() when installFailed != null:
return installFailed(_that.release);case _:
  return null;

}
}

}

/// @nodoc


class UpdateIdle with DiagnosticableTreeMixin implements UpdateState {
  const UpdateIdle();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'UpdateState.idle'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'UpdateState.idle()';
}


}




/// @nodoc


class UpdateChecking with DiagnosticableTreeMixin implements UpdateState {
  const UpdateChecking();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'UpdateState.checking'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateChecking);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'UpdateState.checking()';
}


}




/// @nodoc


class UpdateUpToDate with DiagnosticableTreeMixin implements UpdateState {
  const UpdateUpToDate();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'UpdateState.upToDate'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateUpToDate);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'UpdateState.upToDate()';
}


}




/// @nodoc


class UpdateCheckFailed with DiagnosticableTreeMixin implements UpdateState {
  const UpdateCheckFailed();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'UpdateState.checkFailed'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateCheckFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'UpdateState.checkFailed()';
}


}




/// @nodoc


class UpdateAvailable with DiagnosticableTreeMixin implements UpdateState {
  const UpdateAvailable(this.release);
  

 final  AppRelease release;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateAvailableCopyWith<UpdateAvailable> get copyWith => _$UpdateAvailableCopyWithImpl<UpdateAvailable>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'UpdateState.available'))
    ..add(DiagnosticsProperty('release', release));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateAvailable&&(identical(other.release, release) || other.release == release));
}


@override
int get hashCode {
    return Object.hash(runtimeType,release);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'UpdateState.available(release: $release)';
}


}

/// @nodoc
abstract mixin class $UpdateAvailableCopyWith<$Res> implements $UpdateStateCopyWith<$Res> {
  factory $UpdateAvailableCopyWith(UpdateAvailable value, $Res Function(UpdateAvailable) _then) = _$UpdateAvailableCopyWithImpl;
@useResult
$Res call({
 AppRelease release
});


$AppReleaseCopyWith<$Res> get release;

}
/// @nodoc
class _$UpdateAvailableCopyWithImpl<$Res>
    implements $UpdateAvailableCopyWith<$Res> {
  _$UpdateAvailableCopyWithImpl(this._self, this._then);

  final UpdateAvailable _self;
  final $Res Function(UpdateAvailable) _then;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? release = null,}) {
  return _then(UpdateAvailable(
null == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as AppRelease,
  ));
}

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppReleaseCopyWith<$Res> get release {
  
  return $AppReleaseCopyWith<$Res>(_self.release, (value) {
    return _then(_self.copyWith(release: value));
  });
}
}

/// @nodoc


class UpdateDownloadingState with DiagnosticableTreeMixin implements UpdateState {
  const UpdateDownloadingState(this.release, this.percent);
  

 final  AppRelease release;
 final  int percent;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateDownloadingStateCopyWith<UpdateDownloadingState> get copyWith => _$UpdateDownloadingStateCopyWithImpl<UpdateDownloadingState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'UpdateState.downloading'))
    ..add(DiagnosticsProperty('release', release))..add(DiagnosticsProperty('percent', percent));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateDownloadingState&&(identical(other.release, release) || other.release == release)&&(identical(other.percent, percent) || other.percent == percent));
}


@override
int get hashCode {
    return Object.hash(runtimeType,release,percent);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'UpdateState.downloading(release: $release, percent: $percent)';
}


}

/// @nodoc
abstract mixin class $UpdateDownloadingStateCopyWith<$Res> implements $UpdateStateCopyWith<$Res> {
  factory $UpdateDownloadingStateCopyWith(UpdateDownloadingState value, $Res Function(UpdateDownloadingState) _then) = _$UpdateDownloadingStateCopyWithImpl;
@useResult
$Res call({
 AppRelease release, int percent
});


$AppReleaseCopyWith<$Res> get release;

}
/// @nodoc
class _$UpdateDownloadingStateCopyWithImpl<$Res>
    implements $UpdateDownloadingStateCopyWith<$Res> {
  _$UpdateDownloadingStateCopyWithImpl(this._self, this._then);

  final UpdateDownloadingState _self;
  final $Res Function(UpdateDownloadingState) _then;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? release = null,Object? percent = null,}) {
  return _then(UpdateDownloadingState(
null == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as AppRelease,null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppReleaseCopyWith<$Res> get release {
  
  return $AppReleaseCopyWith<$Res>(_self.release, (value) {
    return _then(_self.copyWith(release: value));
  });
}
}

/// @nodoc


class UpdateInstallFailedState with DiagnosticableTreeMixin implements UpdateState {
  const UpdateInstallFailedState(this.release);
  

 final  AppRelease release;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateInstallFailedStateCopyWith<UpdateInstallFailedState> get copyWith => _$UpdateInstallFailedStateCopyWithImpl<UpdateInstallFailedState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'UpdateState.installFailed'))
    ..add(DiagnosticsProperty('release', release));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateInstallFailedState&&(identical(other.release, release) || other.release == release));
}


@override
int get hashCode {
    return Object.hash(runtimeType,release);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'UpdateState.installFailed(release: $release)';
}


}

/// @nodoc
abstract mixin class $UpdateInstallFailedStateCopyWith<$Res> implements $UpdateStateCopyWith<$Res> {
  factory $UpdateInstallFailedStateCopyWith(UpdateInstallFailedState value, $Res Function(UpdateInstallFailedState) _then) = _$UpdateInstallFailedStateCopyWithImpl;
@useResult
$Res call({
 AppRelease release
});


$AppReleaseCopyWith<$Res> get release;

}
/// @nodoc
class _$UpdateInstallFailedStateCopyWithImpl<$Res>
    implements $UpdateInstallFailedStateCopyWith<$Res> {
  _$UpdateInstallFailedStateCopyWithImpl(this._self, this._then);

  final UpdateInstallFailedState _self;
  final $Res Function(UpdateInstallFailedState) _then;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? release = null,}) {
  return _then(UpdateInstallFailedState(
null == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as AppRelease,
  ));
}

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppReleaseCopyWith<$Res> get release {
  
  return $AppReleaseCopyWith<$Res>(_self.release, (value) {
    return _then(_self.copyWith(release: value));
  });
}
}

// dart format on
