// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BackupState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'BackupState'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'BackupState()';
}


}

/// @nodoc
class $BackupStateCopyWith<$Res>  {
$BackupStateCopyWith(BackupState _, $Res Function(BackupState) __);
}


/// Adds pattern-matching-related methods to [BackupState].
extension BackupStatePatterns on BackupState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BackupIdle value)?  idle,TResult Function( BackupBusy value)?  busy,TResult Function( BackupSaved value)?  backupSaved,TResult Function( BackupFailed value)?  backupFailed,TResult Function( BackupRestored value)?  restored,TResult Function( BackupRestoreFailed value)?  restoreFailed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BackupIdle() when idle != null:
return idle(_that);case BackupBusy() when busy != null:
return busy(_that);case BackupSaved() when backupSaved != null:
return backupSaved(_that);case BackupFailed() when backupFailed != null:
return backupFailed(_that);case BackupRestored() when restored != null:
return restored(_that);case BackupRestoreFailed() when restoreFailed != null:
return restoreFailed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BackupIdle value)  idle,required TResult Function( BackupBusy value)  busy,required TResult Function( BackupSaved value)  backupSaved,required TResult Function( BackupFailed value)  backupFailed,required TResult Function( BackupRestored value)  restored,required TResult Function( BackupRestoreFailed value)  restoreFailed,}){
final _that = this;
switch (_that) {
case BackupIdle():
return idle(_that);case BackupBusy():
return busy(_that);case BackupSaved():
return backupSaved(_that);case BackupFailed():
return backupFailed(_that);case BackupRestored():
return restored(_that);case BackupRestoreFailed():
return restoreFailed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BackupIdle value)?  idle,TResult? Function( BackupBusy value)?  busy,TResult? Function( BackupSaved value)?  backupSaved,TResult? Function( BackupFailed value)?  backupFailed,TResult? Function( BackupRestored value)?  restored,TResult? Function( BackupRestoreFailed value)?  restoreFailed,}){
final _that = this;
switch (_that) {
case BackupIdle() when idle != null:
return idle(_that);case BackupBusy() when busy != null:
return busy(_that);case BackupSaved() when backupSaved != null:
return backupSaved(_that);case BackupFailed() when backupFailed != null:
return backupFailed(_that);case BackupRestored() when restored != null:
return restored(_that);case BackupRestoreFailed() when restoreFailed != null:
return restoreFailed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  busy,TResult Function()?  backupSaved,TResult Function()?  backupFailed,TResult Function()?  restored,TResult Function()?  restoreFailed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BackupIdle() when idle != null:
return idle();case BackupBusy() when busy != null:
return busy();case BackupSaved() when backupSaved != null:
return backupSaved();case BackupFailed() when backupFailed != null:
return backupFailed();case BackupRestored() when restored != null:
return restored();case BackupRestoreFailed() when restoreFailed != null:
return restoreFailed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  busy,required TResult Function()  backupSaved,required TResult Function()  backupFailed,required TResult Function()  restored,required TResult Function()  restoreFailed,}) {final _that = this;
switch (_that) {
case BackupIdle():
return idle();case BackupBusy():
return busy();case BackupSaved():
return backupSaved();case BackupFailed():
return backupFailed();case BackupRestored():
return restored();case BackupRestoreFailed():
return restoreFailed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  busy,TResult? Function()?  backupSaved,TResult? Function()?  backupFailed,TResult? Function()?  restored,TResult? Function()?  restoreFailed,}) {final _that = this;
switch (_that) {
case BackupIdle() when idle != null:
return idle();case BackupBusy() when busy != null:
return busy();case BackupSaved() when backupSaved != null:
return backupSaved();case BackupFailed() when backupFailed != null:
return backupFailed();case BackupRestored() when restored != null:
return restored();case BackupRestoreFailed() when restoreFailed != null:
return restoreFailed();case _:
  return null;

}
}

}

/// @nodoc


class BackupIdle with DiagnosticableTreeMixin implements BackupState {
  const BackupIdle();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'BackupState.idle'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'BackupState.idle()';
}


}




/// @nodoc


class BackupBusy with DiagnosticableTreeMixin implements BackupState {
  const BackupBusy();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'BackupState.busy'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupBusy);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'BackupState.busy()';
}


}




/// @nodoc


class BackupSaved with DiagnosticableTreeMixin implements BackupState {
  const BackupSaved();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'BackupState.backupSaved'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupSaved);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'BackupState.backupSaved()';
}


}




/// @nodoc


class BackupFailed with DiagnosticableTreeMixin implements BackupState {
  const BackupFailed();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'BackupState.backupFailed'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'BackupState.backupFailed()';
}


}




/// @nodoc


class BackupRestored with DiagnosticableTreeMixin implements BackupState {
  const BackupRestored();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'BackupState.restored'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupRestored);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'BackupState.restored()';
}


}




/// @nodoc


class BackupRestoreFailed with DiagnosticableTreeMixin implements BackupState {
  const BackupRestoreFailed();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'BackupState.restoreFailed'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupRestoreFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'BackupState.restoreFailed()';
}


}




// dart format on
