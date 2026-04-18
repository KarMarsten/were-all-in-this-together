// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medication_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MedicationFieldDiff {

/// Stable wire name of the field, e.g. `dose`, `prescriberId`,
/// `schedule`. Kept as a string (not an enum) to stay forward-
/// compatible with future fields — a timeline written under v9
/// should still render under v8, even if it just says
/// `someNewField` verbatim.
 String get field; String? get previous; String? get current;
/// Create a copy of MedicationFieldDiff
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicationFieldDiffCopyWith<MedicationFieldDiff> get copyWith => _$MedicationFieldDiffCopyWithImpl<MedicationFieldDiff>(this as MedicationFieldDiff, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicationFieldDiff&&(identical(other.field, field) || other.field == field)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.current, current) || other.current == current));
}


@override
int get hashCode => Object.hash(runtimeType,field,previous,current);

@override
String toString() {
  return 'MedicationFieldDiff(field: $field, previous: $previous, current: $current)';
}


}

/// @nodoc
abstract mixin class $MedicationFieldDiffCopyWith<$Res>  {
  factory $MedicationFieldDiffCopyWith(MedicationFieldDiff value, $Res Function(MedicationFieldDiff) _then) = _$MedicationFieldDiffCopyWithImpl;
@useResult
$Res call({
 String field, String? previous, String? current
});




}
/// @nodoc
class _$MedicationFieldDiffCopyWithImpl<$Res>
    implements $MedicationFieldDiffCopyWith<$Res> {
  _$MedicationFieldDiffCopyWithImpl(this._self, this._then);

  final MedicationFieldDiff _self;
  final $Res Function(MedicationFieldDiff) _then;

/// Create a copy of MedicationFieldDiff
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? field = null,Object? previous = freezed,Object? current = freezed,}) {
  return _then(_self.copyWith(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as String?,current: freezed == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MedicationFieldDiff].
extension MedicationFieldDiffPatterns on MedicationFieldDiff {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedicationFieldDiff value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedicationFieldDiff() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedicationFieldDiff value)  $default,){
final _that = this;
switch (_that) {
case _MedicationFieldDiff():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedicationFieldDiff value)?  $default,){
final _that = this;
switch (_that) {
case _MedicationFieldDiff() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String field,  String? previous,  String? current)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedicationFieldDiff() when $default != null:
return $default(_that.field,_that.previous,_that.current);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String field,  String? previous,  String? current)  $default,) {final _that = this;
switch (_that) {
case _MedicationFieldDiff():
return $default(_that.field,_that.previous,_that.current);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String field,  String? previous,  String? current)?  $default,) {final _that = this;
switch (_that) {
case _MedicationFieldDiff() when $default != null:
return $default(_that.field,_that.previous,_that.current);case _:
  return null;

}
}

}

/// @nodoc


class _MedicationFieldDiff implements MedicationFieldDiff {
  const _MedicationFieldDiff({required this.field, this.previous, this.current});
  

/// Stable wire name of the field, e.g. `dose`, `prescriberId`,
/// `schedule`. Kept as a string (not an enum) to stay forward-
/// compatible with future fields — a timeline written under v9
/// should still render under v8, even if it just says
/// `someNewField` verbatim.
@override final  String field;
@override final  String? previous;
@override final  String? current;

/// Create a copy of MedicationFieldDiff
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicationFieldDiffCopyWith<_MedicationFieldDiff> get copyWith => __$MedicationFieldDiffCopyWithImpl<_MedicationFieldDiff>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedicationFieldDiff&&(identical(other.field, field) || other.field == field)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.current, current) || other.current == current));
}


@override
int get hashCode => Object.hash(runtimeType,field,previous,current);

@override
String toString() {
  return 'MedicationFieldDiff(field: $field, previous: $previous, current: $current)';
}


}

