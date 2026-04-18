// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'care_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CareProvider {

/// Client-generated UUID v4. Stable across devices, never reused.
 String get id;/// Owning Person's id. Never mutated after creation — moving a
/// provider between People requires a new row so the AAD / key
/// binding stays honest.
 String get personId;/// Free-form display name. Required — "Dr. Chen", "Park Pediatrics",
/// "Ms. Alvarez (OT)", whatever the user actually says.
 String get name;/// Coarse category; see [CareProviderKind] for why this enum is
/// deliberately small.
 CareProviderKind get kind;/// Metadata propagated from the DB row.
 DateTime get createdAt; DateTime get updatedAt;/// Free-text specialty, e.g. "OT", "developmental pediatrics",
/// "speech-language". Kept as free text rather than a second enum
/// so clinical precision can grow without schema changes.
 String? get specialty;/// Dialable phone number (free-form — we don't parse or format).
 String? get phone;/// Single-line address for lookup / navigation. We deliberately do
/// not structure this — users paste from Contacts and Maps handles
/// the rest.
 String? get address;/// Patient portal URL. Expected to be `http(s)://…`; validated at
/// the form layer, not here.
 String? get portalUrl;/// Free-form notes — office hours, receptionist's name, in-network
/// dates, whatever the user finds worth remembering.
 String? get notes; DateTime? get deletedAt; int get rowVersion; String? get lastWriterDeviceId; int get keyVersion;
/// Create a copy of CareProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CareProviderCopyWith<CareProvider> get copyWith => _$CareProviderCopyWithImpl<CareProvider>(this as CareProvider, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CareProvider&&(identical(other.id, id) || other.id == id)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.specialty, specialty) || other.specialty == specialty)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.address, address) || other.address == address)&&(identical(other.portalUrl, portalUrl) || other.portalUrl == portalUrl)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,personId,name,kind,createdAt,updatedAt,specialty,phone,address,portalUrl,notes,deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'CareProvider(id: $id, personId: $personId, name: $name, kind: $kind, createdAt: $createdAt, updatedAt: $updatedAt, specialty: $specialty, phone: $phone, address: $address, portalUrl: $portalUrl, notes: $notes, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class $CareProviderCopyWith<$Res>  {
  factory $CareProviderCopyWith(CareProvider value, $Res Function(CareProvider) _then) = _$CareProviderCopyWithImpl;
