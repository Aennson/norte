// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meeting.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActionItem {

 String get description;/// Person the item was assigned to, when the transcript names one.
 String? get assignee; DateTime? get dueDate;
/// Create a copy of ActionItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionItemCopyWith<ActionItem> get copyWith => _$ActionItemCopyWithImpl<ActionItem>(this as ActionItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionItem&&(identical(other.description, description) || other.description == description)&&(identical(other.assignee, assignee) || other.assignee == assignee)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate));
}


@override
int get hashCode => Object.hash(runtimeType,description,assignee,dueDate);

@override
String toString() {
  return 'ActionItem(description: $description, assignee: $assignee, dueDate: $dueDate)';
}


}

/// @nodoc
abstract mixin class $ActionItemCopyWith<$Res>  {
  factory $ActionItemCopyWith(ActionItem value, $Res Function(ActionItem) _then) = _$ActionItemCopyWithImpl;
@useResult
$Res call({
 String description, String? assignee, DateTime? dueDate
});




}
/// @nodoc
class _$ActionItemCopyWithImpl<$Res>
    implements $ActionItemCopyWith<$Res> {
  _$ActionItemCopyWithImpl(this._self, this._then);

  final ActionItem _self;
  final $Res Function(ActionItem) _then;

/// Create a copy of ActionItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? description = null,Object? assignee = freezed,Object? dueDate = freezed,}) {
  return _then(_self.copyWith(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ActionItem].
extension ActionItemPatterns on ActionItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActionItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActionItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActionItem value)  $default,){
final _that = this;
switch (_that) {
case _ActionItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActionItem value)?  $default,){
final _that = this;
switch (_that) {
case _ActionItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String description,  String? assignee,  DateTime? dueDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActionItem() when $default != null:
return $default(_that.description,_that.assignee,_that.dueDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String description,  String? assignee,  DateTime? dueDate)  $default,) {final _that = this;
switch (_that) {
case _ActionItem():
return $default(_that.description,_that.assignee,_that.dueDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String description,  String? assignee,  DateTime? dueDate)?  $default,) {final _that = this;
switch (_that) {
case _ActionItem() when $default != null:
return $default(_that.description,_that.assignee,_that.dueDate);case _:
  return null;

}
}

}

/// @nodoc


class _ActionItem implements ActionItem {
  const _ActionItem({required this.description, this.assignee, this.dueDate});
  

@override final  String description;
/// Person the item was assigned to, when the transcript names one.
@override final  String? assignee;
@override final  DateTime? dueDate;

/// Create a copy of ActionItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActionItemCopyWith<_ActionItem> get copyWith => __$ActionItemCopyWithImpl<_ActionItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActionItem&&(identical(other.description, description) || other.description == description)&&(identical(other.assignee, assignee) || other.assignee == assignee)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate));
}


@override
int get hashCode => Object.hash(runtimeType,description,assignee,dueDate);

@override
String toString() {
  return 'ActionItem(description: $description, assignee: $assignee, dueDate: $dueDate)';
}


}

