// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'outbox_operation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OutboxOperation {

/// Idempotency key (BR-05). A UUID v4 from the use case, stable across
/// attempts.
 String get operationId; OutboxOperationKind get kind;/// Issue the write targets — or, for [OutboxOperationKind.createIssue],
/// the project key it will be created in.
 String get issueKey;/// Kind-dependent argument: the target status, the comment body, or the
/// summary of the issue to create.
 String get payload;/// When the operation was enqueued.
 DateTime get createdAt;/// Local task the operation belongs to, when there is one. Lets the
/// dispatcher write the resulting issue key back onto the task after a
/// [OutboxOperationKind.createIssue].
 String? get taskId; OutboxOperationState get state;/// How many times the dispatcher has tried. `0` before the first attempt.
 int get attempts;/// Earliest instant the next attempt may run — the backoff window.
/// `null` means "as soon as the dispatcher gets to it".
 DateTime? get nextAttemptAt;/// Message of the failure that ended the last attempt, for the UI and the
/// report. Never carries a payload or a credential (BR-08).
 String? get lastError;/// Insertion order, assigned by the repository. The dispatcher works in
/// ascending order so that two writes to the same issue reach Jira in the
/// order the user made them (S02-IT-03) — [createdAt] cannot serve, since
/// two operations created in the same millisecond would tie.
 int get sequence;
/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutboxOperationCopyWith<OutboxOperation> get copyWith => _$OutboxOperationCopyWithImpl<OutboxOperation>(this as OutboxOperation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutboxOperation&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.issueKey, issueKey) || other.issueKey == issueKey)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.state, state) || other.state == state)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.nextAttemptAt, nextAttemptAt) || other.nextAttemptAt == nextAttemptAt)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.sequence, sequence) || other.sequence == sequence));
}


@override
int get hashCode => Object.hash(runtimeType,operationId,kind,issueKey,payload,createdAt,taskId,state,attempts,nextAttemptAt,lastError,sequence);

@override
String toString() {
  return 'OutboxOperation(operationId: $operationId, kind: $kind, issueKey: $issueKey, payload: $payload, createdAt: $createdAt, taskId: $taskId, state: $state, attempts: $attempts, nextAttemptAt: $nextAttemptAt, lastError: $lastError, sequence: $sequence)';
}


}

