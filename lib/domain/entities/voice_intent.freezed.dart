// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'voice_intent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VoiceIntent {

 IntentType get type;/// Extracted parameters, e.g. `{issueKey: PROJ-123, transition: Done}`.
///
/// The one place `dynamic` is allowed in a public signature
/// (`docs/project-rules.md` §6) — the slot set is defined by the intent.
 Map<String, dynamic> get slots;/// Model confidence in `0.0..1.0`.
 double get confidence;
/// Create a copy of VoiceIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoiceIntentCopyWith<VoiceIntent> get copyWith => _$VoiceIntentCopyWithImpl<VoiceIntent>(this as VoiceIntent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoiceIntent&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.slots, slots)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}


@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(slots),confidence);

@override
String toString() {
  return 'VoiceIntent(type: $type, slots: $slots, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class $VoiceIntentCopyWith<$Res>  {
  factory $VoiceIntentCopyWith(VoiceIntent value, $Res Function(VoiceIntent) _then) = _$VoiceIntentCopyWithImpl;
@useResult
$Res call({
 IntentType type, Map<String, dynamic> slots, double confidence
});




}
/// @nodoc
class _$VoiceIntentCopyWithImpl<$Res>
    implements $VoiceIntentCopyWith<$Res> {
  _$VoiceIntentCopyWithImpl(this._self, this._then);

  final VoiceIntent _self;
  final $Res Function(VoiceIntent) _then;

/// Create a copy of VoiceIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? slots = null,Object? confidence = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IntentType,slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [VoiceIntent].
extension VoiceIntentPatterns on VoiceIntent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VoiceIntent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VoiceIntent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VoiceIntent value)  $default,){
final _that = this;
switch (_that) {
case _VoiceIntent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VoiceIntent value)?  $default,){
final _that = this;
switch (_that) {
case _VoiceIntent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( IntentType type,  Map<String, dynamic> slots,  double confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VoiceIntent() when $default != null:
return $default(_that.type,_that.slots,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( IntentType type,  Map<String, dynamic> slots,  double confidence)  $default,) {final _that = this;
switch (_that) {
case _VoiceIntent():
return $default(_that.type,_that.slots,_that.confidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( IntentType type,  Map<String, dynamic> slots,  double confidence)?  $default,) {final _that = this;
switch (_that) {
case _VoiceIntent() when $default != null:
return $default(_that.type,_that.slots,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc


class _VoiceIntent extends VoiceIntent {
  const _VoiceIntent({required this.type, final  Map<String, dynamic> slots = const <String, dynamic>{}, this.confidence = 0.0}): _slots = slots,super._();
  

@override final  IntentType type;
/// Extracted parameters, e.g. `{issueKey: PROJ-123, transition: Done}`.
///
/// The one place `dynamic` is allowed in a public signature
/// (`docs/project-rules.md` §6) — the slot set is defined by the intent.
 final  Map<String, dynamic> _slots;
/// Extracted parameters, e.g. `{issueKey: PROJ-123, transition: Done}`.
///
/// The one place `dynamic` is allowed in a public signature
/// (`docs/project-rules.md` §6) — the slot set is defined by the intent.
@override@JsonKey() Map<String, dynamic> get slots {
  if (_slots is EqualUnmodifiableMapView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_slots);
}

/// Model confidence in `0.0..1.0`.
@override@JsonKey() final  double confidence;

/// Create a copy of VoiceIntent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VoiceIntentCopyWith<_VoiceIntent> get copyWith => __$VoiceIntentCopyWithImpl<_VoiceIntent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VoiceIntent&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._slots, _slots)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}


@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_slots),confidence);

@override
String toString() {
  return 'VoiceIntent(type: $type, slots: $slots, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$VoiceIntentCopyWith<$Res> implements $VoiceIntentCopyWith<$Res> {
  factory _$VoiceIntentCopyWith(_VoiceIntent value, $Res Function(_VoiceIntent) _then) = __$VoiceIntentCopyWithImpl;
@override @useResult
$Res call({
 IntentType type, Map<String, dynamic> slots, double confidence
});




}
/// @nodoc
class __$VoiceIntentCopyWithImpl<$Res>
    implements _$VoiceIntentCopyWith<$Res> {
  __$VoiceIntentCopyWithImpl(this._self, this._then);

  final _VoiceIntent _self;
  final $Res Function(_VoiceIntent) _then;

/// Create a copy of VoiceIntent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? slots = null,Object? confidence = null,}) {
  return _then(_VoiceIntent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IntentType,slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
