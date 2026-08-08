// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jira_link.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JiraLink {

/// Issue key as Jira spells it, e.g. `PROJ-123`.
 String get issueKey;/// Base URL of the Jira site the issue lives on.
 String get siteUrl;/// Status text from the last successful read. Display only — never used
/// to decide a transition, and never reconciled automatically (BR-02).
 String? get lastKnownStatus;/// When [lastKnownStatus] was read. `null` means "never synced".
 DateTime? get lastSyncedAt;
/// Create a copy of JiraLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JiraLinkCopyWith<JiraLink> get copyWith => _$JiraLinkCopyWithImpl<JiraLink>(this as JiraLink, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JiraLink&&(identical(other.issueKey, issueKey) || other.issueKey == issueKey)&&(identical(other.siteUrl, siteUrl) || other.siteUrl == siteUrl)&&(identical(other.lastKnownStatus, lastKnownStatus) || other.lastKnownStatus == lastKnownStatus)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt));
}


@override
int get hashCode => Object.hash(runtimeType,issueKey,siteUrl,lastKnownStatus,lastSyncedAt);

@override
String toString() {
  return 'JiraLink(issueKey: $issueKey, siteUrl: $siteUrl, lastKnownStatus: $lastKnownStatus, lastSyncedAt: $lastSyncedAt)';
}


}

/// @nodoc
abstract mixin class $JiraLinkCopyWith<$Res>  {
  factory $JiraLinkCopyWith(JiraLink value, $Res Function(JiraLink) _then) = _$JiraLinkCopyWithImpl;
@useResult
$Res call({
 String issueKey, String siteUrl, String? lastKnownStatus, DateTime? lastSyncedAt
});




}
/// @nodoc
class _$JiraLinkCopyWithImpl<$Res>
    implements $JiraLinkCopyWith<$Res> {
  _$JiraLinkCopyWithImpl(this._self, this._then);

  final JiraLink _self;
  final $Res Function(JiraLink) _then;

/// Create a copy of JiraLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? issueKey = null,Object? siteUrl = null,Object? lastKnownStatus = freezed,Object? lastSyncedAt = freezed,}) {
  return _then(_self.copyWith(
issueKey: null == issueKey ? _self.issueKey : issueKey // ignore: cast_nullable_to_non_nullable
as String,siteUrl: null == siteUrl ? _self.siteUrl : siteUrl // ignore: cast_nullable_to_non_nullable
as String,lastKnownStatus: freezed == lastKnownStatus ? _self.lastKnownStatus : lastKnownStatus // ignore: cast_nullable_to_non_nullable
as String?,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [JiraLink].
extension JiraLinkPatterns on JiraLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JiraLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JiraLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JiraLink value)  $default,){
final _that = this;
switch (_that) {
case _JiraLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JiraLink value)?  $default,){
final _that = this;
switch (_that) {
case _JiraLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String issueKey,  String siteUrl,  String? lastKnownStatus,  DateTime? lastSyncedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JiraLink() when $default != null:
return $default(_that.issueKey,_that.siteUrl,_that.lastKnownStatus,_that.lastSyncedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String issueKey,  String siteUrl,  String? lastKnownStatus,  DateTime? lastSyncedAt)  $default,) {final _that = this;
switch (_that) {
case _JiraLink():
return $default(_that.issueKey,_that.siteUrl,_that.lastKnownStatus,_that.lastSyncedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String issueKey,  String siteUrl,  String? lastKnownStatus,  DateTime? lastSyncedAt)?  $default,) {final _that = this;
switch (_that) {
case _JiraLink() when $default != null:
return $default(_that.issueKey,_that.siteUrl,_that.lastKnownStatus,_that.lastSyncedAt);case _:
  return null;

}
}

}

/// @nodoc


class _JiraLink implements JiraLink {
  const _JiraLink({required this.issueKey, required this.siteUrl, this.lastKnownStatus, this.lastSyncedAt});
  

/// Issue key as Jira spells it, e.g. `PROJ-123`.
@override final  String issueKey;
/// Base URL of the Jira site the issue lives on.
@override final  String siteUrl;
/// Status text from the last successful read. Display only — never used
/// to decide a transition, and never reconciled automatically (BR-02).
@override final  String? lastKnownStatus;
/// When [lastKnownStatus] was read. `null` means "never synced".
@override final  DateTime? lastSyncedAt;

/// Create a copy of JiraLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JiraLinkCopyWith<_JiraLink> get copyWith => __$JiraLinkCopyWithImpl<_JiraLink>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JiraLink&&(identical(other.issueKey, issueKey) || other.issueKey == issueKey)&&(identical(other.siteUrl, siteUrl) || other.siteUrl == siteUrl)&&(identical(other.lastKnownStatus, lastKnownStatus) || other.lastKnownStatus == lastKnownStatus)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt));
}


@override
int get hashCode => Object.hash(runtimeType,issueKey,siteUrl,lastKnownStatus,lastSyncedAt);

@override
String toString() {
  return 'JiraLink(issueKey: $issueKey, siteUrl: $siteUrl, lastKnownStatus: $lastKnownStatus, lastSyncedAt: $lastSyncedAt)';
}


}

/// @nodoc
abstract mixin class _$JiraLinkCopyWith<$Res> implements $JiraLinkCopyWith<$Res> {
  factory _$JiraLinkCopyWith(_JiraLink value, $Res Function(_JiraLink) _then) = __$JiraLinkCopyWithImpl;
@override @useResult
$Res call({
 String issueKey, String siteUrl, String? lastKnownStatus, DateTime? lastSyncedAt
});




}
/// @nodoc
class __$JiraLinkCopyWithImpl<$Res>
    implements _$JiraLinkCopyWith<$Res> {
  __$JiraLinkCopyWithImpl(this._self, this._then);

  final _JiraLink _self;
  final $Res Function(_JiraLink) _then;

/// Create a copy of JiraLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? issueKey = null,Object? siteUrl = null,Object? lastKnownStatus = freezed,Object? lastSyncedAt = freezed,}) {
  return _then(_JiraLink(
issueKey: null == issueKey ? _self.issueKey : issueKey // ignore: cast_nullable_to_non_nullable
as String,siteUrl: null == siteUrl ? _self.siteUrl : siteUrl // ignore: cast_nullable_to_non_nullable
as String,lastKnownStatus: freezed == lastKnownStatus ? _self.lastKnownStatus : lastKnownStatus // ignore: cast_nullable_to_non_nullable
as String?,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
