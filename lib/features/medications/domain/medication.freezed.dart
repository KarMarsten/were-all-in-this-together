// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medication.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Medication {

/// Client-generated UUID v4. Stable across devices, never reused.
 String get id;/// Owning Person's id. Never mutated after creation; moving a med
/// between People requires a new row so the AAD / key binding stays
/// honest.
 String get personId;/// Free-form medication name. Required.
 String get name;/// Metadata propagated from the DB row.
 DateTime get createdAt; DateTime get updatedAt;/// Free-form dose description, e.g. "10mg", "5ml in the morning",
/// "half a tablet". Intentionally unstructured.
 String? get dose;/// Physical form — pill, liquid, etc. Optional; used mainly for UI
/// icons.
 MedicationForm? get form;/// Who prescribed it. Free text today; will link to a Doctor record
/// in a later PR.
 String? get prescriber;/// User-visible notes (side effects to watch for, instructions, etc).
 String? get notes;/// First day of the regimen, date-only.
 DateTime? get startDate;/// Last day of the regimen, date-only. `null` means ongoing.
 DateTime? get endDate;/// When and how often to take it. Defaults to
/// [MedicationSchedule.asNeeded] so meds added before the schedule UI
/// existed (v1 payloads) decode sensibly without spawning reminders.
 MedicationSchedule get schedule;/// Override for the global notification re-alert interval, in minutes.
/// `null` means "use the device-wide default from
/// NotificationPreferences". Per-med overrides exist so a
/// time-sensitive med (insulin, anti-rejection) can nag faster than
/// the global default, or a low-stakes one (topical cream) can be
/// configured to not nag at all via [nagCapOverride] = 0.
 int? get nagIntervalMinutesOverride;/// Override for the global nag cap. `null` means "use the device-wide
/// default". `0` means "fire once and then stay silent".
 int? get nagCapOverride; DateTime? get deletedAt; int get rowVersion; String? get lastWriterDeviceId; int get keyVersion;
/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicationCopyWith<Medication> get copyWith => _$MedicationCopyWithImpl<Medication>(this as Medication, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Medication&&(identical(other.id, id) || other.id == id)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.dose, dose) || other.dose == dose)&&(identical(other.form, form) || other.form == form)&&(identical(other.prescriber, prescriber) || other.prescriber == prescriber)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.nagIntervalMinutesOverride, nagIntervalMinutesOverride) || other.nagIntervalMinutesOverride == nagIntervalMinutesOverride)&&(identical(other.nagCapOverride, nagCapOverride) || other.nagCapOverride == nagCapOverride)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,personId,name,createdAt,updatedAt,dose,form,prescriber,notes,startDate,endDate,schedule,nagIntervalMinutesOverride,nagCapOverride,deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'Medication(id: $id, personId: $personId, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, dose: $dose, form: $form, prescriber: $prescriber, notes: $notes, startDate: $startDate, endDate: $endDate, schedule: $schedule, nagIntervalMinutesOverride: $nagIntervalMinutesOverride, nagCapOverride: $nagCapOverride, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class $MedicationCopyWith<$Res>  {
  factory $MedicationCopyWith(Medication value, $Res Function(Medication) _then) = _$MedicationCopyWithImpl;
@useResult
$Res call({
 String id, String personId, String name, DateTime createdAt, DateTime updatedAt, String? dose, MedicationForm? form, String? prescriber, String? notes, DateTime? startDate, DateTime? endDate, MedicationSchedule schedule, int? nagIntervalMinutesOverride, int? nagCapOverride, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});


$MedicationScheduleCopyWith<$Res> get schedule;

}
/// @nodoc
class _$MedicationCopyWithImpl<$Res>
    implements $MedicationCopyWith<$Res> {
  _$MedicationCopyWithImpl(this._self, this._then);

  final Medication _self;
  final $Res Function(Medication) _then;

/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? personId = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? dose = freezed,Object? form = freezed,Object? prescriber = freezed,Object? notes = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? schedule = null,Object? nagIntervalMinutesOverride = freezed,Object? nagCapOverride = freezed,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,dose: freezed == dose ? _self.dose : dose // ignore: cast_nullable_to_non_nullable
as String?,form: freezed == form ? _self.form : form // ignore: cast_nullable_to_non_nullable
as MedicationForm?,prescriber: freezed == prescriber ? _self.prescriber : prescriber // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,schedule: null == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as MedicationSchedule,nagIntervalMinutesOverride: freezed == nagIntervalMinutesOverride ? _self.nagIntervalMinutesOverride : nagIntervalMinutesOverride // ignore: cast_nullable_to_non_nullable
as int?,nagCapOverride: freezed == nagCapOverride ? _self.nagCapOverride : nagCapOverride // ignore: cast_nullable_to_non_nullable
as int?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedicationScheduleCopyWith<$Res> get schedule {
  
  return $MedicationScheduleCopyWith<$Res>(_self.schedule, (value) {
    return _then(_self.copyWith(schedule: value));
  });
}
}


