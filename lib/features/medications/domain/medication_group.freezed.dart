// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medication_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MedicationGroup {

 String get id; String get personId; String get name; MedicationSchedule get schedule; DateTime get createdAt; DateTime get updatedAt; List<String> get memberMedicationIds; DateTime? get deletedAt; int get rowVersion; String? get lastWriterDeviceId; int get keyVersion;
/// Create a copy of MedicationGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicationGroupCopyWith<MedicationGroup> get copyWith => _$MedicationGroupCopyWithImpl<MedicationGroup>(this as MedicationGroup, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicationGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.name, name) || other.name == name)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.memberMedicationIds, memberMedicationIds)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,personId,name,schedule,createdAt,updatedAt,const DeepCollectionEquality().hash(memberMedicationIds),deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'MedicationGroup(id: $id, personId: $personId, name: $name, schedule: $schedule, createdAt: $createdAt, updatedAt: $updatedAt, memberMedicationIds: $memberMedicationIds, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class $MedicationGroupCopyWith<$Res>  {
  factory $MedicationGroupCopyWith(MedicationGroup value, $Res Function(MedicationGroup) _then) = _$MedicationGroupCopyWithImpl;
@useResult
$Res call({
 String id, String personId, String name, MedicationSchedule schedule, DateTime createdAt, DateTime updatedAt, List<String> memberMedicationIds, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});


$MedicationScheduleCopyWith<$Res> get schedule;

}
/// @nodoc
class _$MedicationGroupCopyWithImpl<$Res>
    implements $MedicationGroupCopyWith<$Res> {
  _$MedicationGroupCopyWithImpl(this._self, this._then);

  final MedicationGroup _self;
  final $Res Function(MedicationGroup) _then;

/// Create a copy of MedicationGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? personId = null,Object? name = null,Object? schedule = null,Object? createdAt = null,Object? updatedAt = null,Object? memberMedicationIds = null,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,schedule: null == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as MedicationSchedule,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,memberMedicationIds: null == memberMedicationIds ? _self.memberMedicationIds : memberMedicationIds // ignore: cast_nullable_to_non_nullable
as List<String>,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of MedicationGroup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedicationScheduleCopyWith<$Res> get schedule {
  
  return $MedicationScheduleCopyWith<$Res>(_self.schedule, (value) {
    return _then(_self.copyWith(schedule: value));
  });
}
}


/// Adds pattern-matching-related methods to [MedicationGroup].
extension MedicationGroupPatterns on MedicationGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedicationGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedicationGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedicationGroup value)  $default,){
final _that = this;
switch (_that) {
case _MedicationGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedicationGroup value)?  $default,){
final _that = this;
switch (_that) {
case _MedicationGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String personId,  String name,  MedicationSchedule schedule,  DateTime createdAt,  DateTime updatedAt,  List<String> memberMedicationIds,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedicationGroup() when $default != null:
return $default(_that.id,_that.personId,_that.name,_that.schedule,_that.createdAt,_that.updatedAt,_that.memberMedicationIds,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String personId,  String name,  MedicationSchedule schedule,  DateTime createdAt,  DateTime updatedAt,  List<String> memberMedicationIds,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)  $default,) {final _that = this;
switch (_that) {
case _MedicationGroup():
return $default(_that.id,_that.personId,_that.name,_that.schedule,_that.createdAt,_that.updatedAt,_that.memberMedicationIds,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String personId,  String name,  MedicationSchedule schedule,  DateTime createdAt,  DateTime updatedAt,  List<String> memberMedicationIds,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,) {final _that = this;
switch (_that) {
case _MedicationGroup() when $default != null:
return $default(_that.id,_that.personId,_that.name,_that.schedule,_that.createdAt,_that.updatedAt,_that.memberMedicationIds,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
  return null;

}
}

}

/// @nodoc


class _MedicationGroup implements MedicationGroup {
  const _MedicationGroup({required this.id, required this.personId, required this.name, required this.schedule, required this.createdAt, required this.updatedAt, final  List<String> memberMedicationIds = const <String>[], this.deletedAt, this.rowVersion = 1, this.lastWriterDeviceId, this.keyVersion = 1}): _memberMedicationIds = memberMedicationIds;
  

@override final  String id;
@override final  String personId;
@override final  String name;
@override final  MedicationSchedule schedule;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
 final  List<String> _memberMedicationIds;
@override@JsonKey() List<String> get memberMedicationIds {
  if (_memberMedicationIds is EqualUnmodifiableListView) return _memberMedicationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberMedicationIds);
}

@override final  DateTime? deletedAt;
@override@JsonKey() final  int rowVersion;
@override final  String? lastWriterDeviceId;
@override@JsonKey() final  int keyVersion;

/// Create a copy of MedicationGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicationGroupCopyWith<_MedicationGroup> get copyWith => __$MedicationGroupCopyWithImpl<_MedicationGroup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedicationGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.name, name) || other.name == name)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._memberMedicationIds, _memberMedicationIds)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,personId,name,schedule,createdAt,updatedAt,const DeepCollectionEquality().hash(_memberMedicationIds),deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'MedicationGroup(id: $id, personId: $personId, name: $name, schedule: $schedule, createdAt: $createdAt, updatedAt: $updatedAt, memberMedicationIds: $memberMedicationIds, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class _$MedicationGroupCopyWith<$Res> implements $MedicationGroupCopyWith<$Res> {
  factory _$MedicationGroupCopyWith(_MedicationGroup value, $Res Function(_MedicationGroup) _then) = __$MedicationGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String personId, String name, MedicationSchedule schedule, DateTime createdAt, DateTime updatedAt, List<String> memberMedicationIds, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});


@override $MedicationScheduleCopyWith<$Res> get schedule;

}
/// @nodoc
class __$MedicationGroupCopyWithImpl<$Res>
    implements _$MedicationGroupCopyWith<$Res> {
  __$MedicationGroupCopyWithImpl(this._self, this._then);

  final _MedicationGroup _self;
  final $Res Function(_MedicationGroup) _then;

/// Create a copy of MedicationGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? personId = null,Object? name = null,Object? schedule = null,Object? createdAt = null,Object? updatedAt = null,Object? memberMedicationIds = null,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_MedicationGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,schedule: null == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as MedicationSchedule,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,memberMedicationIds: null == memberMedicationIds ? _self._memberMedicationIds : memberMedicationIds // ignore: cast_nullable_to_non_nullable
as List<String>,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of MedicationGroup
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
