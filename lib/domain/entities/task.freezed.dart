// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Task {

/// Locally generated UUID v4. Stable for the life of the task, and
/// unrelated to any Jira identifier.
 String get id;/// Non-empty, already trimmed by the use case.
 String get title;/// When the task was created. Never changes after creation.
 DateTime get createdAt;/// When the task last changed. Refreshed by the use cases, never by the
/// entity.
 DateTime get updatedAt;/// Free-form detail. `null` and empty are distinct: `null` means the user
/// never wrote one.
 String? get description; TaskStatus get status; Priority get priority;/// Optional deadline. Tasks without one sort last.
 DateTime? get dueDate;/// Optional Jira reference (BR-01).
 JiraLink? get jiraLink;/// User labels, kept in the order the user entered them.
 List<String> get tags;/// Local notes, oldest first — the order they were written in
/// (`sprint-05a`, S05a-IT-01).
///
/// **None of these ever reaches Jira** (§3.2, BR-01). See [TaskComment].
 List<TaskComment> get comments;/// Id of the meeting whose action item produced this task, when one did
/// and that meeting was saved (`sprint-03` validation rules).
///
/// A back-reference for navigation and nothing more: the task is a task
/// like any other, and deleting the meeting does not delete it.
 String? get sourceMeetingId;
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCopyWith<Task> get copyWith => _$TaskCopyWithImpl<Task>(this as Task, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Task&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.jiraLink, jiraLink) || other.jiraLink == jiraLink)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.comments, comments)&&(identical(other.sourceMeetingId, sourceMeetingId) || other.sourceMeetingId == sourceMeetingId));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,createdAt,updatedAt,description,status,priority,dueDate,jiraLink,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(comments),sourceMeetingId);

@override
String toString() {
  return 'Task(id: $id, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, status: $status, priority: $priority, dueDate: $dueDate, jiraLink: $jiraLink, tags: $tags, comments: $comments, sourceMeetingId: $sourceMeetingId)';
}


}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res>  {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) = _$TaskCopyWithImpl;
@useResult
$Res call({
 String id, String title, DateTime createdAt, DateTime updatedAt, String? description, TaskStatus status, Priority priority, DateTime? dueDate, JiraLink? jiraLink, List<String> tags, List<TaskComment> comments, String? sourceMeetingId
});


$JiraLinkCopyWith<$Res>? get jiraLink;

}
/// @nodoc
class _$TaskCopyWithImpl<$Res>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._self, this._then);

  final Task _self;
  final $Res Function(Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? createdAt = null,Object? updatedAt = null,Object? description = freezed,Object? status = null,Object? priority = null,Object? dueDate = freezed,Object? jiraLink = freezed,Object? tags = null,Object? comments = null,Object? sourceMeetingId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,jiraLink: freezed == jiraLink ? _self.jiraLink : jiraLink // ignore: cast_nullable_to_non_nullable
as JiraLink?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as List<TaskComment>,sourceMeetingId: freezed == sourceMeetingId ? _self.sourceMeetingId : sourceMeetingId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JiraLinkCopyWith<$Res>? get jiraLink {
    if (_self.jiraLink == null) {
    return null;
  }

  return $JiraLinkCopyWith<$Res>(_self.jiraLink!, (value) {
    return _then(_self.copyWith(jiraLink: value));
  });
}
}


/// Adds pattern-matching-related methods to [Task].
extension TaskPatterns on Task {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Task value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Task value)  $default,){
final _that = this;
switch (_that) {
case _Task():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Task value)?  $default,){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  DateTime createdAt,  DateTime updatedAt,  String? description,  TaskStatus status,  Priority priority,  DateTime? dueDate,  JiraLink? jiraLink,  List<String> tags,  List<TaskComment> comments,  String? sourceMeetingId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.title,_that.createdAt,_that.updatedAt,_that.description,_that.status,_that.priority,_that.dueDate,_that.jiraLink,_that.tags,_that.comments,_that.sourceMeetingId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  DateTime createdAt,  DateTime updatedAt,  String? description,  TaskStatus status,  Priority priority,  DateTime? dueDate,  JiraLink? jiraLink,  List<String> tags,  List<TaskComment> comments,  String? sourceMeetingId)  $default,) {final _that = this;
switch (_that) {
case _Task():
return $default(_that.id,_that.title,_that.createdAt,_that.updatedAt,_that.description,_that.status,_that.priority,_that.dueDate,_that.jiraLink,_that.tags,_that.comments,_that.sourceMeetingId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  DateTime createdAt,  DateTime updatedAt,  String? description,  TaskStatus status,  Priority priority,  DateTime? dueDate,  JiraLink? jiraLink,  List<String> tags,  List<TaskComment> comments,  String? sourceMeetingId)?  $default,) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.title,_that.createdAt,_that.updatedAt,_that.description,_that.status,_that.priority,_that.dueDate,_that.jiraLink,_that.tags,_that.comments,_that.sourceMeetingId);case _:
  return null;

}
}

}

