// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'norte_database.dart';

// ignore_for_file: type=lint
class $TaskRowsTable extends TaskRows with TableInfo<$TaskRowsTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMsMeta = const VerificationMeta(
    'dueDateMs',
  );
  @override
  late final GeneratedColumn<int> dueDateMs = GeneratedColumn<int>(
    'due_date_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _sourceMeetingIdMeta = const VerificationMeta(
    'sourceMeetingId',
  );
  @override
  late final GeneratedColumn<String> sourceMeetingId = GeneratedColumn<String>(
    'source_meeting_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jiraIssueKeyMeta = const VerificationMeta(
    'jiraIssueKey',
  );
  @override
  late final GeneratedColumn<String> jiraIssueKey = GeneratedColumn<String>(
    'jira_issue_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jiraSiteUrlMeta = const VerificationMeta(
    'jiraSiteUrl',
  );
  @override
  late final GeneratedColumn<String> jiraSiteUrl = GeneratedColumn<String>(
    'jira_site_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jiraLastKnownStatusMeta =
      const VerificationMeta('jiraLastKnownStatus');
  @override
  late final GeneratedColumn<String> jiraLastKnownStatus =
      GeneratedColumn<String>(
        'jira_last_known_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _jiraLastSyncedAtMsMeta =
      const VerificationMeta('jiraLastSyncedAtMs');
  @override
  late final GeneratedColumn<int> jiraLastSyncedAtMs = GeneratedColumn<int>(
    'jira_last_synced_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    status,
    priority,
    dueDateMs,
    createdAtMs,
    updatedAtMs,
    tags,
    sourceMeetingId,
    jiraIssueKey,
    jiraSiteUrl,
    jiraLastKnownStatus,
    jiraLastSyncedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('due_date_ms')) {
      context.handle(
        _dueDateMsMeta,
        dueDateMs.isAcceptableOrUnknown(data['due_date_ms']!, _dueDateMsMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('source_meeting_id')) {
      context.handle(
        _sourceMeetingIdMeta,
        sourceMeetingId.isAcceptableOrUnknown(
          data['source_meeting_id']!,
          _sourceMeetingIdMeta,
        ),
      );
    }
    if (data.containsKey('jira_issue_key')) {
      context.handle(
        _jiraIssueKeyMeta,
        jiraIssueKey.isAcceptableOrUnknown(
          data['jira_issue_key']!,
          _jiraIssueKeyMeta,
        ),
      );
    }
    if (data.containsKey('jira_site_url')) {
      context.handle(
        _jiraSiteUrlMeta,
        jiraSiteUrl.isAcceptableOrUnknown(
          data['jira_site_url']!,
          _jiraSiteUrlMeta,
        ),
      );
    }
    if (data.containsKey('jira_last_known_status')) {
      context.handle(
        _jiraLastKnownStatusMeta,
        jiraLastKnownStatus.isAcceptableOrUnknown(
          data['jira_last_known_status']!,
          _jiraLastKnownStatusMeta,
        ),
      );
    }
    if (data.containsKey('jira_last_synced_at_ms')) {
      context.handle(
        _jiraLastSyncedAtMsMeta,
        jiraLastSyncedAtMs.isAcceptableOrUnknown(
          data['jira_last_synced_at_ms']!,
          _jiraLastSyncedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      dueDateMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_date_ms'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      sourceMeetingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_meeting_id'],
      ),
      jiraIssueKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jira_issue_key'],
      ),
      jiraSiteUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jira_site_url'],
      ),
      jiraLastKnownStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jira_last_known_status'],
      ),
      jiraLastSyncedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jira_last_synced_at_ms'],
      ),
    );
  }

  @override
  $TaskRowsTable createAlias(String alias) {
    return $TaskRowsTable(attachedDatabase, alias);
  }
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  /// UUID v4 produced by the use case.
  final String id;
  final String title;
  final String? description;

  /// `TaskStatus.name` — the name, not the index, so reordering the enum
  /// cannot silently reinterpret stored rows.
  final String status;

  /// `Priority.name`, for the same reason as [status].
  final String priority;

  /// Milliseconds since epoch, UTC.
  final int? dueDateMs;
  final int createdAtMs;
  final int updatedAtMs;

  /// JSON array of strings, order preserved.
  final String tags;

  /// Meeting whose action item produced this task, when one did
  /// (`sprint-03` validation rules). Nullable and not a foreign key: deleting
  /// the meeting must not delete the task.
  final String? sourceMeetingId;
  final String? jiraIssueKey;
  final String? jiraSiteUrl;
  final String? jiraLastKnownStatus;
  final int? jiraLastSyncedAtMs;
  const TaskRow({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDateMs,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.tags,
    this.sourceMeetingId,
    this.jiraIssueKey,
    this.jiraSiteUrl,
    this.jiraLastKnownStatus,
    this.jiraLastSyncedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<String>(priority);
    if (!nullToAbsent || dueDateMs != null) {
      map['due_date_ms'] = Variable<int>(dueDateMs);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    map['tags'] = Variable<String>(tags);
    if (!nullToAbsent || sourceMeetingId != null) {
      map['source_meeting_id'] = Variable<String>(sourceMeetingId);
    }
    if (!nullToAbsent || jiraIssueKey != null) {
      map['jira_issue_key'] = Variable<String>(jiraIssueKey);
    }
    if (!nullToAbsent || jiraSiteUrl != null) {
      map['jira_site_url'] = Variable<String>(jiraSiteUrl);
    }
    if (!nullToAbsent || jiraLastKnownStatus != null) {
      map['jira_last_known_status'] = Variable<String>(jiraLastKnownStatus);
    }
    if (!nullToAbsent || jiraLastSyncedAtMs != null) {
      map['jira_last_synced_at_ms'] = Variable<int>(jiraLastSyncedAtMs);
    }
    return map;
  }

  TaskRowsCompanion toCompanion(bool nullToAbsent) {
    return TaskRowsCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      status: Value(status),
      priority: Value(priority),
      dueDateMs: dueDateMs == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDateMs),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      tags: Value(tags),
      sourceMeetingId: sourceMeetingId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceMeetingId),
      jiraIssueKey: jiraIssueKey == null && nullToAbsent
          ? const Value.absent()
          : Value(jiraIssueKey),
      jiraSiteUrl: jiraSiteUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(jiraSiteUrl),
      jiraLastKnownStatus: jiraLastKnownStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(jiraLastKnownStatus),
      jiraLastSyncedAtMs: jiraLastSyncedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(jiraLastSyncedAtMs),
    );
  }

  factory TaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<String>(json['priority']),
      dueDateMs: serializer.fromJson<int?>(json['dueDateMs']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      tags: serializer.fromJson<String>(json['tags']),
      sourceMeetingId: serializer.fromJson<String?>(json['sourceMeetingId']),
      jiraIssueKey: serializer.fromJson<String?>(json['jiraIssueKey']),
      jiraSiteUrl: serializer.fromJson<String?>(json['jiraSiteUrl']),
      jiraLastKnownStatus: serializer.fromJson<String?>(
        json['jiraLastKnownStatus'],
      ),
      jiraLastSyncedAtMs: serializer.fromJson<int?>(json['jiraLastSyncedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<String>(priority),
      'dueDateMs': serializer.toJson<int?>(dueDateMs),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'tags': serializer.toJson<String>(tags),
      'sourceMeetingId': serializer.toJson<String?>(sourceMeetingId),
      'jiraIssueKey': serializer.toJson<String?>(jiraIssueKey),
      'jiraSiteUrl': serializer.toJson<String?>(jiraSiteUrl),
      'jiraLastKnownStatus': serializer.toJson<String?>(jiraLastKnownStatus),
      'jiraLastSyncedAtMs': serializer.toJson<int?>(jiraLastSyncedAtMs),
    };
  }

  TaskRow copyWith({
    String? id,
    String? title,
    Value<String?> description = const Value.absent(),
    String? status,
    String? priority,
    Value<int?> dueDateMs = const Value.absent(),
    int? createdAtMs,
    int? updatedAtMs,
    String? tags,
    Value<String?> sourceMeetingId = const Value.absent(),
    Value<String?> jiraIssueKey = const Value.absent(),
    Value<String?> jiraSiteUrl = const Value.absent(),
    Value<String?> jiraLastKnownStatus = const Value.absent(),
    Value<int?> jiraLastSyncedAtMs = const Value.absent(),
  }) => TaskRow(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    dueDateMs: dueDateMs.present ? dueDateMs.value : this.dueDateMs,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    tags: tags ?? this.tags,
    sourceMeetingId: sourceMeetingId.present
        ? sourceMeetingId.value
        : this.sourceMeetingId,
    jiraIssueKey: jiraIssueKey.present ? jiraIssueKey.value : this.jiraIssueKey,
    jiraSiteUrl: jiraSiteUrl.present ? jiraSiteUrl.value : this.jiraSiteUrl,
    jiraLastKnownStatus: jiraLastKnownStatus.present
        ? jiraLastKnownStatus.value
        : this.jiraLastKnownStatus,
    jiraLastSyncedAtMs: jiraLastSyncedAtMs.present
        ? jiraLastSyncedAtMs.value
        : this.jiraLastSyncedAtMs,
  );
  TaskRow copyWithCompanion(TaskRowsCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      dueDateMs: data.dueDateMs.present ? data.dueDateMs.value : this.dueDateMs,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      tags: data.tags.present ? data.tags.value : this.tags,
      sourceMeetingId: data.sourceMeetingId.present
          ? data.sourceMeetingId.value
          : this.sourceMeetingId,
      jiraIssueKey: data.jiraIssueKey.present
          ? data.jiraIssueKey.value
          : this.jiraIssueKey,
      jiraSiteUrl: data.jiraSiteUrl.present
          ? data.jiraSiteUrl.value
          : this.jiraSiteUrl,
      jiraLastKnownStatus: data.jiraLastKnownStatus.present
          ? data.jiraLastKnownStatus.value
          : this.jiraLastKnownStatus,
      jiraLastSyncedAtMs: data.jiraLastSyncedAtMs.present
          ? data.jiraLastSyncedAtMs.value
          : this.jiraLastSyncedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('dueDateMs: $dueDateMs, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('tags: $tags, ')
          ..write('sourceMeetingId: $sourceMeetingId, ')
          ..write('jiraIssueKey: $jiraIssueKey, ')
          ..write('jiraSiteUrl: $jiraSiteUrl, ')
          ..write('jiraLastKnownStatus: $jiraLastKnownStatus, ')
          ..write('jiraLastSyncedAtMs: $jiraLastSyncedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    status,
    priority,
    dueDateMs,
    createdAtMs,
    updatedAtMs,
    tags,
    sourceMeetingId,
    jiraIssueKey,
    jiraSiteUrl,
    jiraLastKnownStatus,
    jiraLastSyncedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.dueDateMs == this.dueDateMs &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.tags == this.tags &&
          other.sourceMeetingId == this.sourceMeetingId &&
          other.jiraIssueKey == this.jiraIssueKey &&
          other.jiraSiteUrl == this.jiraSiteUrl &&
          other.jiraLastKnownStatus == this.jiraLastKnownStatus &&
          other.jiraLastSyncedAtMs == this.jiraLastSyncedAtMs);
}

class TaskRowsCompanion extends UpdateCompanion<TaskRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> status;
  final Value<String> priority;
  final Value<int?> dueDateMs;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<String> tags;
  final Value<String?> sourceMeetingId;
  final Value<String?> jiraIssueKey;
  final Value<String?> jiraSiteUrl;
  final Value<String?> jiraLastKnownStatus;
  final Value<int?> jiraLastSyncedAtMs;
  final Value<int> rowid;
  const TaskRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueDateMs = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.tags = const Value.absent(),
    this.sourceMeetingId = const Value.absent(),
    this.jiraIssueKey = const Value.absent(),
    this.jiraSiteUrl = const Value.absent(),
    this.jiraLastKnownStatus = const Value.absent(),
    this.jiraLastSyncedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskRowsCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required String status,
    required String priority,
    this.dueDateMs = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    this.tags = const Value.absent(),
    this.sourceMeetingId = const Value.absent(),
    this.jiraIssueKey = const Value.absent(),
    this.jiraSiteUrl = const Value.absent(),
    this.jiraLastKnownStatus = const Value.absent(),
    this.jiraLastSyncedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       status = Value(status),
       priority = Value(priority),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<TaskRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? status,
    Expression<String>? priority,
    Expression<int>? dueDateMs,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<String>? tags,
    Expression<String>? sourceMeetingId,
    Expression<String>? jiraIssueKey,
    Expression<String>? jiraSiteUrl,
    Expression<String>? jiraLastKnownStatus,
    Expression<int>? jiraLastSyncedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (dueDateMs != null) 'due_date_ms': dueDateMs,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (tags != null) 'tags': tags,
      if (sourceMeetingId != null) 'source_meeting_id': sourceMeetingId,
      if (jiraIssueKey != null) 'jira_issue_key': jiraIssueKey,
      if (jiraSiteUrl != null) 'jira_site_url': jiraSiteUrl,
      if (jiraLastKnownStatus != null)
        'jira_last_known_status': jiraLastKnownStatus,
      if (jiraLastSyncedAtMs != null)
        'jira_last_synced_at_ms': jiraLastSyncedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? status,
    Value<String>? priority,
    Value<int?>? dueDateMs,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<String>? tags,
    Value<String?>? sourceMeetingId,
    Value<String?>? jiraIssueKey,
    Value<String?>? jiraSiteUrl,
    Value<String?>? jiraLastKnownStatus,
    Value<int?>? jiraLastSyncedAtMs,
    Value<int>? rowid,
  }) {
    return TaskRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDateMs: dueDateMs ?? this.dueDateMs,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      tags: tags ?? this.tags,
      sourceMeetingId: sourceMeetingId ?? this.sourceMeetingId,
      jiraIssueKey: jiraIssueKey ?? this.jiraIssueKey,
      jiraSiteUrl: jiraSiteUrl ?? this.jiraSiteUrl,
      jiraLastKnownStatus: jiraLastKnownStatus ?? this.jiraLastKnownStatus,
      jiraLastSyncedAtMs: jiraLastSyncedAtMs ?? this.jiraLastSyncedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (dueDateMs.present) {
      map['due_date_ms'] = Variable<int>(dueDateMs.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (sourceMeetingId.present) {
      map['source_meeting_id'] = Variable<String>(sourceMeetingId.value);
    }
    if (jiraIssueKey.present) {
      map['jira_issue_key'] = Variable<String>(jiraIssueKey.value);
    }
    if (jiraSiteUrl.present) {
      map['jira_site_url'] = Variable<String>(jiraSiteUrl.value);
    }
    if (jiraLastKnownStatus.present) {
      map['jira_last_known_status'] = Variable<String>(
        jiraLastKnownStatus.value,
      );
    }
    if (jiraLastSyncedAtMs.present) {
      map['jira_last_synced_at_ms'] = Variable<int>(jiraLastSyncedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskRowsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('dueDateMs: $dueDateMs, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('tags: $tags, ')
          ..write('sourceMeetingId: $sourceMeetingId, ')
          ..write('jiraIssueKey: $jiraIssueKey, ')
          ..write('jiraSiteUrl: $jiraSiteUrl, ')
          ..write('jiraLastKnownStatus: $jiraLastKnownStatus, ')
          ..write('jiraLastSyncedAtMs: $jiraLastSyncedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxRowsTable extends OutboxRows
    with TableInfo<$OutboxRowsTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issueKeyMeta = const VerificationMeta(
    'issueKey',
  );
  @override
  late final GeneratedColumn<String> issueKey = GeneratedColumn<String>(
    'issue_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextAttemptAtMsMeta = const VerificationMeta(
    'nextAttemptAtMs',
  );
  @override
  late final GeneratedColumn<int> nextAttemptAtMs = GeneratedColumn<int>(
    'next_attempt_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sequence,
    operationId,
    kind,
    issueKey,
    payload,
    taskId,
    state,
    attempts,
    createdAtMs,
    nextAttemptAtMs,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('issue_key')) {
      context.handle(
        _issueKeyMeta,
        issueKey.isAcceptableOrUnknown(data['issue_key']!, _issueKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_issueKeyMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('next_attempt_at_ms')) {
      context.handle(
        _nextAttemptAtMsMeta,
        nextAttemptAtMs.isAcceptableOrUnknown(
          data['next_attempt_at_ms']!,
          _nextAttemptAtMsMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sequence};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      issueKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_key'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      nextAttemptAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at_ms'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $OutboxRowsTable createAlias(String alias) {
    return $OutboxRowsTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  /// Insertion order, and the primary key. Auto-incrementing rather than
  /// derived from a timestamp: two operations created in the same millisecond
  /// must still have a defined order (S02-IT-03).
  final int sequence;

  /// Idempotency key (BR-05), a UUID v4 from the use case. Unique, so the
  /// same operation cannot occupy two rows however often a dispatch is
  /// retried.
  final String operationId;

  /// `OutboxOperationKind.name`.
  final String kind;

  /// Target issue key, or the project key for a `createIssue`.
  final String issueKey;

  /// Target status, comment body, or new-issue summary.
  final String payload;

  /// Local task the operation belongs to, when there is one.
  final String? taskId;

  /// `OutboxOperationState.name`.
  final String state;
  final int attempts;

  /// Milliseconds since epoch, UTC.
  final int createdAtMs;

  /// Opening of the backoff window; `null` means "ready now".
  final int? nextAttemptAtMs;

  /// Message of the last failure. Never a payload or a credential (BR-08).
  final String? lastError;
  const OutboxRow({
    required this.sequence,
    required this.operationId,
    required this.kind,
    required this.issueKey,
    required this.payload,
    this.taskId,
    required this.state,
    required this.attempts,
    required this.createdAtMs,
    this.nextAttemptAtMs,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sequence'] = Variable<int>(sequence);
    map['operation_id'] = Variable<String>(operationId);
    map['kind'] = Variable<String>(kind);
    map['issue_key'] = Variable<String>(issueKey);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    map['state'] = Variable<String>(state);
    map['attempts'] = Variable<int>(attempts);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    if (!nullToAbsent || nextAttemptAtMs != null) {
      map['next_attempt_at_ms'] = Variable<int>(nextAttemptAtMs);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  OutboxRowsCompanion toCompanion(bool nullToAbsent) {
    return OutboxRowsCompanion(
      sequence: Value(sequence),
      operationId: Value(operationId),
      kind: Value(kind),
      issueKey: Value(issueKey),
      payload: Value(payload),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      state: Value(state),
      attempts: Value(attempts),
      createdAtMs: Value(createdAtMs),
      nextAttemptAtMs: nextAttemptAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAtMs),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      sequence: serializer.fromJson<int>(json['sequence']),
      operationId: serializer.fromJson<String>(json['operationId']),
      kind: serializer.fromJson<String>(json['kind']),
      issueKey: serializer.fromJson<String>(json['issueKey']),
      payload: serializer.fromJson<String>(json['payload']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      state: serializer.fromJson<String>(json['state']),
      attempts: serializer.fromJson<int>(json['attempts']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      nextAttemptAtMs: serializer.fromJson<int?>(json['nextAttemptAtMs']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sequence': serializer.toJson<int>(sequence),
      'operationId': serializer.toJson<String>(operationId),
      'kind': serializer.toJson<String>(kind),
      'issueKey': serializer.toJson<String>(issueKey),
      'payload': serializer.toJson<String>(payload),
      'taskId': serializer.toJson<String?>(taskId),
      'state': serializer.toJson<String>(state),
      'attempts': serializer.toJson<int>(attempts),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'nextAttemptAtMs': serializer.toJson<int?>(nextAttemptAtMs),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  OutboxRow copyWith({
    int? sequence,
    String? operationId,
    String? kind,
    String? issueKey,
    String? payload,
    Value<String?> taskId = const Value.absent(),
    String? state,
    int? attempts,
    int? createdAtMs,
    Value<int?> nextAttemptAtMs = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => OutboxRow(
    sequence: sequence ?? this.sequence,
    operationId: operationId ?? this.operationId,
    kind: kind ?? this.kind,
    issueKey: issueKey ?? this.issueKey,
    payload: payload ?? this.payload,
    taskId: taskId.present ? taskId.value : this.taskId,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    nextAttemptAtMs: nextAttemptAtMs.present
        ? nextAttemptAtMs.value
        : this.nextAttemptAtMs,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  OutboxRow copyWithCompanion(OutboxRowsCompanion data) {
    return OutboxRow(
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      kind: data.kind.present ? data.kind.value : this.kind,
      issueKey: data.issueKey.present ? data.issueKey.value : this.issueKey,
      payload: data.payload.present ? data.payload.value : this.payload,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      state: data.state.present ? data.state.value : this.state,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      nextAttemptAtMs: data.nextAttemptAtMs.present
          ? data.nextAttemptAtMs.value
          : this.nextAttemptAtMs,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('sequence: $sequence, ')
          ..write('operationId: $operationId, ')
          ..write('kind: $kind, ')
          ..write('issueKey: $issueKey, ')
          ..write('payload: $payload, ')
          ..write('taskId: $taskId, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('nextAttemptAtMs: $nextAttemptAtMs, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sequence,
    operationId,
    kind,
    issueKey,
    payload,
    taskId,
    state,
    attempts,
    createdAtMs,
    nextAttemptAtMs,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.sequence == this.sequence &&
          other.operationId == this.operationId &&
          other.kind == this.kind &&
          other.issueKey == this.issueKey &&
          other.payload == this.payload &&
          other.taskId == this.taskId &&
          other.state == this.state &&
          other.attempts == this.attempts &&
          other.createdAtMs == this.createdAtMs &&
          other.nextAttemptAtMs == this.nextAttemptAtMs &&
          other.lastError == this.lastError);
}

class OutboxRowsCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> sequence;
  final Value<String> operationId;
  final Value<String> kind;
  final Value<String> issueKey;
  final Value<String> payload;
  final Value<String?> taskId;
  final Value<String> state;
  final Value<int> attempts;
  final Value<int> createdAtMs;
  final Value<int?> nextAttemptAtMs;
  final Value<String?> lastError;
  const OutboxRowsCompanion({
    this.sequence = const Value.absent(),
    this.operationId = const Value.absent(),
    this.kind = const Value.absent(),
    this.issueKey = const Value.absent(),
    this.payload = const Value.absent(),
    this.taskId = const Value.absent(),
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.nextAttemptAtMs = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  OutboxRowsCompanion.insert({
    this.sequence = const Value.absent(),
    required String operationId,
    required String kind,
    required String issueKey,
    required String payload,
    this.taskId = const Value.absent(),
    required String state,
    this.attempts = const Value.absent(),
    required int createdAtMs,
    this.nextAttemptAtMs = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : operationId = Value(operationId),
       kind = Value(kind),
       issueKey = Value(issueKey),
       payload = Value(payload),
       state = Value(state),
       createdAtMs = Value(createdAtMs);
  static Insertable<OutboxRow> custom({
    Expression<int>? sequence,
    Expression<String>? operationId,
    Expression<String>? kind,
    Expression<String>? issueKey,
    Expression<String>? payload,
    Expression<String>? taskId,
    Expression<String>? state,
    Expression<int>? attempts,
    Expression<int>? createdAtMs,
    Expression<int>? nextAttemptAtMs,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (sequence != null) 'sequence': sequence,
      if (operationId != null) 'operation_id': operationId,
      if (kind != null) 'kind': kind,
      if (issueKey != null) 'issue_key': issueKey,
      if (payload != null) 'payload': payload,
      if (taskId != null) 'task_id': taskId,
      if (state != null) 'state': state,
      if (attempts != null) 'attempts': attempts,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (nextAttemptAtMs != null) 'next_attempt_at_ms': nextAttemptAtMs,
      if (lastError != null) 'last_error': lastError,
    });
  }

  OutboxRowsCompanion copyWith({
    Value<int>? sequence,
    Value<String>? operationId,
    Value<String>? kind,
    Value<String>? issueKey,
    Value<String>? payload,
    Value<String?>? taskId,
    Value<String>? state,
    Value<int>? attempts,
    Value<int>? createdAtMs,
    Value<int?>? nextAttemptAtMs,
    Value<String?>? lastError,
  }) {
    return OutboxRowsCompanion(
      sequence: sequence ?? this.sequence,
      operationId: operationId ?? this.operationId,
      kind: kind ?? this.kind,
      issueKey: issueKey ?? this.issueKey,
      payload: payload ?? this.payload,
      taskId: taskId ?? this.taskId,
      state: state ?? this.state,
      attempts: attempts ?? this.attempts,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      nextAttemptAtMs: nextAttemptAtMs ?? this.nextAttemptAtMs,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (issueKey.present) {
      map['issue_key'] = Variable<String>(issueKey.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (nextAttemptAtMs.present) {
      map['next_attempt_at_ms'] = Variable<int>(nextAttemptAtMs.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRowsCompanion(')
          ..write('sequence: $sequence, ')
          ..write('operationId: $operationId, ')
          ..write('kind: $kind, ')
          ..write('issueKey: $issueKey, ')
          ..write('payload: $payload, ')
          ..write('taskId: $taskId, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('nextAttemptAtMs: $nextAttemptAtMs, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $MeetingRowsTable extends MeetingRows
    with TableInfo<$MeetingRowsTable, MeetingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeetingRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retentionMeta = const VerificationMeta(
    'retention',
  );
  @override
  late final GeneratedColumn<String> retention = GeneratedColumn<String>(
    'retention',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTranscriptMeta = const VerificationMeta(
    'rawTranscript',
  );
  @override
  late final GeneratedColumn<String> rawTranscript = GeneratedColumn<String>(
    'raw_transcript',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    type,
    createdAtMs,
    retention,
    rawTranscript,
    summary,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meetings';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeetingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('retention')) {
      context.handle(
        _retentionMeta,
        retention.isAcceptableOrUnknown(data['retention']!, _retentionMeta),
      );
    } else if (isInserting) {
      context.missing(_retentionMeta);
    }
    if (data.containsKey('raw_transcript')) {
      context.handle(
        _rawTranscriptMeta,
        rawTranscript.isAcceptableOrUnknown(
          data['raw_transcript']!,
          _rawTranscriptMeta,
        ),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeetingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeetingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      retention: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}retention'],
      )!,
      rawTranscript: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_transcript'],
      ),
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
    );
  }

  @override
  $MeetingRowsTable createAlias(String alias) {
    return $MeetingRowsTable(attachedDatabase, alias);
  }
}

class MeetingRow extends DataClass implements Insertable<MeetingRow> {
  final String id;
  final String title;

  /// `MeetingType.name` — the name, not the index, so reordering the enum
  /// cannot silently reinterpret stored rows.
  final String type;

  /// Milliseconds since epoch, UTC (as in `tasks`).
  final int createdAtMs;

  /// `RetentionPolicy.name`. Kept on the row so a stored meeting still says
  /// what the user chose, long after the choice was made.
  final String retention;

  /// Present only under `RetentionPolicy.persisted` (BR-03).
  final String? rawTranscript;

  /// The summary as JSON: `sections`, `actionItems`, `generatedAt`,
  /// `engineId`.
  ///
  /// A blob rather than child tables because the shape is the template's, not
  /// the schema's: section headings are user data and change whenever a
  /// template is edited. Modelling them as columns would mean a migration
  /// every time a user renames a heading.
  final String? summary;
  const MeetingRow({
    required this.id,
    required this.title,
    required this.type,
    required this.createdAtMs,
    required this.retention,
    this.rawTranscript,
    this.summary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['retention'] = Variable<String>(retention);
    if (!nullToAbsent || rawTranscript != null) {
      map['raw_transcript'] = Variable<String>(rawTranscript);
    }
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    return map;
  }

  MeetingRowsCompanion toCompanion(bool nullToAbsent) {
    return MeetingRowsCompanion(
      id: Value(id),
      title: Value(title),
      type: Value(type),
      createdAtMs: Value(createdAtMs),
      retention: Value(retention),
      rawTranscript: rawTranscript == null && nullToAbsent
          ? const Value.absent()
          : Value(rawTranscript),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
    );
  }

  factory MeetingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeetingRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      retention: serializer.fromJson<String>(json['retention']),
      rawTranscript: serializer.fromJson<String?>(json['rawTranscript']),
      summary: serializer.fromJson<String?>(json['summary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'retention': serializer.toJson<String>(retention),
      'rawTranscript': serializer.toJson<String?>(rawTranscript),
      'summary': serializer.toJson<String?>(summary),
    };
  }

  MeetingRow copyWith({
    String? id,
    String? title,
    String? type,
    int? createdAtMs,
    String? retention,
    Value<String?> rawTranscript = const Value.absent(),
    Value<String?> summary = const Value.absent(),
  }) => MeetingRow(
    id: id ?? this.id,
    title: title ?? this.title,
    type: type ?? this.type,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    retention: retention ?? this.retention,
    rawTranscript: rawTranscript.present
        ? rawTranscript.value
        : this.rawTranscript,
    summary: summary.present ? summary.value : this.summary,
  );
  MeetingRow copyWithCompanion(MeetingRowsCompanion data) {
    return MeetingRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      retention: data.retention.present ? data.retention.value : this.retention,
      rawTranscript: data.rawTranscript.present
          ? data.rawTranscript.value
          : this.rawTranscript,
      summary: data.summary.present ? data.summary.value : this.summary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeetingRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('retention: $retention, ')
          ..write('rawTranscript: $rawTranscript, ')
          ..write('summary: $summary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    type,
    createdAtMs,
    retention,
    rawTranscript,
    summary,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeetingRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.type == this.type &&
          other.createdAtMs == this.createdAtMs &&
          other.retention == this.retention &&
          other.rawTranscript == this.rawTranscript &&
          other.summary == this.summary);
}

class MeetingRowsCompanion extends UpdateCompanion<MeetingRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> type;
  final Value<int> createdAtMs;
  final Value<String> retention;
  final Value<String?> rawTranscript;
  final Value<String?> summary;
  final Value<int> rowid;
  const MeetingRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.retention = const Value.absent(),
    this.rawTranscript = const Value.absent(),
    this.summary = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeetingRowsCompanion.insert({
    required String id,
    required String title,
    required String type,
    required int createdAtMs,
    required String retention,
    this.rawTranscript = const Value.absent(),
    this.summary = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       type = Value(type),
       createdAtMs = Value(createdAtMs),
       retention = Value(retention);
  static Insertable<MeetingRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? type,
    Expression<int>? createdAtMs,
    Expression<String>? retention,
    Expression<String>? rawTranscript,
    Expression<String>? summary,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (retention != null) 'retention': retention,
      if (rawTranscript != null) 'raw_transcript': rawTranscript,
      if (summary != null) 'summary': summary,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeetingRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? type,
    Value<int>? createdAtMs,
    Value<String>? retention,
    Value<String?>? rawTranscript,
    Value<String?>? summary,
    Value<int>? rowid,
  }) {
    return MeetingRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      retention: retention ?? this.retention,
      rawTranscript: rawTranscript ?? this.rawTranscript,
      summary: summary ?? this.summary,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (retention.present) {
      map['retention'] = Variable<String>(retention.value);
    }
    if (rawTranscript.present) {
      map['raw_transcript'] = Variable<String>(rawTranscript.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeetingRowsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('retention: $retention, ')
          ..write('rawTranscript: $rawTranscript, ')
          ..write('summary: $summary, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MeetingTemplateRowsTable extends MeetingTemplateRows
    with TableInfo<$MeetingTemplateRowsTable, MeetingTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeetingTemplateRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _systemPromptMeta = const VerificationMeta(
    'systemPrompt',
  );
  @override
  late final GeneratedColumn<String> systemPrompt = GeneratedColumn<String>(
    'system_prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionsMeta = const VerificationMeta(
    'sections',
  );
  @override
  late final GeneratedColumn<String> sections = GeneratedColumn<String>(
    'sections',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _extractActionItemsMeta =
      const VerificationMeta('extractActionItems');
  @override
  late final GeneratedColumn<bool> extractActionItems = GeneratedColumn<bool>(
    'extract_action_items',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("extract_action_items" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    systemPrompt,
    sections,
    extractActionItems,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meeting_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeetingTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('system_prompt')) {
      context.handle(
        _systemPromptMeta,
        systemPrompt.isAcceptableOrUnknown(
          data['system_prompt']!,
          _systemPromptMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_systemPromptMeta);
    }
    if (data.containsKey('sections')) {
      context.handle(
        _sectionsMeta,
        sections.isAcceptableOrUnknown(data['sections']!, _sectionsMeta),
      );
    }
    if (data.containsKey('extract_action_items')) {
      context.handle(
        _extractActionItemsMeta,
        extractActionItems.isAcceptableOrUnknown(
          data['extract_action_items']!,
          _extractActionItemsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeetingTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeetingTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      systemPrompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_prompt'],
      )!,
      sections: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sections'],
      )!,
      extractActionItems: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}extract_action_items'],
      )!,
    );
  }

  @override
  $MeetingTemplateRowsTable createAlias(String alias) {
    return $MeetingTemplateRowsTable(attachedDatabase, alias);
  }
}

class MeetingTemplateRow extends DataClass
    implements Insertable<MeetingTemplateRow> {
  /// `builtin.retro` for a seeded template, a UUID for a user's own. Stable,
  /// which is what lets the seed tell "already there" from "newly made".
  final String id;

  /// `MeetingType.name`.
  final String type;
  final String systemPrompt;

  /// JSON array of `{"title": …, "guidance": …}`, order preserved — the order
  /// the summary's sections come back in.
  final String sections;
  final bool extractActionItems;
  const MeetingTemplateRow({
    required this.id,
    required this.type,
    required this.systemPrompt,
    required this.sections,
    required this.extractActionItems,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['system_prompt'] = Variable<String>(systemPrompt);
    map['sections'] = Variable<String>(sections);
    map['extract_action_items'] = Variable<bool>(extractActionItems);
    return map;
  }

  MeetingTemplateRowsCompanion toCompanion(bool nullToAbsent) {
    return MeetingTemplateRowsCompanion(
      id: Value(id),
      type: Value(type),
      systemPrompt: Value(systemPrompt),
      sections: Value(sections),
      extractActionItems: Value(extractActionItems),
    );
  }

  factory MeetingTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeetingTemplateRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      systemPrompt: serializer.fromJson<String>(json['systemPrompt']),
      sections: serializer.fromJson<String>(json['sections']),
      extractActionItems: serializer.fromJson<bool>(json['extractActionItems']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'systemPrompt': serializer.toJson<String>(systemPrompt),
      'sections': serializer.toJson<String>(sections),
      'extractActionItems': serializer.toJson<bool>(extractActionItems),
    };
  }

  MeetingTemplateRow copyWith({
    String? id,
    String? type,
    String? systemPrompt,
    String? sections,
    bool? extractActionItems,
  }) => MeetingTemplateRow(
    id: id ?? this.id,
    type: type ?? this.type,
    systemPrompt: systemPrompt ?? this.systemPrompt,
    sections: sections ?? this.sections,
    extractActionItems: extractActionItems ?? this.extractActionItems,
  );
  MeetingTemplateRow copyWithCompanion(MeetingTemplateRowsCompanion data) {
    return MeetingTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      systemPrompt: data.systemPrompt.present
          ? data.systemPrompt.value
          : this.systemPrompt,
      sections: data.sections.present ? data.sections.value : this.sections,
      extractActionItems: data.extractActionItems.present
          ? data.extractActionItems.value
          : this.extractActionItems,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeetingTemplateRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('sections: $sections, ')
          ..write('extractActionItems: $extractActionItems')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, systemPrompt, sections, extractActionItems);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeetingTemplateRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.systemPrompt == this.systemPrompt &&
          other.sections == this.sections &&
          other.extractActionItems == this.extractActionItems);
}

class MeetingTemplateRowsCompanion extends UpdateCompanion<MeetingTemplateRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> systemPrompt;
  final Value<String> sections;
  final Value<bool> extractActionItems;
  final Value<int> rowid;
  const MeetingTemplateRowsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.systemPrompt = const Value.absent(),
    this.sections = const Value.absent(),
    this.extractActionItems = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeetingTemplateRowsCompanion.insert({
    required String id,
    required String type,
    required String systemPrompt,
    this.sections = const Value.absent(),
    this.extractActionItems = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       systemPrompt = Value(systemPrompt);
  static Insertable<MeetingTemplateRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? systemPrompt,
    Expression<String>? sections,
    Expression<bool>? extractActionItems,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (systemPrompt != null) 'system_prompt': systemPrompt,
      if (sections != null) 'sections': sections,
      if (extractActionItems != null)
        'extract_action_items': extractActionItems,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeetingTemplateRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? systemPrompt,
    Value<String>? sections,
    Value<bool>? extractActionItems,
    Value<int>? rowid,
  }) {
    return MeetingTemplateRowsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      sections: sections ?? this.sections,
      extractActionItems: extractActionItems ?? this.extractActionItems,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (systemPrompt.present) {
      map['system_prompt'] = Variable<String>(systemPrompt.value);
    }
    if (sections.present) {
      map['sections'] = Variable<String>(sections.value);
    }
    if (extractActionItems.present) {
      map['extract_action_items'] = Variable<bool>(extractActionItems.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeetingTemplateRowsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('sections: $sections, ')
          ..write('extractActionItems: $extractActionItems, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReminderRowsTable extends ReminderRows
    with TableInfo<$ReminderRowsTable, ReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggerAtMsMeta = const VerificationMeta(
    'triggerAtMs',
  );
  @override
  late final GeneratedColumn<int> triggerAtMs = GeneratedColumn<int>(
    'trigger_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFiredMeta = const VerificationMeta(
    'isFired',
  );
  @override
  late final GeneratedColumn<bool> isFired = GeneratedColumn<bool>(
    'is_fired',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_fired" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    body,
    triggerAtMs,
    createdAtMs,
    isFired,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['text']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('trigger_at_ms')) {
      context.handle(
        _triggerAtMsMeta,
        triggerAtMs.isAcceptableOrUnknown(
          data['trigger_at_ms']!,
          _triggerAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_triggerAtMsMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('is_fired')) {
      context.handle(
        _isFiredMeta,
        isFired.isAcceptableOrUnknown(data['is_fired']!, _isFiredMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      triggerAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trigger_at_ms'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      isFired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_fired'],
      )!,
    );
  }

  @override
  $ReminderRowsTable createAlias(String alias) {
    return $ReminderRowsTable(attachedDatabase, alias);
  }
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final String id;

  /// The transcribed text. Never the audio it came from (BR-06).
  ///
  /// Named `body` in Dart because `text` is `Table`'s own column builder;
  /// the column itself is `text`, which is what the entity calls it.
  final String body;

  /// Milliseconds since epoch, UTC (as in `tasks`).
  final int triggerAtMs;
  final int createdAtMs;

  /// `true` once the notification has been delivered. Sprint 06 sets it; the
  /// column exists now so the Windows check-on-launch has something to read
  /// rather than a migration to wait for.
  final bool isFired;
  const ReminderRow({
    required this.id,
    required this.body,
    required this.triggerAtMs,
    required this.createdAtMs,
    required this.isFired,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['text'] = Variable<String>(body);
    map['trigger_at_ms'] = Variable<int>(triggerAtMs);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['is_fired'] = Variable<bool>(isFired);
    return map;
  }

  ReminderRowsCompanion toCompanion(bool nullToAbsent) {
    return ReminderRowsCompanion(
      id: Value(id),
      body: Value(body),
      triggerAtMs: Value(triggerAtMs),
      createdAtMs: Value(createdAtMs),
      isFired: Value(isFired),
    );
  }

  factory ReminderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<String>(json['id']),
      body: serializer.fromJson<String>(json['body']),
      triggerAtMs: serializer.fromJson<int>(json['triggerAtMs']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      isFired: serializer.fromJson<bool>(json['isFired']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'body': serializer.toJson<String>(body),
      'triggerAtMs': serializer.toJson<int>(triggerAtMs),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'isFired': serializer.toJson<bool>(isFired),
    };
  }

  ReminderRow copyWith({
    String? id,
    String? body,
    int? triggerAtMs,
    int? createdAtMs,
    bool? isFired,
  }) => ReminderRow(
    id: id ?? this.id,
    body: body ?? this.body,
    triggerAtMs: triggerAtMs ?? this.triggerAtMs,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    isFired: isFired ?? this.isFired,
  );
  ReminderRow copyWithCompanion(ReminderRowsCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      body: data.body.present ? data.body.value : this.body,
      triggerAtMs: data.triggerAtMs.present
          ? data.triggerAtMs.value
          : this.triggerAtMs,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      isFired: data.isFired.present ? data.isFired.value : this.isFired,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
          ..write('id: $id, ')
          ..write('body: $body, ')
          ..write('triggerAtMs: $triggerAtMs, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('isFired: $isFired')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, body, triggerAtMs, createdAtMs, isFired);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRow &&
          other.id == this.id &&
          other.body == this.body &&
          other.triggerAtMs == this.triggerAtMs &&
          other.createdAtMs == this.createdAtMs &&
          other.isFired == this.isFired);
}

class ReminderRowsCompanion extends UpdateCompanion<ReminderRow> {
  final Value<String> id;
  final Value<String> body;
  final Value<int> triggerAtMs;
  final Value<int> createdAtMs;
  final Value<bool> isFired;
  final Value<int> rowid;
  const ReminderRowsCompanion({
    this.id = const Value.absent(),
    this.body = const Value.absent(),
    this.triggerAtMs = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.isFired = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReminderRowsCompanion.insert({
    required String id,
    required String body,
    required int triggerAtMs,
    required int createdAtMs,
    this.isFired = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       body = Value(body),
       triggerAtMs = Value(triggerAtMs),
       createdAtMs = Value(createdAtMs);
  static Insertable<ReminderRow> custom({
    Expression<String>? id,
    Expression<String>? body,
    Expression<int>? triggerAtMs,
    Expression<int>? createdAtMs,
    Expression<bool>? isFired,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (body != null) 'text': body,
      if (triggerAtMs != null) 'trigger_at_ms': triggerAtMs,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (isFired != null) 'is_fired': isFired,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReminderRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? body,
    Value<int>? triggerAtMs,
    Value<int>? createdAtMs,
    Value<bool>? isFired,
    Value<int>? rowid,
  }) {
    return ReminderRowsCompanion(
      id: id ?? this.id,
      body: body ?? this.body,
      triggerAtMs: triggerAtMs ?? this.triggerAtMs,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      isFired: isFired ?? this.isFired,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    if (triggerAtMs.present) {
      map['trigger_at_ms'] = Variable<int>(triggerAtMs.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (isFired.present) {
      map['is_fired'] = Variable<bool>(isFired.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRowsCompanion(')
          ..write('id: $id, ')
          ..write('body: $body, ')
          ..write('triggerAtMs: $triggerAtMs, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('isFired: $isFired, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsRowsTable extends SettingsRows
    with TableInfo<$SettingsRowsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsRowsTable createAlias(String alias) {
    return $SettingsRowsTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  /// Namespaced key, e.g. `voice`.
  final String key;

  /// The value as JSON.
  final String value;
  const SettingsRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingsRowsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsRow copyWith({String? key, String? value}) =>
      SettingsRow(key: key ?? this.key, value: value ?? this.value);
  SettingsRow copyWithCompanion(SettingsRowsCompanion data) {
    return SettingsRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsRowsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsRowsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingsRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsRowsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsRowsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$NorteDatabase extends GeneratedDatabase {
  _$NorteDatabase(QueryExecutor e) : super(e);
  $NorteDatabaseManager get managers => $NorteDatabaseManager(this);
  late final $TaskRowsTable taskRows = $TaskRowsTable(this);
  late final $OutboxRowsTable outboxRows = $OutboxRowsTable(this);
  late final $MeetingRowsTable meetingRows = $MeetingRowsTable(this);
  late final $MeetingTemplateRowsTable meetingTemplateRows =
      $MeetingTemplateRowsTable(this);
  late final $ReminderRowsTable reminderRows = $ReminderRowsTable(this);
  late final $SettingsRowsTable settingsRows = $SettingsRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    taskRows,
    outboxRows,
    meetingRows,
    meetingTemplateRows,
    reminderRows,
    settingsRows,
  ];
}

typedef $$TaskRowsTableCreateCompanionBuilder =
    TaskRowsCompanion Function({
      required String id,
      required String title,
      Value<String?> description,
      required String status,
      required String priority,
      Value<int?> dueDateMs,
      required int createdAtMs,
      required int updatedAtMs,
      Value<String> tags,
      Value<String?> sourceMeetingId,
      Value<String?> jiraIssueKey,
      Value<String?> jiraSiteUrl,
      Value<String?> jiraLastKnownStatus,
      Value<int?> jiraLastSyncedAtMs,
      Value<int> rowid,
    });
typedef $$TaskRowsTableUpdateCompanionBuilder =
    TaskRowsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> description,
      Value<String> status,
      Value<String> priority,
      Value<int?> dueDateMs,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<String> tags,
      Value<String?> sourceMeetingId,
      Value<String?> jiraIssueKey,
      Value<String?> jiraSiteUrl,
      Value<String?> jiraLastKnownStatus,
      Value<int?> jiraLastSyncedAtMs,
      Value<int> rowid,
    });

class $$TaskRowsTableFilterComposer
    extends Composer<_$NorteDatabase, $TaskRowsTable> {
  $$TaskRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDateMs => $composableBuilder(
    column: $table.dueDateMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceMeetingId => $composableBuilder(
    column: $table.sourceMeetingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jiraIssueKey => $composableBuilder(
    column: $table.jiraIssueKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jiraSiteUrl => $composableBuilder(
    column: $table.jiraSiteUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jiraLastKnownStatus => $composableBuilder(
    column: $table.jiraLastKnownStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jiraLastSyncedAtMs => $composableBuilder(
    column: $table.jiraLastSyncedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskRowsTableOrderingComposer
    extends Composer<_$NorteDatabase, $TaskRowsTable> {
  $$TaskRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDateMs => $composableBuilder(
    column: $table.dueDateMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceMeetingId => $composableBuilder(
    column: $table.sourceMeetingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jiraIssueKey => $composableBuilder(
    column: $table.jiraIssueKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jiraSiteUrl => $composableBuilder(
    column: $table.jiraSiteUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jiraLastKnownStatus => $composableBuilder(
    column: $table.jiraLastKnownStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jiraLastSyncedAtMs => $composableBuilder(
    column: $table.jiraLastSyncedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskRowsTableAnnotationComposer
    extends Composer<_$NorteDatabase, $TaskRowsTable> {
  $$TaskRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get dueDateMs =>
      $composableBuilder(column: $table.dueDateMs, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get sourceMeetingId => $composableBuilder(
    column: $table.sourceMeetingId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jiraIssueKey => $composableBuilder(
    column: $table.jiraIssueKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jiraSiteUrl => $composableBuilder(
    column: $table.jiraSiteUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jiraLastKnownStatus => $composableBuilder(
    column: $table.jiraLastKnownStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get jiraLastSyncedAtMs => $composableBuilder(
    column: $table.jiraLastSyncedAtMs,
    builder: (column) => column,
  );
}

class $$TaskRowsTableTableManager
    extends
        RootTableManager<
          _$NorteDatabase,
          $TaskRowsTable,
          TaskRow,
          $$TaskRowsTableFilterComposer,
          $$TaskRowsTableOrderingComposer,
          $$TaskRowsTableAnnotationComposer,
          $$TaskRowsTableCreateCompanionBuilder,
          $$TaskRowsTableUpdateCompanionBuilder,
          (TaskRow, BaseReferences<_$NorteDatabase, $TaskRowsTable, TaskRow>),
          TaskRow,
          PrefetchHooks Function()
        > {
  $$TaskRowsTableTableManager(_$NorteDatabase db, $TaskRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<int?> dueDateMs = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String?> sourceMeetingId = const Value.absent(),
                Value<String?> jiraIssueKey = const Value.absent(),
                Value<String?> jiraSiteUrl = const Value.absent(),
                Value<String?> jiraLastKnownStatus = const Value.absent(),
                Value<int?> jiraLastSyncedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRowsCompanion(
                id: id,
                title: title,
                description: description,
                status: status,
                priority: priority,
                dueDateMs: dueDateMs,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                tags: tags,
                sourceMeetingId: sourceMeetingId,
                jiraIssueKey: jiraIssueKey,
                jiraSiteUrl: jiraSiteUrl,
                jiraLastKnownStatus: jiraLastKnownStatus,
                jiraLastSyncedAtMs: jiraLastSyncedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> description = const Value.absent(),
                required String status,
                required String priority,
                Value<int?> dueDateMs = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                Value<String> tags = const Value.absent(),
                Value<String?> sourceMeetingId = const Value.absent(),
                Value<String?> jiraIssueKey = const Value.absent(),
                Value<String?> jiraSiteUrl = const Value.absent(),
                Value<String?> jiraLastKnownStatus = const Value.absent(),
                Value<int?> jiraLastSyncedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRowsCompanion.insert(
                id: id,
                title: title,
                description: description,
                status: status,
                priority: priority,
                dueDateMs: dueDateMs,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                tags: tags,
                sourceMeetingId: sourceMeetingId,
                jiraIssueKey: jiraIssueKey,
                jiraSiteUrl: jiraSiteUrl,
                jiraLastKnownStatus: jiraLastKnownStatus,
                jiraLastSyncedAtMs: jiraLastSyncedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$NorteDatabase,
      $TaskRowsTable,
      TaskRow,
      $$TaskRowsTableFilterComposer,
      $$TaskRowsTableOrderingComposer,
      $$TaskRowsTableAnnotationComposer,
      $$TaskRowsTableCreateCompanionBuilder,
      $$TaskRowsTableUpdateCompanionBuilder,
      (TaskRow, BaseReferences<_$NorteDatabase, $TaskRowsTable, TaskRow>),
      TaskRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxRowsTableCreateCompanionBuilder =
    OutboxRowsCompanion Function({
      Value<int> sequence,
      required String operationId,
      required String kind,
      required String issueKey,
      required String payload,
      Value<String?> taskId,
      required String state,
      Value<int> attempts,
      required int createdAtMs,
      Value<int?> nextAttemptAtMs,
      Value<String?> lastError,
    });
typedef $$OutboxRowsTableUpdateCompanionBuilder =
    OutboxRowsCompanion Function({
      Value<int> sequence,
      Value<String> operationId,
      Value<String> kind,
      Value<String> issueKey,
      Value<String> payload,
      Value<String?> taskId,
      Value<String> state,
      Value<int> attempts,
      Value<int> createdAtMs,
      Value<int?> nextAttemptAtMs,
      Value<String?> lastError,
    });

class $$OutboxRowsTableFilterComposer
    extends Composer<_$NorteDatabase, $OutboxRowsTable> {
  $$OutboxRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issueKey => $composableBuilder(
    column: $table.issueKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAtMs => $composableBuilder(
    column: $table.nextAttemptAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxRowsTableOrderingComposer
    extends Composer<_$NorteDatabase, $OutboxRowsTable> {
  $$OutboxRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issueKey => $composableBuilder(
    column: $table.issueKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAtMs => $composableBuilder(
    column: $table.nextAttemptAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxRowsTableAnnotationComposer
    extends Composer<_$NorteDatabase, $OutboxRowsTable> {
  $$OutboxRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get issueKey =>
      $composableBuilder(column: $table.issueKey, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextAttemptAtMs => $composableBuilder(
    column: $table.nextAttemptAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$OutboxRowsTableTableManager
    extends
        RootTableManager<
          _$NorteDatabase,
          $OutboxRowsTable,
          OutboxRow,
          $$OutboxRowsTableFilterComposer,
          $$OutboxRowsTableOrderingComposer,
          $$OutboxRowsTableAnnotationComposer,
          $$OutboxRowsTableCreateCompanionBuilder,
          $$OutboxRowsTableUpdateCompanionBuilder,
          (
            OutboxRow,
            BaseReferences<_$NorteDatabase, $OutboxRowsTable, OutboxRow>,
          ),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxRowsTableTableManager(_$NorteDatabase db, $OutboxRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> issueKey = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int?> nextAttemptAtMs = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => OutboxRowsCompanion(
                sequence: sequence,
                operationId: operationId,
                kind: kind,
                issueKey: issueKey,
                payload: payload,
                taskId: taskId,
                state: state,
                attempts: attempts,
                createdAtMs: createdAtMs,
                nextAttemptAtMs: nextAttemptAtMs,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                required String operationId,
                required String kind,
                required String issueKey,
                required String payload,
                Value<String?> taskId = const Value.absent(),
                required String state,
                Value<int> attempts = const Value.absent(),
                required int createdAtMs,
                Value<int?> nextAttemptAtMs = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => OutboxRowsCompanion.insert(
                sequence: sequence,
                operationId: operationId,
                kind: kind,
                issueKey: issueKey,
                payload: payload,
                taskId: taskId,
                state: state,
                attempts: attempts,
                createdAtMs: createdAtMs,
                nextAttemptAtMs: nextAttemptAtMs,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$NorteDatabase,
      $OutboxRowsTable,
      OutboxRow,
      $$OutboxRowsTableFilterComposer,
      $$OutboxRowsTableOrderingComposer,
      $$OutboxRowsTableAnnotationComposer,
      $$OutboxRowsTableCreateCompanionBuilder,
      $$OutboxRowsTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$NorteDatabase, $OutboxRowsTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;
typedef $$MeetingRowsTableCreateCompanionBuilder =
    MeetingRowsCompanion Function({
      required String id,
      required String title,
      required String type,
      required int createdAtMs,
      required String retention,
      Value<String?> rawTranscript,
      Value<String?> summary,
      Value<int> rowid,
    });
typedef $$MeetingRowsTableUpdateCompanionBuilder =
    MeetingRowsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> type,
      Value<int> createdAtMs,
      Value<String> retention,
      Value<String?> rawTranscript,
      Value<String?> summary,
      Value<int> rowid,
    });

class $$MeetingRowsTableFilterComposer
    extends Composer<_$NorteDatabase, $MeetingRowsTable> {
  $$MeetingRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get retention => $composableBuilder(
    column: $table.retention,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawTranscript => $composableBuilder(
    column: $table.rawTranscript,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MeetingRowsTableOrderingComposer
    extends Composer<_$NorteDatabase, $MeetingRowsTable> {
  $$MeetingRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get retention => $composableBuilder(
    column: $table.retention,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawTranscript => $composableBuilder(
    column: $table.rawTranscript,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MeetingRowsTableAnnotationComposer
    extends Composer<_$NorteDatabase, $MeetingRowsTable> {
  $$MeetingRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get retention =>
      $composableBuilder(column: $table.retention, builder: (column) => column);

  GeneratedColumn<String> get rawTranscript => $composableBuilder(
    column: $table.rawTranscript,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);
}

class $$MeetingRowsTableTableManager
    extends
        RootTableManager<
          _$NorteDatabase,
          $MeetingRowsTable,
          MeetingRow,
          $$MeetingRowsTableFilterComposer,
          $$MeetingRowsTableOrderingComposer,
          $$MeetingRowsTableAnnotationComposer,
          $$MeetingRowsTableCreateCompanionBuilder,
          $$MeetingRowsTableUpdateCompanionBuilder,
          (
            MeetingRow,
            BaseReferences<_$NorteDatabase, $MeetingRowsTable, MeetingRow>,
          ),
          MeetingRow,
          PrefetchHooks Function()
        > {
  $$MeetingRowsTableTableManager(_$NorteDatabase db, $MeetingRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeetingRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeetingRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeetingRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<String> retention = const Value.absent(),
                Value<String?> rawTranscript = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeetingRowsCompanion(
                id: id,
                title: title,
                type: type,
                createdAtMs: createdAtMs,
                retention: retention,
                rawTranscript: rawTranscript,
                summary: summary,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String type,
                required int createdAtMs,
                required String retention,
                Value<String?> rawTranscript = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeetingRowsCompanion.insert(
                id: id,
                title: title,
                type: type,
                createdAtMs: createdAtMs,
                retention: retention,
                rawTranscript: rawTranscript,
                summary: summary,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MeetingRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$NorteDatabase,
      $MeetingRowsTable,
      MeetingRow,
      $$MeetingRowsTableFilterComposer,
      $$MeetingRowsTableOrderingComposer,
      $$MeetingRowsTableAnnotationComposer,
      $$MeetingRowsTableCreateCompanionBuilder,
      $$MeetingRowsTableUpdateCompanionBuilder,
      (
        MeetingRow,
        BaseReferences<_$NorteDatabase, $MeetingRowsTable, MeetingRow>,
      ),
      MeetingRow,
      PrefetchHooks Function()
    >;
typedef $$MeetingTemplateRowsTableCreateCompanionBuilder =
    MeetingTemplateRowsCompanion Function({
      required String id,
      required String type,
      required String systemPrompt,
      Value<String> sections,
      Value<bool> extractActionItems,
      Value<int> rowid,
    });
typedef $$MeetingTemplateRowsTableUpdateCompanionBuilder =
    MeetingTemplateRowsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> systemPrompt,
      Value<String> sections,
      Value<bool> extractActionItems,
      Value<int> rowid,
    });

class $$MeetingTemplateRowsTableFilterComposer
    extends Composer<_$NorteDatabase, $MeetingTemplateRowsTable> {
  $$MeetingTemplateRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get systemPrompt => $composableBuilder(
    column: $table.systemPrompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sections => $composableBuilder(
    column: $table.sections,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get extractActionItems => $composableBuilder(
    column: $table.extractActionItems,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MeetingTemplateRowsTableOrderingComposer
    extends Composer<_$NorteDatabase, $MeetingTemplateRowsTable> {
  $$MeetingTemplateRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get systemPrompt => $composableBuilder(
    column: $table.systemPrompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sections => $composableBuilder(
    column: $table.sections,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get extractActionItems => $composableBuilder(
    column: $table.extractActionItems,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MeetingTemplateRowsTableAnnotationComposer
    extends Composer<_$NorteDatabase, $MeetingTemplateRowsTable> {
  $$MeetingTemplateRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get systemPrompt => $composableBuilder(
    column: $table.systemPrompt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sections =>
      $composableBuilder(column: $table.sections, builder: (column) => column);

  GeneratedColumn<bool> get extractActionItems => $composableBuilder(
    column: $table.extractActionItems,
    builder: (column) => column,
  );
}

class $$MeetingTemplateRowsTableTableManager
    extends
        RootTableManager<
          _$NorteDatabase,
          $MeetingTemplateRowsTable,
          MeetingTemplateRow,
          $$MeetingTemplateRowsTableFilterComposer,
          $$MeetingTemplateRowsTableOrderingComposer,
          $$MeetingTemplateRowsTableAnnotationComposer,
          $$MeetingTemplateRowsTableCreateCompanionBuilder,
          $$MeetingTemplateRowsTableUpdateCompanionBuilder,
          (
            MeetingTemplateRow,
            BaseReferences<
              _$NorteDatabase,
              $MeetingTemplateRowsTable,
              MeetingTemplateRow
            >,
          ),
          MeetingTemplateRow,
          PrefetchHooks Function()
        > {
  $$MeetingTemplateRowsTableTableManager(
    _$NorteDatabase db,
    $MeetingTemplateRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeetingTemplateRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeetingTemplateRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MeetingTemplateRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> systemPrompt = const Value.absent(),
                Value<String> sections = const Value.absent(),
                Value<bool> extractActionItems = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeetingTemplateRowsCompanion(
                id: id,
                type: type,
                systemPrompt: systemPrompt,
                sections: sections,
                extractActionItems: extractActionItems,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String systemPrompt,
                Value<String> sections = const Value.absent(),
                Value<bool> extractActionItems = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeetingTemplateRowsCompanion.insert(
                id: id,
                type: type,
                systemPrompt: systemPrompt,
                sections: sections,
                extractActionItems: extractActionItems,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MeetingTemplateRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$NorteDatabase,
      $MeetingTemplateRowsTable,
      MeetingTemplateRow,
      $$MeetingTemplateRowsTableFilterComposer,
      $$MeetingTemplateRowsTableOrderingComposer,
      $$MeetingTemplateRowsTableAnnotationComposer,
      $$MeetingTemplateRowsTableCreateCompanionBuilder,
      $$MeetingTemplateRowsTableUpdateCompanionBuilder,
      (
        MeetingTemplateRow,
        BaseReferences<
          _$NorteDatabase,
          $MeetingTemplateRowsTable,
          MeetingTemplateRow
        >,
      ),
      MeetingTemplateRow,
      PrefetchHooks Function()
    >;
typedef $$ReminderRowsTableCreateCompanionBuilder =
    ReminderRowsCompanion Function({
      required String id,
      required String body,
      required int triggerAtMs,
      required int createdAtMs,
      Value<bool> isFired,
      Value<int> rowid,
    });
typedef $$ReminderRowsTableUpdateCompanionBuilder =
    ReminderRowsCompanion Function({
      Value<String> id,
      Value<String> body,
      Value<int> triggerAtMs,
      Value<int> createdAtMs,
      Value<bool> isFired,
      Value<int> rowid,
    });

class $$ReminderRowsTableFilterComposer
    extends Composer<_$NorteDatabase, $ReminderRowsTable> {
  $$ReminderRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get triggerAtMs => $composableBuilder(
    column: $table.triggerAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFired => $composableBuilder(
    column: $table.isFired,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReminderRowsTableOrderingComposer
    extends Composer<_$NorteDatabase, $ReminderRowsTable> {
  $$ReminderRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get triggerAtMs => $composableBuilder(
    column: $table.triggerAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFired => $composableBuilder(
    column: $table.isFired,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReminderRowsTableAnnotationComposer
    extends Composer<_$NorteDatabase, $ReminderRowsTable> {
  $$ReminderRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get triggerAtMs => $composableBuilder(
    column: $table.triggerAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFired =>
      $composableBuilder(column: $table.isFired, builder: (column) => column);
}

class $$ReminderRowsTableTableManager
    extends
        RootTableManager<
          _$NorteDatabase,
          $ReminderRowsTable,
          ReminderRow,
          $$ReminderRowsTableFilterComposer,
          $$ReminderRowsTableOrderingComposer,
          $$ReminderRowsTableAnnotationComposer,
          $$ReminderRowsTableCreateCompanionBuilder,
          $$ReminderRowsTableUpdateCompanionBuilder,
          (
            ReminderRow,
            BaseReferences<_$NorteDatabase, $ReminderRowsTable, ReminderRow>,
          ),
          ReminderRow,
          PrefetchHooks Function()
        > {
  $$ReminderRowsTableTableManager(_$NorteDatabase db, $ReminderRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReminderRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReminderRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> triggerAtMs = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<bool> isFired = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderRowsCompanion(
                id: id,
                body: body,
                triggerAtMs: triggerAtMs,
                createdAtMs: createdAtMs,
                isFired: isFired,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String body,
                required int triggerAtMs,
                required int createdAtMs,
                Value<bool> isFired = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderRowsCompanion.insert(
                id: id,
                body: body,
                triggerAtMs: triggerAtMs,
                createdAtMs: createdAtMs,
                isFired: isFired,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReminderRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$NorteDatabase,
      $ReminderRowsTable,
      ReminderRow,
      $$ReminderRowsTableFilterComposer,
      $$ReminderRowsTableOrderingComposer,
      $$ReminderRowsTableAnnotationComposer,
      $$ReminderRowsTableCreateCompanionBuilder,
      $$ReminderRowsTableUpdateCompanionBuilder,
      (
        ReminderRow,
        BaseReferences<_$NorteDatabase, $ReminderRowsTable, ReminderRow>,
      ),
      ReminderRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsRowsTableCreateCompanionBuilder =
    SettingsRowsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsRowsTableUpdateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsRowsTableFilterComposer
    extends Composer<_$NorteDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsRowsTableOrderingComposer
    extends Composer<_$NorteDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsRowsTableAnnotationComposer
    extends Composer<_$NorteDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsRowsTableTableManager
    extends
        RootTableManager<
          _$NorteDatabase,
          $SettingsRowsTable,
          SettingsRow,
          $$SettingsRowsTableFilterComposer,
          $$SettingsRowsTableOrderingComposer,
          $$SettingsRowsTableAnnotationComposer,
          $$SettingsRowsTableCreateCompanionBuilder,
          $$SettingsRowsTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$NorteDatabase, $SettingsRowsTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsRowsTableTableManager(_$NorteDatabase db, $SettingsRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsRowsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsRowsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$NorteDatabase,
      $SettingsRowsTable,
      SettingsRow,
      $$SettingsRowsTableFilterComposer,
      $$SettingsRowsTableOrderingComposer,
      $$SettingsRowsTableAnnotationComposer,
      $$SettingsRowsTableCreateCompanionBuilder,
      $$SettingsRowsTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$NorteDatabase, $SettingsRowsTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;

class $NorteDatabaseManager {
  final _$NorteDatabase _db;
  $NorteDatabaseManager(this._db);
  $$TaskRowsTableTableManager get taskRows =>
      $$TaskRowsTableTableManager(_db, _db.taskRows);
  $$OutboxRowsTableTableManager get outboxRows =>
      $$OutboxRowsTableTableManager(_db, _db.outboxRows);
  $$MeetingRowsTableTableManager get meetingRows =>
      $$MeetingRowsTableTableManager(_db, _db.meetingRows);
  $$MeetingTemplateRowsTableTableManager get meetingTemplateRows =>
      $$MeetingTemplateRowsTableTableManager(_db, _db.meetingTemplateRows);
  $$ReminderRowsTableTableManager get reminderRows =>
      $$ReminderRowsTableTableManager(_db, _db.reminderRows);
  $$SettingsRowsTableTableManager get settingsRows =>
      $$SettingsRowsTableTableManager(_db, _db.settingsRows);
}