/// @nodoc
abstract mixin class $OutboxOperationCopyWith<$Res>  {
  factory $OutboxOperationCopyWith(OutboxOperation value, $Res Function(OutboxOperation) _then) = _$OutboxOperationCopyWithImpl;
@useResult
$Res call({
 String operationId, OutboxOperationKind kind, String issueKey, String payload, DateTime createdAt, String? taskId, OutboxOperationState state, int attempts, DateTime? nextAttemptAt, String? lastError, int sequence
});




}
/// @nodoc
class _$OutboxOperationCopyWithImpl<$Res>
    implements $OutboxOperationCopyWith<$Res> {
  _$OutboxOperationCopyWithImpl(this._self, this._then);

  final OutboxOperation _self;
  final $Res Function(OutboxOperation) _then;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? operationId = null,Object? kind = null,Object? issueKey = null,Object? payload = null,Object? createdAt = null,Object? taskId = freezed,Object? state = null,Object? attempts = null,Object? nextAttemptAt = freezed,Object? lastError = freezed,Object? sequence = null,}) {
  return _then(_self.copyWith(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as OutboxOperationKind,issueKey: null == issueKey ? _self.issueKey : issueKey // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,taskId: freezed == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as OutboxOperationState,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,nextAttemptAt: freezed == nextAttemptAt ? _self.nextAttemptAt : nextAttemptAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OutboxOperation].
extension OutboxOperationPatterns on OutboxOperation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutboxOperation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutboxOperation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutboxOperation value)  $default,){
final _that = this;
switch (_that) {
case _OutboxOperation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutboxOperation value)?  $default,){
final _that = this;
switch (_that) {
case _OutboxOperation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String operationId,  OutboxOperationKind kind,  String issueKey,  String payload,  DateTime createdAt,  String? taskId,  OutboxOperationState state,  int attempts,  DateTime? nextAttemptAt,  String? lastError,  int sequence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutboxOperation() when $default != null:
return $default(_that.operationId,_that.kind,_that.issueKey,_that.payload,_that.createdAt,_that.taskId,_that.state,_that.attempts,_that.nextAttemptAt,_that.lastError,_that.sequence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String operationId,  OutboxOperationKind kind,  String issueKey,  String payload,  DateTime createdAt,  String? taskId,  OutboxOperationState state,  int attempts,  DateTime? nextAttemptAt,  String? lastError,  int sequence)  $default,) {final _that = this;
switch (_that) {
case _OutboxOperation():
return $default(_that.operationId,_that.kind,_that.issueKey,_that.payload,_that.createdAt,_that.taskId,_that.state,_that.attempts,_that.nextAttemptAt,_that.lastError,_that.sequence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String operationId,  OutboxOperationKind kind,  String issueKey,  String payload,  DateTime createdAt,  String? taskId,  OutboxOperationState state,  int attempts,  DateTime? nextAttemptAt,  String? lastError,  int sequence)?  $default,) {final _that = this;
switch (_that) {
case _OutboxOperation() when $default != null:
return $default(_that.operationId,_that.kind,_that.issueKey,_that.payload,_that.createdAt,_that.taskId,_that.state,_that.attempts,_that.nextAttemptAt,_that.lastError,_that.sequence);case _:
  return null;

}
}

}

/// @nodoc


class _OutboxOperation implements OutboxOperation {
  const _OutboxOperation({required this.operationId, required this.kind, required this.issueKey, required this.payload, required this.createdAt, this.taskId, this.state = OutboxOperationState.pending, this.attempts = 0, this.nextAttemptAt, this.lastError, this.sequence = 0});
  

/// Idempotency key (BR-05). A UUID v4 from the use case, stable across
/// attempts.
@override final  String operationId;
@override final  OutboxOperationKind kind;
/// Issue the write targets — or, for [OutboxOperationKind.createIssue],
/// the project key it will be created in.
@override final  String issueKey;
/// Kind-dependent argument: the target status, the comment body, or the
/// summary of the issue to create.
@override final  String payload;
/// When the operation was enqueued.
@override final  DateTime createdAt;
/// Local task the operation belongs to, when there is one. Lets the
/// dispatcher write the resulting issue key back onto the task after a
/// [OutboxOperationKind.createIssue].
@override final  String? taskId;
@override@JsonKey() final  OutboxOperationState state;
/// How many times the dispatcher has tried. `0` before the first attempt.
@override@JsonKey() final  int attempts;
/// Earliest instant the next attempt may run — the backoff window.
/// `null` means "as soon as the dispatcher gets to it".
@override final  DateTime? nextAttemptAt;
/// Message of the failure that ended the last attempt, for the UI and the
/// report. Never carries a payload or a credential (BR-08).
@override final  String? lastError;
/// Insertion order, assigned by the repository. The dispatcher works in
/// ascending order so that two writes to the same issue reach Jira in the
/// order the user made them (S02-IT-03) — [createdAt] cannot serve, since
/// two operations created in the same millisecond would tie.
@override@JsonKey() final  int sequence;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutboxOperationCopyWith<_OutboxOperation> get copyWith => __$OutboxOperationCopyWithImpl<_OutboxOperation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutboxOperation&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.issueKey, issueKey) || other.issueKey == issueKey)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.state, state) || other.state == state)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.nextAttemptAt, nextAttemptAt) || other.nextAttemptAt == nextAttemptAt)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.sequence, sequence) || other.sequence == sequence));
}


@override
int get hashCode => Object.hash(runtimeType,operationId,kind,issueKey,payload,createdAt,taskId,state,attempts,nextAttemptAt,lastError,sequence);

@override
String toString() {
  return 'OutboxOperation(operationId: $operationId, kind: $kind, issueKey: $issueKey, payload: $payload, createdAt: $createdAt, taskId: $taskId, state: $state, attempts: $attempts, nextAttemptAt: $nextAttemptAt, lastError: $lastError, sequence: $sequence)';
}


}

/// @nodoc
abstract mixin class _$OutboxOperationCopyWith<$Res> implements $OutboxOperationCopyWith<$Res> {
  factory _$OutboxOperationCopyWith(_OutboxOperation value, $Res Function(_OutboxOperation) _then) = __$OutboxOperationCopyWithImpl;
@override @useResult
$Res call({
 String operationId, OutboxOperationKind kind, String issueKey, String payload, DateTime createdAt, String? taskId, OutboxOperationState state, int attempts, DateTime? nextAttemptAt, String? lastError, int sequence
});




}
/// @nodoc
class __$OutboxOperationCopyWithImpl<$Res>
    implements _$OutboxOperationCopyWith<$Res> {
  __$OutboxOperationCopyWithImpl(this._self, this._then);

  final _OutboxOperation _self;
  final $Res Function(_OutboxOperation) _then;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operationId = null,Object? kind = null,Object? issueKey = null,Object? payload = null,Object? createdAt = null,Object? taskId = freezed,Object? state = null,Object? attempts = null,Object? nextAttemptAt = freezed,Object? lastError = freezed,Object? sequence = null,}) {
  return _then(_OutboxOperation(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as OutboxOperationKind,issueKey: null == issueKey ? _self.issueKey : issueKey // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,taskId: freezed == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as OutboxOperationState,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,nextAttemptAt: freezed == nextAttemptAt ? _self.nextAttemptAt : nextAttemptAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
