// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfileEntry {

 String get id; String get profileId; String get personId; ProfileEntrySection get section; ProfileEntryStatus get status; String get label; DateTime get createdAt; DateTime get updatedAt; String? get parentEntryId; DateTime? get firstNoted; DateTime? get lastNoted; String? get details; DateTime? get deletedAt; int get rowVersion; String? get lastWriterDeviceId; int get keyVersion;
/// Create a copy of ProfileEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileEntryCopyWith<ProfileEntry> get copyWith => _$ProfileEntryCopyWithImpl<ProfileEntry>(this as ProfileEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.section, section) || other.section == section)&&(identical(other.status, status) || other.status == status)&&(identical(other.label, label) || other.label == label)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.parentEntryId, parentEntryId) || other.parentEntryId == parentEntryId)&&(identical(other.firstNoted, firstNoted) || other.firstNoted == firstNoted)&&(identical(other.lastNoted, lastNoted) || other.lastNoted == lastNoted)&&(identical(other.details, details) || other.details == details)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,profileId,personId,section,status,label,createdAt,updatedAt,parentEntryId,firstNoted,lastNoted,details,deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'ProfileEntry(id: $id, profileId: $profileId, personId: $personId, section: $section, status: $status, label: $label, createdAt: $createdAt, updatedAt: $updatedAt, parentEntryId: $parentEntryId, firstNoted: $firstNoted, lastNoted: $lastNoted, details: $details, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class $ProfileEntryCopyWith<$Res>  {
  factory $ProfileEntryCopyWith(ProfileEntry value, $Res Function(ProfileEntry) _then) = _$ProfileEntryCopyWithImpl;
