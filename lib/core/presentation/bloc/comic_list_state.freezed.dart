// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ComicListState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicListState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ComicListState()';
}


}

/// @nodoc
class $ComicListStateCopyWith<$Res>  {
$ComicListStateCopyWith(ComicListState _, $Res Function(ComicListState) __);
}


/// Adds pattern-matching-related methods to [ComicListState].
extension ComicListStatePatterns on ComicListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ComicListInitial value)?  initial,TResult Function( ComicListLoading value)?  loading,TResult Function( ComicListLoaded value)?  loaded,TResult Function( ComicListError value)?  error,TResult Function( ComicListNoInternet value)?  noInternet,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ComicListInitial() when initial != null:
return initial(_that);case ComicListLoading() when loading != null:
return loading(_that);case ComicListLoaded() when loaded != null:
return loaded(_that);case ComicListError() when error != null:
return error(_that);case ComicListNoInternet() when noInternet != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ComicListInitial value)  initial,required TResult Function( ComicListLoading value)  loading,required TResult Function( ComicListLoaded value)  loaded,required TResult Function( ComicListError value)  error,required TResult Function( ComicListNoInternet value)  noInternet,}){
final _that = this;
switch (_that) {
case ComicListInitial():
return initial(_that);case ComicListLoading():
return loading(_that);case ComicListLoaded():
return loaded(_that);case ComicListError():
return error(_that);case ComicListNoInternet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ComicListInitial value)?  initial,TResult? Function( ComicListLoading value)?  loading,TResult? Function( ComicListLoaded value)?  loaded,TResult? Function( ComicListError value)?  error,TResult? Function( ComicListNoInternet value)?  noInternet,}){
final _that = this;
switch (_that) {
case ComicListInitial() when initial != null:
return initial(_that);case ComicListLoading() when loading != null:
return loading(_that);case ComicListLoaded() when loaded != null:
return loaded(_that);case ComicListError() when error != null:
return error(_that);case ComicListNoInternet() when noInternet != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Comic> comics,  bool isLoadMore)?  loaded,TResult Function( String message)?  error,TResult Function()?  noInternet,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ComicListInitial() when initial != null:
return initial();case ComicListLoading() when loading != null:
return loading();case ComicListLoaded() when loaded != null:
return loaded(_that.comics,_that.isLoadMore);case ComicListError() when error != null:
return error(_that.message);case ComicListNoInternet() when noInternet != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Comic> comics,  bool isLoadMore)  loaded,required TResult Function( String message)  error,required TResult Function()  noInternet,}) {final _that = this;
switch (_that) {
case ComicListInitial():
return initial();case ComicListLoading():
return loading();case ComicListLoaded():
return loaded(_that.comics,_that.isLoadMore);case ComicListError():
return error(_that.message);case ComicListNoInternet():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Comic> comics,  bool isLoadMore)?  loaded,TResult? Function( String message)?  error,TResult? Function()?  noInternet,}) {final _that = this;
switch (_that) {
case ComicListInitial() when initial != null:
return initial();case ComicListLoading() when loading != null:
return loading();case ComicListLoaded() when loaded != null:
return loaded(_that.comics,_that.isLoadMore);case ComicListError() when error != null:
return error(_that.message);case ComicListNoInternet() when noInternet != null:
return noInternet();case _:
  return null;

}
}

}

/// @nodoc


class ComicListInitial implements ComicListState {
  const ComicListInitial();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicListInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ComicListState.initial()';
}


}




/// @nodoc


class ComicListLoading implements ComicListState {
  const ComicListLoading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicListLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ComicListState.loading()';
}


}




/// @nodoc


class ComicListLoaded implements ComicListState {
  const ComicListLoaded({required  List<Comic> comics, this.isLoadMore = false}): _comics = comics;
  

 final  List<Comic> _comics;
 List<Comic> get comics {
  if (_comics is EqualUnmodifiableListView) return _comics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_comics);
}

@JsonKey() final  bool isLoadMore;

/// Create a copy of ComicListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicListLoadedCopyWith<ComicListLoaded> get copyWith => _$ComicListLoadedCopyWithImpl<ComicListLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicListLoaded&&const DeepCollectionEquality().equals(other.comics, _comics)&&(identical(other.isLoadMore, isLoadMore) || other.isLoadMore == isLoadMore));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_comics),isLoadMore);
}

@override
String toString() {
    return 'ComicListState.loaded(comics: $comics, isLoadMore: $isLoadMore)';
}


}

/// @nodoc
abstract mixin class $ComicListLoadedCopyWith<$Res> implements $ComicListStateCopyWith<$Res> {
  factory $ComicListLoadedCopyWith(ComicListLoaded value, $Res Function(ComicListLoaded) _then) = _$ComicListLoadedCopyWithImpl;
@useResult
$Res call({
 List<Comic> comics, bool isLoadMore
});




}
/// @nodoc
class _$ComicListLoadedCopyWithImpl<$Res>
    implements $ComicListLoadedCopyWith<$Res> {
  _$ComicListLoadedCopyWithImpl(this._self, this._then);

  final ComicListLoaded _self;
  final $Res Function(ComicListLoaded) _then;

/// Create a copy of ComicListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? comics = null,Object? isLoadMore = null,}) {
  return _then(ComicListLoaded(
comics: null == comics ? _self._comics : comics // ignore: cast_nullable_to_non_nullable
as List<Comic>,isLoadMore: null == isLoadMore ? _self.isLoadMore : isLoadMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class ComicListError implements ComicListState {
  const ComicListError({required this.message});
  

 final  String message;

/// Create a copy of ComicListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicListErrorCopyWith<ComicListError> get copyWith => _$ComicListErrorCopyWithImpl<ComicListError>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicListError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'ComicListState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ComicListErrorCopyWith<$Res> implements $ComicListStateCopyWith<$Res> {
  factory $ComicListErrorCopyWith(ComicListError value, $Res Function(ComicListError) _then) = _$ComicListErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ComicListErrorCopyWithImpl<$Res>
    implements $ComicListErrorCopyWith<$Res> {
  _$ComicListErrorCopyWithImpl(this._self, this._then);

  final ComicListError _self;
  final $Res Function(ComicListError) _then;

/// Create a copy of ComicListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ComicListError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ComicListNoInternet implements ComicListState {
  const ComicListNoInternet();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicListNoInternet);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ComicListState.noInternet()';
}


}




// dart format on
