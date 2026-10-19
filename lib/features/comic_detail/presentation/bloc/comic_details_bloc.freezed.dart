// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_details_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ComicDetailsState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicDetailsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ComicDetailsState()';
}


}

/// @nodoc
class $ComicDetailsStateCopyWith<$Res>  {
$ComicDetailsStateCopyWith(ComicDetailsState _, $Res Function(ComicDetailsState) __);
}


/// Adds pattern-matching-related methods to [ComicDetailsState].
extension ComicDetailsStatePatterns on ComicDetailsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ComicDetailsInitial value)?  initial,TResult Function( ComicDetailsLoading value)?  loading,TResult Function( ComicDetailsLoaded value)?  loaded,TResult Function( ComicDetailsError value)?  error,TResult Function( ComicDetailsNoInternet value)?  noInternet,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ComicDetailsInitial() when initial != null:
return initial(_that);case ComicDetailsLoading() when loading != null:
return loading(_that);case ComicDetailsLoaded() when loaded != null:
return loaded(_that);case ComicDetailsError() when error != null:
return error(_that);case ComicDetailsNoInternet() when noInternet != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ComicDetailsInitial value)  initial,required TResult Function( ComicDetailsLoading value)  loading,required TResult Function( ComicDetailsLoaded value)  loaded,required TResult Function( ComicDetailsError value)  error,required TResult Function( ComicDetailsNoInternet value)  noInternet,}){
final _that = this;
switch (_that) {
case ComicDetailsInitial():
return initial(_that);case ComicDetailsLoading():
return loading(_that);case ComicDetailsLoaded():
return loaded(_that);case ComicDetailsError():
return error(_that);case ComicDetailsNoInternet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ComicDetailsInitial value)?  initial,TResult? Function( ComicDetailsLoading value)?  loading,TResult? Function( ComicDetailsLoaded value)?  loaded,TResult? Function( ComicDetailsError value)?  error,TResult? Function( ComicDetailsNoInternet value)?  noInternet,}){
final _that = this;
switch (_that) {
case ComicDetailsInitial() when initial != null:
return initial(_that);case ComicDetailsLoading() when loading != null:
return loading(_that);case ComicDetailsLoaded() when loaded != null:
return loaded(_that);case ComicDetailsError() when error != null:
return error(_that);case ComicDetailsNoInternet() when noInternet != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( ComicDetails comicDetails)?  loaded,TResult Function( String message)?  error,TResult Function()?  noInternet,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ComicDetailsInitial() when initial != null:
return initial();case ComicDetailsLoading() when loading != null:
return loading();case ComicDetailsLoaded() when loaded != null:
return loaded(_that.comicDetails);case ComicDetailsError() when error != null:
return error(_that.message);case ComicDetailsNoInternet() when noInternet != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( ComicDetails comicDetails)  loaded,required TResult Function( String message)  error,required TResult Function()  noInternet,}) {final _that = this;
switch (_that) {
case ComicDetailsInitial():
return initial();case ComicDetailsLoading():
return loading();case ComicDetailsLoaded():
return loaded(_that.comicDetails);case ComicDetailsError():
return error(_that.message);case ComicDetailsNoInternet():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( ComicDetails comicDetails)?  loaded,TResult? Function( String message)?  error,TResult? Function()?  noInternet,}) {final _that = this;
switch (_that) {
case ComicDetailsInitial() when initial != null:
return initial();case ComicDetailsLoading() when loading != null:
return loading();case ComicDetailsLoaded() when loaded != null:
return loaded(_that.comicDetails);case ComicDetailsError() when error != null:
return error(_that.message);case ComicDetailsNoInternet() when noInternet != null:
return noInternet();case _:
  return null;

}
}

}

/// @nodoc


class ComicDetailsInitial implements ComicDetailsState {
  const ComicDetailsInitial();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicDetailsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ComicDetailsState.initial()';
}


}




/// @nodoc


class ComicDetailsLoading implements ComicDetailsState {
  const ComicDetailsLoading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicDetailsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ComicDetailsState.loading()';
}


}




/// @nodoc


class ComicDetailsLoaded implements ComicDetailsState {
  const ComicDetailsLoaded({required this.comicDetails});
  

 final  ComicDetails comicDetails;

/// Create a copy of ComicDetailsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicDetailsLoadedCopyWith<ComicDetailsLoaded> get copyWith => _$ComicDetailsLoadedCopyWithImpl<ComicDetailsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicDetailsLoaded&&(identical(other.comicDetails, comicDetails) || other.comicDetails == comicDetails));
}


@override
int get hashCode {
    return Object.hash(runtimeType,comicDetails);
}

@override
String toString() {
    return 'ComicDetailsState.loaded(comicDetails: $comicDetails)';
}


}

/// @nodoc
abstract mixin class $ComicDetailsLoadedCopyWith<$Res> implements $ComicDetailsStateCopyWith<$Res> {
  factory $ComicDetailsLoadedCopyWith(ComicDetailsLoaded value, $Res Function(ComicDetailsLoaded) _then) = _$ComicDetailsLoadedCopyWithImpl;
@useResult
$Res call({
 ComicDetails comicDetails
});


$ComicDetailsCopyWith<$Res> get comicDetails;

}
/// @nodoc
class _$ComicDetailsLoadedCopyWithImpl<$Res>
    implements $ComicDetailsLoadedCopyWith<$Res> {
  _$ComicDetailsLoadedCopyWithImpl(this._self, this._then);

  final ComicDetailsLoaded _self;
  final $Res Function(ComicDetailsLoaded) _then;

/// Create a copy of ComicDetailsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? comicDetails = null,}) {
  return _then(ComicDetailsLoaded(
comicDetails: null == comicDetails ? _self.comicDetails : comicDetails // ignore: cast_nullable_to_non_nullable
as ComicDetails,
  ));
}

/// Create a copy of ComicDetailsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicDetailsCopyWith<$Res> get comicDetails {
  
  return $ComicDetailsCopyWith<$Res>(_self.comicDetails, (value) {
    return _then(_self.copyWith(comicDetails: value));
  });
}
}

/// @nodoc


class ComicDetailsError implements ComicDetailsState {
  const ComicDetailsError({required this.message});
  

 final  String message;

/// Create a copy of ComicDetailsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicDetailsErrorCopyWith<ComicDetailsError> get copyWith => _$ComicDetailsErrorCopyWithImpl<ComicDetailsError>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicDetailsError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'ComicDetailsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ComicDetailsErrorCopyWith<$Res> implements $ComicDetailsStateCopyWith<$Res> {
  factory $ComicDetailsErrorCopyWith(ComicDetailsError value, $Res Function(ComicDetailsError) _then) = _$ComicDetailsErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ComicDetailsErrorCopyWithImpl<$Res>
    implements $ComicDetailsErrorCopyWith<$Res> {
  _$ComicDetailsErrorCopyWithImpl(this._self, this._then);

  final ComicDetailsError _self;
  final $Res Function(ComicDetailsError) _then;

/// Create a copy of ComicDetailsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ComicDetailsError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ComicDetailsNoInternet implements ComicDetailsState {
  const ComicDetailsNoInternet();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicDetailsNoInternet);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ComicDetailsState.noInternet()';
}


}




// dart format on
