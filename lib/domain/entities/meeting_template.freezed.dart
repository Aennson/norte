// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meeting_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TemplateSection {

/// Section heading, shown to the user and sent to the engine.
 String get title;/// Optional extra instruction for this section only.
 String? get guidance;
/// Create a copy of TemplateSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TemplateSectionCopyWith<TemplateSection> get copyWith => _$TemplateSectionCopyWithImpl<TemplateSection>(this as TemplateSection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TemplateSection&&(identical(other.title, title) || other.title == title)&&(identical(other.guidance, guidance) || other.guidance == guidance));
}


@override
int get hashCode => Object.hash(runtimeType,title,guidance);

@override
String toString() {
  return 'TemplateSection(title: $title, guidance: $guidance)';
}


}

/// @nodoc
abstract mixin class $TemplateSectionCopyWith<$Res>  {
  factory $TemplateSectionCopyWith(TemplateSection value, $Res Function(TemplateSection) _then) = _$TemplateSectionCopyWithImpl;
@useResult
$Res call({
 String title, String? guidance
});




}
/// @nodoc
class _$TemplateSectionCopyWithImpl<$Res>
    implements $TemplateSectionCopyWith<$Res> {
  _$TemplateSectionCopyWithImpl(this._self, this._then);

  final TemplateSection _self;
  final $Res Function(TemplateSection) _then;

/// Create a copy of TemplateSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? guidance = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,guidance: freezed == guidance ? _self.guidance : guidance // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TemplateSection].
extension TemplateSectionPatterns on TemplateSection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TemplateSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TemplateSection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TemplateSection value)  $default,){
final _that = this;
switch (_that) {
case _TemplateSection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TemplateSection value)?  $default,){
final _that = this;
switch (_that) {
case _TemplateSection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String? guidance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TemplateSection() when $default != null:
return $default(_that.title,_that.guidance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String? guidance)  $default,) {final _that = this;
switch (_that) {
case _TemplateSection():
return $default(_that.title,_that.guidance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String? guidance)?  $default,) {final _that = this;
switch (_that) {
case _TemplateSection() when $default != null:
return $default(_that.title,_that.guidance);case _:
  return null;

}
}

}

/// @nodoc


class _TemplateSection implements TemplateSection {
  const _TemplateSection({required this.title, this.guidance});
  

/// Section heading, shown to the user and sent to the engine.
@override final  String title;
/// Optional extra instruction for this section only.
@override final  String? guidance;

/// Create a copy of TemplateSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TemplateSectionCopyWith<_TemplateSection> get copyWith => __$TemplateSectionCopyWithImpl<_TemplateSection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TemplateSection&&(identical(other.title, title) || other.title == title)&&(identical(other.guidance, guidance) || other.guidance == guidance));
}


@override
int get hashCode => Object.hash(runtimeType,title,guidance);

@override
String toString() {
  return 'TemplateSection(title: $title, guidance: $guidance)';
}


}

