// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SyncState implements DiagnosticableTreeMixin {

/// Signed-in Google account; null when sync is off.
 String? get email; DateTime? get lastSyncedAt; SyncStatus get status;/// Incremented each time sync changed the local library, so library
/// cubits know to reload.
 int get libraryRevision;
/// Create a copy of SyncState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncStateCopyWith<SyncState> get copyWith => _$SyncStateCopyWithImpl<SyncState>(this as SyncState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as SyncState;
  properties
    ..add(DiagnosticsProperty('type', 'SyncState'))
    ..add(DiagnosticsProperty('email', _this.email))..add(DiagnosticsProperty('lastSyncedAt', _this.lastSyncedAt))..add(DiagnosticsProperty('status', _this.status))..add(DiagnosticsProperty('libraryRevision', _this.libraryRevision));
}

@override
bool operator ==(Object other) {
  final _this = this as SyncState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncState&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.lastSyncedAt, _this.lastSyncedAt) || other.lastSyncedAt == _this.lastSyncedAt)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.libraryRevision, _this.libraryRevision) || other.libraryRevision == _this.libraryRevision));
}


@override
int get hashCode {
  final _this = this as SyncState;
  return Object.hash(runtimeType,_this.email,_this.lastSyncedAt,_this.status,_this.libraryRevision);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SyncState;
  return 'SyncState(email: ${_this.email}, lastSyncedAt: ${_this.lastSyncedAt}, status: ${_this.status}, libraryRevision: ${_this.libraryRevision})';
}


}

/// @nodoc
abstract mixin class $SyncStateCopyWith<$Res>  {
  factory $SyncStateCopyWith(SyncState value, $Res Function(SyncState) _then) = _$SyncStateCopyWithImpl;
@useResult
$Res call({
 String? email, DateTime? lastSyncedAt, SyncStatus status, int libraryRevision
});




}
/// @nodoc
class _$SyncStateCopyWithImpl<$Res>
    implements $SyncStateCopyWith<$Res> {
  _$SyncStateCopyWithImpl(this._self, this._then);

  final SyncState _self;
  final $Res Function(SyncState) _then;

/// Create a copy of SyncState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = freezed,Object? lastSyncedAt = freezed,Object? status = null,Object? libraryRevision = null,}) {
  return _then(SyncState(
email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SyncStatus,libraryRevision: null == libraryRevision ? _self.libraryRevision : libraryRevision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncState].
extension SyncStatePatterns on SyncState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncState value)  $default,){
final _that = this;
switch (_that) {
case _SyncState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncState value)?  $default,){
final _that = this;
switch (_that) {
case _SyncState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? email,  DateTime? lastSyncedAt,  SyncStatus status,  int libraryRevision)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncState() when $default != null:
return $default(_that.email,_that.lastSyncedAt,_that.status,_that.libraryRevision);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? email,  DateTime? lastSyncedAt,  SyncStatus status,  int libraryRevision)  $default,) {final _that = this;
switch (_that) {
case _SyncState():
return $default(_that.email,_that.lastSyncedAt,_that.status,_that.libraryRevision);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? email,  DateTime? lastSyncedAt,  SyncStatus status,  int libraryRevision)?  $default,) {final _that = this;
switch (_that) {
case _SyncState() when $default != null:
return $default(_that.email,_that.lastSyncedAt,_that.status,_that.libraryRevision);case _:
  return null;

}
}

}

/// @nodoc


class _SyncState extends SyncState with DiagnosticableTreeMixin {
  const _SyncState({this.email, this.lastSyncedAt, this.status = SyncStatus.idle, this.libraryRevision = 0}): super._();
  

/// Signed-in Google account; null when sync is off.
@override final  String? email;
@override final  DateTime? lastSyncedAt;
@override@JsonKey() final  SyncStatus status;
/// Incremented each time sync changed the local library, so library
/// cubits know to reload.
@override@JsonKey() final  int libraryRevision;

/// Create a copy of SyncState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncStateCopyWith<_SyncState> get copyWith => __$SyncStateCopyWithImpl<_SyncState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SyncState'))
    ..add(DiagnosticsProperty('email', email))..add(DiagnosticsProperty('lastSyncedAt', lastSyncedAt))..add(DiagnosticsProperty('status', status))..add(DiagnosticsProperty('libraryRevision', libraryRevision));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncState&&(identical(other.email, email) || other.email == email)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.libraryRevision, libraryRevision) || other.libraryRevision == libraryRevision));
}


@override
int get hashCode {
    return Object.hash(runtimeType,email,lastSyncedAt,status,libraryRevision);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SyncState(email: $email, lastSyncedAt: $lastSyncedAt, status: $status, libraryRevision: $libraryRevision)';
}


}

/// @nodoc
abstract mixin class _$SyncStateCopyWith<$Res> implements $SyncStateCopyWith<$Res> {
  factory _$SyncStateCopyWith(_SyncState value, $Res Function(_SyncState) _then) = __$SyncStateCopyWithImpl;
@override @useResult
$Res call({
 String? email, DateTime? lastSyncedAt, SyncStatus status, int libraryRevision
});




}
/// @nodoc
class __$SyncStateCopyWithImpl<$Res>
    implements _$SyncStateCopyWith<$Res> {
  __$SyncStateCopyWithImpl(this._self, this._then);

  final _SyncState _self;
  final $Res Function(_SyncState) _then;

/// Create a copy of SyncState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = freezed,Object? lastSyncedAt = freezed,Object? status = null,Object? libraryRevision = null,}) {
  return _then(_SyncState(
email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SyncStatus,libraryRevision: null == libraryRevision ? _self.libraryRevision : libraryRevision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
