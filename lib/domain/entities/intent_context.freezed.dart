// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'intent_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IntentContext {

/// BCP-47 tag of the language the utterance is in: `pt-BR`, `en`, or `it`.
 String get locale;/// Issue keys the user has linked locally, as grounding for the model.
///
/// A hint, never a restriction: a user may name an issue they have not
/// linked yet, and the parser must still hear it.
 List<String> get knownIssueKeys;/// The intent being completed, when this is the second pass of a
/// missing-slot exchange.
 IntentType? get pendingIntent;/// Slots already established in that exchange, which the new answer adds
/// to rather than replaces.
 Map<String, dynamic> get providedSlots;
/// Create a copy of IntentContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntentContextCopyWith<IntentContext> get copyWith => _$IntentContextCopyWithImpl<IntentContext>(this as IntentContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IntentContext&&(identical(other.locale, locale) || other.locale == locale)&&const DeepCollectionEquality().equals(other.knownIssueKeys, knownIssueKeys)&&(identical(other.pendingIntent, pendingIntent) || other.pendingIntent == pendingIntent)&&const DeepCollectionEquality().equals(other.providedSlots, providedSlots));
}


@override
int get hashCode => Object.hash(runtimeType,locale,const DeepCollectionEquality().hash(knownIssueKeys),pendingIntent,const DeepCollectionEquality().hash(providedSlots));

@override
String toString() {
  return 'IntentContext(locale: $locale, knownIssueKeys: $knownIssueKeys, pendingIntent: $pendingIntent, providedSlots: $providedSlots)';
}


}

/// @nodoc
abstract mixin class $IntentContextCopyWith<$Res>  {
  factory $IntentContextCopyWith(IntentContext value, $Res Function(IntentContext) _then) = _$IntentContextCopyWithImpl;
@useResult
$Res call({
 String locale, List<String> knownIssueKeys, IntentType? pendingIntent, Map<String, dynamic> providedSlots
});




}
/// @nodoc
class _$IntentContextCopyWithImpl<$Res>
    implements $IntentContextCopyWith<$Res> {
  _$IntentContextCopyWithImpl(this._self, this._then);

  final IntentContext _self;
  final $Res Function(IntentContext) _then;

/// Create a copy of IntentContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? locale = null,Object? knownIssueKeys = null,Object? pendingIntent = freezed,Object? providedSlots = null,}) {
  return _then(_self.copyWith(
locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,knownIssueKeys: null == knownIssueKeys ? _self.knownIssueKeys : knownIssueKeys // ignore: cast_nullable_to_non_nullable
as List<String>,pendingIntent: freezed == pendingIntent ? _self.pendingIntent : pendingIntent // ignore: cast_nullable_to_non_nullable
as IntentType?,providedSlots: null == providedSlots ? _self.providedSlots : providedSlots // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [IntentContext].
extension IntentContextPatterns on IntentContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IntentContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IntentContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IntentContext value)  $default,){
final _that = this;
switch (_that) {
case _IntentContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IntentContext value)?  $default,){
final _that = this;
switch (_that) {
case _IntentContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String locale,  List<String> knownIssueKeys,  IntentType? pendingIntent,  Map<String, dynamic> providedSlots)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IntentContext() when $default != null:
return $default(_that.locale,_that.knownIssueKeys,_that.pendingIntent,_that.providedSlots);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String locale,  List<String> knownIssueKeys,  IntentType? pendingIntent,  Map<String, dynamic> providedSlots)  $default,) {final _that = this;
switch (_that) {
case _IntentContext():
return $default(_that.locale,_that.knownIssueKeys,_that.pendingIntent,_that.providedSlots);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String locale,  List<String> knownIssueKeys,  IntentType? pendingIntent,  Map<String, dynamic> providedSlots)?  $default,) {final _that = this;
switch (_that) {
case _IntentContext() when $default != null:
return $default(_that.locale,_that.knownIssueKeys,_that.pendingIntent,_that.providedSlots);case _:
  return null;

}
}

}

