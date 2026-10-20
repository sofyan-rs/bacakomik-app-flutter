// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'read_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReadHistory {

/// Chapter slug (`seriesSlug/number`), unique per entry.
 String get slug; String get chapterNumber; DateTime get readDate; ComicDetails get comicDetails;/// Series slug.
 String get comicSlug;/// 0-based page last on screen while the chapter is unfinished. Null
/// once the last page was reached, or when marked read from the list.
 int? get page;/// Pages in the chapter, stored with [page].
 int? get pageCount;
/// Create a copy of ReadHistory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadHistoryCopyWith<ReadHistory> get copyWith => _$ReadHistoryCopyWithImpl<ReadHistory>(this as ReadHistory, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReadHistory;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadHistory&&(identical(other.slug, _this.slug) || other.slug == _this.slug)&&(identical(other.chapterNumber, _this.chapterNumber) || other.chapterNumber == _this.chapterNumber)&&(identical(other.readDate, _this.readDate) || other.readDate == _this.readDate)&&(identical(other.comicDetails, _this.comicDetails) || other.comicDetails == _this.comicDetails)&&(identical(other.comicSlug, _this.comicSlug) || other.comicSlug == _this.comicSlug)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.pageCount, _this.pageCount) || other.pageCount == _this.pageCount));
}


@override
int get hashCode {
  final _this = this as ReadHistory;
  return Object.hash(runtimeType,_this.slug,_this.chapterNumber,_this.readDate,_this.comicDetails,_this.comicSlug,_this.page,_this.pageCount);
}

@override
String toString() {
  final _this = this as ReadHistory;
  return 'ReadHistory(slug: ${_this.slug}, chapterNumber: ${_this.chapterNumber}, readDate: ${_this.readDate}, comicDetails: ${_this.comicDetails}, comicSlug: ${_this.comicSlug}, page: ${_this.page}, pageCount: ${_this.pageCount})';
}


}

