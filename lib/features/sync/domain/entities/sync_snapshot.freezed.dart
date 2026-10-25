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
 Map<String, DateTime> get deletedHistory; List<LibraryCategory> get categories; List<ComicCategories> get comicCategories;/// Deletion time per category id.
 Map<String, DateTime> get deletedCategories;/// When a deleted bookmark was saved again, per slug ([merge]).
 Map<String, DateTime> get savedBookmarks;/// When a deleted history entry was saved again, per chapter slug.
 Map<String, DateTime> get savedHistory;/// When a deleted category was saved again, per id.
 Map<String, DateTime> get savedCategories;
/// Create a copy of SyncSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncSnapshotCopyWith<SyncSnapshot> get copyWith => _$SyncSnapshotCopyWithImpl<SyncSnapshot>(this as SyncSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SyncSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncSnapshot&&const DeepCollectionEquality().equals(other.bookmarks, _this.bookmarks)&&const DeepCollectionEquality().equals(other.history, _this.history)&&const DeepCollectionEquality().equals(other.deletedBookmarks, _this.deletedBookmarks)&&const DeepCollectionEquality().equals(other.deletedHistory, _this.deletedHistory)&&const DeepCollectionEquality().equals(other.categories, _this.categories)&&const DeepCollectionEquality().equals(other.comicCategories, _this.comicCategories)&&const DeepCollectionEquality().equals(other.deletedCategories, _this.deletedCategories)&&const DeepCollectionEquality().equals(other.savedBookmarks, _this.savedBookmarks)&&const DeepCollectionEquality().equals(other.savedHistory, _this.savedHistory)&&const DeepCollectionEquality().equals(other.savedCategories, _this.savedCategories));
}


@override
int get hashCode {
  final _this = this as SyncSnapshot;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.bookmarks),const DeepCollectionEquality().hash(_this.history),const DeepCollectionEquality().hash(_this.deletedBookmarks),const DeepCollectionEquality().hash(_this.deletedHistory),const DeepCollectionEquality().hash(_this.categories),const DeepCollectionEquality().hash(_this.comicCategories),const DeepCollectionEquality().hash(_this.deletedCategories),const DeepCollectionEquality().hash(_this.savedBookmarks),const DeepCollectionEquality().hash(_this.savedHistory),const DeepCollectionEquality().hash(_this.savedCategories));
}

@override
String toString() {
  final _this = this as SyncSnapshot;
  return 'SyncSnapshot(bookmarks: ${_this.bookmarks}, history: ${_this.history}, deletedBookmarks: ${_this.deletedBookmarks}, deletedHistory: ${_this.deletedHistory}, categories: ${_this.categories}, comicCategories: ${_this.comicCategories}, deletedCategories: ${_this.deletedCategories}, savedBookmarks: ${_this.savedBookmarks}, savedHistory: ${_this.savedHistory}, savedCategories: ${_this.savedCategories})';
}


}

