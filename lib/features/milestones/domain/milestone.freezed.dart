// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'milestone.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Milestone {

/// Client-generated UUID v4.
 String get id;/// Owning Person's id. Never mutated — moving a milestone
/// between People requires a new row so AAD / key binding
/// stays honest.
 String get personId;/// Which of the six pre-defined categories this milestone
/// falls into. Drives icon, tint, and list grouping.
 MilestoneKind get kind;/// Free-form title. Required — "Flu shot", "Diagnosed with
/// ASD", "First words", "Moved to Amsterdam".
 String get title;/// Canonical UTC instant the milestone is dated at. For
/// non-exact precision, this is the **start** of the period
/// (year → Jan 1, month → the 1st, day → 00:00 UTC). Keeping
/// the sort key as a single instant means chronological lists
/// work without a special-case comparator.
 DateTime get occurredAt;/// How precisely the user knows when this happened. Controls
/// UI rendering and fuzzy-date rules.
 MilestonePrecision get precision;/// Metadata propagated from the DB row.
 DateTime get createdAt; DateTime get updatedAt;/// Optional link to a `CareProvider`. Same soft-reference
/// pattern as `Appointment.providerId` and
/// `Medication.prescriberId` — archived providers still
/// resolve so historical attribution survives retirement.
 String? get providerId;/// Free-form notes. Where the story goes: "Second dose of
/// two", "Dr. Chen was very kind", "walked holding the couch
/// first, confident after two weeks".
 String? get notes; DateTime? get deletedAt; int get rowVersion; String? get lastWriterDeviceId; int get keyVersion;
/// Create a copy of Milestone
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MilestoneCopyWith<Milestone> get copyWith => _$MilestoneCopyWithImpl<Milestone>(this as Milestone, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Milestone&&(identical(other.id, id) || other.id == id)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.precision, precision) || other.precision == precision)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,personId,kind,title,occurredAt,precision,createdAt,updatedAt,providerId,notes,deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'Milestone(id: $id, personId: $personId, kind: $kind, title: $title, occurredAt: $occurredAt, precision: $precision, createdAt: $createdAt, updatedAt: $updatedAt, providerId: $providerId, notes: $notes, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class $MilestoneCopyWith<$Res>  {
  factory $MilestoneCopyWith(Milestone value, $Res Function(Milestone) _then) = _$MilestoneCopyWithImpl;