/// @nodoc


class _IntentContext extends IntentContext {
  const _IntentContext({this.locale = 'pt-BR', final  List<String> knownIssueKeys = const <String>[], this.pendingIntent, final  Map<String, dynamic> providedSlots = const <String, dynamic>{}}): _knownIssueKeys = knownIssueKeys,_providedSlots = providedSlots,super._();
  

/// BCP-47 tag of the language the utterance is in: `pt-BR`, `en`, or `it`.
@override@JsonKey() final  String locale;
/// Issue keys the user has linked locally, as grounding for the model.
///
/// A hint, never a restriction: a user may name an issue they have not
/// linked yet, and the parser must still hear it.
 final  List<String> _knownIssueKeys;
/// Issue keys the user has linked locally, as grounding for the model.
///
/// A hint, never a restriction: a user may name an issue they have not
/// linked yet, and the parser must still hear it.
@override@JsonKey() List<String> get knownIssueKeys {
  if (_knownIssueKeys is EqualUnmodifiableListView) return _knownIssueKeys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_knownIssueKeys);
}

/// The intent being completed, when this is the second pass of a
/// missing-slot exchange.
@override final  IntentType? pendingIntent;
/// Slots already established in that exchange, which the new answer adds
/// to rather than replaces.
 final  Map<String, dynamic> _providedSlots;
/// Slots already established in that exchange, which the new answer adds
/// to rather than replaces.
@override@JsonKey() Map<String, dynamic> get providedSlots {
  if (_providedSlots is EqualUnmodifiableMapView) return _providedSlots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_providedSlots);
}


/// Create a copy of IntentContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IntentContextCopyWith<_IntentContext> get copyWith => __$IntentContextCopyWithImpl<_IntentContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IntentContext&&(identical(other.locale, locale) || other.locale == locale)&&const DeepCollectionEquality().equals(other._knownIssueKeys, _knownIssueKeys)&&(identical(other.pendingIntent, pendingIntent) || other.pendingIntent == pendingIntent)&&const DeepCollectionEquality().equals(other._providedSlots, _providedSlots));
}


@override
int get hashCode => Object.hash(runtimeType,locale,const DeepCollectionEquality().hash(_knownIssueKeys),pendingIntent,const DeepCollectionEquality().hash(_providedSlots));

@override
String toString() {
  return 'IntentContext(locale: $locale, knownIssueKeys: $knownIssueKeys, pendingIntent: $pendingIntent, providedSlots: $providedSlots)';
}


}

/// @nodoc
abstract mixin class _$IntentContextCopyWith<$Res> implements $IntentContextCopyWith<$Res> {
  factory _$IntentContextCopyWith(_IntentContext value, $Res Function(_IntentContext) _then) = __$IntentContextCopyWithImpl;
@override @useResult
$Res call({
 String locale, List<String> knownIssueKeys, IntentType? pendingIntent, Map<String, dynamic> providedSlots
});




}
/// @nodoc
class __$IntentContextCopyWithImpl<$Res>
    implements _$IntentContextCopyWith<$Res> {
  __$IntentContextCopyWithImpl(this._self, this._then);

  final _IntentContext _self;
  final $Res Function(_IntentContext) _then;

/// Create a copy of IntentContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? locale = null,Object? knownIssueKeys = null,Object? pendingIntent = freezed,Object? providedSlots = null,}) {
  return _then(_IntentContext(
locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,knownIssueKeys: null == knownIssueKeys ? _self._knownIssueKeys : knownIssueKeys // ignore: cast_nullable_to_non_nullable
as List<String>,pendingIntent: freezed == pendingIntent ? _self.pendingIntent : pendingIntent // ignore: cast_nullable_to_non_nullable
as IntentType?,providedSlots: null == providedSlots ? _self._providedSlots : providedSlots // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
