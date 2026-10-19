// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reader_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReaderState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ReaderState()';
}


}

/// @nodoc
class $ReaderStateCopyWith<$Res>  {
$ReaderStateCopyWith(ReaderState _, $Res Function(ReaderState) __);
}


/// Adds pattern-matching-related methods to [ReaderState].
extension ReaderStatePatterns on ReaderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReaderInitial value)?  initial,TResult Function( ReaderLoading value)?  loading,TResult Function( ReaderLoaded value)?  loaded,TResult Function( ReaderError value)?  error,TResult Function( ReaderNoInternet value)?  noInternet,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReaderInitial() when initial != null:
return initial(_that);case ReaderLoading() when loading != null:
return loading(_that);case ReaderLoaded() when loaded != null:
return loaded(_that);case ReaderError() when error != null:
return error(_that);case ReaderNoInternet() when noInternet != null:
return noInternet(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReaderInitial value)  initial,required TResult Function( ReaderLoading value)  loading,required TResult Function( ReaderLoaded value)  loaded,required TResult Function( ReaderError value)  error,required TResult Function( ReaderNoInternet value)  noInternet,}){
final _that = this;
switch (_that) {
case ReaderInitial():
return initial(_that);case ReaderLoading():
return loading(_that);case ReaderLoaded():
return loaded(_that);case ReaderError():
return error(_that);case ReaderNoInternet():
return noInternet(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReaderInitial value)?  initial,TResult? Function( ReaderLoading value)?  loading,TResult? Function( ReaderLoaded value)?  loaded,TResult? Function( ReaderError value)?  error,TResult? Function( ReaderNoInternet value)?  noInternet,}){
final _that = this;
switch (_that) {
case ReaderInitial() when initial != null:
return initial(_that);case ReaderLoading() when loading != null:
return loading(_that);case ReaderLoaded() when loaded != null:
return loaded(_that);case ReaderError() when error != null:
return error(_that);case ReaderNoInternet() when noInternet != null:
return noInternet(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( ChapterContent chapter)?  loaded,TResult Function( String message)?  error,TResult Function()?  noInternet,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReaderInitial() when initial != null:
return initial();case ReaderLoading() when loading != null:
return loading();case ReaderLoaded() when loaded != null:
return loaded(_that.chapter);case ReaderError() when error != null:
return error(_that.message);case ReaderNoInternet() when noInternet != null:
return noInternet();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( ChapterContent chapter)  loaded,required TResult Function( String message)  error,required TResult Function()  noInternet,}) {final _that = this;
switch (_that) {
case ReaderInitial():
return initial();case ReaderLoading():
return loading();case ReaderLoaded():
return loaded(_that.chapter);case ReaderError():
return error(_that.message);case ReaderNoInternet():
return noInternet();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( ChapterContent chapter)?  loaded,TResult? Function( String message)?  error,TResult? Function()?  noInternet,}) {final _that = this;
switch (_that) {
case ReaderInitial() when initial != null:
return initial();case ReaderLoading() when loading != null:
return loading();case ReaderLoaded() when loaded != null:
return loaded(_that.chapter);case ReaderError() when error != null:
return error(_that.message);case ReaderNoInternet() when noInternet != null:
return noInternet();case _:
  return null;

}
}

}

/// @nodoc


class ReaderInitial implements ReaderState {
  const ReaderInitial();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ReaderState.initial()';
}


}




/// @nodoc


class ReaderLoading implements ReaderState {
  const ReaderLoading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ReaderState.loading()';
}


}




/// @nodoc


class ReaderLoaded implements ReaderState {
  const ReaderLoaded({required this.chapter});
  

 final  ChapterContent chapter;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReaderLoadedCopyWith<ReaderLoaded> get copyWith => _$ReaderLoadedCopyWithImpl<ReaderLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderLoaded&&(identical(other.chapter, chapter) || other.chapter == chapter));
}


@override
int get hashCode {
    return Object.hash(runtimeType,chapter);
}

@override
String toString() {
    return 'ReaderState.loaded(chapter: $chapter)';
}


}

/// @nodoc
abstract mixin class $ReaderLoadedCopyWith<$Res> implements $ReaderStateCopyWith<$Res> {
  factory $ReaderLoadedCopyWith(ReaderLoaded value, $Res Function(ReaderLoaded) _then) = _$ReaderLoadedCopyWithImpl;
@useResult
$Res call({
 ChapterContent chapter
});


$ChapterContentCopyWith<$Res> get chapter;

}
/// @nodoc
class _$ReaderLoadedCopyWithImpl<$Res>
    implements $ReaderLoadedCopyWith<$Res> {
  _$ReaderLoadedCopyWithImpl(this._self, this._then);

  final ReaderLoaded _self;
  final $Res Function(ReaderLoaded) _then;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? chapter = null,}) {
  return _then(ReaderLoaded(
chapter: null == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as ChapterContent,
  ));
}

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChapterContentCopyWith<$Res> get chapter {
  
  return $ChapterContentCopyWith<$Res>(_self.chapter, (value) {
    return _then(_self.copyWith(chapter: value));
  });
}
}

/// @nodoc


class ReaderError implements ReaderState {
  const ReaderError({required this.message});
  

 final  String message;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReaderErrorCopyWith<ReaderError> get copyWith => _$ReaderErrorCopyWithImpl<ReaderError>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'ReaderState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ReaderErrorCopyWith<$Res> implements $ReaderStateCopyWith<$Res> {
  factory $ReaderErrorCopyWith(ReaderError value, $Res Function(ReaderError) _then) = _$ReaderErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ReaderErrorCopyWithImpl<$Res>
    implements $ReaderErrorCopyWith<$Res> {
  _$ReaderErrorCopyWithImpl(this._self, this._then);

  final ReaderError _self;
  final $Res Function(ReaderError) _then;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ReaderError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ReaderNoInternet implements ReaderState {
  const ReaderNoInternet();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderNoInternet);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ReaderState.noInternet()';
}


}




// dart format on
