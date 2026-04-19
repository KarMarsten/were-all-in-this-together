// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'observation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Observation {

 String get id; String get personId; DateTime get observedAt; ObservationCategory get category; String get label; DateTime get createdAt; DateTime get updatedAt; String? get profileEntryId; String? get notes; List<String> get tags; DateTime? get deletedAt; int get rowVersion; String? get lastWriterDeviceId; int get keyVersion;
/// Create a copy of Observation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ObservationCopyWith<Observation> get copyWith => _$ObservationCopyWithImpl<Observation>(this as Observation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Observation&&(identical(other.id, id) || other.id == id)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.observedAt, observedAt) || other.observedAt == observedAt)&&(identical(other.category, category) || other.category == category)&&(identical(other.label, label) || other.label == label)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.profileEntryId, profileEntryId) || other.profileEntryId == profileEntryId)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,personId,observedAt,category,label,createdAt,updatedAt,profileEntryId,notes,const DeepCollectionEquality().hash(tags),deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'Observation(id: $id, personId: $personId, observedAt: $observedAt, category: $category, label: $label, createdAt: $createdAt, updatedAt: $updatedAt, profileEntryId: $profileEntryId, notes: $notes, tags: $tags, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class $ObservationCopyWith<$Res>  {
  factory $ObservationCopyWith(Observation value, $Res Function(Observation) _then) = _$ObservationCopyWithImpl;