/// @nodoc
abstract mixin class _$ActionItemCopyWith<$Res> implements $ActionItemCopyWith<$Res> {
  factory _$ActionItemCopyWith(_ActionItem value, $Res Function(_ActionItem) _then) = __$ActionItemCopyWithImpl;
@override @useResult
$Res call({
 String description, String? assignee, DateTime? dueDate
});




}
/// @nodoc
class __$ActionItemCopyWithImpl<$Res>
    implements _$ActionItemCopyWith<$Res> {
  __$ActionItemCopyWithImpl(this._self, this._then);

  final _ActionItem _self;
  final $Res Function(_ActionItem) _then;

/// Create a copy of ActionItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? description = null,Object? assignee = freezed,Object? dueDate = freezed,}) {
  return _then(_ActionItem(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$MeetingSummary {

/// Section title → section body, in the template's declared order.
 Map<String, String> get sections;/// When the summary was produced.
 DateTime get generatedAt;/// Identifier of the engine that produced it, for diagnostics.
 String? get engineId;
/// Create a copy of MeetingSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeetingSummaryCopyWith<MeetingSummary> get copyWith => _$MeetingSummaryCopyWithImpl<MeetingSummary>(this as MeetingSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeetingSummary&&const DeepCollectionEquality().equals(other.sections, sections)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.engineId, engineId) || other.engineId == engineId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(sections),generatedAt,engineId);

@override
String toString() {
  return 'MeetingSummary(sections: $sections, generatedAt: $generatedAt, engineId: $engineId)';
}


}

/// @nodoc
abstract mixin class $MeetingSummaryCopyWith<$Res>  {
  factory $MeetingSummaryCopyWith(MeetingSummary value, $Res Function(MeetingSummary) _then) = _$MeetingSummaryCopyWithImpl;
@useResult
$Res call({
 Map<String, String> sections, DateTime generatedAt, String? engineId
});




}
/// @nodoc
class _$MeetingSummaryCopyWithImpl<$Res>
    implements $MeetingSummaryCopyWith<$Res> {
  _$MeetingSummaryCopyWithImpl(this._self, this._then);

  final MeetingSummary _self;
  final $Res Function(MeetingSummary) _then;

/// Create a copy of MeetingSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sections = null,Object? generatedAt = null,Object? engineId = freezed,}) {
  return _then(_self.copyWith(
sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as Map<String, String>,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,engineId: freezed == engineId ? _self.engineId : engineId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MeetingSummary].
extension MeetingSummaryPatterns on MeetingSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeetingSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeetingSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeetingSummary value)  $default,){
final _that = this;
switch (_that) {
case _MeetingSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeetingSummary value)?  $default,){
final _that = this;
switch (_that) {
case _MeetingSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, String> sections,  DateTime generatedAt,  String? engineId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeetingSummary() when $default != null:
return $default(_that.sections,_that.generatedAt,_that.engineId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, String> sections,  DateTime generatedAt,  String? engineId)  $default,) {final _that = this;
switch (_that) {
case _MeetingSummary():
return $default(_that.sections,_that.generatedAt,_that.engineId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, String> sections,  DateTime generatedAt,  String? engineId)?  $default,) {final _that = this;
switch (_that) {
case _MeetingSummary() when $default != null:
return $default(_that.sections,_that.generatedAt,_that.engineId);case _:
  return null;

}
}

}

/// @nodoc


class _MeetingSummary implements MeetingSummary {
  const _MeetingSummary({required final  Map<String, String> sections, required this.generatedAt, this.engineId}): _sections = sections;
  

/// Section title → section body, in the template's declared order.
 final  Map<String, String> _sections;
/// Section title → section body, in the template's declared order.
@override Map<String, String> get sections {
  if (_sections is EqualUnmodifiableMapView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_sections);
}

/// When the summary was produced.
@override final  DateTime generatedAt;
/// Identifier of the engine that produced it, for diagnostics.
@override final  String? engineId;

/// Create a copy of MeetingSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeetingSummaryCopyWith<_MeetingSummary> get copyWith => __$MeetingSummaryCopyWithImpl<_MeetingSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeetingSummary&&const DeepCollectionEquality().equals(other._sections, _sections)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.engineId, engineId) || other.engineId == engineId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_sections),generatedAt,engineId);

@override
String toString() {
  return 'MeetingSummary(sections: $sections, generatedAt: $generatedAt, engineId: $engineId)';
}


}

/// @nodoc
abstract mixin class _$MeetingSummaryCopyWith<$Res> implements $MeetingSummaryCopyWith<$Res> {
  factory _$MeetingSummaryCopyWith(_MeetingSummary value, $Res Function(_MeetingSummary) _then) = __$MeetingSummaryCopyWithImpl;
@override @useResult
$Res call({
 Map<String, String> sections, DateTime generatedAt, String? engineId
});




}
/// @nodoc
class __$MeetingSummaryCopyWithImpl<$Res>
    implements _$MeetingSummaryCopyWith<$Res> {
  __$MeetingSummaryCopyWithImpl(this._self, this._then);

  final _MeetingSummary _self;
  final $Res Function(_MeetingSummary) _then;

/// Create a copy of MeetingSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sections = null,Object? generatedAt = null,Object? engineId = freezed,}) {
  return _then(_MeetingSummary(
sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as Map<String, String>,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,engineId: freezed == engineId ? _self.engineId : engineId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$Meeting {

 String get id; String get title; DateTime get createdAt; MeetingType get type;/// Pasted by the user or produced by a transcription engine. Held in
/// memory only while [retention] is [RetentionPolicy.ephemeral] (BR-03).
 String get rawTranscript; MeetingSummary? get summary; List<ActionItem> get actionItems; RetentionPolicy get retention;
/// Create a copy of Meeting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeetingCopyWith<Meeting> get copyWith => _$MeetingCopyWithImpl<Meeting>(this as Meeting, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Meeting&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.type, type) || other.type == type)&&(identical(other.rawTranscript, rawTranscript) || other.rawTranscript == rawTranscript)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.actionItems, actionItems)&&(identical(other.retention, retention) || other.retention == retention));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,createdAt,type,rawTranscript,summary,const DeepCollectionEquality().hash(actionItems),retention);

@override
String toString() {
  return 'Meeting(id: $id, title: $title, createdAt: $createdAt, type: $type, rawTranscript: $rawTranscript, summary: $summary, actionItems: $actionItems, retention: $retention)';
}


}

/// @nodoc
abstract mixin class $MeetingCopyWith<$Res>  {
  factory $MeetingCopyWith(Meeting value, $Res Function(Meeting) _then) = _$MeetingCopyWithImpl;
@useResult
$Res call({
 String id, String title, DateTime createdAt, MeetingType type, String rawTranscript, MeetingSummary? summary, List<ActionItem> actionItems, RetentionPolicy retention
});


$MeetingSummaryCopyWith<$Res>? get summary;

}
/// @nodoc
class _$MeetingCopyWithImpl<$Res>
    implements $MeetingCopyWith<$Res> {
  _$MeetingCopyWithImpl(this._self, this._then);

  final Meeting _self;
  final $Res Function(Meeting) _then;

/// Create a copy of Meeting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? createdAt = null,Object? type = null,Object? rawTranscript = null,Object? summary = freezed,Object? actionItems = null,Object? retention = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MeetingType,rawTranscript: null == rawTranscript ? _self.rawTranscript : rawTranscript // ignore: cast_nullable_to_non_nullable
as String,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as MeetingSummary?,actionItems: null == actionItems ? _self.actionItems : actionItems // ignore: cast_nullable_to_non_nullable
as List<ActionItem>,retention: null == retention ? _self.retention : retention // ignore: cast_nullable_to_non_nullable
as RetentionPolicy,
  ));
}
/// Create a copy of Meeting
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeetingSummaryCopyWith<$Res>? get summary {
    if (_self.summary == null) {
    return null;
  }

  return $MeetingSummaryCopyWith<$Res>(_self.summary!, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// Adds pattern-matching-related methods to [Meeting].
extension MeetingPatterns on Meeting {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Meeting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Meeting() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Meeting value)  $default,){
final _that = this;
switch (_that) {
case _Meeting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Meeting value)?  $default,){
final _that = this;
switch (_that) {
case _Meeting() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  DateTime createdAt,  MeetingType type,  String rawTranscript,  MeetingSummary? summary,  List<ActionItem> actionItems,  RetentionPolicy retention)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Meeting() when $default != null:
return $default(_that.id,_that.title,_that.createdAt,_that.type,_that.rawTranscript,_that.summary,_that.actionItems,_that.retention);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  DateTime createdAt,  MeetingType type,  String rawTranscript,  MeetingSummary? summary,  List<ActionItem> actionItems,  RetentionPolicy retention)  $default,) {final _that = this;
switch (_that) {
case _Meeting():
return $default(_that.id,_that.title,_that.createdAt,_that.type,_that.rawTranscript,_that.summary,_that.actionItems,_that.retention);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  DateTime createdAt,  MeetingType type,  String rawTranscript,  MeetingSummary? summary,  List<ActionItem> actionItems,  RetentionPolicy retention)?  $default,) {final _that = this;
switch (_that) {
case _Meeting() when $default != null:
return $default(_that.id,_that.title,_that.createdAt,_that.type,_that.rawTranscript,_that.summary,_that.actionItems,_that.retention);case _:
  return null;

}
}

}

/// @nodoc


class _Meeting implements Meeting {
  const _Meeting({required this.id, required this.title, required this.createdAt, this.type = MeetingType.custom, this.rawTranscript = '', this.summary, final  List<ActionItem> actionItems = const <ActionItem>[], this.retention = RetentionPolicy.ephemeral}): _actionItems = actionItems;
  

@override final  String id;
@override final  String title;
@override final  DateTime createdAt;
@override@JsonKey() final  MeetingType type;
/// Pasted by the user or produced by a transcription engine. Held in
/// memory only while [retention] is [RetentionPolicy.ephemeral] (BR-03).
@override@JsonKey() final  String rawTranscript;
@override final  MeetingSummary? summary;
 final  List<ActionItem> _actionItems;
@override@JsonKey() List<ActionItem> get actionItems {
  if (_actionItems is EqualUnmodifiableListView) return _actionItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actionItems);
}

@override@JsonKey() final  RetentionPolicy retention;

/// Create a copy of Meeting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeetingCopyWith<_Meeting> get copyWith => __$MeetingCopyWithImpl<_Meeting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Meeting&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.type, type) || other.type == type)&&(identical(other.rawTranscript, rawTranscript) || other.rawTranscript == rawTranscript)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._actionItems, _actionItems)&&(identical(other.retention, retention) || other.retention == retention));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,createdAt,type,rawTranscript,summary,const DeepCollectionEquality().hash(_actionItems),retention);

@override
String toString() {
  return 'Meeting(id: $id, title: $title, createdAt: $createdAt, type: $type, rawTranscript: $rawTranscript, summary: $summary, actionItems: $actionItems, retention: $retention)';
}


}

/// @nodoc
abstract mixin class _$MeetingCopyWith<$Res> implements $MeetingCopyWith<$Res> {
  factory _$MeetingCopyWith(_Meeting value, $Res Function(_Meeting) _then) = __$MeetingCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, DateTime createdAt, MeetingType type, String rawTranscript, MeetingSummary? summary, List<ActionItem> actionItems, RetentionPolicy retention
});


@override $MeetingSummaryCopyWith<$Res>? get summary;

}
/// @nodoc
class __$MeetingCopyWithImpl<$Res>
    implements _$MeetingCopyWith<$Res> {
  __$MeetingCopyWithImpl(this._self, this._then);

  final _Meeting _self;
  final $Res Function(_Meeting) _then;

/// Create a copy of Meeting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? createdAt = null,Object? type = null,Object? rawTranscript = null,Object? summary = freezed,Object? actionItems = null,Object? retention = null,}) {
  return _then(_Meeting(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MeetingType,rawTranscript: null == rawTranscript ? _self.rawTranscript : rawTranscript // ignore: cast_nullable_to_non_nullable
as String,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as MeetingSummary?,actionItems: null == actionItems ? _self._actionItems : actionItems // ignore: cast_nullable_to_non_nullable
as List<ActionItem>,retention: null == retention ? _self.retention : retention // ignore: cast_nullable_to_non_nullable
as RetentionPolicy,
  ));
}

/// Create a copy of Meeting
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeetingSummaryCopyWith<$Res>? get summary {
    if (_self.summary == null) {
    return null;
  }

  return $MeetingSummaryCopyWith<$Res>(_self.summary!, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

// dart format on
