// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'appointment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Appointment {

/// Client-generated UUID v4. Stable across devices, never reused.
 String get id;/// Owning Person's id. Never mutated after creation — moving
/// an appointment between People requires a new row so the AAD
/// / key binding stays honest.
 String get personId;/// Free-form title. Required — "Dr. Chen — flu shot",
/// "IEP review", "OT session".
 String get title;/// When the appointment starts (UTC instant).
 DateTime get scheduledAt;/// Metadata propagated from the DB row.
 DateTime get createdAt; DateTime get updatedAt;/// Optional link to a `CareProvider`. Kept as a soft id rather
/// than an embedded provider snapshot so provider edits
/// (renames, phone changes) are reflected immediately in every
/// appointment that links to them.
 String? get providerId;/// Where the visit happens — free-text on purpose. Users paste
/// from Contacts / Maps / emails; any structure we imposed
/// would immediately be wrong for telehealth, school visits,
/// "Dr. Chen's office but the new suite".
 String? get location;/// How long it's expected to run. Optional because "some time
/// in the afternoon" is a real level of knowledge.
 int? get durationMinutes;/// Free-form notes — questions to ask, docs to bring, insurance
/// details, anything the user wants in their pocket during the
/// visit.
 String? get notes;/// How many minutes before [scheduledAt] to surface a local
/// reminder notification. Stored now, wired to the notification
/// system in a later PR. `null` means no reminder.
 int? get reminderLeadMinutes; DateTime? get deletedAt; int get rowVersion; String? get lastWriterDeviceId; int get keyVersion;
/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppointmentCopyWith<Appointment> get copyWith => _$AppointmentCopyWithImpl<Appointment>(this as Appointment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Appointment&&(identical(other.id, id) || other.id == id)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.title, title) || other.title == title)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.location, location) || other.location == location)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.reminderLeadMinutes, reminderLeadMinutes) || other.reminderLeadMinutes == reminderLeadMinutes)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,personId,title,scheduledAt,createdAt,updatedAt,providerId,location,durationMinutes,notes,reminderLeadMinutes,deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'Appointment(id: $id, personId: $personId, title: $title, scheduledAt: $scheduledAt, createdAt: $createdAt, updatedAt: $updatedAt, providerId: $providerId, location: $location, durationMinutes: $durationMinutes, notes: $notes, reminderLeadMinutes: $reminderLeadMinutes, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class $AppointmentCopyWith<$Res>  {
  factory $AppointmentCopyWith(Appointment value, $Res Function(Appointment) _then) = _$AppointmentCopyWithImpl;
