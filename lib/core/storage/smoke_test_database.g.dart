// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smoke_test_database.dart';

// ignore_for_file: type=lint
class $SmokeTestRowsTable extends SmokeTestRows
    with TableInfo<$SmokeTestRowsTable, SmokeTestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmokeTestRowsTable(this.attachedDatabase, [this._alias]);
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
  List<GeneratedColumn> get $columns => [value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'smoke_test_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmokeTestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  SmokeTestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmokeTestRow(
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SmokeTestRowsTable createAlias(String alias) {
    return $SmokeTestRowsTable(attachedDatabase, alias);
  }
}

class SmokeTestRow extends DataClass implements Insertable<SmokeTestRow> {
  final String value;
  const SmokeTestRow({required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['value'] = Variable<String>(value);
    return map;
  }

  SmokeTestRowsCompanion toCompanion(bool nullToAbsent) {
    return SmokeTestRowsCompanion(value: Value(value));
  }

  factory SmokeTestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmokeTestRow(value: serializer.fromJson<String>(json['value']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'value': serializer.toJson<String>(value)};
  }

  SmokeTestRow copyWith({String? value}) =>
      SmokeTestRow(value: value ?? this.value);
  SmokeTestRow copyWithCompanion(SmokeTestRowsCompanion data) {
    return SmokeTestRow(
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmokeTestRow(')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => value.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmokeTestRow && other.value == this.value);
}

class SmokeTestRowsCompanion extends UpdateCompanion<SmokeTestRow> {
  final Value<String> value;
  final Value<int> rowid;
  const SmokeTestRowsCompanion({
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SmokeTestRowsCompanion.insert({
    required String value,
    this.rowid = const Value.absent(),
  }) : value = Value(value);
  static Insertable<SmokeTestRow> custom({
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SmokeTestRowsCompanion copyWith({Value<String>? value, Value<int>? rowid}) {
    return SmokeTestRowsCompanion(
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
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
    return (StringBuffer('SmokeTestRowsCompanion(')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SmokeTestDatabase extends GeneratedDatabase {
  _$SmokeTestDatabase(QueryExecutor e) : super(e);
  $SmokeTestDatabaseManager get managers => $SmokeTestDatabaseManager(this);
  late final $SmokeTestRowsTable smokeTestRows = $SmokeTestRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [smokeTestRows];
}

typedef $$SmokeTestRowsTableCreateCompanionBuilder =
    SmokeTestRowsCompanion Function({required String value, Value<int> rowid});
typedef $$SmokeTestRowsTableUpdateCompanionBuilder =
    SmokeTestRowsCompanion Function({Value<String> value, Value<int> rowid});

class $$SmokeTestRowsTableFilterComposer
    extends Composer<_$SmokeTestDatabase, $SmokeTestRowsTable> {
  $$SmokeTestRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SmokeTestRowsTableOrderingComposer
    extends Composer<_$SmokeTestDatabase, $SmokeTestRowsTable> {
  $$SmokeTestRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SmokeTestRowsTableAnnotationComposer
    extends Composer<_$SmokeTestDatabase, $SmokeTestRowsTable> {
  $$SmokeTestRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SmokeTestRowsTableTableManager
    extends
        RootTableManager<
          _$SmokeTestDatabase,
          $SmokeTestRowsTable,
          SmokeTestRow,
          $$SmokeTestRowsTableFilterComposer,
          $$SmokeTestRowsTableOrderingComposer,
          $$SmokeTestRowsTableAnnotationComposer,
          $$SmokeTestRowsTableCreateCompanionBuilder,
          $$SmokeTestRowsTableUpdateCompanionBuilder,
          (
            SmokeTestRow,
            BaseReferences<
              _$SmokeTestDatabase,
              $SmokeTestRowsTable,
              SmokeTestRow
            >,
          ),
          SmokeTestRow,
          PrefetchHooks Function()
        > {
  $$SmokeTestRowsTableTableManager(
    _$SmokeTestDatabase db,
    $SmokeTestRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmokeTestRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmokeTestRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmokeTestRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmokeTestRowsCompanion(value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SmokeTestRowsCompanion.insert(value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SmokeTestRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$SmokeTestDatabase,
      $SmokeTestRowsTable,
      SmokeTestRow,
      $$SmokeTestRowsTableFilterComposer,
      $$SmokeTestRowsTableOrderingComposer,
      $$SmokeTestRowsTableAnnotationComposer,
      $$SmokeTestRowsTableCreateCompanionBuilder,
      $$SmokeTestRowsTableUpdateCompanionBuilder,
      (
        SmokeTestRow,
        BaseReferences<_$SmokeTestDatabase, $SmokeTestRowsTable, SmokeTestRow>,
      ),
      SmokeTestRow,
      PrefetchHooks Function()
    >;

class $SmokeTestDatabaseManager {
  final _$SmokeTestDatabase _db;
  $SmokeTestDatabaseManager(this._db);
  $$SmokeTestRowsTableTableManager get smokeTestRows =>
      $$SmokeTestRowsTableTableManager(_db, _db.smokeTestRows);
}