/// @nodoc


class _Task implements Task {
  const _Task({required this.id, required this.title, required this.createdAt, required this.updatedAt, this.description, this.status = TaskStatus.todo, this.priority = Priority.medium, this.dueDate, this.jiraLink, final  List<String> tags = const <String>[], final  List<TaskComment> comments = const <TaskComment>[], this.sourceMeetingId}): _tags = tags,_comments = comments;
  

/// Locally generated UUID v4. Stable for the life of the task, and
/// unrelated to any Jira identifier.
@override final  String id;
/// Non-empty, already trimmed by the use case.
@override final  String title;
/// When the task was created. Never changes after creation.
@override final  DateTime createdAt;
/// When the task last changed. Refreshed by the use cases, never by the
/// entity.
@override final  DateTime updatedAt;
/// Free-form detail. `null` and empty are distinct: `null` means the user
/// never wrote one.
@override final  String? description;
@override@JsonKey() final  TaskStatus status;
@override@JsonKey() final  Priority priority;
/// Optional deadline. Tasks without one sort last.
@override final  DateTime? dueDate;
/// Optional Jira reference (BR-01).
@override final  JiraLink? jiraLink;
/// User labels, kept in the order the user entered them.
 final  List<String> _tags;
/// User labels, kept in the order the user entered them.
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

/// Local notes, oldest first — the order they were written in
/// (`sprint-05a`, S05a-IT-01).
///
/// **None of these ever reaches Jira** (§3.2, BR-01). See [TaskComment].
 final  List<TaskComment> _comments;
/// Local notes, oldest first — the order they were written in
/// (`sprint-05a`, S05a-IT-01).
///
/// **None of these ever reaches Jira** (§3.2, BR-01). See [TaskComment].
@override@JsonKey() List<TaskComment> get comments {
  if (_comments is EqualUnmodifiableListView) return _comments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_comments);
}

/// Id of the meeting whose action item produced this task, when one did
/// and that meeting was saved (`sprint-03` validation rules).
///
/// A back-reference for navigation and nothing more: the task is a task
/// like any other, and deleting the meeting does not delete it.
@override final  String? sourceMeetingId;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCopyWith<_Task> get copyWith => __$TaskCopyWithImpl<_Task>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Task&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.jiraLink, jiraLink) || other.jiraLink == jiraLink)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._comments, _comments)&&(identical(other.sourceMeetingId, sourceMeetingId) || other.sourceMeetingId == sourceMeetingId));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,createdAt,updatedAt,description,status,priority,dueDate,jiraLink,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_comments),sourceMeetingId);

@override
String toString() {
  return 'Task(id: $id, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, status: $status, priority: $priority, dueDate: $dueDate, jiraLink: $jiraLink, tags: $tags, comments: $comments, sourceMeetingId: $sourceMeetingId)';
}


}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) = __$TaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, DateTime createdAt, DateTime updatedAt, String? description, TaskStatus status, Priority priority, DateTime? dueDate, JiraLink? jiraLink, List<String> tags, List<TaskComment> comments, String? sourceMeetingId
});


@override $JiraLinkCopyWith<$Res>? get jiraLink;

}
/// @nodoc
class __$TaskCopyWithImpl<$Res>
    implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(this._self, this._then);

  final _Task _self;
  final $Res Function(_Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? createdAt = null,Object? updatedAt = null,Object? description = freezed,Object? status = null,Object? priority = null,Object? dueDate = freezed,Object? jiraLink = freezed,Object? tags = null,Object? comments = null,Object? sourceMeetingId = freezed,}) {
  return _then(_Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,jiraLink: freezed == jiraLink ? _self.jiraLink : jiraLink // ignore: cast_nullable_to_non_nullable
as JiraLink?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,comments: null == comments ? _self._comments : comments // ignore: cast_nullable_to_non_nullable
as List<TaskComment>,sourceMeetingId: freezed == sourceMeetingId ? _self.sourceMeetingId : sourceMeetingId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JiraLinkCopyWith<$Res>? get jiraLink {
    if (_self.jiraLink == null) {
    return null;
  }

  return $JiraLinkCopyWith<$Res>(_self.jiraLink!, (value) {
    return _then(_self.copyWith(jiraLink: value));
  });
}
}

// dart format on
