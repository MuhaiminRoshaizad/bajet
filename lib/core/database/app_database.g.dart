// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _openingBalanceMeta = const VerificationMeta(
    'openingBalance',
  );
  @override
  late final GeneratedColumn<int> openingBalance = GeneratedColumn<int>(
    'opening_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> openingDate =
      GeneratedColumn<String>(
        'opening_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AppSettingsTable.$converteropeningDate);
  static const VerificationMeta _weeklyCapMeta = const VerificationMeta(
    'weeklyCap',
  );
  @override
  late final GeneratedColumn<int> weeklyCap = GeneratedColumn<int>(
    'weekly_cap',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bufferMeta = const VerificationMeta('buffer');
  @override
  late final GeneratedColumn<int> buffer = GeneratedColumn<int>(
    'buffer',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    openingBalance,
    openingDate,
    weeklyCap,
    buffer,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
        _openingBalanceMeta,
        openingBalance.isAcceptableOrUnknown(
          data['opening_balance']!,
          _openingBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingBalanceMeta);
    }
    if (data.containsKey('weekly_cap')) {
      context.handle(
        _weeklyCapMeta,
        weeklyCap.isAcceptableOrUnknown(data['weekly_cap']!, _weeklyCapMeta),
      );
    } else if (isInserting) {
      context.missing(_weeklyCapMeta);
    }
    if (data.containsKey('buffer')) {
      context.handle(
        _bufferMeta,
        buffer.isAcceptableOrUnknown(data['buffer']!, _bufferMeta),
      );
    } else if (isInserting) {
      context.missing(_bufferMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      openingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_balance'],
      )!,
      openingDate: $AppSettingsTable.$converteropeningDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}opening_date'],
        )!,
      ),
      weeklyCap: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekly_cap'],
      )!,
      buffer: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}buffer'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converteropeningDate =
      const DayConverter();
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final int openingBalance;
  final DateTime openingDate;
  final int weeklyCap;

  /// The minimum that must remain after buying a goal.
  final int buffer;
  const AppSetting({
    required this.id,
    required this.openingBalance,
    required this.openingDate,
    required this.weeklyCap,
    required this.buffer,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['opening_balance'] = Variable<int>(openingBalance);
    {
      map['opening_date'] = Variable<String>(
        $AppSettingsTable.$converteropeningDate.toSql(openingDate),
      );
    }
    map['weekly_cap'] = Variable<int>(weeklyCap);
    map['buffer'] = Variable<int>(buffer);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      openingBalance: Value(openingBalance),
      openingDate: Value(openingDate),
      weeklyCap: Value(weeklyCap),
      buffer: Value(buffer),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      openingBalance: serializer.fromJson<int>(json['openingBalance']),
      openingDate: serializer.fromJson<DateTime>(json['openingDate']),
      weeklyCap: serializer.fromJson<int>(json['weeklyCap']),
      buffer: serializer.fromJson<int>(json['buffer']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'openingBalance': serializer.toJson<int>(openingBalance),
      'openingDate': serializer.toJson<DateTime>(openingDate),
      'weeklyCap': serializer.toJson<int>(weeklyCap),
      'buffer': serializer.toJson<int>(buffer),
    };
  }

  AppSetting copyWith({
    int? id,
    int? openingBalance,
    DateTime? openingDate,
    int? weeklyCap,
    int? buffer,
  }) => AppSetting(
    id: id ?? this.id,
    openingBalance: openingBalance ?? this.openingBalance,
    openingDate: openingDate ?? this.openingDate,
    weeklyCap: weeklyCap ?? this.weeklyCap,
    buffer: buffer ?? this.buffer,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      openingBalance: data.openingBalance.present
          ? data.openingBalance.value
          : this.openingBalance,
      openingDate: data.openingDate.present
          ? data.openingDate.value
          : this.openingDate,
      weeklyCap: data.weeklyCap.present ? data.weeklyCap.value : this.weeklyCap,
      buffer: data.buffer.present ? data.buffer.value : this.buffer,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('openingDate: $openingDate, ')
          ..write('weeklyCap: $weeklyCap, ')
          ..write('buffer: $buffer')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, openingBalance, openingDate, weeklyCap, buffer);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.openingBalance == this.openingBalance &&
          other.openingDate == this.openingDate &&
          other.weeklyCap == this.weeklyCap &&
          other.buffer == this.buffer);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<int> openingBalance;
  final Value<DateTime> openingDate;
  final Value<int> weeklyCap;
  final Value<int> buffer;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.openingDate = const Value.absent(),
    this.weeklyCap = const Value.absent(),
    this.buffer = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required int openingBalance,
    required DateTime openingDate,
    required int weeklyCap,
    required int buffer,
  }) : openingBalance = Value(openingBalance),
       openingDate = Value(openingDate),
       weeklyCap = Value(weeklyCap),
       buffer = Value(buffer);
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<int>? openingBalance,
    Expression<String>? openingDate,
    Expression<int>? weeklyCap,
    Expression<int>? buffer,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (openingDate != null) 'opening_date': openingDate,
      if (weeklyCap != null) 'weekly_cap': weeklyCap,
      if (buffer != null) 'buffer': buffer,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<int>? openingBalance,
    Value<DateTime>? openingDate,
    Value<int>? weeklyCap,
    Value<int>? buffer,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      openingBalance: openingBalance ?? this.openingBalance,
      openingDate: openingDate ?? this.openingDate,
      weeklyCap: weeklyCap ?? this.weeklyCap,
      buffer: buffer ?? this.buffer,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<int>(openingBalance.value);
    }
    if (openingDate.present) {
      map['opening_date'] = Variable<String>(
        $AppSettingsTable.$converteropeningDate.toSql(openingDate.value),
      );
    }
    if (weeklyCap.present) {
      map['weekly_cap'] = Variable<int>(weeklyCap.value);
    }
    if (buffer.present) {
      map['buffer'] = Variable<int>(buffer.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('openingDate: $openingDate, ')
          ..write('weeklyCap: $weeklyCap, ')
          ..write('buffer: $buffer')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EntryKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EntryKind>($CategoriesTable.$converterkind);
  static const VerificationMeta _tintMeta = const VerificationMeta('tint');
  @override
  late final GeneratedColumn<String> tint = GeneratedColumn<String>(
    'tint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFixedMeta = const VerificationMeta(
    'isFixed',
  );
  @override
  late final GeneratedColumn<bool> isFixed = GeneratedColumn<bool>(
    'is_fixed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_fixed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _monthlyBudgetMeta = const VerificationMeta(
    'monthlyBudget',
  );
  @override
  late final GeneratedColumn<int> monthlyBudget = GeneratedColumn<int>(
    'monthly_budget',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    label,
    kind,
    tint,
    isFixed,
    monthlyBudget,
    archived,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
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
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('tint')) {
      context.handle(
        _tintMeta,
        tint.isAcceptableOrUnknown(data['tint']!, _tintMeta),
      );
    } else if (isInserting) {
      context.missing(_tintMeta);
    }
    if (data.containsKey('is_fixed')) {
      context.handle(
        _isFixedMeta,
        isFixed.isAcceptableOrUnknown(data['is_fixed']!, _isFixedMeta),
      );
    }
    if (data.containsKey('monthly_budget')) {
      context.handle(
        _monthlyBudgetMeta,
        monthlyBudget.isAcceptableOrUnknown(
          data['monthly_budget']!,
          _monthlyBudgetMeta,
        ),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      kind: $CategoriesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      tint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tint'],
      )!,
      isFixed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_fixed'],
      )!,
      monthlyBudget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monthly_budget'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EntryKind, String, String> $converterkind =
      const EnumNameConverter<EntryKind>(EntryKind.values);
}

class Category extends DataClass implements Insertable<Category> {
  final String key;
  final String label;
  final EntryKind kind;
  final String tint;

  /// Fixed spending, such as bills, is excluded from the weekly cap.
  final bool isFixed;
  final int? monthlyBudget;
  final bool archived;
  final int sortOrder;
  const Category({
    required this.key,
    required this.label,
    required this.kind,
    required this.tint,
    required this.isFixed,
    this.monthlyBudget,
    required this.archived,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['label'] = Variable<String>(label);
    {
      map['kind'] = Variable<String>(
        $CategoriesTable.$converterkind.toSql(kind),
      );
    }
    map['tint'] = Variable<String>(tint);
    map['is_fixed'] = Variable<bool>(isFixed);
    if (!nullToAbsent || monthlyBudget != null) {
      map['monthly_budget'] = Variable<int>(monthlyBudget);
    }
    map['archived'] = Variable<bool>(archived);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      key: Value(key),
      label: Value(label),
      kind: Value(kind),
      tint: Value(tint),
      isFixed: Value(isFixed),
      monthlyBudget: monthlyBudget == null && nullToAbsent
          ? const Value.absent()
          : Value(monthlyBudget),
      archived: Value(archived),
      sortOrder: Value(sortOrder),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      key: serializer.fromJson<String>(json['key']),
      label: serializer.fromJson<String>(json['label']),
      kind: $CategoriesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      tint: serializer.fromJson<String>(json['tint']),
      isFixed: serializer.fromJson<bool>(json['isFixed']),
      monthlyBudget: serializer.fromJson<int?>(json['monthlyBudget']),
      archived: serializer.fromJson<bool>(json['archived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'label': serializer.toJson<String>(label),
      'kind': serializer.toJson<String>(
        $CategoriesTable.$converterkind.toJson(kind),
      ),
      'tint': serializer.toJson<String>(tint),
      'isFixed': serializer.toJson<bool>(isFixed),
      'monthlyBudget': serializer.toJson<int?>(monthlyBudget),
      'archived': serializer.toJson<bool>(archived),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Category copyWith({
    String? key,
    String? label,
    EntryKind? kind,
    String? tint,
    bool? isFixed,
    Value<int?> monthlyBudget = const Value.absent(),
    bool? archived,
    int? sortOrder,
  }) => Category(
    key: key ?? this.key,
    label: label ?? this.label,
    kind: kind ?? this.kind,
    tint: tint ?? this.tint,
    isFixed: isFixed ?? this.isFixed,
    monthlyBudget: monthlyBudget.present
        ? monthlyBudget.value
        : this.monthlyBudget,
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      key: data.key.present ? data.key.value : this.key,
      label: data.label.present ? data.label.value : this.label,
      kind: data.kind.present ? data.kind.value : this.kind,
      tint: data.tint.present ? data.tint.value : this.tint,
      isFixed: data.isFixed.present ? data.isFixed.value : this.isFixed,
      monthlyBudget: data.monthlyBudget.present
          ? data.monthlyBudget.value
          : this.monthlyBudget,
      archived: data.archived.present ? data.archived.value : this.archived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('key: $key, ')
          ..write('label: $label, ')
          ..write('kind: $kind, ')
          ..write('tint: $tint, ')
          ..write('isFixed: $isFixed, ')
          ..write('monthlyBudget: $monthlyBudget, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    key,
    label,
    kind,
    tint,
    isFixed,
    monthlyBudget,
    archived,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.key == this.key &&
          other.label == this.label &&
          other.kind == this.kind &&
          other.tint == this.tint &&
          other.isFixed == this.isFixed &&
          other.monthlyBudget == this.monthlyBudget &&
          other.archived == this.archived &&
          other.sortOrder == this.sortOrder);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> key;
  final Value<String> label;
  final Value<EntryKind> kind;
  final Value<String> tint;
  final Value<bool> isFixed;
  final Value<int?> monthlyBudget;
  final Value<bool> archived;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.key = const Value.absent(),
    this.label = const Value.absent(),
    this.kind = const Value.absent(),
    this.tint = const Value.absent(),
    this.isFixed = const Value.absent(),
    this.monthlyBudget = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String key,
    required String label,
    required EntryKind kind,
    required String tint,
    this.isFixed = const Value.absent(),
    this.monthlyBudget = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       label = Value(label),
       kind = Value(kind),
       tint = Value(tint);
  static Insertable<Category> custom({
    Expression<String>? key,
    Expression<String>? label,
    Expression<String>? kind,
    Expression<String>? tint,
    Expression<bool>? isFixed,
    Expression<int>? monthlyBudget,
    Expression<bool>? archived,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (label != null) 'label': label,
      if (kind != null) 'kind': kind,
      if (tint != null) 'tint': tint,
      if (isFixed != null) 'is_fixed': isFixed,
      if (monthlyBudget != null) 'monthly_budget': monthlyBudget,
      if (archived != null) 'archived': archived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? key,
    Value<String>? label,
    Value<EntryKind>? kind,
    Value<String>? tint,
    Value<bool>? isFixed,
    Value<int?>? monthlyBudget,
    Value<bool>? archived,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      key: key ?? this.key,
      label: label ?? this.label,
      kind: kind ?? this.kind,
      tint: tint ?? this.tint,
      isFixed: isFixed ?? this.isFixed,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $CategoriesTable.$converterkind.toSql(kind.value),
      );
    }
    if (tint.present) {
      map['tint'] = Variable<String>(tint.value);
    }
    if (isFixed.present) {
      map['is_fixed'] = Variable<bool>(isFixed.value);
    }
    if (monthlyBudget.present) {
      map['monthly_budget'] = Variable<int>(monthlyBudget.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('key: $key, ')
          ..write('label: $label, ')
          ..write('kind: $kind, ')
          ..write('tint: $tint, ')
          ..write('isFixed: $isFixed, ')
          ..write('monthlyBudget: $monthlyBudget, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringItemsTable extends RecurringItems
    with TableInfo<$RecurringItemsTable, RecurringItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EntryKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EntryKind>($RecurringItemsTable.$converterkind);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    check: () => ComparableExpr(amount).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryKeyMeta = const VerificationMeta(
    'categoryKey',
  );
  @override
  late final GeneratedColumn<String> categoryKey = GeneratedColumn<String>(
    'category_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories ("key")',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> nextDue =
      GeneratedColumn<String>(
        'next_due',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($RecurringItemsTable.$converternextDue);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isEstimateMeta = const VerificationMeta(
    'isEstimate',
  );
  @override
  late final GeneratedColumn<bool> isEstimate = GeneratedColumn<bool>(
    'is_estimate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_estimate" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _windowDaysMeta = const VerificationMeta(
    'windowDays',
  );
  @override
  late final GeneratedColumn<int> windowDays = GeneratedColumn<int>(
    'window_days',
    aliasedName,
    false,
    check: () => ComparableExpr(windowDays).isBetweenValues(0, maxWindowDays),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    amount,
    categoryKey,
    nextDue,
    active,
    isEstimate,
    windowDays,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category_key')) {
      context.handle(
        _categoryKeyMeta,
        categoryKey.isAcceptableOrUnknown(
          data['category_key']!,
          _categoryKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryKeyMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('is_estimate')) {
      context.handle(
        _isEstimateMeta,
        isEstimate.isAcceptableOrUnknown(data['is_estimate']!, _isEstimateMeta),
      );
    }
    if (data.containsKey('window_days')) {
      context.handle(
        _windowDaysMeta,
        windowDays.isAcceptableOrUnknown(data['window_days']!, _windowDaysMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: $RecurringItemsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      categoryKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_key'],
      )!,
      nextDue: $RecurringItemsTable.$converternextDue.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}next_due'],
        )!,
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      isEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_estimate'],
      )!,
      windowDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}window_days'],
      )!,
    );
  }

  @override
  $RecurringItemsTable createAlias(String alias) {
    return $RecurringItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EntryKind, String, String> $converterkind =
      const EnumNameConverter<EntryKind>(EntryKind.values);
  static TypeConverter<DateTime, String> $converternextDue =
      const DayConverter();
}

class RecurringItem extends DataClass implements Insertable<RecurringItem> {
  final int id;
  final String name;
  final EntryKind kind;
  final int amount;
  final String categoryKey;

  /// The next occurrence not yet paid; its day of month repeats monthly.
  final DateTime nextDue;
  final bool active;
  final bool isEstimate;

  /// Days after [nextDue] it may still land, for pay or bills that move
  /// around; 0 means on the day itself.
  final int windowDays;
  const RecurringItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.amount,
    required this.categoryKey,
    required this.nextDue,
    required this.active,
    required this.isEstimate,
    required this.windowDays,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['kind'] = Variable<String>(
        $RecurringItemsTable.$converterkind.toSql(kind),
      );
    }
    map['amount'] = Variable<int>(amount);
    map['category_key'] = Variable<String>(categoryKey);
    {
      map['next_due'] = Variable<String>(
        $RecurringItemsTable.$converternextDue.toSql(nextDue),
      );
    }
    map['active'] = Variable<bool>(active);
    map['is_estimate'] = Variable<bool>(isEstimate);
    map['window_days'] = Variable<int>(windowDays);
    return map;
  }

  RecurringItemsCompanion toCompanion(bool nullToAbsent) {
    return RecurringItemsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      amount: Value(amount),
      categoryKey: Value(categoryKey),
      nextDue: Value(nextDue),
      active: Value(active),
      isEstimate: Value(isEstimate),
      windowDays: Value(windowDays),
    );
  }

  factory RecurringItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringItem(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: $RecurringItemsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      amount: serializer.fromJson<int>(json['amount']),
      categoryKey: serializer.fromJson<String>(json['categoryKey']),
      nextDue: serializer.fromJson<DateTime>(json['nextDue']),
      active: serializer.fromJson<bool>(json['active']),
      isEstimate: serializer.fromJson<bool>(json['isEstimate']),
      windowDays: serializer.fromJson<int>(json['windowDays']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(
        $RecurringItemsTable.$converterkind.toJson(kind),
      ),
      'amount': serializer.toJson<int>(amount),
      'categoryKey': serializer.toJson<String>(categoryKey),
      'nextDue': serializer.toJson<DateTime>(nextDue),
      'active': serializer.toJson<bool>(active),
      'isEstimate': serializer.toJson<bool>(isEstimate),
      'windowDays': serializer.toJson<int>(windowDays),
    };
  }

  RecurringItem copyWith({
    int? id,
    String? name,
    EntryKind? kind,
    int? amount,
    String? categoryKey,
    DateTime? nextDue,
    bool? active,
    bool? isEstimate,
    int? windowDays,
  }) => RecurringItem(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    categoryKey: categoryKey ?? this.categoryKey,
    nextDue: nextDue ?? this.nextDue,
    active: active ?? this.active,
    isEstimate: isEstimate ?? this.isEstimate,
    windowDays: windowDays ?? this.windowDays,
  );
  RecurringItem copyWithCompanion(RecurringItemsCompanion data) {
    return RecurringItem(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      categoryKey: data.categoryKey.present
          ? data.categoryKey.value
          : this.categoryKey,
      nextDue: data.nextDue.present ? data.nextDue.value : this.nextDue,
      active: data.active.present ? data.active.value : this.active,
      isEstimate: data.isEstimate.present
          ? data.isEstimate.value
          : this.isEstimate,
      windowDays: data.windowDays.present
          ? data.windowDays.value
          : this.windowDays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringItem(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('nextDue: $nextDue, ')
          ..write('active: $active, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('windowDays: $windowDays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    amount,
    categoryKey,
    nextDue,
    active,
    isEstimate,
    windowDays,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringItem &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.categoryKey == this.categoryKey &&
          other.nextDue == this.nextDue &&
          other.active == this.active &&
          other.isEstimate == this.isEstimate &&
          other.windowDays == this.windowDays);
}

class RecurringItemsCompanion extends UpdateCompanion<RecurringItem> {
  final Value<int> id;
  final Value<String> name;
  final Value<EntryKind> kind;
  final Value<int> amount;
  final Value<String> categoryKey;
  final Value<DateTime> nextDue;
  final Value<bool> active;
  final Value<bool> isEstimate;
  final Value<int> windowDays;
  const RecurringItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.categoryKey = const Value.absent(),
    this.nextDue = const Value.absent(),
    this.active = const Value.absent(),
    this.isEstimate = const Value.absent(),
    this.windowDays = const Value.absent(),
  });
  RecurringItemsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required EntryKind kind,
    required int amount,
    required String categoryKey,
    required DateTime nextDue,
    this.active = const Value.absent(),
    this.isEstimate = const Value.absent(),
    this.windowDays = const Value.absent(),
  }) : name = Value(name),
       kind = Value(kind),
       amount = Value(amount),
       categoryKey = Value(categoryKey),
       nextDue = Value(nextDue);
  static Insertable<RecurringItem> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? amount,
    Expression<String>? categoryKey,
    Expression<String>? nextDue,
    Expression<bool>? active,
    Expression<bool>? isEstimate,
    Expression<int>? windowDays,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (categoryKey != null) 'category_key': categoryKey,
      if (nextDue != null) 'next_due': nextDue,
      if (active != null) 'active': active,
      if (isEstimate != null) 'is_estimate': isEstimate,
      if (windowDays != null) 'window_days': windowDays,
    });
  }

  RecurringItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<EntryKind>? kind,
    Value<int>? amount,
    Value<String>? categoryKey,
    Value<DateTime>? nextDue,
    Value<bool>? active,
    Value<bool>? isEstimate,
    Value<int>? windowDays,
  }) {
    return RecurringItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      categoryKey: categoryKey ?? this.categoryKey,
      nextDue: nextDue ?? this.nextDue,
      active: active ?? this.active,
      isEstimate: isEstimate ?? this.isEstimate,
      windowDays: windowDays ?? this.windowDays,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $RecurringItemsTable.$converterkind.toSql(kind.value),
      );
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (categoryKey.present) {
      map['category_key'] = Variable<String>(categoryKey.value);
    }
    if (nextDue.present) {
      map['next_due'] = Variable<String>(
        $RecurringItemsTable.$converternextDue.toSql(nextDue.value),
      );
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (isEstimate.present) {
      map['is_estimate'] = Variable<bool>(isEstimate.value);
    }
    if (windowDays.present) {
      map['window_days'] = Variable<int>(windowDays.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('nextDue: $nextDue, ')
          ..write('active: $active, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('windowDays: $windowDays')
          ..write(')'))
        .toString();
  }
}

class $EntriesTable extends Entries with TableInfo<$EntriesTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> occurredOn =
      GeneratedColumn<String>(
        'occurred_on',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($EntriesTable.$converteroccurredOn);
  @override
  late final GeneratedColumnWithTypeConverter<EntryKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EntryKind>($EntriesTable.$converterkind);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    check: () => ComparableExpr(amount).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryKeyMeta = const VerificationMeta(
    'categoryKey',
  );
  @override
  late final GeneratedColumn<String> categoryKey = GeneratedColumn<String>(
    'category_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories ("key")',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptMeta = const VerificationMeta(
    'receipt',
  );
  @override
  late final GeneratedColumn<String> receipt = GeneratedColumn<String>(
    'receipt',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurringItemIdMeta = const VerificationMeta(
    'recurringItemId',
  );
  @override
  late final GeneratedColumn<int> recurringItemId = GeneratedColumn<int>(
    'recurring_item_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recurring_items (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    occurredOn,
    kind,
    amount,
    categoryKey,
    label,
    note,
    receipt,
    recurringItemId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category_key')) {
      context.handle(
        _categoryKeyMeta,
        categoryKey.isAcceptableOrUnknown(
          data['category_key']!,
          _categoryKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryKeyMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('receipt')) {
      context.handle(
        _receiptMeta,
        receipt.isAcceptableOrUnknown(data['receipt']!, _receiptMeta),
      );
    }
    if (data.containsKey('recurring_item_id')) {
      context.handle(
        _recurringItemIdMeta,
        recurringItemId.isAcceptableOrUnknown(
          data['recurring_item_id']!,
          _recurringItemIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      occurredOn: $EntriesTable.$converteroccurredOn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}occurred_on'],
        )!,
      ),
      kind: $EntriesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      categoryKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_key'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      receipt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt'],
      ),
      recurringItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurring_item_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converteroccurredOn =
      const DayConverter();
  static JsonTypeConverter2<EntryKind, String, String> $converterkind =
      const EnumNameConverter<EntryKind>(EntryKind.values);
}

class Entry extends DataClass implements Insertable<Entry> {
  final int id;
  final DateTime occurredOn;
  final EntryKind kind;
  final int amount;
  final String categoryKey;

  /// A short name such as "Coffee", used for per-item stats like average cost.
  final String? label;
  final String? note;

  /// File name of an attached receipt image in the app's receipts folder.
  final String? receipt;

  /// Set when the entry confirms a recurring item.
  final int? recurringItemId;
  final DateTime createdAt;
  const Entry({
    required this.id,
    required this.occurredOn,
    required this.kind,
    required this.amount,
    required this.categoryKey,
    this.label,
    this.note,
    this.receipt,
    this.recurringItemId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['occurred_on'] = Variable<String>(
        $EntriesTable.$converteroccurredOn.toSql(occurredOn),
      );
    }
    {
      map['kind'] = Variable<String>($EntriesTable.$converterkind.toSql(kind));
    }
    map['amount'] = Variable<int>(amount);
    map['category_key'] = Variable<String>(categoryKey);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || receipt != null) {
      map['receipt'] = Variable<String>(receipt);
    }
    if (!nullToAbsent || recurringItemId != null) {
      map['recurring_item_id'] = Variable<int>(recurringItemId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      occurredOn: Value(occurredOn),
      kind: Value(kind),
      amount: Value(amount),
      categoryKey: Value(categoryKey),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      receipt: receipt == null && nullToAbsent
          ? const Value.absent()
          : Value(receipt),
      recurringItemId: recurringItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringItemId),
      createdAt: Value(createdAt),
    );
  }

  factory Entry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      id: serializer.fromJson<int>(json['id']),
      occurredOn: serializer.fromJson<DateTime>(json['occurredOn']),
      kind: $EntriesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      amount: serializer.fromJson<int>(json['amount']),
      categoryKey: serializer.fromJson<String>(json['categoryKey']),
      label: serializer.fromJson<String?>(json['label']),
      note: serializer.fromJson<String?>(json['note']),
      receipt: serializer.fromJson<String?>(json['receipt']),
      recurringItemId: serializer.fromJson<int?>(json['recurringItemId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'occurredOn': serializer.toJson<DateTime>(occurredOn),
      'kind': serializer.toJson<String>(
        $EntriesTable.$converterkind.toJson(kind),
      ),
      'amount': serializer.toJson<int>(amount),
      'categoryKey': serializer.toJson<String>(categoryKey),
      'label': serializer.toJson<String?>(label),
      'note': serializer.toJson<String?>(note),
      'receipt': serializer.toJson<String?>(receipt),
      'recurringItemId': serializer.toJson<int?>(recurringItemId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Entry copyWith({
    int? id,
    DateTime? occurredOn,
    EntryKind? kind,
    int? amount,
    String? categoryKey,
    Value<String?> label = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> receipt = const Value.absent(),
    Value<int?> recurringItemId = const Value.absent(),
    DateTime? createdAt,
  }) => Entry(
    id: id ?? this.id,
    occurredOn: occurredOn ?? this.occurredOn,
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    categoryKey: categoryKey ?? this.categoryKey,
    label: label.present ? label.value : this.label,
    note: note.present ? note.value : this.note,
    receipt: receipt.present ? receipt.value : this.receipt,
    recurringItemId: recurringItemId.present
        ? recurringItemId.value
        : this.recurringItemId,
    createdAt: createdAt ?? this.createdAt,
  );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      id: data.id.present ? data.id.value : this.id,
      occurredOn: data.occurredOn.present
          ? data.occurredOn.value
          : this.occurredOn,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      categoryKey: data.categoryKey.present
          ? data.categoryKey.value
          : this.categoryKey,
      label: data.label.present ? data.label.value : this.label,
      note: data.note.present ? data.note.value : this.note,
      receipt: data.receipt.present ? data.receipt.value : this.receipt,
      recurringItemId: data.recurringItemId.present
          ? data.recurringItemId.value
          : this.recurringItemId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('id: $id, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('label: $label, ')
          ..write('note: $note, ')
          ..write('receipt: $receipt, ')
          ..write('recurringItemId: $recurringItemId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    occurredOn,
    kind,
    amount,
    categoryKey,
    label,
    note,
    receipt,
    recurringItemId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.id == this.id &&
          other.occurredOn == this.occurredOn &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.categoryKey == this.categoryKey &&
          other.label == this.label &&
          other.note == this.note &&
          other.receipt == this.receipt &&
          other.recurringItemId == this.recurringItemId &&
          other.createdAt == this.createdAt);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<int> id;
  final Value<DateTime> occurredOn;
  final Value<EntryKind> kind;
  final Value<int> amount;
  final Value<String> categoryKey;
  final Value<String?> label;
  final Value<String?> note;
  final Value<String?> receipt;
  final Value<int?> recurringItemId;
  final Value<DateTime> createdAt;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.occurredOn = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.categoryKey = const Value.absent(),
    this.label = const Value.absent(),
    this.note = const Value.absent(),
    this.receipt = const Value.absent(),
    this.recurringItemId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime occurredOn,
    required EntryKind kind,
    required int amount,
    required String categoryKey,
    this.label = const Value.absent(),
    this.note = const Value.absent(),
    this.receipt = const Value.absent(),
    this.recurringItemId = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : occurredOn = Value(occurredOn),
       kind = Value(kind),
       amount = Value(amount),
       categoryKey = Value(categoryKey);
  static Insertable<Entry> custom({
    Expression<int>? id,
    Expression<String>? occurredOn,
    Expression<String>? kind,
    Expression<int>? amount,
    Expression<String>? categoryKey,
    Expression<String>? label,
    Expression<String>? note,
    Expression<String>? receipt,
    Expression<int>? recurringItemId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (occurredOn != null) 'occurred_on': occurredOn,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (categoryKey != null) 'category_key': categoryKey,
      if (label != null) 'label': label,
      if (note != null) 'note': note,
      if (receipt != null) 'receipt': receipt,
      if (recurringItemId != null) 'recurring_item_id': recurringItemId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? occurredOn,
    Value<EntryKind>? kind,
    Value<int>? amount,
    Value<String>? categoryKey,
    Value<String?>? label,
    Value<String?>? note,
    Value<String?>? receipt,
    Value<int?>? recurringItemId,
    Value<DateTime>? createdAt,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      occurredOn: occurredOn ?? this.occurredOn,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      categoryKey: categoryKey ?? this.categoryKey,
      label: label ?? this.label,
      note: note ?? this.note,
      receipt: receipt ?? this.receipt,
      recurringItemId: recurringItemId ?? this.recurringItemId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (occurredOn.present) {
      map['occurred_on'] = Variable<String>(
        $EntriesTable.$converteroccurredOn.toSql(occurredOn.value),
      );
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $EntriesTable.$converterkind.toSql(kind.value),
      );
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (categoryKey.present) {
      map['category_key'] = Variable<String>(categoryKey.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (receipt.present) {
      map['receipt'] = Variable<String>(receipt.value);
    }
    if (recurringItemId.present) {
      map['recurring_item_id'] = Variable<int>(recurringItemId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('label: $label, ')
          ..write('note: $note, ')
          ..write('receipt: $receipt, ')
          ..write('recurringItemId: $recurringItemId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WeeklyRulesTable extends WeeklyRules
    with TableInfo<$WeeklyRulesTable, WeeklyRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    check: () => ComparableExpr(weekday).isBetweenValues(1, 7),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RhythmDayType, String> dayType =
      GeneratedColumn<String>(
        'day_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RhythmDayType>($WeeklyRulesTable.$converterdayType);
  static const VerificationMeta _plannedSpendMeta = const VerificationMeta(
    'plannedSpend',
  );
  @override
  late final GeneratedColumn<int> plannedSpend = GeneratedColumn<int>(
    'planned_spend',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isFastingDayMeta = const VerificationMeta(
    'isFastingDay',
  );
  @override
  late final GeneratedColumn<bool> isFastingDay = GeneratedColumn<bool>(
    'is_fasting_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_fasting_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    weekday,
    label,
    dayType,
    plannedSpend,
    isFastingDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeeklyRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('planned_spend')) {
      context.handle(
        _plannedSpendMeta,
        plannedSpend.isAcceptableOrUnknown(
          data['planned_spend']!,
          _plannedSpendMeta,
        ),
      );
    }
    if (data.containsKey('is_fasting_day')) {
      context.handle(
        _isFastingDayMeta,
        isFastingDay.isAcceptableOrUnknown(
          data['is_fasting_day']!,
          _isFastingDayMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {weekday};
  @override
  WeeklyRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyRule(
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      dayType: $WeeklyRulesTable.$converterdayType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}day_type'],
        )!,
      ),
      plannedSpend: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_spend'],
      )!,
      isFastingDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_fasting_day'],
      )!,
    );
  }

  @override
  $WeeklyRulesTable createAlias(String alias) {
    return $WeeklyRulesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RhythmDayType, String, String> $converterdayType =
      const EnumNameConverter<RhythmDayType>(RhythmDayType.values);
}

class WeeklyRule extends DataClass implements Insertable<WeeklyRule> {
  /// 1 is Monday, matching DateTime.weekday.
  final int weekday;
  final String label;
  final RhythmDayType dayType;
  final int plannedSpend;
  final bool isFastingDay;
  const WeeklyRule({
    required this.weekday,
    required this.label,
    required this.dayType,
    required this.plannedSpend,
    required this.isFastingDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['weekday'] = Variable<int>(weekday);
    map['label'] = Variable<String>(label);
    {
      map['day_type'] = Variable<String>(
        $WeeklyRulesTable.$converterdayType.toSql(dayType),
      );
    }
    map['planned_spend'] = Variable<int>(plannedSpend);
    map['is_fasting_day'] = Variable<bool>(isFastingDay);
    return map;
  }

  WeeklyRulesCompanion toCompanion(bool nullToAbsent) {
    return WeeklyRulesCompanion(
      weekday: Value(weekday),
      label: Value(label),
      dayType: Value(dayType),
      plannedSpend: Value(plannedSpend),
      isFastingDay: Value(isFastingDay),
    );
  }

  factory WeeklyRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyRule(
      weekday: serializer.fromJson<int>(json['weekday']),
      label: serializer.fromJson<String>(json['label']),
      dayType: $WeeklyRulesTable.$converterdayType.fromJson(
        serializer.fromJson<String>(json['dayType']),
      ),
      plannedSpend: serializer.fromJson<int>(json['plannedSpend']),
      isFastingDay: serializer.fromJson<bool>(json['isFastingDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'weekday': serializer.toJson<int>(weekday),
      'label': serializer.toJson<String>(label),
      'dayType': serializer.toJson<String>(
        $WeeklyRulesTable.$converterdayType.toJson(dayType),
      ),
      'plannedSpend': serializer.toJson<int>(plannedSpend),
      'isFastingDay': serializer.toJson<bool>(isFastingDay),
    };
  }

  WeeklyRule copyWith({
    int? weekday,
    String? label,
    RhythmDayType? dayType,
    int? plannedSpend,
    bool? isFastingDay,
  }) => WeeklyRule(
    weekday: weekday ?? this.weekday,
    label: label ?? this.label,
    dayType: dayType ?? this.dayType,
    plannedSpend: plannedSpend ?? this.plannedSpend,
    isFastingDay: isFastingDay ?? this.isFastingDay,
  );
  WeeklyRule copyWithCompanion(WeeklyRulesCompanion data) {
    return WeeklyRule(
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      label: data.label.present ? data.label.value : this.label,
      dayType: data.dayType.present ? data.dayType.value : this.dayType,
      plannedSpend: data.plannedSpend.present
          ? data.plannedSpend.value
          : this.plannedSpend,
      isFastingDay: data.isFastingDay.present
          ? data.isFastingDay.value
          : this.isFastingDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyRule(')
          ..write('weekday: $weekday, ')
          ..write('label: $label, ')
          ..write('dayType: $dayType, ')
          ..write('plannedSpend: $plannedSpend, ')
          ..write('isFastingDay: $isFastingDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(weekday, label, dayType, plannedSpend, isFastingDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyRule &&
          other.weekday == this.weekday &&
          other.label == this.label &&
          other.dayType == this.dayType &&
          other.plannedSpend == this.plannedSpend &&
          other.isFastingDay == this.isFastingDay);
}

class WeeklyRulesCompanion extends UpdateCompanion<WeeklyRule> {
  final Value<int> weekday;
  final Value<String> label;
  final Value<RhythmDayType> dayType;
  final Value<int> plannedSpend;
  final Value<bool> isFastingDay;
  const WeeklyRulesCompanion({
    this.weekday = const Value.absent(),
    this.label = const Value.absent(),
    this.dayType = const Value.absent(),
    this.plannedSpend = const Value.absent(),
    this.isFastingDay = const Value.absent(),
  });
  WeeklyRulesCompanion.insert({
    this.weekday = const Value.absent(),
    required String label,
    required RhythmDayType dayType,
    this.plannedSpend = const Value.absent(),
    this.isFastingDay = const Value.absent(),
  }) : label = Value(label),
       dayType = Value(dayType);
  static Insertable<WeeklyRule> custom({
    Expression<int>? weekday,
    Expression<String>? label,
    Expression<String>? dayType,
    Expression<int>? plannedSpend,
    Expression<bool>? isFastingDay,
  }) {
    return RawValuesInsertable({
      if (weekday != null) 'weekday': weekday,
      if (label != null) 'label': label,
      if (dayType != null) 'day_type': dayType,
      if (plannedSpend != null) 'planned_spend': plannedSpend,
      if (isFastingDay != null) 'is_fasting_day': isFastingDay,
    });
  }

  WeeklyRulesCompanion copyWith({
    Value<int>? weekday,
    Value<String>? label,
    Value<RhythmDayType>? dayType,
    Value<int>? plannedSpend,
    Value<bool>? isFastingDay,
  }) {
    return WeeklyRulesCompanion(
      weekday: weekday ?? this.weekday,
      label: label ?? this.label,
      dayType: dayType ?? this.dayType,
      plannedSpend: plannedSpend ?? this.plannedSpend,
      isFastingDay: isFastingDay ?? this.isFastingDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (dayType.present) {
      map['day_type'] = Variable<String>(
        $WeeklyRulesTable.$converterdayType.toSql(dayType.value),
      );
    }
    if (plannedSpend.present) {
      map['planned_spend'] = Variable<int>(plannedSpend.value);
    }
    if (isFastingDay.present) {
      map['is_fasting_day'] = Variable<bool>(isFastingDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyRulesCompanion(')
          ..write('weekday: $weekday, ')
          ..write('label: $label, ')
          ..write('dayType: $dayType, ')
          ..write('plannedSpend: $plannedSpend, ')
          ..write('isFastingDay: $isFastingDay')
          ..write(')'))
        .toString();
  }
}

class $PlannedEventsTable extends PlannedEvents
    with TableInfo<$PlannedEventsTable, PlannedEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannedEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EntryKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EntryKind>($PlannedEventsTable.$converterkind);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    check: () => ComparableExpr(amount).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryKeyMeta = const VerificationMeta(
    'categoryKey',
  );
  @override
  late final GeneratedColumn<String> categoryKey = GeneratedColumn<String>(
    'category_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories ("key")',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> dueOn =
      GeneratedColumn<String>(
        'due_on',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PlannedEventsTable.$converterdueOn);
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _countInProjectionMeta = const VerificationMeta(
    'countInProjection',
  );
  @override
  late final GeneratedColumn<bool> countInProjection = GeneratedColumn<bool>(
    'count_in_projection',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("count_in_projection" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _repeatsYearlyMeta = const VerificationMeta(
    'repeatsYearly',
  );
  @override
  late final GeneratedColumn<bool> repeatsYearly = GeneratedColumn<bool>(
    'repeats_yearly',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("repeats_yearly" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    amount,
    categoryKey,
    dueOn,
    done,
    countInProjection,
    repeatsYearly,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planned_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannedEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category_key')) {
      context.handle(
        _categoryKeyMeta,
        categoryKey.isAcceptableOrUnknown(
          data['category_key']!,
          _categoryKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryKeyMeta);
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    if (data.containsKey('count_in_projection')) {
      context.handle(
        _countInProjectionMeta,
        countInProjection.isAcceptableOrUnknown(
          data['count_in_projection']!,
          _countInProjectionMeta,
        ),
      );
    }
    if (data.containsKey('repeats_yearly')) {
      context.handle(
        _repeatsYearlyMeta,
        repeatsYearly.isAcceptableOrUnknown(
          data['repeats_yearly']!,
          _repeatsYearlyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlannedEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannedEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: $PlannedEventsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      categoryKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_key'],
      )!,
      dueOn: $PlannedEventsTable.$converterdueOn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}due_on'],
        )!,
      ),
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      )!,
      countInProjection: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}count_in_projection'],
      )!,
      repeatsYearly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}repeats_yearly'],
      )!,
    );
  }

  @override
  $PlannedEventsTable createAlias(String alias) {
    return $PlannedEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EntryKind, String, String> $converterkind =
      const EnumNameConverter<EntryKind>(EntryKind.values);
  static TypeConverter<DateTime, String> $converterdueOn = const DayConverter();
}

class PlannedEvent extends DataClass implements Insertable<PlannedEvent> {
  final int id;
  final String name;
  final EntryKind kind;
  final int amount;
  final String categoryKey;
  final DateTime dueOn;
  final bool done;

  /// False for money that may not arrive, such as an unconfirmed bonus.
  final bool countInProjection;

  /// Comes back on the same date every year, such as a birthday; [dueOn] is
  /// the next one, and marking it done moves it on a year.
  final bool repeatsYearly;
  const PlannedEvent({
    required this.id,
    required this.name,
    required this.kind,
    required this.amount,
    required this.categoryKey,
    required this.dueOn,
    required this.done,
    required this.countInProjection,
    required this.repeatsYearly,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['kind'] = Variable<String>(
        $PlannedEventsTable.$converterkind.toSql(kind),
      );
    }
    map['amount'] = Variable<int>(amount);
    map['category_key'] = Variable<String>(categoryKey);
    {
      map['due_on'] = Variable<String>(
        $PlannedEventsTable.$converterdueOn.toSql(dueOn),
      );
    }
    map['done'] = Variable<bool>(done);
    map['count_in_projection'] = Variable<bool>(countInProjection);
    map['repeats_yearly'] = Variable<bool>(repeatsYearly);
    return map;
  }

  PlannedEventsCompanion toCompanion(bool nullToAbsent) {
    return PlannedEventsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      amount: Value(amount),
      categoryKey: Value(categoryKey),
      dueOn: Value(dueOn),
      done: Value(done),
      countInProjection: Value(countInProjection),
      repeatsYearly: Value(repeatsYearly),
    );
  }

  factory PlannedEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannedEvent(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: $PlannedEventsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      amount: serializer.fromJson<int>(json['amount']),
      categoryKey: serializer.fromJson<String>(json['categoryKey']),
      dueOn: serializer.fromJson<DateTime>(json['dueOn']),
      done: serializer.fromJson<bool>(json['done']),
      countInProjection: serializer.fromJson<bool>(json['countInProjection']),
      repeatsYearly: serializer.fromJson<bool>(json['repeatsYearly']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(
        $PlannedEventsTable.$converterkind.toJson(kind),
      ),
      'amount': serializer.toJson<int>(amount),
      'categoryKey': serializer.toJson<String>(categoryKey),
      'dueOn': serializer.toJson<DateTime>(dueOn),
      'done': serializer.toJson<bool>(done),
      'countInProjection': serializer.toJson<bool>(countInProjection),
      'repeatsYearly': serializer.toJson<bool>(repeatsYearly),
    };
  }

  PlannedEvent copyWith({
    int? id,
    String? name,
    EntryKind? kind,
    int? amount,
    String? categoryKey,
    DateTime? dueOn,
    bool? done,
    bool? countInProjection,
    bool? repeatsYearly,
  }) => PlannedEvent(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    categoryKey: categoryKey ?? this.categoryKey,
    dueOn: dueOn ?? this.dueOn,
    done: done ?? this.done,
    countInProjection: countInProjection ?? this.countInProjection,
    repeatsYearly: repeatsYearly ?? this.repeatsYearly,
  );
  PlannedEvent copyWithCompanion(PlannedEventsCompanion data) {
    return PlannedEvent(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      categoryKey: data.categoryKey.present
          ? data.categoryKey.value
          : this.categoryKey,
      dueOn: data.dueOn.present ? data.dueOn.value : this.dueOn,
      done: data.done.present ? data.done.value : this.done,
      countInProjection: data.countInProjection.present
          ? data.countInProjection.value
          : this.countInProjection,
      repeatsYearly: data.repeatsYearly.present
          ? data.repeatsYearly.value
          : this.repeatsYearly,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannedEvent(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('dueOn: $dueOn, ')
          ..write('done: $done, ')
          ..write('countInProjection: $countInProjection, ')
          ..write('repeatsYearly: $repeatsYearly')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    amount,
    categoryKey,
    dueOn,
    done,
    countInProjection,
    repeatsYearly,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedEvent &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.categoryKey == this.categoryKey &&
          other.dueOn == this.dueOn &&
          other.done == this.done &&
          other.countInProjection == this.countInProjection &&
          other.repeatsYearly == this.repeatsYearly);
}

class PlannedEventsCompanion extends UpdateCompanion<PlannedEvent> {
  final Value<int> id;
  final Value<String> name;
  final Value<EntryKind> kind;
  final Value<int> amount;
  final Value<String> categoryKey;
  final Value<DateTime> dueOn;
  final Value<bool> done;
  final Value<bool> countInProjection;
  final Value<bool> repeatsYearly;
  const PlannedEventsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.categoryKey = const Value.absent(),
    this.dueOn = const Value.absent(),
    this.done = const Value.absent(),
    this.countInProjection = const Value.absent(),
    this.repeatsYearly = const Value.absent(),
  });
  PlannedEventsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required EntryKind kind,
    required int amount,
    required String categoryKey,
    required DateTime dueOn,
    this.done = const Value.absent(),
    this.countInProjection = const Value.absent(),
    this.repeatsYearly = const Value.absent(),
  }) : name = Value(name),
       kind = Value(kind),
       amount = Value(amount),
       categoryKey = Value(categoryKey),
       dueOn = Value(dueOn);
  static Insertable<PlannedEvent> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? amount,
    Expression<String>? categoryKey,
    Expression<String>? dueOn,
    Expression<bool>? done,
    Expression<bool>? countInProjection,
    Expression<bool>? repeatsYearly,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (categoryKey != null) 'category_key': categoryKey,
      if (dueOn != null) 'due_on': dueOn,
      if (done != null) 'done': done,
      if (countInProjection != null) 'count_in_projection': countInProjection,
      if (repeatsYearly != null) 'repeats_yearly': repeatsYearly,
    });
  }

  PlannedEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<EntryKind>? kind,
    Value<int>? amount,
    Value<String>? categoryKey,
    Value<DateTime>? dueOn,
    Value<bool>? done,
    Value<bool>? countInProjection,
    Value<bool>? repeatsYearly,
  }) {
    return PlannedEventsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      categoryKey: categoryKey ?? this.categoryKey,
      dueOn: dueOn ?? this.dueOn,
      done: done ?? this.done,
      countInProjection: countInProjection ?? this.countInProjection,
      repeatsYearly: repeatsYearly ?? this.repeatsYearly,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $PlannedEventsTable.$converterkind.toSql(kind.value),
      );
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (categoryKey.present) {
      map['category_key'] = Variable<String>(categoryKey.value);
    }
    if (dueOn.present) {
      map['due_on'] = Variable<String>(
        $PlannedEventsTable.$converterdueOn.toSql(dueOn.value),
      );
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (countInProjection.present) {
      map['count_in_projection'] = Variable<bool>(countInProjection.value);
    }
    if (repeatsYearly.present) {
      map['repeats_yearly'] = Variable<bool>(repeatsYearly.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannedEventsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('dueOn: $dueOn, ')
          ..write('done: $done, ')
          ..write('countInProjection: $countInProjection, ')
          ..write('repeatsYearly: $repeatsYearly')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<int> price = GeneratedColumn<int>(
    'price',
    aliasedName,
    false,
    check: () => ComparableExpr(price).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> targetDate =
      GeneratedColumn<String>(
        'target_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($GoalsTable.$convertertargetDate);
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _listingUrlMeta = const VerificationMeta(
    'listingUrl',
  );
  @override
  late final GeneratedColumn<String> listingUrl = GeneratedColumn<String>(
    'listing_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GoalStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('active'),
      ).withConverter<GoalStatus>($GoalsTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> achievedOn =
      GeneratedColumn<String>(
        'achieved_on',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($GoalsTable.$converterachievedOnn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    price,
    targetDate,
    priority,
    listingUrl,
    status,
    achievedOn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Goal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('listing_url')) {
      context.handle(
        _listingUrlMeta,
        listingUrl.isAcceptableOrUnknown(data['listing_url']!, _listingUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price'],
      )!,
      targetDate: $GoalsTable.$convertertargetDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}target_date'],
        )!,
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      listingUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}listing_url'],
      ),
      status: $GoalsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      achievedOn: $GoalsTable.$converterachievedOnn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}achieved_on'],
        ),
      ),
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $convertertargetDate =
      const DayConverter();
  static JsonTypeConverter2<GoalStatus, String, String> $converterstatus =
      const EnumNameConverter<GoalStatus>(GoalStatus.values);
  static TypeConverter<DateTime, String> $converterachievedOn =
      const DayConverter();
  static TypeConverter<DateTime?, String?> $converterachievedOnn =
      NullAwareTypeConverter.wrap($converterachievedOn);
}

class Goal extends DataClass implements Insertable<Goal> {
  final int id;
  final String name;
  final int price;
  final DateTime targetDate;
  final int priority;
  final String? listingUrl;
  final GoalStatus status;
  final DateTime? achievedOn;
  const Goal({
    required this.id,
    required this.name,
    required this.price,
    required this.targetDate,
    required this.priority,
    this.listingUrl,
    required this.status,
    this.achievedOn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['price'] = Variable<int>(price);
    {
      map['target_date'] = Variable<String>(
        $GoalsTable.$convertertargetDate.toSql(targetDate),
      );
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || listingUrl != null) {
      map['listing_url'] = Variable<String>(listingUrl);
    }
    {
      map['status'] = Variable<String>(
        $GoalsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || achievedOn != null) {
      map['achieved_on'] = Variable<String>(
        $GoalsTable.$converterachievedOnn.toSql(achievedOn),
      );
    }
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      name: Value(name),
      price: Value(price),
      targetDate: Value(targetDate),
      priority: Value(priority),
      listingUrl: listingUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(listingUrl),
      status: Value(status),
      achievedOn: achievedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(achievedOn),
    );
  }

  factory Goal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<int>(json['price']),
      targetDate: serializer.fromJson<DateTime>(json['targetDate']),
      priority: serializer.fromJson<int>(json['priority']),
      listingUrl: serializer.fromJson<String?>(json['listingUrl']),
      status: $GoalsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      achievedOn: serializer.fromJson<DateTime?>(json['achievedOn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<int>(price),
      'targetDate': serializer.toJson<DateTime>(targetDate),
      'priority': serializer.toJson<int>(priority),
      'listingUrl': serializer.toJson<String?>(listingUrl),
      'status': serializer.toJson<String>(
        $GoalsTable.$converterstatus.toJson(status),
      ),
      'achievedOn': serializer.toJson<DateTime?>(achievedOn),
    };
  }

  Goal copyWith({
    int? id,
    String? name,
    int? price,
    DateTime? targetDate,
    int? priority,
    Value<String?> listingUrl = const Value.absent(),
    GoalStatus? status,
    Value<DateTime?> achievedOn = const Value.absent(),
  }) => Goal(
    id: id ?? this.id,
    name: name ?? this.name,
    price: price ?? this.price,
    targetDate: targetDate ?? this.targetDate,
    priority: priority ?? this.priority,
    listingUrl: listingUrl.present ? listingUrl.value : this.listingUrl,
    status: status ?? this.status,
    achievedOn: achievedOn.present ? achievedOn.value : this.achievedOn,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      priority: data.priority.present ? data.priority.value : this.priority,
      listingUrl: data.listingUrl.present
          ? data.listingUrl.value
          : this.listingUrl,
      status: data.status.present ? data.status.value : this.status,
      achievedOn: data.achievedOn.present
          ? data.achievedOn.value
          : this.achievedOn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('targetDate: $targetDate, ')
          ..write('priority: $priority, ')
          ..write('listingUrl: $listingUrl, ')
          ..write('status: $status, ')
          ..write('achievedOn: $achievedOn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    price,
    targetDate,
    priority,
    listingUrl,
    status,
    achievedOn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.name == this.name &&
          other.price == this.price &&
          other.targetDate == this.targetDate &&
          other.priority == this.priority &&
          other.listingUrl == this.listingUrl &&
          other.status == this.status &&
          other.achievedOn == this.achievedOn);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> price;
  final Value<DateTime> targetDate;
  final Value<int> priority;
  final Value<String?> listingUrl;
  final Value<GoalStatus> status;
  final Value<DateTime?> achievedOn;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.priority = const Value.absent(),
    this.listingUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.achievedOn = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int price,
    required DateTime targetDate,
    this.priority = const Value.absent(),
    this.listingUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.achievedOn = const Value.absent(),
  }) : name = Value(name),
       price = Value(price),
       targetDate = Value(targetDate);
  static Insertable<Goal> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? price,
    Expression<String>? targetDate,
    Expression<int>? priority,
    Expression<String>? listingUrl,
    Expression<String>? status,
    Expression<String>? achievedOn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (targetDate != null) 'target_date': targetDate,
      if (priority != null) 'priority': priority,
      if (listingUrl != null) 'listing_url': listingUrl,
      if (status != null) 'status': status,
      if (achievedOn != null) 'achieved_on': achievedOn,
    });
  }

  GoalsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? price,
    Value<DateTime>? targetDate,
    Value<int>? priority,
    Value<String?>? listingUrl,
    Value<GoalStatus>? status,
    Value<DateTime?>? achievedOn,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      targetDate: targetDate ?? this.targetDate,
      priority: priority ?? this.priority,
      listingUrl: listingUrl ?? this.listingUrl,
      status: status ?? this.status,
      achievedOn: achievedOn ?? this.achievedOn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<int>(price.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(
        $GoalsTable.$convertertargetDate.toSql(targetDate.value),
      );
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (listingUrl.present) {
      map['listing_url'] = Variable<String>(listingUrl.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $GoalsTable.$converterstatus.toSql(status.value),
      );
    }
    if (achievedOn.present) {
      map['achieved_on'] = Variable<String>(
        $GoalsTable.$converterachievedOnn.toSql(achievedOn.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('targetDate: $targetDate, ')
          ..write('priority: $priority, ')
          ..write('listingUrl: $listingUrl, ')
          ..write('status: $status, ')
          ..write('achievedOn: $achievedOn')
          ..write(')'))
        .toString();
  }
}

class $FavouritesTable extends Favourites
    with TableInfo<$FavouritesTable, Favourite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavouritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryKeyMeta = const VerificationMeta(
    'categoryKey',
  );
  @override
  late final GeneratedColumn<String> categoryKey = GeneratedColumn<String>(
    'category_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories ("key")',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    check: () => ComparableExpr(amount).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    categoryKey,
    amount,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favourites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favourite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('category_key')) {
      context.handle(
        _categoryKeyMeta,
        categoryKey.isAcceptableOrUnknown(
          data['category_key']!,
          _categoryKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryKeyMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Favourite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favourite(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      categoryKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_key'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $FavouritesTable createAlias(String alias) {
    return $FavouritesTable(attachedDatabase, alias);
  }
}

class Favourite extends DataClass implements Insertable<Favourite> {
  final int id;
  final String label;
  final String categoryKey;
  final int amount;
  final int sortOrder;
  const Favourite({
    required this.id,
    required this.label,
    required this.categoryKey,
    required this.amount,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['label'] = Variable<String>(label);
    map['category_key'] = Variable<String>(categoryKey);
    map['amount'] = Variable<int>(amount);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  FavouritesCompanion toCompanion(bool nullToAbsent) {
    return FavouritesCompanion(
      id: Value(id),
      label: Value(label),
      categoryKey: Value(categoryKey),
      amount: Value(amount),
      sortOrder: Value(sortOrder),
    );
  }

  factory Favourite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favourite(
      id: serializer.fromJson<int>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      categoryKey: serializer.fromJson<String>(json['categoryKey']),
      amount: serializer.fromJson<int>(json['amount']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'label': serializer.toJson<String>(label),
      'categoryKey': serializer.toJson<String>(categoryKey),
      'amount': serializer.toJson<int>(amount),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Favourite copyWith({
    int? id,
    String? label,
    String? categoryKey,
    int? amount,
    int? sortOrder,
  }) => Favourite(
    id: id ?? this.id,
    label: label ?? this.label,
    categoryKey: categoryKey ?? this.categoryKey,
    amount: amount ?? this.amount,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Favourite copyWithCompanion(FavouritesCompanion data) {
    return Favourite(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      categoryKey: data.categoryKey.present
          ? data.categoryKey.value
          : this.categoryKey,
      amount: data.amount.present ? data.amount.value : this.amount,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favourite(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('amount: $amount, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, categoryKey, amount, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favourite &&
          other.id == this.id &&
          other.label == this.label &&
          other.categoryKey == this.categoryKey &&
          other.amount == this.amount &&
          other.sortOrder == this.sortOrder);
}

class FavouritesCompanion extends UpdateCompanion<Favourite> {
  final Value<int> id;
  final Value<String> label;
  final Value<String> categoryKey;
  final Value<int> amount;
  final Value<int> sortOrder;
  const FavouritesCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.categoryKey = const Value.absent(),
    this.amount = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  FavouritesCompanion.insert({
    this.id = const Value.absent(),
    required String label,
    required String categoryKey,
    required int amount,
    this.sortOrder = const Value.absent(),
  }) : label = Value(label),
       categoryKey = Value(categoryKey),
       amount = Value(amount);
  static Insertable<Favourite> custom({
    Expression<int>? id,
    Expression<String>? label,
    Expression<String>? categoryKey,
    Expression<int>? amount,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (categoryKey != null) 'category_key': categoryKey,
      if (amount != null) 'amount': amount,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  FavouritesCompanion copyWith({
    Value<int>? id,
    Value<String>? label,
    Value<String>? categoryKey,
    Value<int>? amount,
    Value<int>? sortOrder,
  }) {
    return FavouritesCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      categoryKey: categoryKey ?? this.categoryKey,
      amount: amount ?? this.amount,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (categoryKey.present) {
      map['category_key'] = Variable<String>(categoryKey.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavouritesCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('amount: $amount, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $RecurringItemsTable recurringItems = $RecurringItemsTable(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $WeeklyRulesTable weeklyRules = $WeeklyRulesTable(this);
  late final $PlannedEventsTable plannedEvents = $PlannedEventsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $FavouritesTable favourites = $FavouritesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    categories,
    recurringItems,
    entries,
    weeklyRules,
    plannedEvents,
    goals,
    favourites,
  ];
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      required int openingBalance,
      required DateTime openingDate,
      required int weeklyCap,
      required int buffer,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<int> openingBalance,
      Value<DateTime> openingDate,
      Value<int> weeklyCap,
      Value<int> buffer,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get openingDate =>
      $composableBuilder(
        column: $table.openingDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get weeklyCap => $composableBuilder(
    column: $table.weeklyCap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get buffer => $composableBuilder(
    column: $table.buffer,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openingDate => $composableBuilder(
    column: $table.openingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weeklyCap => $composableBuilder(
    column: $table.weeklyCap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get buffer => $composableBuilder(
    column: $table.buffer,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, String> get openingDate =>
      $composableBuilder(
        column: $table.openingDate,
        builder: (column) => column,
      );

  GeneratedColumn<int> get weeklyCap =>
      $composableBuilder(column: $table.weeklyCap, builder: (column) => column);

  GeneratedColumn<int> get buffer =>
      $composableBuilder(column: $table.buffer, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> openingBalance = const Value.absent(),
                Value<DateTime> openingDate = const Value.absent(),
                Value<int> weeklyCap = const Value.absent(),
                Value<int> buffer = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                openingBalance: openingBalance,
                openingDate: openingDate,
                weeklyCap: weeklyCap,
                buffer: buffer,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int openingBalance,
                required DateTime openingDate,
                required int weeklyCap,
                required int buffer,
              }) => AppSettingsCompanion.insert(
                id: id,
                openingBalance: openingBalance,
                openingDate: openingDate,
                weeklyCap: weeklyCap,
                buffer: buffer,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String key,
      required String label,
      required EntryKind kind,
      required String tint,
      Value<bool> isFixed,
      Value<int?> monthlyBudget,
      Value<bool> archived,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> key,
      Value<String> label,
      Value<EntryKind> kind,
      Value<String> tint,
      Value<bool> isFixed,
      Value<int?> monthlyBudget,
      Value<bool> archived,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RecurringItemsTable, List<RecurringItem>>
  _recurringItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recurringItems,
    aliasName: 'categories__key__recurring_items__category_key',
  );

  $$RecurringItemsTableProcessedTableManager get recurringItemsRefs {
    final manager = $$RecurringItemsTableTableManager(
      $_db,
      $_db.recurringItems,
    ).filter((f) => f.categoryKey.key.sqlEquals($_itemColumn<String>('key')!));

    final cache = $_typedResult.readTableOrNull(_recurringItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EntriesTable, List<Entry>> _entriesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.entries,
    aliasName: 'categories__key__entries__category_key',
  );

  $$EntriesTableProcessedTableManager get entriesRefs {
    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.categoryKey.key.sqlEquals($_itemColumn<String>('key')!));

    final cache = $_typedResult.readTableOrNull(_entriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlannedEventsTable, List<PlannedEvent>>
  _plannedEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.plannedEvents,
    aliasName: 'categories__key__planned_events__category_key',
  );

  $$PlannedEventsTableProcessedTableManager get plannedEventsRefs {
    final manager = $$PlannedEventsTableTableManager(
      $_db,
      $_db.plannedEvents,
    ).filter((f) => f.categoryKey.key.sqlEquals($_itemColumn<String>('key')!));

    final cache = $_typedResult.readTableOrNull(_plannedEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FavouritesTable, List<Favourite>>
  _favouritesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.favourites,
    aliasName: 'categories__key__favourites__category_key',
  );

  $$FavouritesTableProcessedTableManager get favouritesRefs {
    final manager = $$FavouritesTableTableManager(
      $_db,
      $_db.favourites,
    ).filter((f) => f.categoryKey.key.sqlEquals($_itemColumn<String>('key')!));

    final cache = $_typedResult.readTableOrNull(_favouritesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EntryKind, EntryKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get tint => $composableBuilder(
    column: $table.tint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFixed => $composableBuilder(
    column: $table.isFixed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monthlyBudget => $composableBuilder(
    column: $table.monthlyBudget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> recurringItemsRefs(
    Expression<bool> Function($$RecurringItemsTableFilterComposer f) f,
  ) {
    final $$RecurringItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.recurringItems,
      getReferencedColumn: (t) => t.categoryKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringItemsTableFilterComposer(
            $db: $db,
            $table: $db.recurringItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> entriesRefs(
    Expression<bool> Function($$EntriesTableFilterComposer f) f,
  ) {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.categoryKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> plannedEventsRefs(
    Expression<bool> Function($$PlannedEventsTableFilterComposer f) f,
  ) {
    final $$PlannedEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.plannedEvents,
      getReferencedColumn: (t) => t.categoryKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedEventsTableFilterComposer(
            $db: $db,
            $table: $db.plannedEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> favouritesRefs(
    Expression<bool> Function($$FavouritesTableFilterComposer f) f,
  ) {
    final $$FavouritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.favourites,
      getReferencedColumn: (t) => t.categoryKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavouritesTableFilterComposer(
            $db: $db,
            $table: $db.favourites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tint => $composableBuilder(
    column: $table.tint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFixed => $composableBuilder(
    column: $table.isFixed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monthlyBudget => $composableBuilder(
    column: $table.monthlyBudget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EntryKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get tint =>
      $composableBuilder(column: $table.tint, builder: (column) => column);

  GeneratedColumn<bool> get isFixed =>
      $composableBuilder(column: $table.isFixed, builder: (column) => column);

  GeneratedColumn<int> get monthlyBudget => $composableBuilder(
    column: $table.monthlyBudget,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> recurringItemsRefs<T extends Object>(
    Expression<T> Function($$RecurringItemsTableAnnotationComposer a) f,
  ) {
    final $$RecurringItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.recurringItems,
      getReferencedColumn: (t) => t.categoryKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.recurringItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> entriesRefs<T extends Object>(
    Expression<T> Function($$EntriesTableAnnotationComposer a) f,
  ) {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.categoryKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> plannedEventsRefs<T extends Object>(
    Expression<T> Function($$PlannedEventsTableAnnotationComposer a) f,
  ) {
    final $$PlannedEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.plannedEvents,
      getReferencedColumn: (t) => t.categoryKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> favouritesRefs<T extends Object>(
    Expression<T> Function($$FavouritesTableAnnotationComposer a) f,
  ) {
    final $$FavouritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.favourites,
      getReferencedColumn: (t) => t.categoryKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavouritesTableAnnotationComposer(
            $db: $db,
            $table: $db.favourites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({
            bool recurringItemsRefs,
            bool entriesRefs,
            bool plannedEventsRefs,
            bool favouritesRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<EntryKind> kind = const Value.absent(),
                Value<String> tint = const Value.absent(),
                Value<bool> isFixed = const Value.absent(),
                Value<int?> monthlyBudget = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                key: key,
                label: label,
                kind: kind,
                tint: tint,
                isFixed: isFixed,
                monthlyBudget: monthlyBudget,
                archived: archived,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String label,
                required EntryKind kind,
                required String tint,
                Value<bool> isFixed = const Value.absent(),
                Value<int?> monthlyBudget = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                key: key,
                label: label,
                kind: kind,
                tint: tint,
                isFixed: isFixed,
                monthlyBudget: monthlyBudget,
                archived: archived,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, Category>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                recurringItemsRefs = false,
                entriesRefs = false,
                plannedEventsRefs = false,
                favouritesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (recurringItemsRefs) db.recurringItems,
                    if (entriesRefs) db.entries,
                    if (plannedEventsRefs) db.plannedEvents,
                    if (favouritesRefs) db.favourites,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (recurringItemsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          RecurringItem
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._recurringItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).recurringItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryKey == item.key,
                              ),
                          typedResults: items,
                        ),
                      if (entriesRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Entry
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._entriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).entriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryKey == item.key,
                              ),
                          typedResults: items,
                        ),
                      if (plannedEventsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          PlannedEvent
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._plannedEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).plannedEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryKey == item.key,
                              ),
                          typedResults: items,
                        ),
                      if (favouritesRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Favourite
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._favouritesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).favouritesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryKey == item.key,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({
        bool recurringItemsRefs,
        bool entriesRefs,
        bool plannedEventsRefs,
        bool favouritesRefs,
      })
    >;
typedef $$RecurringItemsTableCreateCompanionBuilder =
    RecurringItemsCompanion Function({
      Value<int> id,
      required String name,
      required EntryKind kind,
      required int amount,
      required String categoryKey,
      required DateTime nextDue,
      Value<bool> active,
      Value<bool> isEstimate,
      Value<int> windowDays,
    });
typedef $$RecurringItemsTableUpdateCompanionBuilder =
    RecurringItemsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<EntryKind> kind,
      Value<int> amount,
      Value<String> categoryKey,
      Value<DateTime> nextDue,
      Value<bool> active,
      Value<bool> isEstimate,
      Value<int> windowDays,
    });

final class $$RecurringItemsTableReferences
    extends BaseReferences<_$AppDatabase, $RecurringItemsTable, RecurringItem> {
  $$RecurringItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CategoriesTable _categoryKeyTable(_$AppDatabase db) => db.categories
      .createAlias('recurring_items__category_key__categories__key');

  $$CategoriesTableProcessedTableManager get categoryKey {
    final $_column = $_itemColumn<String>('category_key')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.key.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EntriesTable, List<Entry>> _entriesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.entries,
    aliasName: 'recurring_items__id__entries__recurring_item_id',
  );

  $$EntriesTableProcessedTableManager get entriesRefs {
    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.recurringItemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_entriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecurringItemsTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringItemsTable> {
  $$RecurringItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EntryKind, EntryKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get nextDue =>
      $composableBuilder(
        column: $table.nextDue,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get windowDays => $composableBuilder(
    column: $table.windowDays,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryKey {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> entriesRefs(
    Expression<bool> Function($$EntriesTableFilterComposer f) f,
  ) {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.recurringItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecurringItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringItemsTable> {
  $$RecurringItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextDue => $composableBuilder(
    column: $table.nextDue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get windowDays => $composableBuilder(
    column: $table.windowDays,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryKey {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringItemsTable> {
  $$RecurringItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EntryKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get nextDue =>
      $composableBuilder(column: $table.nextDue, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get windowDays => $composableBuilder(
    column: $table.windowDays,
    builder: (column) => column,
  );

  $$CategoriesTableAnnotationComposer get categoryKey {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> entriesRefs<T extends Object>(
    Expression<T> Function($$EntriesTableAnnotationComposer a) f,
  ) {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.recurringItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecurringItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringItemsTable,
          RecurringItem,
          $$RecurringItemsTableFilterComposer,
          $$RecurringItemsTableOrderingComposer,
          $$RecurringItemsTableAnnotationComposer,
          $$RecurringItemsTableCreateCompanionBuilder,
          $$RecurringItemsTableUpdateCompanionBuilder,
          (RecurringItem, $$RecurringItemsTableReferences),
          RecurringItem,
          PrefetchHooks Function({bool categoryKey, bool entriesRefs})
        > {
  $$RecurringItemsTableTableManager(
    _$AppDatabase db,
    $RecurringItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<EntryKind> kind = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> categoryKey = const Value.absent(),
                Value<DateTime> nextDue = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<bool> isEstimate = const Value.absent(),
                Value<int> windowDays = const Value.absent(),
              }) => RecurringItemsCompanion(
                id: id,
                name: name,
                kind: kind,
                amount: amount,
                categoryKey: categoryKey,
                nextDue: nextDue,
                active: active,
                isEstimate: isEstimate,
                windowDays: windowDays,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required EntryKind kind,
                required int amount,
                required String categoryKey,
                required DateTime nextDue,
                Value<bool> active = const Value.absent(),
                Value<bool> isEstimate = const Value.absent(),
                Value<int> windowDays = const Value.absent(),
              }) => RecurringItemsCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                amount: amount,
                categoryKey: categoryKey,
                nextDue: nextDue,
                active: active,
                isEstimate: isEstimate,
                windowDays: windowDays,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecurringItemsTable, RecurringItem>(table),
                  $$RecurringItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryKey = false, entriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (entriesRefs) db.entries],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryKey) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryKey,
                                referencedTable: $$RecurringItemsTableReferences
                                    ._categoryKeyTable(db),
                                referencedColumn:
                                    $$RecurringItemsTableReferences
                                        ._categoryKeyTable(db)
                                        .key,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (entriesRefs)
                    await $_getPrefetchedData<
                      RecurringItem,
                      $RecurringItemsTable,
                      Entry
                    >(
                      currentTable: table,
                      referencedTable: $$RecurringItemsTableReferences
                          ._entriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RecurringItemsTableReferences(
                            db,
                            table,
                            p0,
                          ).entriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.recurringItemId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RecurringItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringItemsTable,
      RecurringItem,
      $$RecurringItemsTableFilterComposer,
      $$RecurringItemsTableOrderingComposer,
      $$RecurringItemsTableAnnotationComposer,
      $$RecurringItemsTableCreateCompanionBuilder,
      $$RecurringItemsTableUpdateCompanionBuilder,
      (RecurringItem, $$RecurringItemsTableReferences),
      RecurringItem,
      PrefetchHooks Function({bool categoryKey, bool entriesRefs})
    >;
typedef $$EntriesTableCreateCompanionBuilder =
    EntriesCompanion Function({
      Value<int> id,
      required DateTime occurredOn,
      required EntryKind kind,
      required int amount,
      required String categoryKey,
      Value<String?> label,
      Value<String?> note,
      Value<String?> receipt,
      Value<int?> recurringItemId,
      Value<DateTime> createdAt,
    });
typedef $$EntriesTableUpdateCompanionBuilder =
    EntriesCompanion Function({
      Value<int> id,
      Value<DateTime> occurredOn,
      Value<EntryKind> kind,
      Value<int> amount,
      Value<String> categoryKey,
      Value<String?> label,
      Value<String?> note,
      Value<String?> receipt,
      Value<int?> recurringItemId,
      Value<DateTime> createdAt,
    });

final class $$EntriesTableReferences
    extends BaseReferences<_$AppDatabase, $EntriesTable, Entry> {
  $$EntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryKeyTable(_$AppDatabase db) =>
      db.categories.createAlias('entries__category_key__categories__key');

  $$CategoriesTableProcessedTableManager get categoryKey {
    final $_column = $_itemColumn<String>('category_key')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.key.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RecurringItemsTable _recurringItemIdTable(_$AppDatabase db) => db
      .recurringItems
      .createAlias('entries__recurring_item_id__recurring_items__id');

  $$RecurringItemsTableProcessedTableManager? get recurringItemId {
    final $_column = $_itemColumn<int>('recurring_item_id');
    if ($_column == null) return null;
    final manager = $$RecurringItemsTableTableManager(
      $_db,
      $_db.recurringItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recurringItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get occurredOn =>
      $composableBuilder(
        column: $table.occurredOn,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<EntryKind, EntryKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receipt => $composableBuilder(
    column: $table.receipt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryKey {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurringItemsTableFilterComposer get recurringItemId {
    final $$RecurringItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringItemId,
      referencedTable: $db.recurringItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringItemsTableFilterComposer(
            $db: $db,
            $table: $db.recurringItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurredOn => $composableBuilder(
    column: $table.occurredOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receipt => $composableBuilder(
    column: $table.receipt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryKey {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurringItemsTableOrderingComposer get recurringItemId {
    final $$RecurringItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringItemId,
      referencedTable: $db.recurringItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringItemsTableOrderingComposer(
            $db: $db,
            $table: $db.recurringItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get occurredOn =>
      $composableBuilder(
        column: $table.occurredOn,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<EntryKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get receipt =>
      $composableBuilder(column: $table.receipt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryKey {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurringItemsTableAnnotationComposer get recurringItemId {
    final $$RecurringItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringItemId,
      referencedTable: $db.recurringItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.recurringItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntriesTable,
          Entry,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (Entry, $$EntriesTableReferences),
          Entry,
          PrefetchHooks Function({bool categoryKey, bool recurringItemId})
        > {
  $$EntriesTableTableManager(_$AppDatabase db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> occurredOn = const Value.absent(),
                Value<EntryKind> kind = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> categoryKey = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> receipt = const Value.absent(),
                Value<int?> recurringItemId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                occurredOn: occurredOn,
                kind: kind,
                amount: amount,
                categoryKey: categoryKey,
                label: label,
                note: note,
                receipt: receipt,
                recurringItemId: recurringItemId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime occurredOn,
                required EntryKind kind,
                required int amount,
                required String categoryKey,
                Value<String?> label = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> receipt = const Value.absent(),
                Value<int?> recurringItemId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                occurredOn: occurredOn,
                kind: kind,
                amount: amount,
                categoryKey: categoryKey,
                label: label,
                note: note,
                receipt: receipt,
                recurringItemId: recurringItemId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntriesTable, Entry>(table),
                  $$EntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({categoryKey = false, recurringItemId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryKey) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryKey,
                                    referencedTable: $$EntriesTableReferences
                                        ._categoryKeyTable(db),
                                    referencedColumn: $$EntriesTableReferences
                                        ._categoryKeyTable(db)
                                        .key,
                                  )
                                  as T;
                        }
                        if (recurringItemId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.recurringItemId,
                                    referencedTable: $$EntriesTableReferences
                                        ._recurringItemIdTable(db),
                                    referencedColumn: $$EntriesTableReferences
                                        ._recurringItemIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntriesTable,
      Entry,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (Entry, $$EntriesTableReferences),
      Entry,
      PrefetchHooks Function({bool categoryKey, bool recurringItemId})
    >;
typedef $$WeeklyRulesTableCreateCompanionBuilder =
    WeeklyRulesCompanion Function({
      Value<int> weekday,
      required String label,
      required RhythmDayType dayType,
      Value<int> plannedSpend,
      Value<bool> isFastingDay,
    });
typedef $$WeeklyRulesTableUpdateCompanionBuilder =
    WeeklyRulesCompanion Function({
      Value<int> weekday,
      Value<String> label,
      Value<RhythmDayType> dayType,
      Value<int> plannedSpend,
      Value<bool> isFastingDay,
    });

class $$WeeklyRulesTableFilterComposer
    extends Composer<_$AppDatabase, $WeeklyRulesTable> {
  $$WeeklyRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RhythmDayType, RhythmDayType, String>
  get dayType => $composableBuilder(
    column: $table.dayType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get plannedSpend => $composableBuilder(
    column: $table.plannedSpend,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFastingDay => $composableBuilder(
    column: $table.isFastingDay,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeeklyRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeeklyRulesTable> {
  $$WeeklyRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayType => $composableBuilder(
    column: $table.dayType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedSpend => $composableBuilder(
    column: $table.plannedSpend,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFastingDay => $composableBuilder(
    column: $table.isFastingDay,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeeklyRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeeklyRulesTable> {
  $$WeeklyRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RhythmDayType, String> get dayType =>
      $composableBuilder(column: $table.dayType, builder: (column) => column);

  GeneratedColumn<int> get plannedSpend => $composableBuilder(
    column: $table.plannedSpend,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFastingDay => $composableBuilder(
    column: $table.isFastingDay,
    builder: (column) => column,
  );
}

class $$WeeklyRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeeklyRulesTable,
          WeeklyRule,
          $$WeeklyRulesTableFilterComposer,
          $$WeeklyRulesTableOrderingComposer,
          $$WeeklyRulesTableAnnotationComposer,
          $$WeeklyRulesTableCreateCompanionBuilder,
          $$WeeklyRulesTableUpdateCompanionBuilder,
          (
            WeeklyRule,
            BaseReferences<_$AppDatabase, $WeeklyRulesTable, WeeklyRule>,
          ),
          WeeklyRule,
          PrefetchHooks Function()
        > {
  $$WeeklyRulesTableTableManager(_$AppDatabase db, $WeeklyRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeeklyRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeeklyRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeeklyRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> weekday = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<RhythmDayType> dayType = const Value.absent(),
                Value<int> plannedSpend = const Value.absent(),
                Value<bool> isFastingDay = const Value.absent(),
              }) => WeeklyRulesCompanion(
                weekday: weekday,
                label: label,
                dayType: dayType,
                plannedSpend: plannedSpend,
                isFastingDay: isFastingDay,
              ),
          createCompanionCallback:
              ({
                Value<int> weekday = const Value.absent(),
                required String label,
                required RhythmDayType dayType,
                Value<int> plannedSpend = const Value.absent(),
                Value<bool> isFastingDay = const Value.absent(),
              }) => WeeklyRulesCompanion.insert(
                weekday: weekday,
                label: label,
                dayType: dayType,
                plannedSpend: plannedSpend,
                isFastingDay: isFastingDay,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WeeklyRulesTable, WeeklyRule>(table),
                  BaseReferences<_$AppDatabase, $WeeklyRulesTable, WeeklyRule>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeeklyRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeeklyRulesTable,
      WeeklyRule,
      $$WeeklyRulesTableFilterComposer,
      $$WeeklyRulesTableOrderingComposer,
      $$WeeklyRulesTableAnnotationComposer,
      $$WeeklyRulesTableCreateCompanionBuilder,
      $$WeeklyRulesTableUpdateCompanionBuilder,
      (
        WeeklyRule,
        BaseReferences<_$AppDatabase, $WeeklyRulesTable, WeeklyRule>,
      ),
      WeeklyRule,
      PrefetchHooks Function()
    >;
typedef $$PlannedEventsTableCreateCompanionBuilder =
    PlannedEventsCompanion Function({
      Value<int> id,
      required String name,
      required EntryKind kind,
      required int amount,
      required String categoryKey,
      required DateTime dueOn,
      Value<bool> done,
      Value<bool> countInProjection,
      Value<bool> repeatsYearly,
    });
typedef $$PlannedEventsTableUpdateCompanionBuilder =
    PlannedEventsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<EntryKind> kind,
      Value<int> amount,
      Value<String> categoryKey,
      Value<DateTime> dueOn,
      Value<bool> done,
      Value<bool> countInProjection,
      Value<bool> repeatsYearly,
    });

final class $$PlannedEventsTableReferences
    extends BaseReferences<_$AppDatabase, $PlannedEventsTable, PlannedEvent> {
  $$PlannedEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CategoriesTable _categoryKeyTable(_$AppDatabase db) => db.categories
      .createAlias('planned_events__category_key__categories__key');

  $$CategoriesTableProcessedTableManager get categoryKey {
    final $_column = $_itemColumn<String>('category_key')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.key.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlannedEventsTableFilterComposer
    extends Composer<_$AppDatabase, $PlannedEventsTable> {
  $$PlannedEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EntryKind, EntryKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get dueOn =>
      $composableBuilder(
        column: $table.dueOn,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get countInProjection => $composableBuilder(
    column: $table.countInProjection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get repeatsYearly => $composableBuilder(
    column: $table.repeatsYearly,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryKey {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlannedEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlannedEventsTable> {
  $$PlannedEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueOn => $composableBuilder(
    column: $table.dueOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get countInProjection => $composableBuilder(
    column: $table.countInProjection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get repeatsYearly => $composableBuilder(
    column: $table.repeatsYearly,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryKey {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlannedEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlannedEventsTable> {
  $$PlannedEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EntryKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get dueOn =>
      $composableBuilder(column: $table.dueOn, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<bool> get countInProjection => $composableBuilder(
    column: $table.countInProjection,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get repeatsYearly => $composableBuilder(
    column: $table.repeatsYearly,
    builder: (column) => column,
  );

  $$CategoriesTableAnnotationComposer get categoryKey {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlannedEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlannedEventsTable,
          PlannedEvent,
          $$PlannedEventsTableFilterComposer,
          $$PlannedEventsTableOrderingComposer,
          $$PlannedEventsTableAnnotationComposer,
          $$PlannedEventsTableCreateCompanionBuilder,
          $$PlannedEventsTableUpdateCompanionBuilder,
          (PlannedEvent, $$PlannedEventsTableReferences),
          PlannedEvent,
          PrefetchHooks Function({bool categoryKey})
        > {
  $$PlannedEventsTableTableManager(_$AppDatabase db, $PlannedEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannedEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannedEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannedEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<EntryKind> kind = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> categoryKey = const Value.absent(),
                Value<DateTime> dueOn = const Value.absent(),
                Value<bool> done = const Value.absent(),
                Value<bool> countInProjection = const Value.absent(),
                Value<bool> repeatsYearly = const Value.absent(),
              }) => PlannedEventsCompanion(
                id: id,
                name: name,
                kind: kind,
                amount: amount,
                categoryKey: categoryKey,
                dueOn: dueOn,
                done: done,
                countInProjection: countInProjection,
                repeatsYearly: repeatsYearly,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required EntryKind kind,
                required int amount,
                required String categoryKey,
                required DateTime dueOn,
                Value<bool> done = const Value.absent(),
                Value<bool> countInProjection = const Value.absent(),
                Value<bool> repeatsYearly = const Value.absent(),
              }) => PlannedEventsCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                amount: amount,
                categoryKey: categoryKey,
                dueOn: dueOn,
                done: done,
                countInProjection: countInProjection,
                repeatsYearly: repeatsYearly,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlannedEventsTable, PlannedEvent>(table),
                  $$PlannedEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryKey = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryKey) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryKey,
                                referencedTable: $$PlannedEventsTableReferences
                                    ._categoryKeyTable(db),
                                referencedColumn: $$PlannedEventsTableReferences
                                    ._categoryKeyTable(db)
                                    .key,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlannedEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlannedEventsTable,
      PlannedEvent,
      $$PlannedEventsTableFilterComposer,
      $$PlannedEventsTableOrderingComposer,
      $$PlannedEventsTableAnnotationComposer,
      $$PlannedEventsTableCreateCompanionBuilder,
      $$PlannedEventsTableUpdateCompanionBuilder,
      (PlannedEvent, $$PlannedEventsTableReferences),
      PlannedEvent,
      PrefetchHooks Function({bool categoryKey})
    >;
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      Value<int> id,
      required String name,
      required int price,
      required DateTime targetDate,
      Value<int> priority,
      Value<String?> listingUrl,
      Value<GoalStatus> status,
      Value<DateTime?> achievedOn,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> price,
      Value<DateTime> targetDate,
      Value<int> priority,
      Value<String?> listingUrl,
      Value<GoalStatus> status,
      Value<DateTime?> achievedOn,
    });

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get targetDate =>
      $composableBuilder(
        column: $table.targetDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listingUrl => $composableBuilder(
    column: $table.listingUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GoalStatus, GoalStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get achievedOn =>
      $composableBuilder(
        column: $table.achievedOn,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listingUrl => $composableBuilder(
    column: $table.listingUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get achievedOn => $composableBuilder(
    column: $table.achievedOn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get targetDate =>
      $composableBuilder(
        column: $table.targetDate,
        builder: (column) => column,
      );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get listingUrl => $composableBuilder(
    column: $table.listingUrl,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<GoalStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get achievedOn =>
      $composableBuilder(
        column: $table.achievedOn,
        builder: (column) => column,
      );
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          Goal,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
          Goal,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> price = const Value.absent(),
                Value<DateTime> targetDate = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> listingUrl = const Value.absent(),
                Value<GoalStatus> status = const Value.absent(),
                Value<DateTime?> achievedOn = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                name: name,
                price: price,
                targetDate: targetDate,
                priority: priority,
                listingUrl: listingUrl,
                status: status,
                achievedOn: achievedOn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int price,
                required DateTime targetDate,
                Value<int> priority = const Value.absent(),
                Value<String?> listingUrl = const Value.absent(),
                Value<GoalStatus> status = const Value.absent(),
                Value<DateTime?> achievedOn = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                name: name,
                price: price,
                targetDate: targetDate,
                priority: priority,
                listingUrl: listingUrl,
                status: status,
                achievedOn: achievedOn,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoalsTable, Goal>(table),
                  BaseReferences<_$AppDatabase, $GoalsTable, Goal>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      Goal,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
      Goal,
      PrefetchHooks Function()
    >;
typedef $$FavouritesTableCreateCompanionBuilder =
    FavouritesCompanion Function({
      Value<int> id,
      required String label,
      required String categoryKey,
      required int amount,
      Value<int> sortOrder,
    });
typedef $$FavouritesTableUpdateCompanionBuilder =
    FavouritesCompanion Function({
      Value<int> id,
      Value<String> label,
      Value<String> categoryKey,
      Value<int> amount,
      Value<int> sortOrder,
    });

final class $$FavouritesTableReferences
    extends BaseReferences<_$AppDatabase, $FavouritesTable, Favourite> {
  $$FavouritesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryKeyTable(_$AppDatabase db) =>
      db.categories.createAlias('favourites__category_key__categories__key');

  $$CategoriesTableProcessedTableManager get categoryKey {
    final $_column = $_itemColumn<String>('category_key')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.key.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FavouritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavouritesTable> {
  $$FavouritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryKey {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavouritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavouritesTable> {
  $$FavouritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryKey {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavouritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavouritesTable> {
  $$FavouritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryKey {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavouritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavouritesTable,
          Favourite,
          $$FavouritesTableFilterComposer,
          $$FavouritesTableOrderingComposer,
          $$FavouritesTableAnnotationComposer,
          $$FavouritesTableCreateCompanionBuilder,
          $$FavouritesTableUpdateCompanionBuilder,
          (Favourite, $$FavouritesTableReferences),
          Favourite,
          PrefetchHooks Function({bool categoryKey})
        > {
  $$FavouritesTableTableManager(_$AppDatabase db, $FavouritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavouritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavouritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavouritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> categoryKey = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => FavouritesCompanion(
                id: id,
                label: label,
                categoryKey: categoryKey,
                amount: amount,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String label,
                required String categoryKey,
                required int amount,
                Value<int> sortOrder = const Value.absent(),
              }) => FavouritesCompanion.insert(
                id: id,
                label: label,
                categoryKey: categoryKey,
                amount: amount,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavouritesTable, Favourite>(table),
                  $$FavouritesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryKey = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryKey) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryKey,
                                referencedTable: $$FavouritesTableReferences
                                    ._categoryKeyTable(db),
                                referencedColumn: $$FavouritesTableReferences
                                    ._categoryKeyTable(db)
                                    .key,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FavouritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavouritesTable,
      Favourite,
      $$FavouritesTableFilterComposer,
      $$FavouritesTableOrderingComposer,
      $$FavouritesTableAnnotationComposer,
      $$FavouritesTableCreateCompanionBuilder,
      $$FavouritesTableUpdateCompanionBuilder,
      (Favourite, $$FavouritesTableReferences),
      Favourite,
      PrefetchHooks Function({bool categoryKey})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$RecurringItemsTableTableManager get recurringItems =>
      $$RecurringItemsTableTableManager(_db, _db.recurringItems);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$WeeklyRulesTableTableManager get weeklyRules =>
      $$WeeklyRulesTableTableManager(_db, _db.weeklyRules);
  $$PlannedEventsTableTableManager get plannedEvents =>
      $$PlannedEventsTableTableManager(_db, _db.plannedEvents);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$FavouritesTableTableManager get favourites =>
      $$FavouritesTableTableManager(_db, _db.favourites);
}