/// Adds pattern-matching-related methods to [Medication].
extension MedicationPatterns on Medication {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Medication value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Medication() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Medication value)  $default,){
final _that = this;
switch (_that) {
case _Medication():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Medication value)?  $default,){
final _that = this;
switch (_that) {
case _Medication() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String personId,  String name,  DateTime createdAt,  DateTime updatedAt,  String? dose,  MedicationForm? form,  String? prescriber,  String? notes,  DateTime? startDate,  DateTime? endDate,  MedicationSchedule schedule,  int? nagIntervalMinutesOverride,  int? nagCapOverride,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Medication() when $default != null:
return $default(_that.id,_that.personId,_that.name,_that.createdAt,_that.updatedAt,_that.dose,_that.form,_that.prescriber,_that.notes,_that.startDate,_that.endDate,_that.schedule,_that.nagIntervalMinutesOverride,_that.nagCapOverride,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String personId,  String name,  DateTime createdAt,  DateTime updatedAt,  String? dose,  MedicationForm? form,  String? prescriber,  String? notes,  DateTime? startDate,  DateTime? endDate,  MedicationSchedule schedule,  int? nagIntervalMinutesOverride,  int? nagCapOverride,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)  $default,) {final _that = this;
switch (_that) {
case _Medication():
return $default(_that.id,_that.personId,_that.name,_that.createdAt,_that.updatedAt,_that.dose,_that.form,_that.prescriber,_that.notes,_that.startDate,_that.endDate,_that.schedule,_that.nagIntervalMinutesOverride,_that.nagCapOverride,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String personId,  String name,  DateTime createdAt,  DateTime updatedAt,  String? dose,  MedicationForm? form,  String? prescriber,  String? notes,  DateTime? startDate,  DateTime? endDate,  MedicationSchedule schedule,  int? nagIntervalMinutesOverride,  int? nagCapOverride,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,) {final _that = this;
switch (_that) {
case _Medication() when $default != null:
return $default(_that.id,_that.personId,_that.name,_that.createdAt,_that.updatedAt,_that.dose,_that.form,_that.prescriber,_that.notes,_that.startDate,_that.endDate,_that.schedule,_that.nagIntervalMinutesOverride,_that.nagCapOverride,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
  return null;

}
}

}

/// @nodoc


class _Medication implements Medication {
  const _Medication({required this.id, required this.personId, required this.name, required this.createdAt, required this.updatedAt, this.dose, this.form, this.prescriber, this.notes, this.startDate, this.endDate, this.schedule = MedicationSchedule.asNeeded, this.nagIntervalMinutesOverride, this.nagCapOverride, this.deletedAt, this.rowVersion = 1, this.lastWriterDeviceId, this.keyVersion = 1});
  

/// Client-generated UUID v4. Stable across devices, never reused.
@override final  String id;
/// Owning Person's id. Never mutated after creation; moving a med
/// between People requires a new row so the AAD / key binding stays
/// honest.
@override final  String personId;
/// Free-form medication name. Required.
@override final  String name;
/// Metadata propagated from the DB row.
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// Free-form dose description, e.g. "10mg", "5ml in the morning",
/// "half a tablet". Intentionally unstructured.
@override final  String? dose;
/// Physical form — pill, liquid, etc. Optional; used mainly for UI
/// icons.
@override final  MedicationForm? form;
/// Who prescribed it. Free text today; will link to a Doctor record
/// in a later PR.
@override final  String? prescriber;
/// User-visible notes (side effects to watch for, instructions, etc).
@override final  String? notes;
/// First day of the regimen, date-only.
@override final  DateTime? startDate;
/// Last day of the regimen, date-only. `null` means ongoing.
@override final  DateTime? endDate;
/// When and how often to take it. Defaults to
/// [MedicationSchedule.asNeeded] so meds added before the schedule UI
/// existed (v1 payloads) decode sensibly without spawning reminders.
@override@JsonKey() final  MedicationSchedule schedule;
/// Override for the global notification re-alert interval, in minutes.
/// `null` means "use the device-wide default from
/// NotificationPreferences". Per-med overrides exist so a
/// time-sensitive med (insulin, anti-rejection) can nag faster than
/// the global default, or a low-stakes one (topical cream) can be
/// configured to not nag at all via [nagCapOverride] = 0.
@override final  int? nagIntervalMinutesOverride;
/// Override for the global nag cap. `null` means "use the device-wide
/// default". `0` means "fire once and then stay silent".
@override final  int? nagCapOverride;
@override final  DateTime? deletedAt;
@override@JsonKey() final  int rowVersion;
@override final  String? lastWriterDeviceId;
@override@JsonKey() final  int keyVersion;

/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicationCopyWith<_Medication> get copyWith => __$MedicationCopyWithImpl<_Medication>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Medication&&(identical(other.id, id) || other.id == id)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.dose, dose) || other.dose == dose)&&(identical(other.form, form) || other.form == form)&&(identical(other.prescriber, prescriber) || other.prescriber == prescriber)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.nagIntervalMinutesOverride, nagIntervalMinutesOverride) || other.nagIntervalMinutesOverride == nagIntervalMinutesOverride)&&(identical(other.nagCapOverride, nagCapOverride) || other.nagCapOverride == nagCapOverride)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,personId,name,createdAt,updatedAt,dose,form,prescriber,notes,startDate,endDate,schedule,nagIntervalMinutesOverride,nagCapOverride,deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'Medication(id: $id, personId: $personId, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, dose: $dose, form: $form, prescriber: $prescriber, notes: $notes, startDate: $startDate, endDate: $endDate, schedule: $schedule, nagIntervalMinutesOverride: $nagIntervalMinutesOverride, nagCapOverride: $nagCapOverride, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class _$MedicationCopyWith<$Res> implements $MedicationCopyWith<$Res> {
  factory _$MedicationCopyWith(_Medication value, $Res Function(_Medication) _then) = __$MedicationCopyWithImpl;