/// @nodoc
abstract mixin class _$TemplateSectionCopyWith<$Res> implements $TemplateSectionCopyWith<$Res> {
  factory _$TemplateSectionCopyWith(_TemplateSection value, $Res Function(_TemplateSection) _then) = __$TemplateSectionCopyWithImpl;
@override @useResult
$Res call({
 String title, String? guidance
});




}
/// @nodoc
class __$TemplateSectionCopyWithImpl<$Res>
    implements _$TemplateSectionCopyWith<$Res> {
  __$TemplateSectionCopyWithImpl(this._self, this._then);

  final _TemplateSection _self;
  final $Res Function(_TemplateSection) _then;

/// Create a copy of TemplateSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? guidance = freezed,}) {
  return _then(_TemplateSection(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,guidance: freezed == guidance ? _self.guidance : guidance // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$MeetingTemplate {

 String get id; MeetingType get type;/// System prompt handed to the engine. Fixed payload — never carries the
/// transcript.
 String get systemPrompt; List<TemplateSection> get sections;/// Whether the engine should also return `ActionItem`s.
 bool get extractActionItems;
/// Create a copy of MeetingTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeetingTemplateCopyWith<MeetingTemplate> get copyWith => _$MeetingTemplateCopyWithImpl<MeetingTemplate>(this as MeetingTemplate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeetingTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.systemPrompt, systemPrompt) || other.systemPrompt == systemPrompt)&&const DeepCollectionEquality().equals(other.sections, sections)&&(identical(other.extractActionItems, extractActionItems) || other.extractActionItems == extractActionItems));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,systemPrompt,const DeepCollectionEquality().hash(sections),extractActionItems);

@override
String toString() {
  return 'MeetingTemplate(id: $id, type: $type, systemPrompt: $systemPrompt, sections: $sections, extractActionItems: $extractActionItems)';
}


}

/// @nodoc
abstract mixin class $MeetingTemplateCopyWith<$Res>  {
  factory $MeetingTemplateCopyWith(MeetingTemplate value, $Res Function(MeetingTemplate) _then) = _$MeetingTemplateCopyWithImpl;
@useResult
$Res call({
 String id, MeetingType type, String systemPrompt, List<TemplateSection> sections, bool extractActionItems
});




}
/// @nodoc
class _$MeetingTemplateCopyWithImpl<$Res>
    implements $MeetingTemplateCopyWith<$Res> {
  _$MeetingTemplateCopyWithImpl(this._self, this._then);

  final MeetingTemplate _self;
  final $Res Function(MeetingTemplate) _then;

/// Create a copy of MeetingTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? systemPrompt = null,Object? sections = null,Object? extractActionItems = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MeetingType,systemPrompt: null == systemPrompt ? _self.systemPrompt : systemPrompt // ignore: cast_nullable_to_non_nullable
as String,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<TemplateSection>,extractActionItems: null == extractActionItems ? _self.extractActionItems : extractActionItems // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MeetingTemplate].
extension MeetingTemplatePatterns on MeetingTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeetingTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeetingTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeetingTemplate value)  $default,){
final _that = this;
switch (_that) {
case _MeetingTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeetingTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _MeetingTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  MeetingType type,  String systemPrompt,  List<TemplateSection> sections,  bool extractActionItems)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeetingTemplate() when $default != null:
return $default(_that.id,_that.type,_that.systemPrompt,_that.sections,_that.extractActionItems);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  MeetingType type,  String systemPrompt,  List<TemplateSection> sections,  bool extractActionItems)  $default,) {final _that = this;
switch (_that) {
case _MeetingTemplate():
return $default(_that.id,_that.type,_that.systemPrompt,_that.sections,_that.extractActionItems);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  MeetingType type,  String systemPrompt,  List<TemplateSection> sections,  bool extractActionItems)?  $default,) {final _that = this;
switch (_that) {
case _MeetingTemplate() when $default != null:
return $default(_that.id,_that.type,_that.systemPrompt,_that.sections,_that.extractActionItems);case _:
  return null;

}
}

}

/// @nodoc


class _MeetingTemplate extends MeetingTemplate {
  const _MeetingTemplate({required this.id, required this.type, required this.systemPrompt, final  List<TemplateSection> sections = const <TemplateSection>[], this.extractActionItems = true}): _sections = sections,super._();
  

@override final  String id;
@override final  MeetingType type;
/// System prompt handed to the engine. Fixed payload — never carries the
/// transcript.
@override final  String systemPrompt;
 final  List<TemplateSection> _sections;
@override@JsonKey() List<TemplateSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

/// Whether the engine should also return `ActionItem`s.
@override@JsonKey() final  bool extractActionItems;

/// Create a copy of MeetingTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeetingTemplateCopyWith<_MeetingTemplate> get copyWith => __$MeetingTemplateCopyWithImpl<_MeetingTemplate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeetingTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.systemPrompt, systemPrompt) || other.systemPrompt == systemPrompt)&&const DeepCollectionEquality().equals(other._sections, _sections)&&(identical(other.extractActionItems, extractActionItems) || other.extractActionItems == extractActionItems));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,systemPrompt,const DeepCollectionEquality().hash(_sections),extractActionItems);

@override
String toString() {
  return 'MeetingTemplate(id: $id, type: $type, systemPrompt: $systemPrompt, sections: $sections, extractActionItems: $extractActionItems)';
}


}

/// @nodoc
abstract mixin class _$MeetingTemplateCopyWith<$Res> implements $MeetingTemplateCopyWith<$Res> {
  factory _$MeetingTemplateCopyWith(_MeetingTemplate value, $Res Function(_MeetingTemplate) _then) = __$MeetingTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, MeetingType type, String systemPrompt, List<TemplateSection> sections, bool extractActionItems
});




}
/// @nodoc
class __$MeetingTemplateCopyWithImpl<$Res>
    implements _$MeetingTemplateCopyWith<$Res> {
  __$MeetingTemplateCopyWithImpl(this._self, this._then);

  final _MeetingTemplate _self;
  final $Res Function(_MeetingTemplate) _then;

/// Create a copy of MeetingTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? systemPrompt = null,Object? sections = null,Object? extractActionItems = null,}) {
  return _then(_MeetingTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MeetingType,systemPrompt: null == systemPrompt ? _self.systemPrompt : systemPrompt // ignore: cast_nullable_to_non_nullable
as String,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<TemplateSection>,extractActionItems: null == extractActionItems ? _self.extractActionItems : extractActionItems // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
