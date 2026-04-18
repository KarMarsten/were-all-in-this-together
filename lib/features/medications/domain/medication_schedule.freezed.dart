// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medication_schedule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MedicationSchedule implements DiagnosticableTreeMixin {

 ScheduleKind get kind; List<ScheduledTime> get times;/// ISO-8601 weekdays: 1 = Monday ... 7 = Sunday. Empty for
/// [ScheduleKind.daily] and [ScheduleKind.asNeeded].
 Set<int> get days;
/// Create a copy of MedicationSchedule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicationScheduleCopyWith<MedicationSchedule> get copyWith => _$MedicationScheduleCopyWithImpl<MedicationSchedule>(this as MedicationSchedule, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MedicationSchedule'))
    ..add(DiagnosticsProperty('kind', kind))..add(DiagnosticsProperty('times', times))..add(DiagnosticsProperty('days', days));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicationSchedule&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.times, times)&&const DeepCollectionEquality().equals(other.days, days));
}


@override
int get hashCode => Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(times),const DeepCollectionEquality().hash(days));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MedicationSchedule(kind: $kind, times: $times, days: $days)';
}


}

/// @nodoc
abstract mixin class $MedicationScheduleCopyWith<$Res>  {
  factory $MedicationScheduleCopyWith(MedicationSchedule value, $Res Function(MedicationSchedule) _then) = _$MedicationScheduleCopyWithImpl;
@useResult
$Res call({
 ScheduleKind kind, List<ScheduledTime> times, Set<int> days
});




}
/// @nodoc
class _$MedicationScheduleCopyWithImpl<$Res>
    implements $MedicationScheduleCopyWith<$Res> {
  _$MedicationScheduleCopyWithImpl(this._self, this._then);

  final MedicationSchedule _self;
  final $Res Function(MedicationSchedule) _then;

/// Create a copy of MedicationSchedule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? times = null,Object? days = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ScheduleKind,times: null == times ? _self.times : times // ignore: cast_nullable_to_non_nullable
as List<ScheduledTime>,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [MedicationSchedule].
extension MedicationSchedulePatterns on MedicationSchedule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedicationSchedule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedicationSchedule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedicationSchedule value)  $default,){
final _that = this;
switch (_that) {
case _MedicationSchedule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedicationSchedule value)?  $default,){
final _that = this;
switch (_that) {
case _MedicationSchedule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ScheduleKind kind,  List<ScheduledTime> times,  Set<int> days)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedicationSchedule() when $default != null:
return $default(_that.kind,_that.times,_that.days);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ScheduleKind kind,  List<ScheduledTime> times,  Set<int> days)  $default,) {final _that = this;
switch (_that) {
case _MedicationSchedule():
return $default(_that.kind,_that.times,_that.days);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ScheduleKind kind,  List<ScheduledTime> times,  Set<int> days)?  $default,) {final _that = this;
switch (_that) {
case _MedicationSchedule() when $default != null:
return $default(_that.kind,_that.times,_that.days);case _:
  return null;

}
}

}

/// @nodoc


class _MedicationSchedule extends MedicationSchedule with DiagnosticableTreeMixin {
  const _MedicationSchedule({required this.kind, final  List<ScheduledTime> times = const <ScheduledTime>[], final  Set<int> days = const <int>{}}): _times = times,_days = days,super._();
  

@override final  ScheduleKind kind;
 final  List<ScheduledTime> _times;
@override@JsonKey() List<ScheduledTime> get times {
  if (_times is EqualUnmodifiableListView) return _times;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_times);
}

/// ISO-8601 weekdays: 1 = Monday ... 7 = Sunday. Empty for
/// [ScheduleKind.daily] and [ScheduleKind.asNeeded].
 final  Set<int> _days;
/// ISO-8601 weekdays: 1 = Monday ... 7 = Sunday. Empty for
/// [ScheduleKind.daily] and [ScheduleKind.asNeeded].
@override@JsonKey() Set<int> get days {
  if (_days is EqualUnmodifiableSetView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_days);
}


/// Create a copy of MedicationSchedule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicationScheduleCopyWith<_MedicationSchedule> get copyWith => __$MedicationScheduleCopyWithImpl<_MedicationSchedule>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MedicationSchedule'))
    ..add(DiagnosticsProperty('kind', kind))..add(DiagnosticsProperty('times', times))..add(DiagnosticsProperty('days', days));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedicationSchedule&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other._times, _times)&&const DeepCollectionEquality().equals(other._days, _days));
}


@override
int get hashCode => Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(_times),const DeepCollectionEquality().hash(_days));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MedicationSchedule(kind: $kind, times: $times, days: $days)';
}


}

/// @nodoc
abstract mixin class _$MedicationScheduleCopyWith<$Res> implements $MedicationScheduleCopyWith<$Res> {
  factory _$MedicationScheduleCopyWith(_MedicationSchedule value, $Res Function(_MedicationSchedule) _then) = __$MedicationScheduleCopyWithImpl;
@override @useResult
$Res call({
 ScheduleKind kind, List<ScheduledTime> times, Set<int> days
});




}
/// @nodoc
class __$MedicationScheduleCopyWithImpl<$Res>
    implements _$MedicationScheduleCopyWith<$Res> {
  __$MedicationScheduleCopyWithImpl(this._self, this._then);

  final _MedicationSchedule _self;
  final $Res Function(_MedicationSchedule) _then;

/// Create a copy of MedicationSchedule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? times = null,Object? days = null,}) {
  return _then(_MedicationSchedule(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ScheduleKind,times: null == times ? _self._times : times // ignore: cast_nullable_to_non_nullable
as List<ScheduledTime>,days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}


}

// dart format on