@useResult
$Res call({
 String id, String personId, DateTime observedAt, ObservationCategory category, String label, DateTime createdAt, DateTime updatedAt, String? profileEntryId, String? notes, List<String> tags, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});




}
/// @nodoc
class _$ObservationCopyWithImpl<$Res>
    implements $ObservationCopyWith<$Res> {
  _$ObservationCopyWithImpl(this._self, this._then);

  final Observation _self;
  final $Res Function(Observation) _then;

/// Create a copy of Observation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? personId = null,Object? observedAt = null,Object? category = null,Object? label = null,Object? createdAt = null,Object? updatedAt = null,Object? profileEntryId = freezed,Object? notes = freezed,Object? tags = null,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,observedAt: null == observedAt ? _self.observedAt : observedAt // ignore: cast_nullable_to_non_nullable
as DateTime,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ObservationCategory,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,profileEntryId: freezed == profileEntryId ? _self.profileEntryId : profileEntryId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Observation].
extension ObservationPatterns on Observation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Observation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Observation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Observation value)  $default,){
final _that = this;
switch (_that) {
case _Observation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Observation value)?  $default,){
final _that = this;
switch (_that) {
case _Observation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String personId,  DateTime observedAt,  ObservationCategory category,  String label,  DateTime createdAt,  DateTime updatedAt,  String? profileEntryId,  String? notes,  List<String> tags,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Observation() when $default != null:
return $default(_that.id,_that.personId,_that.observedAt,_that.category,_that.label,_that.createdAt,_that.updatedAt,_that.profileEntryId,_that.notes,_that.tags,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String personId,  DateTime observedAt,  ObservationCategory category,  String label,  DateTime createdAt,  DateTime updatedAt,  String? profileEntryId,  String? notes,  List<String> tags,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)  $default,) {final _that = this;
switch (_that) {
case _Observation():
return $default(_that.id,_that.personId,_that.observedAt,_that.category,_that.label,_that.createdAt,_that.updatedAt,_that.profileEntryId,_that.notes,_that.tags,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String personId,  DateTime observedAt,  ObservationCategory category,  String label,  DateTime createdAt,  DateTime updatedAt,  String? profileEntryId,  String? notes,  List<String> tags,  DateTime? deletedAt,  int rowVersion,  String? lastWriterDeviceId,  int keyVersion)?  $default,) {final _that = this;
switch (_that) {
case _Observation() when $default != null:
return $default(_that.id,_that.personId,_that.observedAt,_that.category,_that.label,_that.createdAt,_that.updatedAt,_that.profileEntryId,_that.notes,_that.tags,_that.deletedAt,_that.rowVersion,_that.lastWriterDeviceId,_that.keyVersion);case _:
  return null;

}
}

}

/// @nodoc


class _Observation implements Observation {
  const _Observation({required this.id, required this.personId, required this.observedAt, required this.category, required this.label, required this.createdAt, required this.updatedAt, this.profileEntryId, this.notes, final  List<String> tags = const <String>[], this.deletedAt, this.rowVersion = 1, this.lastWriterDeviceId, this.keyVersion = 1}): _tags = tags;
  

@override final  String id;
@override final  String personId;
@override final  DateTime observedAt;
@override final  ObservationCategory category;
@override final  String label;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? profileEntryId;
@override final  String? notes;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  DateTime? deletedAt;
@override@JsonKey() final  int rowVersion;
@override final  String? lastWriterDeviceId;
@override@JsonKey() final  int keyVersion;

/// Create a copy of Observation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ObservationCopyWith<_Observation> get copyWith => __$ObservationCopyWithImpl<_Observation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Observation&&(identical(other.id, id) || other.id == id)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.observedAt, observedAt) || other.observedAt == observedAt)&&(identical(other.category, category) || other.category == category)&&(identical(other.label, label) || other.label == label)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.profileEntryId, profileEntryId) || other.profileEntryId == profileEntryId)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.rowVersion, rowVersion) || other.rowVersion == rowVersion)&&(identical(other.lastWriterDeviceId, lastWriterDeviceId) || other.lastWriterDeviceId == lastWriterDeviceId)&&(identical(other.keyVersion, keyVersion) || other.keyVersion == keyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,personId,observedAt,category,label,createdAt,updatedAt,profileEntryId,notes,const DeepCollectionEquality().hash(_tags),deletedAt,rowVersion,lastWriterDeviceId,keyVersion);

@override
String toString() {
  return 'Observation(id: $id, personId: $personId, observedAt: $observedAt, category: $category, label: $label, createdAt: $createdAt, updatedAt: $updatedAt, profileEntryId: $profileEntryId, notes: $notes, tags: $tags, deletedAt: $deletedAt, rowVersion: $rowVersion, lastWriterDeviceId: $lastWriterDeviceId, keyVersion: $keyVersion)';
}


}

/// @nodoc
abstract mixin class _$ObservationCopyWith<$Res> implements $ObservationCopyWith<$Res> {
  factory _$ObservationCopyWith(_Observation value, $Res Function(_Observation) _then) = __$ObservationCopyWithImpl;
@override @useResult
$Res call({
 String id, String personId, DateTime observedAt, ObservationCategory category, String label, DateTime createdAt, DateTime updatedAt, String? profileEntryId, String? notes, List<String> tags, DateTime? deletedAt, int rowVersion, String? lastWriterDeviceId, int keyVersion
});




}
/// @nodoc
class __$ObservationCopyWithImpl<$Res>
    implements _$ObservationCopyWith<$Res> {
  __$ObservationCopyWithImpl(this._self, this._then);

  final _Observation _self;
  final $Res Function(_Observation) _then;

/// Create a copy of Observation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? personId = null,Object? observedAt = null,Object? category = null,Object? label = null,Object? createdAt = null,Object? updatedAt = null,Object? profileEntryId = freezed,Object? notes = freezed,Object? tags = null,Object? deletedAt = freezed,Object? rowVersion = null,Object? lastWriterDeviceId = freezed,Object? keyVersion = null,}) {
  return _then(_Observation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,observedAt: null == observedAt ? _self.observedAt : observedAt // ignore: cast_nullable_to_non_nullable
as DateTime,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ObservationCategory,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,profileEntryId: freezed == profileEntryId ? _self.profileEntryId : profileEntryId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rowVersion: null == rowVersion ? _self.rowVersion : rowVersion // ignore: cast_nullable_to_non_nullable
as int,lastWriterDeviceId: freezed == lastWriterDeviceId ? _self.lastWriterDeviceId : lastWriterDeviceId // ignore: cast_nullable_to_non_nullable
as String?,keyVersion: null == keyVersion ? _self.keyVersion : keyVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
