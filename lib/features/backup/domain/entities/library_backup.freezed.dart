// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_backup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LibraryBackup {

 List<Bookmark> get bookmarks; List<ReadHistory> get history;
/// Create a copy of LibraryBackup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryBackupCopyWith<LibraryBackup> get copyWith => _$LibraryBackupCopyWithImpl<LibraryBackup>(this as LibraryBackup, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LibraryBackup;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryBackup&&const DeepCollectionEquality().equals(other.bookmarks, _this.bookmarks)&&const DeepCollectionEquality().equals(other.history, _this.history));
}


@override
int get hashCode {
  final _this = this as LibraryBackup;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.bookmarks),const DeepCollectionEquality().hash(_this.history));
}

@override
String toString() {
  final _this = this as LibraryBackup;
  return 'LibraryBackup(bookmarks: ${_this.bookmarks}, history: ${_this.history})';
}


}

/// @nodoc
abstract mixin class $LibraryBackupCopyWith<$Res>  {
  factory $LibraryBackupCopyWith(LibraryBackup value, $Res Function(LibraryBackup) _then) = _$LibraryBackupCopyWithImpl;
@useResult
$Res call({
 List<Bookmark> bookmarks, List<ReadHistory> history
});




}
/// @nodoc
class _$LibraryBackupCopyWithImpl<$Res>
    implements $LibraryBackupCopyWith<$Res> {
  _$LibraryBackupCopyWithImpl(this._self, this._then);

  final LibraryBackup _self;
  final $Res Function(LibraryBackup) _then;

/// Create a copy of LibraryBackup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bookmarks = null,Object? history = null,}) {
  return _then(LibraryBackup(
bookmarks: null == bookmarks ? _self.bookmarks : bookmarks // ignore: cast_nullable_to_non_nullable
as List<Bookmark>,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as List<ReadHistory>,
  ));
}

}


/// Adds pattern-matching-related methods to [LibraryBackup].
extension LibraryBackupPatterns on LibraryBackup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryBackup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryBackup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryBackup value)  $default,){
final _that = this;
switch (_that) {
case _LibraryBackup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryBackup value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryBackup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Bookmark> bookmarks,  List<ReadHistory> history)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryBackup() when $default != null:
return $default(_that.bookmarks,_that.history);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Bookmark> bookmarks,  List<ReadHistory> history)  $default,) {final _that = this;
switch (_that) {
case _LibraryBackup():
return $default(_that.bookmarks,_that.history);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Bookmark> bookmarks,  List<ReadHistory> history)?  $default,) {final _that = this;
switch (_that) {
case _LibraryBackup() when $default != null:
return $default(_that.bookmarks,_that.history);case _:
  return null;

}
}

}

/// @nodoc


class _LibraryBackup extends LibraryBackup {
  const _LibraryBackup({ List<Bookmark> bookmarks = const [],  List<ReadHistory> history = const []}): _bookmarks = bookmarks,_history = history,super._();
  

 final  List<Bookmark> _bookmarks;
@override@JsonKey() List<Bookmark> get bookmarks {
  if (_bookmarks is EqualUnmodifiableListView) return _bookmarks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bookmarks);
}

 final  List<ReadHistory> _history;
@override@JsonKey() List<ReadHistory> get history {
  if (_history is EqualUnmodifiableListView) return _history;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_history);
}


/// Create a copy of LibraryBackup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryBackupCopyWith<_LibraryBackup> get copyWith => __$LibraryBackupCopyWithImpl<_LibraryBackup>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryBackup&&const DeepCollectionEquality().equals(other.bookmarks, _bookmarks)&&const DeepCollectionEquality().equals(other.history, _history));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_bookmarks),const DeepCollectionEquality().hash(_history));
}

@override
String toString() {
    return 'LibraryBackup(bookmarks: $bookmarks, history: $history)';
}


}

/// @nodoc
abstract mixin class _$LibraryBackupCopyWith<$Res> implements $LibraryBackupCopyWith<$Res> {
  factory _$LibraryBackupCopyWith(_LibraryBackup value, $Res Function(_LibraryBackup) _then) = __$LibraryBackupCopyWithImpl;
@override @useResult
$Res call({
 List<Bookmark> bookmarks, List<ReadHistory> history
});




}
/// @nodoc
class __$LibraryBackupCopyWithImpl<$Res>
    implements _$LibraryBackupCopyWith<$Res> {
  __$LibraryBackupCopyWithImpl(this._self, this._then);

  final _LibraryBackup _self;
  final $Res Function(_LibraryBackup) _then;

/// Create a copy of LibraryBackup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bookmarks = null,Object? history = null,}) {
  return _then(_LibraryBackup(
bookmarks: null == bookmarks ? _self._bookmarks : bookmarks // ignore: cast_nullable_to_non_nullable
as List<Bookmark>,history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<ReadHistory>,
  ));
}


}

// dart format on