@useResult
$Res call({
 String id, String personId, MilestoneKind kind, String title, DateTime occurredAt, MilestonePrecision precision, DateTime createdAt, DateTime updatedAt, String? providerId, String? notes, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});




}
/// @nodoc
class _$MilestoneCopyWithImpl<$Res>
    implements $MilestoneCopyWith<$Res> {
  _$MilestoneCopyWithImpl(this._self, this._then);

  final Milestone _self;
  final $Res Function(Milestone) _then;

/// Create a copy of Milestone
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? personId = null,Object? kind = null,Object? title = null,Object? occurredAt = null,Object? precision = null,Object? createdAt = null,Object? updatedAt = null,Object? providerId = freezed,Object? notes = freezed,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MilestoneKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,precision: null == precision ? _self.precision : precision // ignore: cast_nullable_to_non_nullable
as MilestonePrecision,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,providerId: freezed == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Milestone].
extension MilestonePatterns on Milestone {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Milestone value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Milestone() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Milestone value)  $default,){
final _that = this;
switch (_that) {
case _Milestone():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Milestone value)?  $default,){
final _that = this;
switch (_that) {
case _Milestone() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String personId,  MilestoneKind kind,  String title,  DateTime occurredAt,  MilestonePrecision precision,  DateTime createdAt,  DateTime updatedAt,  String? providerId,  String? notes,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Milestone() when $default != null:
return $default(_that.id,_that.personId,_that.kind,_that.title,_that.occurredAt,_that.precision,_that.createdAt,_that.updatedAt,_that.providerId,_that.notes,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String personId,  MilestoneKind kind,  String title,  DateTime occurredAt,  MilestonePrecision precision,  DateTime createdAt,  DateTime updatedAt,  String? providerId,  String? notes,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)  $default,) {final _that = this;
switch (_that) {
case _Milestone():
return $default(_that.id,_that.personId,_that.kind,_that.title,_that.occurredAt,_that.precision,_that.createdAt,_that.updatedAt,_that.providerId,_that.notes,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String personId,  MilestoneKind kind,  String title,  DateTime occurredAt,  MilestonePrecision precision,  DateTime createdAt,  DateTime updatedAt,  String? providerId,  String? notes,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,) {final _that = this;
switch (_that) {
case _Milestone() when $default != null:
return $default(_that.id,_that.personId,_that.kind,_that.title,_that.occurredAt,_that.precision,_that.createdAt,_that.updatedAt,_that.providerId,_that.notes,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
  return null;

}
}

}

/// @nodoc


class _Milestone implements Milestone {
  const _Milestone({required this.id, required this.personId, required this.kind, required this.title, required this.occurredAt, required this.precision, required this.createdAt, required this.updatedAt, this.providerId, this.notes, this.deletedAt, this.rowVersion = 1, this.lastWriterDeviceId, this.keyVersion = 1});
  

/// Client-generated UUID v4.
@override final  String id;
/// Owning Person's id. Never mutated — moving a milestone
/// between People requires a new row so AAD / key binding
/// stays honest.
@override final  String personId;
/// Which of the six pre-defined categories this milestone
/// falls into. Drives icon, tint, and list grouping.
@override final  MilestoneKind kind;
/// Free-form title. Required — "Flu shot", "Diagnosed with
/// ASD", "First words", "Moved to Amsterdam".
@override final  String title;
/// Canonical UTC instant the milestone is dated at. For
/// non-exact precision, this is the **start** of the period
/// (year → Jan 1, month → the 1st, day → 00:00 UTC). Keeping
/// the sort key as a single instant means chronological lists
/// work without a special-case comparator.
@override final  DateTime occurredAt;
/// How precisely the user knows when this happened. Controls
/// UI rendering and fuzzy-date rules.
@override final  MilestonePrecision precision;
/// Metadata propagated from the DB row.
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// Optional link to a `CareProvider`. Same soft-reference
/// pattern as `Appointment.providerId` and
/// `Medication.prescriberId` — archived providers still
/// resolve so historical attribution survives retirement.
@override final  String? providerId;
/// Free-form notes. Where the story goes: "Second dose of
/// two", "Dr. Chen was very kind", "walked holding the couch
/// first, confident after two weeks".
@override final  String? notes;
@override final  DateTime? deletedAt;
@override@JsonKey() final  int rowVersion;
@override final  String? lastWriterDeviceId;
@override@JsonKey() final  int keyVersion;

/// Create a copy of Milestone
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MilestoneCopyWith<_Milestone> get copyWith => __$MilestoneCopyWithImpl<_Milestone>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Milestone&&(identical(other.id, id) || other.id == id)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.precision, precision) || other.precision == precision)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,personId,kind,title,occurredAt,precision,createdAt,updatedAt,providerId,notes,deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'Milestone(id: $id, personId: $personId, kind: $kind, title: $title, occurredAt: $occurredAt, precision: $precision, createdAt: $createdAt, updatedAt: $updatedAt, providerId: $providerId, notes: $notes, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class _$MilestoneCopyWith<$Res> implements $MilestoneCopyWith<$Res> {
  factory _$MilestoneCopyWith(_Milestone value, $Res Function(_Milestone) _then) = __$MilestoneCopyWithImpl;
@override @useResult
$Res call({
 String id, String personId, MilestoneKind kind, String title, DateTime occurredAt, MilestonePrecision precision, DateTime createdAt, DateTime updatedAt, String? providerId, String? notes, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});




}
/// @nodoc
class __$MilestoneCopyWithImpl<$Res>
    implements _$MilestoneCopyWith<$Res> {
  __$MilestoneCopyWithImpl(this._self, this._then);

  final _Milestone _self;
  final $Res Function(_Milestone) _then;

/// Create a copy of Milestone
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? personId = null,Object? kind = null,Object? title = null,Object? occurredAt = null,Object? precision = null,Object? createdAt = null,Object? updatedAt = null,Object? providerId = freezed,Object? notes = freezed,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_Milestone(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MilestoneKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,precision: null == precision ? _self.precision : precision // ignore: cast_nullable_to_non_nullable
as MilestonePrecision,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,providerId: freezed == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