/// @nodoc
abstract mixin class $ReadHistoryCopyWith<$Res>  {
  factory $ReadHistoryCopyWith(ReadHistory value, $Res Function(ReadHistory) _then) = _$ReadHistoryCopyWithImpl;
@useResult
$Res call({
 String slug, String chapterNumber, DateTime readDate, ComicDetails comicDetails, String comicSlug, int? page, int? pageCount
});


$ComicDetailsCopyWith<$Res> get comicDetails;

}
/// @nodoc
class _$ReadHistoryCopyWithImpl<$Res>
    implements $ReadHistoryCopyWith<$Res> {
  _$ReadHistoryCopyWithImpl(this._self, this._then);

  final ReadHistory _self;
  final $Res Function(ReadHistory) _then;

/// Create a copy of ReadHistory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? chapterNumber = null,Object? readDate = null,Object? comicDetails = null,Object? comicSlug = null,Object? page = freezed,Object? pageCount = freezed,}) {
  return _then(ReadHistory(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,chapterNumber: null == chapterNumber ? _self.chapterNumber : chapterNumber // ignore: cast_nullable_to_non_nullable
as String,readDate: null == readDate ? _self.readDate : readDate // ignore: cast_nullable_to_non_nullable
as DateTime,comicDetails: null == comicDetails ? _self.comicDetails : comicDetails // ignore: cast_nullable_to_non_nullable
as ComicDetails,comicSlug: null == comicSlug ? _self.comicSlug : comicSlug // ignore: cast_nullable_to_non_nullable
as String,page: freezed == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int?,pageCount: freezed == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of ReadHistory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicDetailsCopyWith<$Res> get comicDetails {
  
  return $ComicDetailsCopyWith<$Res>(_self.comicDetails, (value) {
    return _then(_self.copyWith(comicDetails: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReadHistory].
extension ReadHistoryPatterns on ReadHistory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadHistory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadHistory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadHistory value)  $default,){
final _that = this;
switch (_that) {
case _ReadHistory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadHistory value)?  $default,){
final _that = this;
switch (_that) {
case _ReadHistory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  String chapterNumber,  DateTime readDate,  ComicDetails comicDetails,  String comicSlug,  int? page,  int? pageCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadHistory() when $default != null:
return $default(_that.slug,_that.chapterNumber,_that.readDate,_that.comicDetails,_that.comicSlug,_that.page,_that.pageCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  String chapterNumber,  DateTime readDate,  ComicDetails comicDetails,  String comicSlug,  int? page,  int? pageCount)  $default,) {final _that = this;
switch (_that) {
case _ReadHistory():
return $default(_that.slug,_that.chapterNumber,_that.readDate,_that.comicDetails,_that.comicSlug,_that.page,_that.pageCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  String chapterNumber,  DateTime readDate,  ComicDetails comicDetails,  String comicSlug,  int? page,  int? pageCount)?  $default,) {final _that = this;
switch (_that) {
case _ReadHistory() when $default != null:
return $default(_that.slug,_that.chapterNumber,_that.readDate,_that.comicDetails,_that.comicSlug,_that.page,_that.pageCount);case _:
  return null;

}
}

}

/// @nodoc


class _ReadHistory extends ReadHistory {
  const _ReadHistory({required this.slug, required this.chapterNumber, required this.readDate, required this.comicDetails, required this.comicSlug, this.page, this.pageCount}): super._();
  

/// Chapter slug (`seriesSlug/number`), unique per entry.
@override final  String slug;
@override final  String chapterNumber;
@override final  DateTime readDate;
@override final  ComicDetails comicDetails;
/// Series slug.
@override final  String comicSlug;
/// 0-based page last on screen while the chapter is unfinished. Null
/// once the last page was reached, or when marked read from the list.
@override final  int? page;
/// Pages in the chapter, stored with [page].
@override final  int? pageCount;

/// Create a copy of ReadHistory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadHistoryCopyWith<_ReadHistory> get copyWith => __$ReadHistoryCopyWithImpl<_ReadHistory>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadHistory&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.chapterNumber, chapterNumber) || other.chapterNumber == chapterNumber)&&(identical(other.readDate, readDate) || other.readDate == readDate)&&(identical(other.comicDetails, comicDetails) || other.comicDetails == comicDetails)&&(identical(other.comicSlug, comicSlug) || other.comicSlug == comicSlug)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,slug,chapterNumber,readDate,comicDetails,comicSlug,page,pageCount);
}

@override
String toString() {
    return 'ReadHistory(slug: $slug, chapterNumber: $chapterNumber, readDate: $readDate, comicDetails: $comicDetails, comicSlug: $comicSlug, page: $page, pageCount: $pageCount)';
}


}

/// @nodoc
abstract mixin class _$ReadHistoryCopyWith<$Res> implements $ReadHistoryCopyWith<$Res> {
  factory _$ReadHistoryCopyWith(_ReadHistory value, $Res Function(_ReadHistory) _then) = __$ReadHistoryCopyWithImpl;
@override @useResult
$Res call({
 String slug, String chapterNumber, DateTime readDate, ComicDetails comicDetails, String comicSlug, int? page, int? pageCount
});


@override $ComicDetailsCopyWith<$Res> get comicDetails;

}
/// @nodoc
class __$ReadHistoryCopyWithImpl<$Res>
    implements _$ReadHistoryCopyWith<$Res> {
  __$ReadHistoryCopyWithImpl(this._self, this._then);

  final _ReadHistory _self;
  final $Res Function(_ReadHistory) _then;

/// Create a copy of ReadHistory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? chapterNumber = null,Object? readDate = null,Object? comicDetails = null,Object? comicSlug = null,Object? page = freezed,Object? pageCount = freezed,}) {
  return _then(_ReadHistory(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,chapterNumber: null == chapterNumber ? _self.chapterNumber : chapterNumber // ignore: cast_nullable_to_non_nullable
as String,readDate: null == readDate ? _self.readDate : readDate // ignore: cast_nullable_to_non_nullable
as DateTime,comicDetails: null == comicDetails ? _self.comicDetails : comicDetails // ignore: cast_nullable_to_non_nullable
as ComicDetails,comicSlug: null == comicSlug ? _self.comicSlug : comicSlug // ignore: cast_nullable_to_non_nullable
as String,page: freezed == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int?,pageCount: freezed == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of ReadHistory
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
mixin _$ComicLatestHistory {

 String get comicSlug; ComicDetails get comicDetails; ReadHistory get latestHistory;
/// Create a copy of ComicLatestHistory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicLatestHistoryCopyWith<ComicLatestHistory> get copyWith => _$ComicLatestHistoryCopyWithImpl<ComicLatestHistory>(this as ComicLatestHistory, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ComicLatestHistory;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicLatestHistory&&(identical(other.comicSlug, _this.comicSlug) || other.comicSlug == _this.comicSlug)&&(identical(other.comicDetails, _this.comicDetails) || other.comicDetails == _this.comicDetails)&&(identical(other.latestHistory, _this.latestHistory) || other.latestHistory == _this.latestHistory));
}


@override
int get hashCode {
  final _this = this as ComicLatestHistory;
  return Object.hash(runtimeType,_this.comicSlug,_this.comicDetails,_this.latestHistory);
}

@override
String toString() {
  final _this = this as ComicLatestHistory;
  return 'ComicLatestHistory(comicSlug: ${_this.comicSlug}, comicDetails: ${_this.comicDetails}, latestHistory: ${_this.latestHistory})';
}


}

/// @nodoc
abstract mixin class $ComicLatestHistoryCopyWith<$Res>  {
  factory $ComicLatestHistoryCopyWith(ComicLatestHistory value, $Res Function(ComicLatestHistory) _then) = _$ComicLatestHistoryCopyWithImpl;
@useResult
$Res call({
 String comicSlug, ComicDetails comicDetails, ReadHistory latestHistory
});


$ComicDetailsCopyWith<$Res> get comicDetails;$ReadHistoryCopyWith<$Res> get latestHistory;

}
/// @nodoc
class _$ComicLatestHistoryCopyWithImpl<$Res>
    implements $ComicLatestHistoryCopyWith<$Res> {
  _$ComicLatestHistoryCopyWithImpl(this._self, this._then);

  final ComicLatestHistory _self;
  final $Res Function(ComicLatestHistory) _then;

/// Create a copy of ComicLatestHistory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comicSlug = null,Object? comicDetails = null,Object? latestHistory = null,}) {
  return _then(ComicLatestHistory(
comicSlug: null == comicSlug ? _self.comicSlug : comicSlug // ignore: cast_nullable_to_non_nullable
as String,comicDetails: null == comicDetails ? _self.comicDetails : comicDetails // ignore: cast_nullable_to_non_nullable
as ComicDetails,latestHistory: null == latestHistory ? _self.latestHistory : latestHistory // ignore: cast_nullable_to_non_nullable
as ReadHistory,
  ));
}
/// Create a copy of ComicLatestHistory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicDetailsCopyWith<$Res> get comicDetails {
  
  return $ComicDetailsCopyWith<$Res>(_self.comicDetails, (value) {
    return _then(_self.copyWith(comicDetails: value));
  });
}/// Create a copy of ComicLatestHistory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadHistoryCopyWith<$Res> get latestHistory {
  
  return $ReadHistoryCopyWith<$Res>(_self.latestHistory, (value) {
    return _then(_self.copyWith(latestHistory: value));
  });
}
}


/// Adds pattern-matching-related methods to [ComicLatestHistory].
extension ComicLatestHistoryPatterns on ComicLatestHistory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicLatestHistory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicLatestHistory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicLatestHistory value)  $default,){
final _that = this;
switch (_that) {
case _ComicLatestHistory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicLatestHistory value)?  $default,){
final _that = this;
switch (_that) {
case _ComicLatestHistory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String comicSlug,  ComicDetails comicDetails,  ReadHistory latestHistory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicLatestHistory() when $default != null:
return $default(_that.comicSlug,_that.comicDetails,_that.latestHistory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String comicSlug,  ComicDetails comicDetails,  ReadHistory latestHistory)  $default,) {final _that = this;
switch (_that) {
case _ComicLatestHistory():
return $default(_that.comicSlug,_that.comicDetails,_that.latestHistory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String comicSlug,  ComicDetails comicDetails,  ReadHistory latestHistory)?  $default,) {final _that = this;
switch (_that) {
case _ComicLatestHistory() when $default != null:
return $default(_that.comicSlug,_that.comicDetails,_that.latestHistory);case _:
  return null;

}
}

}

/// @nodoc


class _ComicLatestHistory implements ComicLatestHistory {
  const _ComicLatestHistory({required this.comicSlug, required this.comicDetails, required this.latestHistory});
  

@override final  String comicSlug;
@override final  ComicDetails comicDetails;
@override final  ReadHistory latestHistory;

/// Create a copy of ComicLatestHistory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicLatestHistoryCopyWith<_ComicLatestHistory> get copyWith => __$ComicLatestHistoryCopyWithImpl<_ComicLatestHistory>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicLatestHistory&&(identical(other.comicSlug, comicSlug) || other.comicSlug == comicSlug)&&(identical(other.comicDetails, comicDetails) || other.comicDetails == comicDetails)&&(identical(other.latestHistory, latestHistory) || other.latestHistory == latestHistory));
}


@override
int get hashCode {
    return Object.hash(runtimeType,comicSlug,comicDetails,latestHistory);
}

@override
String toString() {
    return 'ComicLatestHistory(comicSlug: $comicSlug, comicDetails: $comicDetails, latestHistory: $latestHistory)';
}


}

/// @nodoc
abstract mixin class _$ComicLatestHistoryCopyWith<$Res> implements $ComicLatestHistoryCopyWith<$Res> {
  factory _$ComicLatestHistoryCopyWith(_ComicLatestHistory value, $Res Function(_ComicLatestHistory) _then) = __$ComicLatestHistoryCopyWithImpl;
@override @useResult
$Res call({
 String comicSlug, ComicDetails comicDetails, ReadHistory latestHistory
});


@override $ComicDetailsCopyWith<$Res> get comicDetails;@override $ReadHistoryCopyWith<$Res> get latestHistory;

}
/// @nodoc
class __$ComicLatestHistoryCopyWithImpl<$Res>
    implements _$ComicLatestHistoryCopyWith<$Res> {
  __$ComicLatestHistoryCopyWithImpl(this._self, this._then);

  final _ComicLatestHistory _self;
  final $Res Function(_ComicLatestHistory) _then;

/// Create a copy of ComicLatestHistory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comicSlug = null,Object? comicDetails = null,Object? latestHistory = null,}) {
  return _then(_ComicLatestHistory(
comicSlug: null == comicSlug ? _self.comicSlug : comicSlug // ignore: cast_nullable_to_non_nullable
as String,comicDetails: null == comicDetails ? _self.comicDetails : comicDetails // ignore: cast_nullable_to_non_nullable
as ComicDetails,latestHistory: null == latestHistory ? _self.latestHistory : latestHistory // ignore: cast_nullable_to_non_nullable
as ReadHistory,
  ));
}

/// Create a copy of ComicLatestHistory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicDetailsCopyWith<$Res> get comicDetails {
  
  return $ComicDetailsCopyWith<$Res>(_self.comicDetails, (value) {
    return _then(_self.copyWith(comicDetails: value));
  });
}/// Create a copy of ComicLatestHistory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadHistoryCopyWith<$Res> get latestHistory {
  
  return $ReadHistoryCopyWith<$Res>(_self.latestHistory, (value) {
    return _then(_self.copyWith(latestHistory: value));
  });
}
}

// dart format on
