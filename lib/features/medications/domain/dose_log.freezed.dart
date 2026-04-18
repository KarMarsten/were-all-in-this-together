// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dose_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DoseLog {

 String get id; String get personId; String get medicationId;/// The wall-clock time the dose was due, converted to UTC. Part of
/// the log's composite identity.
 DateTime get scheduledAt;/// When the user tapped Taken / Skipped, in UTC. Used for sort
/// stability and — Phase 2 — adherence reports.
 DateTime get loggedAt; DoseOutcome get outcome; DateTime get createdAt; DateTime get updatedAt;/// Optional free-text note, e.g. "took 15 min late, with dinner".
/// Empty / whitespace-only notes are stored as null by the repo.
 String? get note;/// Tombstone. Set when the user taps Undo on a previously-logged
/// dose. Kept rather than hard-deleting so Phase 2 sync is
/// symmetric with every other table.
 DateTime? get deletedAt; int get rowVersion; String? get lastWriterDeviceId; int get keyVersion;
/// Create a copy of DoseLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DoseLogCopyWith<DoseLog> get copyWith => _$DoseLogCopyWithImpl<DoseLog>(this as DoseLog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DoseLog&&(identical(other.id, id) || other.id == id)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.medicationId, medicationId) || other.medicationId == medicationId)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.loggedAt, loggedAt) || other.loggedAt == loggedAt)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.note, note) || other.note == note)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,personId,medicationId,scheduledAt,loggedAt,outcome,createdAt,updatedAt,note,deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'DoseLog(id: $id, personId: $personId, medicationId: $medicationId, scheduledAt: $scheduledAt, loggedAt: $loggedAt, outcome: $outcome, createdAt: $createdAt, updatedAt: $updatedAt, note: $note, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class $DoseLogCopyWith<$Res>  {
  factory $DoseLogCopyWith(DoseLog value, $Res Function(DoseLog) _then) = _$DoseLogCopyWithImpl;
