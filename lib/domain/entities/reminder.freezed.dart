// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Reminder {

 String get id;/// Transcribed text. The audio it came from is discarded immediately after
/// the transcription is confirmed (BR-06) — no field here ever holds it.
 String get text;/// When the notification should fire.
 DateTime get triggerAt; DateTime get createdAt;/// `true` once the notification has been delivered.
 bool get isFired;/// Transient handle to the capture that produced [text]
/// (`docs/architecture.md` §3.1). It is cleared as soon as the
/// transcription is confirmed and **must never be persisted** (BR-06) —
/// the Sprint 06 repository drops this field on write.
 String? get sourceAudioNote;
/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReminderCopyWith<Reminder> get copyWith => _$ReminderCopyWithImpl<Reminder>(this as Reminder, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reminder&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.triggerAt, triggerAt) || other.triggerAt == triggerAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isFired, isFired) || other.isFired == isFired)&&(identical(other.sourceAudioNote, sourceAudioNote) || other.sourceAudioNote == sourceAudioNote));
}


@override
int get hashCode => Object.hash(runtimeType,id,text,triggerAt,createdAt,isFired,sourceAudioNote);

@override
String toString() {
  return 'Reminder(id: $id, text: $text, triggerAt: $triggerAt, createdAt: $createdAt, isFired: $isFired, sourceAudioNote: $sourceAudioNote)';
}


}

/// @nodoc
abstract mixin class $ReminderCopyWith<$Res>  {
  factory $ReminderCopyWith(Reminder value, $Res Function(Reminder) _then) = _$ReminderCopyWithImpl;
@useResult
$Res call({
 String id, String text, DateTime triggerAt, DateTime createdAt, bool isFired, String? sourceAudioNote
});




}
/// @nodoc
class _$ReminderCopyWithImpl<$Res>
    implements $ReminderCopyWith<$Res> {
  _$ReminderCopyWithImpl(this._self, this._then);

  final Reminder _self;
  final $Res Function(Reminder) _then;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? triggerAt = null,Object? createdAt = null,Object? isFired = null,Object? sourceAudioNote = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,triggerAt: null == triggerAt ? _self.triggerAt : triggerAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isFired: null == isFired ? _self.isFired : isFired // ignore: cast_nullable_to_non_nullable
as bool,sourceAudioNote: freezed == sourceAudioNote ? _self.sourceAudioNote : sourceAudioNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Reminder].
extension ReminderPatterns on Reminder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reminder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reminder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reminder value)  $default,){
final _that = this;
switch (_that) {
case _Reminder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reminder value)?  $default,){
final _that = this;
switch (_that) {
case _Reminder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String text,  DateTime triggerAt,  DateTime createdAt,  bool isFired,  String? sourceAudioNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reminder() when $default != null:
return $default(_that.id,_that.text,_that.triggerAt,_that.createdAt,_that.isFired,_that.sourceAudioNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String text,  DateTime triggerAt,  DateTime createdAt,  bool isFired,  String? sourceAudioNote)  $default,) {final _that = this;
switch (_that) {
case _Reminder():
return $default(_that.id,_that.text,_that.triggerAt,_that.createdAt,_that.isFired,_that.sourceAudioNote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String text,  DateTime triggerAt,  DateTime createdAt,  bool isFired,  String? sourceAudioNote)?  $default,) {final _that = this;
switch (_that) {
case _Reminder() when $default != null:
return $default(_that.id,_that.text,_that.triggerAt,_that.createdAt,_that.isFired,_that.sourceAudioNote);case _:
  return null;

}
}

}

/// @nodoc


class _Reminder implements Reminder {
  const _Reminder({required this.id, required this.text, required this.triggerAt, required this.createdAt, this.isFired = false, this.sourceAudioNote});
  

@override final  String id;
/// Transcribed text. The audio it came from is discarded immediately after
/// the transcription is confirmed (BR-06) — no field here ever holds it.
@override final  String text;
/// When the notification should fire.
@override final  DateTime triggerAt;
@override final  DateTime createdAt;
/// `true` once the notification has been delivered.
@override@JsonKey() final  bool isFired;
/// Transient handle to the capture that produced [text]
/// (`docs/architecture.md` §3.1). It is cleared as soon as the
/// transcription is confirmed and **must never be persisted** (BR-06) —
/// the Sprint 06 repository drops this field on write.
@override final  String? sourceAudioNote;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReminderCopyWith<_Reminder> get copyWith => __$ReminderCopyWithImpl<_Reminder>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reminder&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.triggerAt, triggerAt) || other.triggerAt == triggerAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isFired, isFired) || other.isFired == isFired)&&(identical(other.sourceAudioNote, sourceAudioNote) || other.sourceAudioNote == sourceAudioNote));
}


@override
int get hashCode => Object.hash(runtimeType,id,text,triggerAt,createdAt,isFired,sourceAudioNote);

@override
String toString() {
  return 'Reminder(id: $id, text: $text, triggerAt: $triggerAt, createdAt: $createdAt, isFired: $isFired, sourceAudioNote: $sourceAudioNote)';
}


}

/// @nodoc
abstract mixin class _$ReminderCopyWith<$Res> implements $ReminderCopyWith<$Res> {
  factory _$ReminderCopyWith(_Reminder value, $Res Function(_Reminder) _then) = __$ReminderCopyWithImpl;
@override @useResult
$Res call({
 String id, String text, DateTime triggerAt, DateTime createdAt, bool isFired, String? sourceAudioNote
});




}
/// @nodoc
class __$ReminderCopyWithImpl<$Res>
    implements _$ReminderCopyWith<$Res> {
  __$ReminderCopyWithImpl(this._self, this._then);

  final _Reminder _self;
  final $Res Function(_Reminder) _then;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? triggerAt = null,Object? createdAt = null,Object? isFired = null,Object? sourceAudioNote = freezed,}) {
  return _then(_Reminder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,triggerAt: null == triggerAt ? _self.triggerAt : triggerAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isFired: null == isFired ? _self.isFired : isFired // ignore: cast_nullable_to_non_nullable
as bool,sourceAudioNote: freezed == sourceAudioNote ? _self.sourceAudioNote : sourceAudioNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
