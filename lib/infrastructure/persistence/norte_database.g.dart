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
          ..write('jiraIssueKey: $jiraIssueKey, ')
          ..write('jiraSiteUrl: $jiraSiteUrl, ')
          ..write('jiraLastKnownStatus: $jiraLastKnownStatus, ')
          ..write('jiraLastSyncedAtMs: $jiraLastSyncedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$NorteDatabase extends GeneratedDatabase {
  _$NorteDatabase(QueryExecutor e) : super(e);
  $NorteDatabaseManager get managers => $NorteDatabaseManager(this);
  late final $TaskRowsTable taskRows = $TaskRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [taskRows];
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

class $NorteDatabaseManager {
  final _$NorteDatabase _db;
  $NorteDatabaseManager(this._db);
  $$TaskRowsTableTableManager get taskRows =>
      $$TaskRowsTableTableManager(_db, _db.taskRows);
}