@override @useResult
$Res call({
 String id, String personId, String name, DateTime createdAt, DateTime updatedAt, String? dose, MedicationForm? form, String? prescriber, String? notes, DateTime? startDate, DateTime? endDate, MedicationSchedule schedule, int? nagIntervalMinutesOverride, int? nagCapOverride, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});


@override $MedicationScheduleCopyWith<$Res> get schedule;

}
/// @nodoc
class __$MedicationCopyWithImpl<$Res>
    implements _$MedicationCopyWith<$Res> {
  __$MedicationCopyWithImpl(this._self, this._then);

  final _Medication _self;
  final $Res Function(_Medication) _then;

/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? personId = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? dose = freezed,Object? form = freezed,Object? prescriber = freezed,Object? notes = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? schedule = null,Object? nagIntervalMinutesOverride = freezed,Object? nagCapOverride = freezed,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_Medication(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,dose: freezed == dose ? _self.dose : dose // ignore: cast_nullable_to_non_nullable
as String?,form: freezed == form ? _self.form : form // ignore: cast_nullable_to_non_nullable
as MedicationForm?,prescriber: freezed == prescriber ? _self.prescriber : prescriber // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,schedule: null == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as MedicationSchedule,nagIntervalMinutesOverride: freezed == nagIntervalMinutesOverride ? _self.nagIntervalMinutesOverride : nagIntervalMinutesOverride // ignore: cast_nullable_to_non_nullable
as int?,nagCapOverride: freezed == nagCapOverride ? _self.nagCapOverride : nagCapOverride // ignore: cast_nullable_to_non_nullable
as int?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Medication
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedicationScheduleCopyWith<$Res> get schedule {
  
  return $MedicationScheduleCopyWith<$Res>(_self.schedule, (value) {
    return _then(_self.copyWith(schedule: value));
  });
}
}

// dart format on