/// @nodoc
abstract mixin class $SyncSnapshotCopyWith<$Res>  {
  factory $SyncSnapshotCopyWith(SyncSnapshot value, $Res Function(SyncSnapshot) _then) = _$SyncSnapshotCopyWithImpl;
@useResult
$Res call({
 List<Bookmark> bookmarks, List<ReadHistory> history, Map<String, DateTime> deletedBookmarks, Map<String, DateTime> deletedHistory, List<LibraryCategory> categories, List<ComicCategories> comicCategories, Map<String, DateTime> deletedCategories, Map<String, DateTime> savedBookmarks, Map<String, DateTime> savedHistory, Map<String, DateTime> savedCategories
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
@pragma('vm:prefer-inline') @override $Res call({Object? bookmarks = null,Object? history = null,Object? deletedBookmarks = null,Object? deletedHistory = null,Object? categories = null,Object? comicCategories = null,Object? deletedCategories = null,Object? savedBookmarks = null,Object? savedHistory = null,Object? savedCategories = null,}) {
  return _then(SyncSnapshot(
bookmarks: null == bookmarks ? _self.bookmarks : bookmarks // ignore: cast_nullable_to_non_nullable
as List<Bookmark>,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as List<ReadHistory>,deletedBookmarks: null == deletedBookmarks ? _self.deletedBookmarks : deletedBookmarks // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,deletedHistory: null == deletedHistory ? _self.deletedHistory : deletedHistory // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<LibraryCategory>,comicCategories: null == comicCategories ? _self.comicCategories : comicCategories // ignore: cast_nullable_to_non_nullable
as List<ComicCategories>,deletedCategories: null == deletedCategories ? _self.deletedCategories : deletedCategories // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,savedBookmarks: null == savedBookmarks ? _self.savedBookmarks : savedBookmarks // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,savedHistory: null == savedHistory ? _self.savedHistory : savedHistory // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,savedCategories: null == savedCategories ? _self.savedCategories : savedCategories // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Bookmark> bookmarks,  List<ReadHistory> history,  Map<String, DateTime> deletedBookmarks,  Map<String, DateTime> deletedHistory,  List<LibraryCategory> categories,  List<ComicCategories> comicCategories,  Map<String, DateTime> deletedCategories,  Map<String, DateTime> savedBookmarks,  Map<String, DateTime> savedHistory,  Map<String, DateTime> savedCategories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncSnapshot() when $default != null:
return $default(_that.bookmarks,_that.history,_that.deletedBookmarks,_that.deletedHistory,_that.categories,_that.comicCategories,_that.deletedCategories,_that.savedBookmarks,_that.savedHistory,_that.savedCategories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Bookmark> bookmarks,  List<ReadHistory> history,  Map<String, DateTime> deletedBookmarks,  Map<String, DateTime> deletedHistory,  List<LibraryCategory> categories,  List<ComicCategories> comicCategories,  Map<String, DateTime> deletedCategories,  Map<String, DateTime> savedBookmarks,  Map<String, DateTime> savedHistory,  Map<String, DateTime> savedCategories)  $default,) {final _that = this;
switch (_that) {
case _SyncSnapshot():
return $default(_that.bookmarks,_that.history,_that.deletedBookmarks,_that.deletedHistory,_that.categories,_that.comicCategories,_that.deletedCategories,_that.savedBookmarks,_that.savedHistory,_that.savedCategories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Bookmark> bookmarks,  List<ReadHistory> history,  Map<String, DateTime> deletedBookmarks,  Map<String, DateTime> deletedHistory,  List<LibraryCategory> categories,  List<ComicCategories> comicCategories,  Map<String, DateTime> deletedCategories,  Map<String, DateTime> savedBookmarks,  Map<String, DateTime> savedHistory,  Map<String, DateTime> savedCategories)?  $default,) {final _that = this;
switch (_that) {
case _SyncSnapshot() when $default != null:
return $default(_that.bookmarks,_that.history,_that.deletedBookmarks,_that.deletedHistory,_that.categories,_that.comicCategories,_that.deletedCategories,_that.savedBookmarks,_that.savedHistory,_that.savedCategories);case _:
  return null;

}
}

}

/// @nodoc


class _SyncSnapshot extends SyncSnapshot {
  const _SyncSnapshot({ List<Bookmark> bookmarks = const [],  List<ReadHistory> history = const [],  Map<String, DateTime> deletedBookmarks = const {},  Map<String, DateTime> deletedHistory = const {},  List<LibraryCategory> categories = const [],  List<ComicCategories> comicCategories = const [],  Map<String, DateTime> deletedCategories = const {},  Map<String, DateTime> savedBookmarks = const {},  Map<String, DateTime> savedHistory = const {},  Map<String, DateTime> savedCategories = const {}}): _bookmarks = bookmarks,_history = history,_deletedBookmarks = deletedBookmarks,_deletedHistory = deletedHistory,_categories = categories,_comicCategories = comicCategories,_deletedCategories = deletedCategories,_savedBookmarks = savedBookmarks,_savedHistory = savedHistory,_savedCategories = savedCategories,super._();
  

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

 final  List<LibraryCategory> _categories;
@override@JsonKey() List<LibraryCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<ComicCategories> _comicCategories;
@override@JsonKey() List<ComicCategories> get comicCategories {
  if (_comicCategories is EqualUnmodifiableListView) return _comicCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_comicCategories);
}

/// Deletion time per category id.
 final  Map<String, DateTime> _deletedCategories;
/// Deletion time per category id.
@override@JsonKey() Map<String, DateTime> get deletedCategories {
  if (_deletedCategories is EqualUnmodifiableMapView) return _deletedCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_deletedCategories);
}

/// When a deleted bookmark was saved again, per slug ([merge]).
 final  Map<String, DateTime> _savedBookmarks;
/// When a deleted bookmark was saved again, per slug ([merge]).
@override@JsonKey() Map<String, DateTime> get savedBookmarks {
  if (_savedBookmarks is EqualUnmodifiableMapView) return _savedBookmarks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_savedBookmarks);
}

/// When a deleted history entry was saved again, per chapter slug.
 final  Map<String, DateTime> _savedHistory;
/// When a deleted history entry was saved again, per chapter slug.
@override@JsonKey() Map<String, DateTime> get savedHistory {
  if (_savedHistory is EqualUnmodifiableMapView) return _savedHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_savedHistory);
}

/// When a deleted category was saved again, per id.
 final  Map<String, DateTime> _savedCategories;
/// When a deleted category was saved again, per id.
@override@JsonKey() Map<String, DateTime> get savedCategories {
  if (_savedCategories is EqualUnmodifiableMapView) return _savedCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_savedCategories);
}


/// Create a copy of SyncSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncSnapshotCopyWith<_SyncSnapshot> get copyWith => __$SyncSnapshotCopyWithImpl<_SyncSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncSnapshot&&const DeepCollectionEquality().equals(other.bookmarks, _bookmarks)&&const DeepCollectionEquality().equals(other.history, _history)&&const DeepCollectionEquality().equals(other.deletedBookmarks, _deletedBookmarks)&&const DeepCollectionEquality().equals(other.deletedHistory, _deletedHistory)&&const DeepCollectionEquality().equals(other.categories, _categories)&&const DeepCollectionEquality().equals(other.comicCategories, _comicCategories)&&const DeepCollectionEquality().equals(other.deletedCategories, _deletedCategories)&&const DeepCollectionEquality().equals(other.savedBookmarks, _savedBookmarks)&&const DeepCollectionEquality().equals(other.savedHistory, _savedHistory)&&const DeepCollectionEquality().equals(other.savedCategories, _savedCategories));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_bookmarks),const DeepCollectionEquality().hash(_history),const DeepCollectionEquality().hash(_deletedBookmarks),const DeepCollectionEquality().hash(_deletedHistory),const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_comicCategories),const DeepCollectionEquality().hash(_deletedCategories),const DeepCollectionEquality().hash(_savedBookmarks),const DeepCollectionEquality().hash(_savedHistory),const DeepCollectionEquality().hash(_savedCategories));
}