@useResult
$Res call({
 String id, String personId, String medicationId, DateTime scheduledAt, DateTime loggedAt, DoseOutcome outcome, DateTime createdAt, DateTime updatedAt, String? note, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});




}
/// @nodoc
class _$DoseLogCopyWithImpl<$Res>
    implements $DoseLogCopyWith<$Res> {
  _$DoseLogCopyWithImpl(this._self, this._then);

  final DoseLog _self;
  final $Res Function(DoseLog) _then;

/// Create a copy of DoseLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? personId = null,Object? medicationId = null,Object? scheduledAt = null,Object? loggedAt = null,Object? outcome = null,Object? createdAt = null,Object? updatedAt = null,Object? note = freezed,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,medicationId: null == medicationId ? _self.medicationId : medicationId // ignore: cast_nullable_to_non_nullable
as String,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime,loggedAt: null == loggedAt ? _self.loggedAt : loggedAt // ignore: cast_nullable_to_non_nullable
as DateTime,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as DoseOutcome,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DoseLog].
extension DoseLogPatterns on DoseLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DoseLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DoseLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DoseLog value)  $default,){
final _that = this;
switch (_that) {
case _DoseLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DoseLog value)?  $default,){
final _that = this;
switch (_that) {
case _DoseLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String personId,  String medicationId,  DateTime scheduledAt,  DateTime loggedAt,  DoseOutcome outcome,  DateTime createdAt,  DateTime updatedAt,  String? note,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DoseLog() when $default != null:
return $default(_that.id,_that.personId,_that.medicationId,_that.scheduledAt,_that.loggedAt,_that.outcome,_that.createdAt,_that.updatedAt,_that.note,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String personId,  String medicationId,  DateTime scheduledAt,  DateTime loggedAt,  DoseOutcome outcome,  DateTime createdAt,  DateTime updatedAt,  String? note,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)  $default,) {final _that = this;
switch (_that) {
case _DoseLog():
return $default(_that.id,_that.personId,_that.medicationId,_that.scheduledAt,_that.loggedAt,_that.outcome,_that.createdAt,_that.updatedAt,_that.note,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String personId,  String medicationId,  DateTime scheduledAt,  DateTime loggedAt,  DoseOutcome outcome,  DateTime createdAt,  DateTime updatedAt,  String? note,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,) {final _that = this;
switch (_that) {
case _DoseLog() when $default != null:
return $default(_that.id,_that.personId,_that.medicationId,_that.scheduledAt,_that.loggedAt,_that.outcome,_that.createdAt,_that.updatedAt,_that.note,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
  return null;

}
}

}

/// @nodoc


class _DoseLog implements DoseLog {
  const _DoseLog({required this.id, required this.personId, required this.medicationId, required this.scheduledAt, required this.loggedAt, required this.outcome, required this.createdAt, required this.updatedAt, this.note, this.deletedAt, this.rowVersion = 1, this.lastWriterDeviceId, this.keyVersion = 1});
  

@override final  String id;
@override final  String personId;
@override final  String medicationId;
/// The wall-clock time the dose was due, converted to UTC. Part of
/// the log's composite identity.
@override final  DateTime scheduledAt;
/// When the user tapped Taken / Skipped, in UTC. Used for sort
/// stability and — Phase 2 — adherence reports.
@override final  DateTime loggedAt;
@override final  DoseOutcome outcome;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// Optional free-text note, e.g. "took 15 min late, with dinner".
/// Empty / whitespace-only notes are stored as null by the repo.
@override final  String? note;
/// Tombstone. Set when the user taps Undo on a previously-logged
/// dose. Kept rather than hard-deleting so Phase 2 sync is
/// symmetric with every other table.
@override final  DateTime? deletedAt;
@override@JsonKey() final  int rowVersion;
@override final  String? lastWriterDeviceId;
@override@JsonKey() final  int keyVersion;

/// Create a copy of DoseLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DoseLogCopyWith<_DoseLog> get copyWith => __$DoseLogCopyWithImpl<_DoseLog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DoseLog&&(identical(other.id, id) || other.id == id)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.medicationId, medicationId) || other.medicationId == medicationId)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.loggedAt, loggedAt) || other.loggedAt == loggedAt)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.note, note) || other.note == note)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,personId,medicationId,scheduledAt,loggedAt,outcome,createdAt,updatedAt,note,deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'DoseLog(id: $id, personId: $personId, medicationId: $medicationId, scheduledAt: $scheduledAt, loggedAt: $loggedAt, outcome: $outcome, createdAt: $createdAt, updatedAt: $updatedAt, note: $note, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class _$DoseLogCopyWith<$Res> implements $DoseLogCopyWith<$Res> {
  factory _$DoseLogCopyWith(_DoseLog value, $Res Function(_DoseLog) _then) = __$DoseLogCopyWithImpl;
@override @useResult
$Res call({
 String id, String personId, String medicationId, DateTime scheduledAt, DateTime loggedAt, DoseOutcome outcome, DateTime createdAt, DateTime updatedAt, String? note, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});




}
/// @nodoc
class __$DoseLogCopyWithImpl<$Res>
    implements _$DoseLogCopyWith<$Res> {
  __$DoseLogCopyWithImpl(this._self, this._then);

  final _DoseLog _self;
  final $Res Function(_DoseLog) _then;

/// Create a copy of DoseLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? personId = null,Object? medicationId = null,Object? scheduledAt = null,Object? loggedAt = null,Object? outcome = null,Object? createdAt = null,Object? updatedAt = null,Object? note = freezed,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_DoseLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,medicationId: null == medicationId ? _self.medicationId : medicationId // ignore: cast_nullable_to_non_nullable
as String,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime,loggedAt: null == loggedAt ? _self.loggedAt : loggedAt // ignore: cast_nullable_to_non_nullable
as DateTime,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as DoseOutcome,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