/// @nodoc
abstract mixin class _$MedicationFieldDiffCopyWith<$Res> implements $MedicationFieldDiffCopyWith<$Res> {
  factory _$MedicationFieldDiffCopyWith(_MedicationFieldDiff value, $Res Function(_MedicationFieldDiff) _then) = __$MedicationFieldDiffCopyWithImpl;
@override @useResult
$Res call({
 String field, String? previous, String? current
});




}
/// @nodoc
class __$MedicationFieldDiffCopyWithImpl<$Res>
    implements _$MedicationFieldDiffCopyWith<$Res> {
  __$MedicationFieldDiffCopyWithImpl(this._self, this._then);

  final _MedicationFieldDiff _self;
  final $Res Function(_MedicationFieldDiff) _then;

/// Create a copy of MedicationFieldDiff
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field = null,Object? previous = freezed,Object? current = freezed,}) {
  return _then(_MedicationFieldDiff(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as String?,current: freezed == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$MedicationEvent {

/// Client-generated UUID v4.
 String get id;/// Id of the medication this event belongs to.
 String get medicationId;/// Owning Person, duplicated from the medication so event
/// queries don't need a join and AAD scoping matches the other
/// tables.
 String get personId; MedicationEventKind get kind;/// When the change took effect in the patient's timeline.
/// For auto-logged events this equals [createdAt]. Manual
/// backfill events set this to the historical date the user
/// reports.
 DateTime get occurredAt;/// Row-metadata timestamps (when the event row itself was first
/// written / last mutated). Separate from [occurredAt] so
/// backfills keep a clean audit trail of when they were
/// entered.
 DateTime get createdAt; DateTime get updatedAt;/// Non-empty only for [MedicationEventKind.fieldsChanged]. Other
/// kinds keep it `const []`.
 List<MedicationFieldDiff> get diffs;/// Optional free-text annotation. For auto-logged events this is
/// typically `null`; the user can attach rationale when manually
/// backfilling or recording a standalone [MedicationEventKind.note].
 String? get note; DateTime? get deletedAt; int get rowVersion; String? get lastWriterDeviceId; int get keyVersion;
/// Create a copy of MedicationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicationEventCopyWith<MedicationEvent> get copyWith => _$MedicationEventCopyWithImpl<MedicationEvent>(this as MedicationEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicationEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.medicationId, medicationId) || other.medicationId == medicationId)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.diffs, diffs)&&(identical(other.note, note) || other.note == note)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,medicationId,personId,kind,occurredAt,createdAt,updatedAt,const DeepCollectionEquality().hash(diffs),note,deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'MedicationEvent(id: $id, medicationId: $medicationId, personId: $personId, kind: $kind, occurredAt: $occurredAt, createdAt: $createdAt, updatedAt: $updatedAt, diffs: $diffs, note: $note, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class $MedicationEventCopyWith<$Res>  {
  factory $MedicationEventCopyWith(MedicationEvent value, $Res Function(MedicationEvent) _then) = _$MedicationEventCopyWithImpl;
@useResult
$Res call({
 String id, String medicationId, String personId, MedicationEventKind kind, DateTime occurredAt, DateTime createdAt, DateTime updatedAt, List<MedicationFieldDiff> diffs, String? note, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});




}
/// @nodoc
class _$MedicationEventCopyWithImpl<$Res>
    implements $MedicationEventCopyWith<$Res> {
  _$MedicationEventCopyWithImpl(this._self, this._then);

  final MedicationEvent _self;
  final $Res Function(MedicationEvent) _then;

/// Create a copy of MedicationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? medicationId = null,Object? personId = null,Object? kind = null,Object? occurredAt = null,Object? createdAt = null,Object? updatedAt = null,Object? diffs = null,Object? note = freezed,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,medicationId: null == medicationId ? _self.medicationId : medicationId // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MedicationEventKind,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,diffs: null == diffs ? _self.diffs : diffs // ignore: cast_nullable_to_non_nullable
as List<MedicationFieldDiff>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MedicationEvent].
extension MedicationEventPatterns on MedicationEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedicationEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedicationEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedicationEvent value)  $default,){
final _that = this;
switch (_that) {
case _MedicationEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedicationEvent value)?  $default,){
final _that = this;
switch (_that) {
case _MedicationEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String medicationId,  String personId,  MedicationEventKind kind,  DateTime occurredAt,  DateTime createdAt,  DateTime updatedAt,  List<MedicationFieldDiff> diffs,  String? note,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedicationEvent() when $default != null:
return $default(_that.id,_that.medicationId,_that.personId,_that.kind,_that.occurredAt,_that.createdAt,_that.updatedAt,_that.diffs,_that.note,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String medicationId,  String personId,  MedicationEventKind kind,  DateTime occurredAt,  DateTime createdAt,  DateTime updatedAt,  List<MedicationFieldDiff> diffs,  String? note,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)  $default,) {final _that = this;
switch (_that) {
case _MedicationEvent():
return $default(_that.id,_that.medicationId,_that.personId,_that.kind,_that.occurredAt,_that.createdAt,_that.updatedAt,_that.diffs,_that.note,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String medicationId,  String personId,  MedicationEventKind kind,  DateTime occurredAt,  DateTime createdAt,  DateTime updatedAt,  List<MedicationFieldDiff> diffs,  String? note,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,) {final _that = this;
switch (_that) {
case _MedicationEvent() when $default != null:
return $default(_that.id,_that.medicationId,_that.personId,_that.kind,_that.occurredAt,_that.createdAt,_that.updatedAt,_that.diffs,_that.note,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
  return null;

}
}

}

/// @nodoc


class _MedicationEvent implements MedicationEvent {
  const _MedicationEvent({required this.id, required this.medicationId, required this.personId, required this.kind, required this.occurredAt, required this.createdAt, required this.updatedAt, final  List<MedicationFieldDiff> diffs = const <MedicationFieldDiff>[], this.note, this.deletedAt, this.rowVersion = 1, this.lastWriterDeviceId, this.keyVersion = 1}): _diffs = diffs;
  

/// Client-generated UUID v4.
@override final  String id;
/// Id of the medication this event belongs to.
@override final  String medicationId;
/// Owning Person, duplicated from the medication so event
/// queries don't need a join and AAD scoping matches the other
/// tables.
@override final  String personId;
@override final  MedicationEventKind kind;
/// When the change took effect in the patient's timeline.
/// For auto-logged events this equals [createdAt]. Manual
/// backfill events set this to the historical date the user
/// reports.
@override final  DateTime occurredAt;
/// Row-metadata timestamps (when the event row itself was first
/// written / last mutated). Separate from [occurredAt] so
/// backfills keep a clean audit trail of when they were
/// entered.
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// Non-empty only for [MedicationEventKind.fieldsChanged]. Other
/// kinds keep it `const []`.
 final  List<MedicationFieldDiff> _diffs;
/// Non-empty only for [MedicationEventKind.fieldsChanged]. Other
/// kinds keep it `const []`.
@override@JsonKey() List<MedicationFieldDiff> get diffs {
  if (_diffs is EqualUnmodifiableListView) return _diffs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diffs);
}

/// Optional free-text annotation. For auto-logged events this is
/// typically `null`; the user can attach rationale when manually
/// backfilling or recording a standalone [MedicationEventKind.note].
@override final  String? note;
@override final  DateTime? deletedAt;
@override@JsonKey() final  int rowVersion;
@override final  String? lastWriterDeviceId;
@override@JsonKey() final  int keyVersion;

/// Create a copy of MedicationEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicationEventCopyWith<_MedicationEvent> get copyWith => __$MedicationEventCopyWithImpl<_MedicationEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedicationEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.medicationId, medicationId) || other.medicationId == medicationId)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._diffs, _diffs)&&(identical(other.note, note) || other.note == note)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,medicationId,personId,kind,occurredAt,createdAt,updatedAt,const DeepCollectionEquality().hash(_diffs),note,deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'MedicationEvent(id: $id, medicationId: $medicationId, personId: $personId, kind: $kind, occurredAt: $occurredAt, createdAt: $createdAt, updatedAt: $updatedAt, diffs: $diffs, note: $note, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class _$MedicationEventCopyWith<$Res> implements $MedicationEventCopyWith<$Res> {
  factory _$MedicationEventCopyWith(_MedicationEvent value, $Res Function(_MedicationEvent) _then) = __$MedicationEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String medicationId, String personId, MedicationEventKind kind, DateTime occurredAt, DateTime createdAt, DateTime updatedAt, List<MedicationFieldDiff> diffs, String? note, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});




}
/// @nodoc
class __$MedicationEventCopyWithImpl<$Res>
    implements _$MedicationEventCopyWith<$Res> {
  __$MedicationEventCopyWithImpl(this._self, this._then);

  final _MedicationEvent _self;
  final $Res Function(_MedicationEvent) _then;

/// Create a copy of MedicationEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? medicationId = null,Object? personId = null,Object? kind = null,Object? occurredAt = null,Object? createdAt = null,Object? updatedAt = null,Object? diffs = null,Object? note = freezed,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_MedicationEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,medicationId: null == medicationId ? _self.medicationId : medicationId // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MedicationEventKind,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,diffs: null == diffs ? _self._diffs : diffs // ignore: cast_nullable_to_non_nullable
as List<MedicationFieldDiff>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