@useResult
$Res call({
 String id, String profileId, String personId, ProfileEntrySection section, ProfileEntryStatus status, String label, DateTime createdAt, DateTime updatedAt, String? parentEntryId, DateTime? firstNoted, DateTime? lastNoted, String? details, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});




}
/// @nodoc
class _$ProfileEntryCopyWithImpl<$Res>
    implements $ProfileEntryCopyWith<$Res> {
  _$ProfileEntryCopyWithImpl(this._self, this._then);

  final ProfileEntry _self;
  final $Res Function(ProfileEntry) _then;

/// Create a copy of ProfileEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? profileId = null,Object? personId = null,Object? section = null,Object? status = null,Object? label = null,Object? createdAt = null,Object? updatedAt = null,Object? parentEntryId = freezed,Object? firstNoted = freezed,Object? lastNoted = freezed,Object? details = freezed,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,profileId: null == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,section: null == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as ProfileEntrySection,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProfileEntryStatus,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,parentEntryId: freezed == parentEntryId ? _self.parentEntryId : parentEntryId // ignore: cast_nullable_to_non_nullable
as String?,firstNoted: freezed == firstNoted ? _self.firstNoted : firstNoted // ignore: cast_nullable_to_non_nullable
as DateTime?,lastNoted: freezed == lastNoted ? _self.lastNoted : lastNoted // ignore: cast_nullable_to_non_nullable
as DateTime?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileEntry].
extension ProfileEntryPatterns on ProfileEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileEntry value)  $default,){
final _that = this;
switch (_that) {
case _ProfileEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String profileId,  String personId,  ProfileEntrySection section,  ProfileEntryStatus status,  String label,  DateTime createdAt,  DateTime updatedAt,  String? parentEntryId,  DateTime? firstNoted,  DateTime? lastNoted,  String? details,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileEntry() when $default != null:
return $default(_that.id,_that.profileId,_that.personId,_that.section,_that.status,_that.label,_that.createdAt,_that.updatedAt,_that.parentEntryId,_that.firstNoted,_that.lastNoted,_that.details,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String profileId,  String personId,  ProfileEntrySection section,  ProfileEntryStatus status,  String label,  DateTime createdAt,  DateTime updatedAt,  String? parentEntryId,  DateTime? firstNoted,  DateTime? lastNoted,  String? details,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)  $default,) {final _that = this;
switch (_that) {
case _ProfileEntry():
return $default(_that.id,_that.profileId,_that.personId,_that.section,_that.status,_that.label,_that.createdAt,_that.updatedAt,_that.parentEntryId,_that.firstNoted,_that.lastNoted,_that.details,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String profileId,  String personId,  ProfileEntrySection section,  ProfileEntryStatus status,  String label,  DateTime createdAt,  DateTime updatedAt,  String? parentEntryId,  DateTime? firstNoted,  DateTime? lastNoted,  String? details,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,) {final _that = this;
switch (_that) {
case _ProfileEntry() when $default != null:
return $default(_that.id,_that.profileId,_that.personId,_that.section,_that.status,_that.label,_that.createdAt,_that.updatedAt,_that.parentEntryId,_that.firstNoted,_that.lastNoted,_that.details,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
  return null;

}
}

}

/// @nodoc


class _ProfileEntry implements ProfileEntry {
  const _ProfileEntry({required this.id, required this.profileId, required this.personId, required this.section, required this.status, required this.label, required this.createdAt, required this.updatedAt, this.parentEntryId, this.firstNoted, this.lastNoted, this.details, this.deletedAt, this.rowVersion = 1, this.lastWriterDeviceId, this.keyVersion = 1});
  

@override final  String id;
@override final  String profileId;
@override final  String personId;
@override final  ProfileEntrySection section;
@override final  ProfileEntryStatus status;
@override final  String label;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? parentEntryId;
@override final  DateTime? firstNoted;
@override final  DateTime? lastNoted;
@override final  String? details;
@override final  DateTime? deletedAt;
@override@JsonKey() final  int rowVersion;
@override final  String? lastWriterDeviceId;
@override@JsonKey() final  int keyVersion;

/// Create a copy of ProfileEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileEntryCopyWith<_ProfileEntry> get copyWith => __$ProfileEntryCopyWithImpl<_ProfileEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.section, section) || other.section == section)&&(identical(other.status, status) || other.status == status)&&(identical(other.label, label) || other.label == label)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.parentEntryId, parentEntryId) || other.parentEntryId == parentEntryId)&&(identical(other.firstNoted, firstNoted) || other.firstNoted == firstNoted)&&(identical(other.lastNoted, lastNoted) || other.lastNoted == lastNoted)&&(identical(other.details, details) || other.details == details)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,profileId,personId,section,status,label,createdAt,updatedAt,parentEntryId,firstNoted,lastNoted,details,deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'ProfileEntry(id: $id, profileId: $profileId, personId: $personId, section: $section, status: $status, label: $label, createdAt: $createdAt, updatedAt: $updatedAt, parentEntryId: $parentEntryId, firstNoted: $firstNoted, lastNoted: $lastNoted, details: $details, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class _$ProfileEntryCopyWith<$Res> implements $ProfileEntryCopyWith<$Res> {
  factory _$ProfileEntryCopyWith(_ProfileEntry value, $Res Function(_ProfileEntry) _then) = __$ProfileEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String profileId, String personId, ProfileEntrySection section, ProfileEntryStatus status, String label, DateTime createdAt, DateTime updatedAt, String? parentEntryId, DateTime? firstNoted, DateTime? lastNoted, String? details, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});




}
/// @nodoc
class __$ProfileEntryCopyWithImpl<$Res>
    implements _$ProfileEntryCopyWith<$Res> {
  __$ProfileEntryCopyWithImpl(this._self, this._then);

  final _ProfileEntry _self;
  final $Res Function(_ProfileEntry) _then;

/// Create a copy of ProfileEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? profileId = null,Object? personId = null,Object? section = null,Object? status = null,Object? label = null,Object? createdAt = null,Object? updatedAt = null,Object? parentEntryId = freezed,Object? firstNoted = freezed,Object? lastNoted = freezed,Object? details = freezed,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_ProfileEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,profileId: null == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,section: null == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as ProfileEntrySection,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProfileEntryStatus,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,parentEntryId: freezed == parentEntryId ? _self.parentEntryId : parentEntryId // ignore: cast_nullable_to_non_nullable
as String?,firstNoted: freezed == firstNoted ? _self.firstNoted : firstNoted // ignore: cast_nullable_to_non_nullable
as DateTime?,lastNoted: freezed == lastNoted ? _self.lastNoted : lastNoted // ignore: cast_nullable_to_non_nullable
as DateTime?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