@override
String toString() {
    return 'SyncSnapshot(bookmarks: $bookmarks, history: $history, deletedBookmarks: $deletedBookmarks, deletedHistory: $deletedHistory, categories: $categories, comicCategories: $comicCategories, deletedCategories: $deletedCategories, savedBookmarks: $savedBookmarks, savedHistory: $savedHistory, savedCategories: $savedCategories)';
}


}

/// @nodoc
abstract mixin class _$SyncSnapshotCopyWith<$Res> implements $SyncSnapshotCopyWith<$Res> {
  factory _$SyncSnapshotCopyWith(_SyncSnapshot value, $Res Function(_SyncSnapshot) _then) = __$SyncSnapshotCopyWithImpl;
@override @useResult
$Res call({
 List<Bookmark> bookmarks, List<ReadHistory> history, Map<String, DateTime> deletedBookmarks, Map<String, DateTime> deletedHistory, List<LibraryCategory> categories, List<ComicCategories> comicCategories, Map<String, DateTime> deletedCategories, Map<String, DateTime> savedBookmarks, Map<String, DateTime> savedHistory, Map<String, DateTime> savedCategories
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
@override @pragma('vm:prefer-inline') $Res call({Object? bookmarks = null,Object? history = null,Object? deletedBookmarks = null,Object? deletedHistory = null,Object? categories = null,Object? comicCategories = null,Object? deletedCategories = null,Object? savedBookmarks = null,Object? savedHistory = null,Object? savedCategories = null,}) {
  return _then(_SyncSnapshot(
bookmarks: null == bookmarks ? _self._bookmarks : bookmarks // ignore: cast_nullable_to_non_nullable
as List<Bookmark>,history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<ReadHistory>,deletedBookmarks: null == deletedBookmarks ? _self._deletedBookmarks : deletedBookmarks // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,deletedHistory: null == deletedHistory ? _self._deletedHistory : deletedHistory // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<LibraryCategory>,comicCategories: null == comicCategories ? _self._comicCategories : comicCategories // ignore: cast_nullable_to_non_nullable
as List<ComicCategories>,deletedCategories: null == deletedCategories ? _self._deletedCategories : deletedCategories // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,savedBookmarks: null == savedBookmarks ? _self._savedBookmarks : savedBookmarks // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,savedHistory: null == savedHistory ? _self._savedHistory : savedHistory // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,savedCategories: null == savedCategories ? _self._savedCategories : savedCategories // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,
  ));
}


}

// dart format on
