// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SyncSnapshot {

 List<Bookmark> get bookmarks; List<ReadHistory> get history;/// Deletion time per bookmark slug.
 Map<String, DateTime> get deletedBookmarks;/// Deletion time per chapter slug.
 Map<String, DateTime> get deletedHistory;
/// Create a copy of SyncSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncSnapshotCopyWith<SyncSnapshot> get copyWith => _$SyncSnapshotCopyWithImpl<SyncSnapshot>(this as SyncSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SyncSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncSnapshot&&const DeepCollectionEquality().equals(other.bookmarks, _this.bookmarks)&&const DeepCollectionEquality().equals(other.history, _this.history)&&const DeepCollectionEquality().equals(other.deletedBookmarks, _this.deletedBookmarks)&&const DeepCollectionEquality().equals(other.deletedHistory, _this.deletedHistory));
}


@override
int get hashCode {
  final _this = this as SyncSnapshot;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.bookmarks),const DeepCollectionEquality().hash(_this.history),const DeepCollectionEquality().hash(_this.deletedBookmarks),const DeepCollectionEquality().hash(_this.deletedHistory));
}

@override
String toString() {
  final _this = this as SyncSnapshot;
  return 'SyncSnapshot(bookmarks: ${_this.bookmarks}, history: ${_this.history}, deletedBookmarks: ${_this.deletedBookmarks}, deletedHistory: ${_this.deletedHistory})';
}


}

/// @nodoc
abstract mixin class $SyncSnapshotCopyWith<$Res>  {
  factory $SyncSnapshotCopyWith(SyncSnapshot value, $Res Function(SyncSnapshot) _then) = _$SyncSnapshotCopyWithImpl;
@useResult
$Res call({
 List<Bookmark> bookmarks, List<ReadHistory> history, Map<String, DateTime> deletedBookmarks, Map<String, DateTime> deletedHistory
});




}
/// @nodoc
class _$SyncSnapshotCopyWithImpl<$Res>
    implements $SyncSnapshotCopyWith<$Res> {
  _$SyncSnapshotCopyWithImpl(this._self, this._then);

  final SyncSnapshot _self;
  final $Res Function(SyncSnapshot) _then;

/// Create a copy of SyncSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bookmarks = null,Object? history = null,Object? deletedBookmarks = null,Object? deletedHistory = null,}) {
  return _then(SyncSnapshot(
bookmarks: null == bookmarks ? _self.bookmarks : bookmarks // ignore: cast_nullable_to_non_nullable
as List<Bookmark>,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as List<ReadHistory>,deletedBookmarks: null == deletedBookmarks ? _self.deletedBookmarks : deletedBookmarks // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,deletedHistory: null == deletedHistory ? _self.deletedHistory : deletedHistory // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncSnapshot].
extension SyncSnapshotPatterns on SyncSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _SyncSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _SyncSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Bookmark> bookmarks,  List<ReadHistory> history,  Map<String, DateTime> deletedBookmarks,  Map<String, DateTime> deletedHistory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncSnapshot() when $default != null:
return $default(_that.bookmarks,_that.history,_that.deletedBookmarks,_that.deletedHistory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Bookmark> bookmarks,  List<ReadHistory> history,  Map<String, DateTime> deletedBookmarks,  Map<String, DateTime> deletedHistory)  $default,) {final _that = this;
switch (_that) {
case _SyncSnapshot():
return $default(_that.bookmarks,_that.history,_that.deletedBookmarks,_that.deletedHistory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Bookmark> bookmarks,  List<ReadHistory> history,  Map<String, DateTime> deletedBookmarks,  Map<String, DateTime> deletedHistory)?  $default,) {final _that = this;
switch (_that) {
case _SyncSnapshot() when $default != null:
return $default(_that.bookmarks,_that.history,_that.deletedBookmarks,_that.deletedHistory);case _:
  return null;

}
}

}

/// @nodoc


class _SyncSnapshot extends SyncSnapshot {
  const _SyncSnapshot({ List<Bookmark> bookmarks = const [],  List<ReadHistory> history = const [],  Map<String, DateTime> deletedBookmarks = const {},  Map<String, DateTime> deletedHistory = const {}}): _bookmarks = bookmarks,_history = history,_deletedBookmarks = deletedBookmarks,_deletedHistory = deletedHistory,super._();
  

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

/// Deletion time per bookmark slug.
 final  Map<String, DateTime> _deletedBookmarks;
/// Deletion time per bookmark slug.
@override@JsonKey() Map<String, DateTime> get deletedBookmarks {
  if (_deletedBookmarks is EqualUnmodifiableMapView) return _deletedBookmarks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_deletedBookmarks);
}

/// Deletion time per chapter slug.
 final  Map<String, DateTime> _deletedHistory;
/// Deletion time per chapter slug.
@override@JsonKey() Map<String, DateTime> get deletedHistory {
  if (_deletedHistory is EqualUnmodifiableMapView) return _deletedHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_deletedHistory);
}


/// Create a copy of SyncSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncSnapshotCopyWith<_SyncSnapshot> get copyWith => __$SyncSnapshotCopyWithImpl<_SyncSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncSnapshot&&const DeepCollectionEquality().equals(other.bookmarks, _bookmarks)&&const DeepCollectionEquality().equals(other.history, _history)&&const DeepCollectionEquality().equals(other.deletedBookmarks, _deletedBookmarks)&&const DeepCollectionEquality().equals(other.deletedHistory, _deletedHistory));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_bookmarks),const DeepCollectionEquality().hash(_history),const DeepCollectionEquality().hash(_deletedBookmarks),const DeepCollectionEquality().hash(_deletedHistory));
}

@override
String toString() {
    return 'SyncSnapshot(bookmarks: $bookmarks, history: $history, deletedBookmarks: $deletedBookmarks, deletedHistory: $deletedHistory)';
}


}

/// @nodoc
abstract mixin class _$SyncSnapshotCopyWith<$Res> implements $SyncSnapshotCopyWith<$Res> {
  factory _$SyncSnapshotCopyWith(_SyncSnapshot value, $Res Function(_SyncSnapshot) _then) = __$SyncSnapshotCopyWithImpl;
@override @useResult
$Res call({
 List<Bookmark> bookmarks, List<ReadHistory> history, Map<String, DateTime> deletedBookmarks, Map<String, DateTime> deletedHistory
});




}
/// @nodoc
class __$SyncSnapshotCopyWithImpl<$Res>
    implements _$SyncSnapshotCopyWith<$Res> {
  __$SyncSnapshotCopyWithImpl(this._self, this._then);

  final _SyncSnapshot _self;
  final $Res Function(_SyncSnapshot) _then;

/// Create a copy of SyncSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bookmarks = null,Object? history = null,Object? deletedBookmarks = null,Object? deletedHistory = null,}) {
  return _then(_SyncSnapshot(
bookmarks: null == bookmarks ? _self._bookmarks : bookmarks // ignore: cast_nullable_to_non_nullable
as List<Bookmark>,history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<ReadHistory>,deletedBookmarks: null == deletedBookmarks ? _self._deletedBookmarks : deletedBookmarks // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,deletedHistory: null == deletedHistory ? _self._deletedHistory : deletedHistory // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,
  ));
}


}

// dart format on