@useResult
$Res call({
 String id, String personId, String title, DateTime scheduledAt, DateTime createdAt, DateTime updatedAt, String? providerId, String? location, int? durationMinutes, String? notes, int? reminderLeadMinutes, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});




}
/// @nodoc
class _$AppointmentCopyWithImpl<$Res>
    implements $AppointmentCopyWith<$Res> {
  _$AppointmentCopyWithImpl(this._self, this._then);

  final Appointment _self;
  final $Res Function(Appointment) _then;

/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? personId = null,Object? title = null,Object? scheduledAt = null,Object? createdAt = null,Object? updatedAt = null,Object? providerId = freezed,Object? location = freezed,Object? durationMinutes = freezed,Object? notes = freezed,Object? reminderLeadMinutes = freezed,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,providerId: freezed == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,durationMinutes: freezed == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,reminderLeadMinutes: freezed == reminderLeadMinutes ? _self.reminderLeadMinutes : reminderLeadMinutes // ignore: cast_nullable_to_non_nullable
as int?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Appointment].
extension AppointmentPatterns on Appointment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Appointment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Appointment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Appointment value)  $default,){
final _that = this;
switch (_that) {
case _Appointment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Appointment value)?  $default,){
final _that = this;
switch (_that) {
case _Appointment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String personId,  String title,  DateTime scheduledAt,  DateTime createdAt,  DateTime updatedAt,  String? providerId,  String? location,  int? durationMinutes,  String? notes,  int? reminderLeadMinutes,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Appointment() when $default != null:
return $default(_that.id,_that.personId,_that.title,_that.scheduledAt,_that.createdAt,_that.updatedAt,_that.providerId,_that.location,_that.durationMinutes,_that.notes,_that.reminderLeadMinutes,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String personId,  String title,  DateTime scheduledAt,  DateTime createdAt,  DateTime updatedAt,  String? providerId,  String? location,  int? durationMinutes,  String? notes,  int? reminderLeadMinutes,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)  $default,) {final _that = this;
switch (_that) {
case _Appointment():
return $default(_that.id,_that.personId,_that.title,_that.scheduledAt,_that.createdAt,_that.updatedAt,_that.providerId,_that.location,_that.durationMinutes,_that.notes,_that.reminderLeadMinutes,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String personId,  String title,  DateTime scheduledAt,  DateTime createdAt,  DateTime updatedAt,  String? providerId,  String? location,  int? durationMinutes,  String? notes,  int? reminderLeadMinutes,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,) {final _that = this;
switch (_that) {
case _Appointment() when $default != null:
return $default(_that.id,_that.personId,_that.title,_that.scheduledAt,_that.createdAt,_that.updatedAt,_that.providerId,_that.location,_that.durationMinutes,_that.notes,_that.reminderLeadMinutes,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
  return null;

}
}

}

/// @nodoc


class _Appointment implements Appointment {
  const _Appointment({required this.id, required this.personId, required this.title, required this.scheduledAt, required this.createdAt, required this.updatedAt, this.providerId, this.location, this.durationMinutes, this.notes, this.reminderLeadMinutes, this.deletedAt, this.rowVersion = 1, this.lastWriterDeviceId, this.keyVersion = 1});
  

/// Client-generated UUID v4. Stable across devices, never reused.
@override final  String id;
/// Owning Person's id. Never mutated after creation — moving
/// an appointment between People requires a new row so the AAD
/// / key binding stays honest.
@override final  String personId;
/// Free-form title. Required — "Dr. Chen — flu shot",
/// "IEP review", "OT session".
@override final  String title;
/// When the appointment starts (UTC instant).
@override final  DateTime scheduledAt;
/// Metadata propagated from the DB row.
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// Optional link to a `CareProvider`. Kept as a soft id rather
/// than an embedded provider snapshot so provider edits
/// (renames, phone changes) are reflected immediately in every
/// appointment that links to them.
@override final  String? providerId;
/// Where the visit happens — free-text on purpose. Users paste
/// from Contacts / Maps / emails; any structure we imposed
/// would immediately be wrong for telehealth, school visits,
/// "Dr. Chen's office but the new suite".
@override final  String? location;
/// How long it's expected to run. Optional because "some time
/// in the afternoon" is a real level of knowledge.
@override final  int? durationMinutes;
/// Free-form notes — questions to ask, docs to bring, insurance
/// details, anything the user wants in their pocket during the
/// visit.
@override final  String? notes;
/// How many minutes before [scheduledAt] to surface a local
/// reminder notification. Stored now, wired to the notification
/// system in a later PR. `null` means no reminder.
@override final  int? reminderLeadMinutes;
@override final  DateTime? deletedAt;
@override@JsonKey() final  int rowVersion;
@override final  String? lastWriterDeviceId;
@override@JsonKey() final  int keyVersion;

/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppointmentCopyWith<_Appointment> get copyWith => __$AppointmentCopyWithImpl<_Appointment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Appointment&&(identical(other.id, id) || other.id == id)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.title, title) || other.title == title)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.location, location) || other.location == location)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.reminderLeadMinutes, reminderLeadMinutes) || other.reminderLeadMinutes == reminderLeadMinutes)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,personId,title,scheduledAt,createdAt,updatedAt,providerId,location,durationMinutes,notes,reminderLeadMinutes,deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'Appointment(id: $id, personId: $personId, title: $title, scheduledAt: $scheduledAt, createdAt: $createdAt, updatedAt: $updatedAt, providerId: $providerId, location: $location, durationMinutes: $durationMinutes, notes: $notes, reminderLeadMinutes: $reminderLeadMinutes, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class _$AppointmentCopyWith<$Res> implements $AppointmentCopyWith<$Res> {
  factory _$AppointmentCopyWith(_Appointment value, $Res Function(_Appointment) _then) = __$AppointmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String personId, String title, DateTime scheduledAt, DateTime createdAt, DateTime updatedAt, String? providerId, String? location, int? durationMinutes, String? notes, int? reminderLeadMinutes, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});




}
/// @nodoc
class __$AppointmentCopyWithImpl<$Res>
    implements _$AppointmentCopyWith<$Res> {
  __$AppointmentCopyWithImpl(this._self, this._then);

  final _Appointment _self;
  final $Res Function(_Appointment) _then;

/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? personId = null,Object? title = null,Object? scheduledAt = null,Object? createdAt = null,Object? updatedAt = null,Object? providerId = freezed,Object? location = freezed,Object? durationMinutes = freezed,Object? notes = freezed,Object? reminderLeadMinutes = freezed,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_Appointment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,providerId: freezed == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,durationMinutes: freezed == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,reminderLeadMinutes: freezed == reminderLeadMinutes ? _self.reminderLeadMinutes : reminderLeadMinutes // ignore: cast_nullable_to_non_nullable
as int?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