@useResult
$Res call({
 String id, String personId, String name, CareProviderKind kind, DateTime createdAt, DateTime updatedAt, String? specialty, String? phone, String? address, String? portalUrl, String? notes, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});




}
/// @nodoc
class _$CareProviderCopyWithImpl<$Res>
    implements $CareProviderCopyWith<$Res> {
  _$CareProviderCopyWithImpl(this._self, this._then);

  final CareProvider _self;
  final $Res Function(CareProvider) _then;

/// Create a copy of CareProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? personId = null,Object? name = null,Object? kind = null,Object? createdAt = null,Object? updatedAt = null,Object? specialty = freezed,Object? phone = freezed,Object? address = freezed,Object? portalUrl = freezed,Object? notes = freezed,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as CareProviderKind,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,specialty: freezed == specialty ? _self.specialty : specialty // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,portalUrl: freezed == portalUrl ? _self.portalUrl : portalUrl // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CareProvider].
extension CareProviderPatterns on CareProvider {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CareProvider value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CareProvider() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CareProvider value)  $default,){
final _that = this;
switch (_that) {
case _CareProvider():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CareProvider value)?  $default,){
final _that = this;
switch (_that) {
case _CareProvider() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String personId,  String name,  CareProviderKind kind,  DateTime createdAt,  DateTime updatedAt,  String? specialty,  String? phone,  String? address,  String? portalUrl,  String? notes,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CareProvider() when $default != null:
return $default(_that.id,_that.personId,_that.name,_that.kind,_that.createdAt,_that.updatedAt,_that.specialty,_that.phone,_that.address,_that.portalUrl,_that.notes,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String personId,  String name,  CareProviderKind kind,  DateTime createdAt,  DateTime updatedAt,  String? specialty,  String? phone,  String? address,  String? portalUrl,  String? notes,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)  $default,) {final _that = this;
switch (_that) {
case _CareProvider():
return $default(_that.id,_that.personId,_that.name,_that.kind,_that.createdAt,_that.updatedAt,_that.specialty,_that.phone,_that.address,_that.portalUrl,_that.notes,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String personId,  String name,  CareProviderKind kind,  DateTime createdAt,  DateTime updatedAt,  String? specialty,  String? phone,  String? address,  String? portalUrl,  String? notes,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,) {final _that = this;
switch (_that) {
case _CareProvider() when $default != null:
return $default(_that.id,_that.personId,_that.name,_that.kind,_that.createdAt,_that.updatedAt,_that.specialty,_that.phone,_that.address,_that.portalUrl,_that.notes,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
  return null;

}
}

}

/// @nodoc


class _CareProvider implements CareProvider {
  const _CareProvider({required this.id, required this.personId, required this.name, required this.kind, required this.createdAt, required this.updatedAt, this.specialty, this.phone, this.address, this.portalUrl, this.notes, this.deletedAt, this.rowVersion = 1, this.lastWriterDeviceId, this.keyVersion = 1});
  

/// Client-generated UUID v4. Stable across devices, never reused.
@override final  String id;
/// Owning Person's id. Never mutated after creation — moving a
/// provider between People requires a new row so the AAD / key
/// binding stays honest.
@override final  String personId;
/// Free-form display name. Required — "Dr. Chen", "Park Pediatrics",
/// "Ms. Alvarez (OT)", whatever the user actually says.
@override final  String name;
/// Coarse category; see [CareProviderKind] for why this enum is
/// deliberately small.
@override final  CareProviderKind kind;
/// Metadata propagated from the DB row.
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// Free-text specialty, e.g. "OT", "developmental pediatrics",
/// "speech-language". Kept as free text rather than a second enum
/// so clinical precision can grow without schema changes.
@override final  String? specialty;
/// Dialable phone number (free-form — we don't parse or format).
@override final  String? phone;
/// Single-line address for lookup / navigation. We deliberately do
/// not structure this — users paste from Contacts and Maps handles
/// the rest.
@override final  String? address;
/// Patient portal URL. Expected to be `http(s)://…`; validated at
/// the form layer, not here.
@override final  String? portalUrl;
/// Free-form notes — office hours, receptionist's name, in-network
/// dates, whatever the user finds worth remembering.
@override final  String? notes;
@override final  DateTime? deletedAt;
@override@JsonKey() final  int rowVersion;
@override final  String? lastWriterDeviceId;
@override@JsonKey() final  int keyVersion;

/// Create a copy of CareProvider
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CareProviderCopyWith<_CareProvider> get copyWith => __$CareProviderCopyWithImpl<_CareProvider>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CareProvider&&(identical(other.id, id) || other.id == id)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.specialty, specialty) || other.specialty == specialty)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.address, address) || other.address == address)&&(identical(other.portalUrl, portalUrl) || other.portalUrl == portalUrl)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,personId,name,kind,createdAt,updatedAt,specialty,phone,address,portalUrl,notes,deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'CareProvider(id: $id, personId: $personId, name: $name, kind: $kind, createdAt: $createdAt, updatedAt: $updatedAt, specialty: $specialty, phone: $phone, address: $address, portalUrl: $portalUrl, notes: $notes, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class _$CareProviderCopyWith<$Res> implements $CareProviderCopyWith<$Res> {
  factory _$CareProviderCopyWith(_CareProvider value, $Res Function(_CareProvider) _then) = __$CareProviderCopyWithImpl;
@override @useResult
$Res call({
 String id, String personId, String name, CareProviderKind kind, DateTime createdAt, DateTime updatedAt, String? specialty, String? phone, String? address, String? portalUrl, String? notes, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});




}
/// @nodoc
class __$CareProviderCopyWithImpl<$Res>
    implements _$CareProviderCopyWith<$Res> {
  __$CareProviderCopyWithImpl(this._self, this._then);

  final _CareProvider _self;
  final $Res Function(_CareProvider) _then;

/// Create a copy of CareProvider
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? personId = null,Object? name = null,Object? kind = null,Object? createdAt = null,Object? updatedAt = null,Object? specialty = freezed,Object? phone = freezed,Object? address = freezed,Object? portalUrl = freezed,Object? notes = freezed,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_CareProvider(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as CareProviderKind,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,specialty: freezed == specialty ? _self.specialty : specialty // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,portalUrl: freezed == portalUrl ? _self.portalUrl : portalUrl // ignore: cast_nullable_to_non_nullable
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
