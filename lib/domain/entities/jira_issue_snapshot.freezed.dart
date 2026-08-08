// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jira_issue_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JiraIssueSnapshot {

/// Issue key as Jira spells it, e.g. `PROJ-123`.
 String get issueKey;/// Base URL of the site the issue lives on.
 String get siteUrl;/// Status name at the moment of the read. Display cache only — Jira
/// remains the source of truth and this is never used to decide a
/// transition (BR-02).
 String get status;
/// Create a copy of JiraIssueSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JiraIssueSnapshotCopyWith<JiraIssueSnapshot> get copyWith => _$JiraIssueSnapshotCopyWithImpl<JiraIssueSnapshot>(this as JiraIssueSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JiraIssueSnapshot&&(identical(other.issueKey, issueKey) || other.issueKey == issueKey)&&(identical(other.siteUrl, siteUrl) || other.siteUrl == siteUrl)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,issueKey,siteUrl,status);

@override
String toString() {
  return 'JiraIssueSnapshot(issueKey: $issueKey, siteUrl: $siteUrl, status: $status)';
}


}

/// @nodoc
abstract mixin class $JiraIssueSnapshotCopyWith<$Res>  {
  factory $JiraIssueSnapshotCopyWith(JiraIssueSnapshot value, $Res Function(JiraIssueSnapshot) _then) = _$JiraIssueSnapshotCopyWithImpl;
@useResult
$Res call({
 String issueKey, String siteUrl, String status
});




}
/// @nodoc
class _$JiraIssueSnapshotCopyWithImpl<$Res>
    implements $JiraIssueSnapshotCopyWith<$Res> {
  _$JiraIssueSnapshotCopyWithImpl(this._self, this._then);

  final JiraIssueSnapshot _self;
  final $Res Function(JiraIssueSnapshot) _then;

/// Create a copy of JiraIssueSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? issueKey = null,Object? siteUrl = null,Object? status = null,}) {
  return _then(_self.copyWith(
issueKey: null == issueKey ? _self.issueKey : issueKey // ignore: cast_nullable_to_non_nullable
as String,siteUrl: null == siteUrl ? _self.siteUrl : siteUrl // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [JiraIssueSnapshot].
extension JiraIssueSnapshotPatterns on JiraIssueSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JiraIssueSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JiraIssueSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JiraIssueSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _JiraIssueSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JiraIssueSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _JiraIssueSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String issueKey,  String siteUrl,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JiraIssueSnapshot() when $default != null:
return $default(_that.issueKey,_that.siteUrl,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String issueKey,  String siteUrl,  String status)  $default,) {final _that = this;
switch (_that) {
case _JiraIssueSnapshot():
return $default(_that.issueKey,_that.siteUrl,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String issueKey,  String siteUrl,  String status)?  $default,) {final _that = this;
switch (_that) {
case _JiraIssueSnapshot() when $default != null:
return $default(_that.issueKey,_that.siteUrl,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _JiraIssueSnapshot implements JiraIssueSnapshot {
  const _JiraIssueSnapshot({required this.issueKey, required this.siteUrl, required this.status});
  

/// Issue key as Jira spells it, e.g. `PROJ-123`.
@override final  String issueKey;
/// Base URL of the site the issue lives on.
@override final  String siteUrl;
/// Status name at the moment of the read. Display cache only — Jira
/// remains the source of truth and this is never used to decide a
/// transition (BR-02).
@override final  String status;

/// Create a copy of JiraIssueSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JiraIssueSnapshotCopyWith<_JiraIssueSnapshot> get copyWith => __$JiraIssueSnapshotCopyWithImpl<_JiraIssueSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JiraIssueSnapshot&&(identical(other.issueKey, issueKey) || other.issueKey == issueKey)&&(identical(other.siteUrl, siteUrl) || other.siteUrl == siteUrl)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,issueKey,siteUrl,status);

@override
String toString() {
  return 'JiraIssueSnapshot(issueKey: $issueKey, siteUrl: $siteUrl, status: $status)';
}


}

/// @nodoc
abstract mixin class _$JiraIssueSnapshotCopyWith<$Res> implements $JiraIssueSnapshotCopyWith<$Res> {
  factory _$JiraIssueSnapshotCopyWith(_JiraIssueSnapshot value, $Res Function(_JiraIssueSnapshot) _then) = __$JiraIssueSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String issueKey, String siteUrl, String status
});




}
/// @nodoc
class __$JiraIssueSnapshotCopyWithImpl<$Res>
    implements _$JiraIssueSnapshotCopyWith<$Res> {
  __$JiraIssueSnapshotCopyWithImpl(this._self, this._then);

  final _JiraIssueSnapshot _self;
  final $Res Function(_JiraIssueSnapshot) _then;

/// Create a copy of JiraIssueSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? issueKey = null,Object? siteUrl = null,Object? status = null,}) {
  return _then(_JiraIssueSnapshot(
issueKey: null == issueKey ? _self.issueKey : issueKey // ignore: cast_nullable_to_non_nullable
as String,siteUrl: null == siteUrl ? _self.siteUrl : siteUrl // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
