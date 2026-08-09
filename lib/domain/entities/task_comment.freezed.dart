// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskComment {

/// Locally generated UUID v4, unique across every task.
 String get id;/// What the user wrote, already trimmed by the use case. Never blank.
 String get body;/// When the comment was made. Never changes.
 DateTime get createdAt;
/// Create a copy of TaskComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCommentCopyWith<TaskComment> get copyWith => _$TaskCommentCopyWithImpl<TaskComment>(this as TaskComment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskComment&&(identical(other.id, id) || other.id == id)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,body,createdAt);

@override
String toString() {
  return 'TaskComment(id: $id, body: $body, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TaskCommentCopyWith<$Res>  {
  factory $TaskCommentCopyWith(TaskComment value, $Res Function(TaskComment) _then) = _$TaskCommentCopyWithImpl;
@useResult
$Res call({
 String id, String body, DateTime createdAt
});




}
/// @nodoc
class _$TaskCommentCopyWithImpl<$Res>
    implements $TaskCommentCopyWith<$Res> {
  _$TaskCommentCopyWithImpl(this._self, this._then);

  final TaskComment _self;
  final $Res Function(TaskComment) _then;

/// Create a copy of TaskComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? body = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskComment].
extension TaskCommentPatterns on TaskComment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskComment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskComment value)  $default,){
final _that = this;
switch (_that) {
case _TaskComment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskComment value)?  $default,){
final _that = this;
switch (_that) {
case _TaskComment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String body,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskComment() when $default != null:
return $default(_that.id,_that.body,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String body,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _TaskComment():
return $default(_that.id,_that.body,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String body,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TaskComment() when $default != null:
return $default(_that.id,_that.body,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _TaskComment implements TaskComment {
  const _TaskComment({required this.id, required this.body, required this.createdAt});
  

/// Locally generated UUID v4, unique across every task.
@override final  String id;
/// What the user wrote, already trimmed by the use case. Never blank.
@override final  String body;
/// When the comment was made. Never changes.
@override final  DateTime createdAt;

/// Create a copy of TaskComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCommentCopyWith<_TaskComment> get copyWith => __$TaskCommentCopyWithImpl<_TaskComment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskComment&&(identical(other.id, id) || other.id == id)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,body,createdAt);

@override
String toString() {
  return 'TaskComment(id: $id, body: $body, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TaskCommentCopyWith<$Res> implements $TaskCommentCopyWith<$Res> {
  factory _$TaskCommentCopyWith(_TaskComment value, $Res Function(_TaskComment) _then) = __$TaskCommentCopyWithImpl;
@override @useResult
$Res call({
 String id, String body, DateTime createdAt
});




}
/// @nodoc
class __$TaskCommentCopyWithImpl<$Res>
    implements _$TaskCommentCopyWith<$Res> {
  __$TaskCommentCopyWithImpl(this._self, this._then);

  final _TaskComment _self;
  final $Res Function(_TaskComment) _then;

/// Create a copy of TaskComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? body = null,Object? createdAt = null,}) {
  return _then(_TaskComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
