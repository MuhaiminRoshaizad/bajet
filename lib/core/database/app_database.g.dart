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
  static const VerificationMeta _totalCardColorMeta = const VerificationMeta(
    'totalCardColor',
  );
  @override
  late final GeneratedColumn<int> totalCardColor = GeneratedColumn<int>(
    'total_card_color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CardFinish, String>
  totalCardFinish = GeneratedColumn<String>(
    'total_card_finish',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('matte'),
  ).withConverter<CardFinish>($AppSettingsTable.$convertertotalCardFinish);
  static const VerificationMeta _userNameMeta = const VerificationMeta(
    'userName',
  );
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
    'user_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    openingDate,
    weeklyCap,
    buffer,
    totalCardColor,
    totalCardFinish,
    userName,
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
    if (data.containsKey('total_card_color')) {
      context.handle(
        _totalCardColorMeta,
        totalCardColor.isAcceptableOrUnknown(
          data['total_card_color']!,
          _totalCardColorMeta,
        ),
      );
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
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
      totalCardColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_card_color'],
      ),
      totalCardFinish: $AppSettingsTable.$convertertotalCardFinish.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}total_card_finish'],
        )!,
      ),
      userName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_name'],
      ),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converteropeningDate =
      const DayConverter();
  static JsonTypeConverter2<CardFinish, String, String>
  $convertertotalCardFinish = const EnumNameConverter<CardFinish>(
    CardFinish.values,
  );
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final DateTime openingDate;
  final int weeklyCap;

  /// The minimum that must remain after buying a goal.
  final int buffer;

  /// The total card's look; no colour means it follows the app's theme.
  final int? totalCardColor;
  final CardFinish totalCardFinish;

  /// What the coach calls the user; none means it uses no name.
  final String? userName;
  const AppSetting({
    required this.id,
    required this.openingDate,
    required this.weeklyCap,
    required this.buffer,
    this.totalCardColor,
    required this.totalCardFinish,
    this.userName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['opening_date'] = Variable<String>(
        $AppSettingsTable.$converteropeningDate.toSql(openingDate),
      );
    }
    map['weekly_cap'] = Variable<int>(weeklyCap);
    map['buffer'] = Variable<int>(buffer);
    if (!nullToAbsent || totalCardColor != null) {
      map['total_card_color'] = Variable<int>(totalCardColor);
    }
    {
      map['total_card_finish'] = Variable<String>(
        $AppSettingsTable.$convertertotalCardFinish.toSql(totalCardFinish),
      );
    }
    if (!nullToAbsent || userName != null) {
      map['user_name'] = Variable<String>(userName);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      openingDate: Value(openingDate),
      weeklyCap: Value(weeklyCap),
      buffer: Value(buffer),
      totalCardColor: totalCardColor == null && nullToAbsent
          ? const Value.absent()
          : Value(totalCardColor),
      totalCardFinish: Value(totalCardFinish),
      userName: userName == null && nullToAbsent
          ? const Value.absent()
          : Value(userName),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      openingDate: serializer.fromJson<DateTime>(json['openingDate']),
      weeklyCap: serializer.fromJson<int>(json['weeklyCap']),
      buffer: serializer.fromJson<int>(json['buffer']),
      totalCardColor: serializer.fromJson<int?>(json['totalCardColor']),
      totalCardFinish: $AppSettingsTable.$convertertotalCardFinish.fromJson(
        serializer.fromJson<String>(json['totalCardFinish']),
      ),
      userName: serializer.fromJson<String?>(json['userName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'openingDate': serializer.toJson<DateTime>(openingDate),
      'weeklyCap': serializer.toJson<int>(weeklyCap),
      'buffer': serializer.toJson<int>(buffer),
      'totalCardColor': serializer.toJson<int?>(totalCardColor),
      'totalCardFinish': serializer.toJson<String>(
        $AppSettingsTable.$convertertotalCardFinish.toJson(totalCardFinish),
      ),
      'userName': serializer.toJson<String?>(userName),
    };
  }

  AppSetting copyWith({
    int? id,
    DateTime? openingDate,
    int? weeklyCap,
    int? buffer,
    Value<int?> totalCardColor = const Value.absent(),
    CardFinish? totalCardFinish,
    Value<String?> userName = const Value.absent(),
  }) => AppSetting(
    id: id ?? this.id,
    openingDate: openingDate ?? this.openingDate,
    weeklyCap: weeklyCap ?? this.weeklyCap,
    buffer: buffer ?? this.buffer,
    totalCardColor: totalCardColor.present
        ? totalCardColor.value
        : this.totalCardColor,
    totalCardFinish: totalCardFinish ?? this.totalCardFinish,
    userName: userName.present ? userName.value : this.userName,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      openingDate: data.openingDate.present
          ? data.openingDate.value
          : this.openingDate,
      weeklyCap: data.weeklyCap.present ? data.weeklyCap.value : this.weeklyCap,
      buffer: data.buffer.present ? data.buffer.value : this.buffer,
      totalCardColor: data.totalCardColor.present
          ? data.totalCardColor.value
          : this.totalCardColor,
      totalCardFinish: data.totalCardFinish.present
          ? data.totalCardFinish.value
          : this.totalCardFinish,
      userName: data.userName.present ? data.userName.value : this.userName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('openingDate: $openingDate, ')
          ..write('weeklyCap: $weeklyCap, ')
          ..write('buffer: $buffer, ')
          ..write('totalCardColor: $totalCardColor, ')
          ..write('totalCardFinish: $totalCardFinish, ')
          ..write('userName: $userName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    openingDate,
    weeklyCap,
    buffer,
    totalCardColor,
    totalCardFinish,
    userName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.openingDate == this.openingDate &&
          other.weeklyCap == this.weeklyCap &&
          other.buffer == this.buffer &&
          other.totalCardColor == this.totalCardColor &&
          other.totalCardFinish == this.totalCardFinish &&
          other.userName == this.userName);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<DateTime> openingDate;
  final Value<int> weeklyCap;
  final Value<int> buffer;
  final Value<int?> totalCardColor;
  final Value<CardFinish> totalCardFinish;
  final Value<String?> userName;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.openingDate = const Value.absent(),
    this.weeklyCap = const Value.absent(),
    this.buffer = const Value.absent(),
    this.totalCardColor = const Value.absent(),
    this.totalCardFinish = const Value.absent(),
    this.userName = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime openingDate,
    required int weeklyCap,
    required int buffer,
    this.totalCardColor = const Value.absent(),
    this.totalCardFinish = const Value.absent(),
    this.userName = const Value.absent(),
  }) : openingDate = Value(openingDate),
       weeklyCap = Value(weeklyCap),
       buffer = Value(buffer);
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? openingDate,
    Expression<int>? weeklyCap,
    Expression<int>? buffer,
    Expression<int>? totalCardColor,
    Expression<String>? totalCardFinish,
    Expression<String>? userName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (openingDate != null) 'opening_date': openingDate,
      if (weeklyCap != null) 'weekly_cap': weeklyCap,
      if (buffer != null) 'buffer': buffer,
      if (totalCardColor != null) 'total_card_color': totalCardColor,
      if (totalCardFinish != null) 'total_card_finish': totalCardFinish,
      if (userName != null) 'user_name': userName,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? openingDate,
    Value<int>? weeklyCap,
    Value<int>? buffer,
    Value<int?>? totalCardColor,
    Value<CardFinish>? totalCardFinish,
    Value<String?>? userName,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      openingDate: openingDate ?? this.openingDate,
      weeklyCap: weeklyCap ?? this.weeklyCap,
      buffer: buffer ?? this.buffer,
      totalCardColor: totalCardColor ?? this.totalCardColor,
      totalCardFinish: totalCardFinish ?? this.totalCardFinish,
      userName: userName ?? this.userName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
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
    if (totalCardColor.present) {
      map['total_card_color'] = Variable<int>(totalCardColor.value);
    }
    if (totalCardFinish.present) {
      map['total_card_finish'] = Variable<String>(
        $AppSettingsTable.$convertertotalCardFinish.toSql(
          totalCardFinish.value,
        ),
      );
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('openingDate: $openingDate, ')
          ..write('weeklyCap: $weeklyCap, ')
          ..write('buffer: $buffer, ')
          ..write('totalCardColor: $totalCardColor, ')
          ..write('totalCardFinish: $totalCardFinish, ')
          ..write('userName: $userName')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumnWithTypeConverter<AccountKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AccountKind>($AccountsTable.$converterkind);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inkColorMeta = const VerificationMeta(
    'inkColor',
  );
  @override
  late final GeneratedColumn<int> inkColor = GeneratedColumn<int>(
    'ink_color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CardFinish, String> finish =
      GeneratedColumn<String>(
        'finish',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('matte'),
      ).withConverter<CardFinish>($AccountsTable.$converterfinish);
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
    kind,
    name,
    nickname,
    openingBalance,
    color,
    inkColor,
    finish,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
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
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
        _openingBalanceMeta,
        openingBalance.isAcceptableOrUnknown(
          data['opening_balance']!,
          _openingBalanceMeta,
        ),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('ink_color')) {
      context.handle(
        _inkColorMeta,
        inkColor.isAcceptableOrUnknown(data['ink_color']!, _inkColorMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: $AccountsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      ),
      openingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_balance'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      inkColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ink_color'],
      ),
      finish: $AccountsTable.$converterfinish.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}finish'],
        )!,
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountKind, String, String> $converterkind =
      const EnumNameConverter<AccountKind>(AccountKind.values);
  static JsonTypeConverter2<CardFinish, String, String> $converterfinish =
      const EnumNameConverter<CardFinish>(CardFinish.values);
}

class Account extends DataClass implements Insertable<Account> {
  final int id;
  final AccountKind kind;

  /// The provider, such as a bank's name, shown as plain text; "Cash" for cash.
  final String name;
  final String? nickname;
  final int openingBalance;

  /// The card's colour as ARGB, and its text colour when the user picked one
  /// (such as gold on black); otherwise text follows the card's lightness.
  final int color;
  final int? inkColor;
  final CardFinish finish;
  final int sortOrder;
  const Account({
    required this.id,
    required this.kind,
    required this.name,
    this.nickname,
    required this.openingBalance,
    required this.color,
    this.inkColor,
    required this.finish,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['kind'] = Variable<String>($AccountsTable.$converterkind.toSql(kind));
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || nickname != null) {
      map['nickname'] = Variable<String>(nickname);
    }
    map['opening_balance'] = Variable<int>(openingBalance);
    map['color'] = Variable<int>(color);
    if (!nullToAbsent || inkColor != null) {
      map['ink_color'] = Variable<int>(inkColor);
    }
    {
      map['finish'] = Variable<String>(
        $AccountsTable.$converterfinish.toSql(finish),
      );
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      kind: Value(kind),
      name: Value(name),
      nickname: nickname == null && nullToAbsent
          ? const Value.absent()
          : Value(nickname),
      openingBalance: Value(openingBalance),
      color: Value(color),
      inkColor: inkColor == null && nullToAbsent
          ? const Value.absent()
          : Value(inkColor),
      finish: Value(finish),
      sortOrder: Value(sortOrder),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      kind: $AccountsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      name: serializer.fromJson<String>(json['name']),
      nickname: serializer.fromJson<String?>(json['nickname']),
      openingBalance: serializer.fromJson<int>(json['openingBalance']),
      color: serializer.fromJson<int>(json['color']),
      inkColor: serializer.fromJson<int?>(json['inkColor']),
      finish: $AccountsTable.$converterfinish.fromJson(
        serializer.fromJson<String>(json['finish']),
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(
        $AccountsTable.$converterkind.toJson(kind),
      ),
      'name': serializer.toJson<String>(name),
      'nickname': serializer.toJson<String?>(nickname),
      'openingBalance': serializer.toJson<int>(openingBalance),
      'color': serializer.toJson<int>(color),
      'inkColor': serializer.toJson<int?>(inkColor),
      'finish': serializer.toJson<String>(
        $AccountsTable.$converterfinish.toJson(finish),
      ),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Account copyWith({
    int? id,
    AccountKind? kind,
    String? name,
    Value<String?> nickname = const Value.absent(),
    int? openingBalance,
    int? color,
    Value<int?> inkColor = const Value.absent(),
    CardFinish? finish,
    int? sortOrder,
  }) => Account(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    nickname: nickname.present ? nickname.value : this.nickname,
    openingBalance: openingBalance ?? this.openingBalance,
    color: color ?? this.color,
    inkColor: inkColor.present ? inkColor.value : this.inkColor,
    finish: finish ?? this.finish,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      openingBalance: data.openingBalance.present
          ? data.openingBalance.value
          : this.openingBalance,
      color: data.color.present ? data.color.value : this.color,
      inkColor: data.inkColor.present ? data.inkColor.value : this.inkColor,
      finish: data.finish.present ? data.finish.value : this.finish,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('nickname: $nickname, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('color: $color, ')
          ..write('inkColor: $inkColor, ')
          ..write('finish: $finish, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    name,
    nickname,
    openingBalance,
    color,
    inkColor,
    finish,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.nickname == this.nickname &&
          other.openingBalance == this.openingBalance &&
          other.color == this.color &&
          other.inkColor == this.inkColor &&
          other.finish == this.finish &&
          other.sortOrder == this.sortOrder);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<AccountKind> kind;
  final Value<String> name;
  final Value<String?> nickname;
  final Value<int> openingBalance;
  final Value<int> color;
  final Value<int?> inkColor;
  final Value<CardFinish> finish;
  final Value<int> sortOrder;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.nickname = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.color = const Value.absent(),
    this.inkColor = const Value.absent(),
    this.finish = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required AccountKind kind,
    required String name,
    this.nickname = const Value.absent(),
    this.openingBalance = const Value.absent(),
    required int color,
    this.inkColor = const Value.absent(),
    this.finish = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : kind = Value(kind),
       name = Value(name),
       color = Value(color);
  static Insertable<Account> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? nickname,
    Expression<int>? openingBalance,
    Expression<int>? color,
    Expression<int>? inkColor,
    Expression<String>? finish,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (nickname != null) 'nickname': nickname,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (color != null) 'color': color,
      if (inkColor != null) 'ink_color': inkColor,
      if (finish != null) 'finish': finish,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<AccountKind>? kind,
    Value<String>? name,
    Value<String?>? nickname,
    Value<int>? openingBalance,
    Value<int>? color,
    Value<int?>? inkColor,
    Value<CardFinish>? finish,
    Value<int>? sortOrder,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      openingBalance: openingBalance ?? this.openingBalance,
      color: color ?? this.color,
      inkColor: inkColor ?? this.inkColor,
      finish: finish ?? this.finish,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $AccountsTable.$converterkind.toSql(kind.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<int>(openingBalance.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (inkColor.present) {
      map['ink_color'] = Variable<int>(inkColor.value);
    }
    if (finish.present) {
      map['finish'] = Variable<String>(
        $AccountsTable.$converterfinish.toSql(finish.value),
      );
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('nickname: $nickname, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('color: $color, ')
          ..write('inkColor: $inkColor, ')
          ..write('finish: $finish, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $TransfersTable extends Transfers
    with TableInfo<$TransfersTable, Transfer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransfersTable(this.attachedDatabase, [this._alias]);
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
      ).withConverter<DateTime>($TransfersTable.$converteroccurredOn);
  static const VerificationMeta _fromAccountIdMeta = const VerificationMeta(
    'fromAccountId',
  );
  @override
  late final GeneratedColumn<int> fromAccountId = GeneratedColumn<int>(
    'from_account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<int> toAccountId = GeneratedColumn<int>(
    'to_account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
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
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    fromAccountId,
    toAccountId,
    amount,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transfer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('from_account_id')) {
      context.handle(
        _fromAccountIdMeta,
        fromAccountId.isAcceptableOrUnknown(
          data['from_account_id']!,
          _fromAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromAccountIdMeta);
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_toAccountIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  Transfer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transfer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      occurredOn: $TransfersTable.$converteroccurredOn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}occurred_on'],
        )!,
      ),
      fromAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_account_id'],
      )!,
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_account_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TransfersTable createAlias(String alias) {
    return $TransfersTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converteroccurredOn =
      const DayConverter();
}

class Transfer extends DataClass implements Insertable<Transfer> {
  final int id;
  final DateTime occurredOn;
  final int fromAccountId;
  final int toAccountId;
  final int amount;
  final String? note;
  final DateTime createdAt;
  const Transfer({
    required this.id,
    required this.occurredOn,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['occurred_on'] = Variable<String>(
        $TransfersTable.$converteroccurredOn.toSql(occurredOn),
      );
    }
    map['from_account_id'] = Variable<int>(fromAccountId);
    map['to_account_id'] = Variable<int>(toAccountId);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransfersCompanion toCompanion(bool nullToAbsent) {
    return TransfersCompanion(
      id: Value(id),
      occurredOn: Value(occurredOn),
      fromAccountId: Value(fromAccountId),
      toAccountId: Value(toAccountId),
      amount: Value(amount),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory Transfer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transfer(
      id: serializer.fromJson<int>(json['id']),
      occurredOn: serializer.fromJson<DateTime>(json['occurredOn']),
      fromAccountId: serializer.fromJson<int>(json['fromAccountId']),
      toAccountId: serializer.fromJson<int>(json['toAccountId']),
      amount: serializer.fromJson<int>(json['amount']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'occurredOn': serializer.toJson<DateTime>(occurredOn),
      'fromAccountId': serializer.toJson<int>(fromAccountId),
      'toAccountId': serializer.toJson<int>(toAccountId),
      'amount': serializer.toJson<int>(amount),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Transfer copyWith({
    int? id,
    DateTime? occurredOn,
    int? fromAccountId,
    int? toAccountId,
    int? amount,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => Transfer(
    id: id ?? this.id,
    occurredOn: occurredOn ?? this.occurredOn,
    fromAccountId: fromAccountId ?? this.fromAccountId,
    toAccountId: toAccountId ?? this.toAccountId,
    amount: amount ?? this.amount,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  Transfer copyWithCompanion(TransfersCompanion data) {
    return Transfer(
      id: data.id.present ? data.id.value : this.id,
      occurredOn: data.occurredOn.present
          ? data.occurredOn.value
          : this.occurredOn,
      fromAccountId: data.fromAccountId.present
          ? data.fromAccountId.value
          : this.fromAccountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      amount: data.amount.present ? data.amount.value : this.amount,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transfer(')
          ..write('id: $id, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    occurredOn,
    fromAccountId,
    toAccountId,
    amount,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transfer &&
          other.id == this.id &&
          other.occurredOn == this.occurredOn &&
          other.fromAccountId == this.fromAccountId &&
          other.toAccountId == this.toAccountId &&
          other.amount == this.amount &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class TransfersCompanion extends UpdateCompanion<Transfer> {
  final Value<int> id;
  final Value<DateTime> occurredOn;
  final Value<int> fromAccountId;
  final Value<int> toAccountId;
  final Value<int> amount;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const TransfersCompanion({
    this.id = const Value.absent(),
    this.occurredOn = const Value.absent(),
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.amount = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TransfersCompanion.insert({
    this.id = const Value.absent(),
    required DateTime occurredOn,
    required int fromAccountId,
    required int toAccountId,
    required int amount,
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : occurredOn = Value(occurredOn),
       fromAccountId = Value(fromAccountId),
       toAccountId = Value(toAccountId),
       amount = Value(amount);
  static Insertable<Transfer> custom({
    Expression<int>? id,
    Expression<String>? occurredOn,
    Expression<int>? fromAccountId,
    Expression<int>? toAccountId,
    Expression<int>? amount,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (occurredOn != null) 'occurred_on': occurredOn,
      if (fromAccountId != null) 'from_account_id': fromAccountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (amount != null) 'amount': amount,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TransfersCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? occurredOn,
    Value<int>? fromAccountId,
    Value<int>? toAccountId,
    Value<int>? amount,
    Value<String?>? note,
    Value<DateTime>? createdAt,
  }) {
    return TransfersCompanion(
      id: id ?? this.id,
      occurredOn: occurredOn ?? this.occurredOn,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
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
        $TransfersTable.$converteroccurredOn.toSql(occurredOn.value),
      );
    }
    if (fromAccountId.present) {
      map['from_account_id'] = Variable<int>(fromAccountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<int>(toAccountId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransfersCompanion(')
          ..write('id: $id, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
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
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
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
    accountId,
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
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
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
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
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

  /// The account it is paid from or into.
  final int accountId;
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
    required this.accountId,
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
    map['account_id'] = Variable<int>(accountId);
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
      accountId: Value(accountId),
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
      accountId: serializer.fromJson<int>(json['accountId']),
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
      'accountId': serializer.toJson<int>(accountId),
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
    int? accountId,
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
    accountId: accountId ?? this.accountId,
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
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
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
          ..write('windowDays: $windowDays, ')
          ..write('accountId: $accountId')
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
    accountId,
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
          other.windowDays == this.windowDays &&
          other.accountId == this.accountId);
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
  final Value<int> accountId;
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
    this.accountId = const Value.absent(),
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
    required int accountId,
  }) : name = Value(name),
       kind = Value(kind),
       amount = Value(amount),
       categoryKey = Value(categoryKey),
       nextDue = Value(nextDue),
       accountId = Value(accountId);
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
    Expression<int>? accountId,
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
      if (accountId != null) 'account_id': accountId,
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
    Value<int>? accountId,
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
      accountId: accountId ?? this.accountId,
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
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
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
          ..write('windowDays: $windowDays, ')
          ..write('accountId: $accountId')
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
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
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
  static const VerificationMeta _plannedEventIdMeta = const VerificationMeta(
    'plannedEventId',
  );
  @override
  late final GeneratedColumn<int> plannedEventId = GeneratedColumn<int>(
    'planned_event_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES planned_events (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String>
  plannedEventOn = GeneratedColumn<String>(
    'planned_event_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<DateTime?>($EntriesTable.$converterplannedEventOnn);
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
    accountId,
    label,
    note,
    receipt,
    recurringItemId,
    plannedEventId,
    plannedEventOn,
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
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
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
    if (data.containsKey('planned_event_id')) {
      context.handle(
        _plannedEventIdMeta,
        plannedEventId.isAcceptableOrUnknown(
          data['planned_event_id']!,
          _plannedEventIdMeta,
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
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
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
      plannedEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_event_id'],
      ),
      plannedEventOn: $EntriesTable.$converterplannedEventOnn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}planned_event_on'],
        ),
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
  static TypeConverter<DateTime, String> $converterplannedEventOn =
      const DayConverter();
  static TypeConverter<DateTime?, String?> $converterplannedEventOnn =
      NullAwareTypeConverter.wrap($converterplannedEventOn);
}

class Entry extends DataClass implements Insertable<Entry> {
  final int id;
  final DateTime occurredOn;
  final EntryKind kind;
  final int amount;
  final String categoryKey;

  /// Where the money came from or went to.
  final int accountId;

  /// A short name such as "Coffee", used for per-item stats like average cost.
  final String? label;
  final String? note;

  /// File name of an attached receipt image in the app's receipts folder.
  final String? receipt;

  /// Set when the entry confirms a recurring item.
  final int? recurringItemId;

  /// Set when the entry was spent on a planned event, such as a birthday,
  /// with the date of the occurrence it was for, so a yearly event's
  /// spending stays with its own year.
  final int? plannedEventId;
  final DateTime? plannedEventOn;
  final DateTime createdAt;
  const Entry({
    required this.id,
    required this.occurredOn,
    required this.kind,
    required this.amount,
    required this.categoryKey,
    required this.accountId,
    this.label,
    this.note,
    this.receipt,
    this.recurringItemId,
    this.plannedEventId,
    this.plannedEventOn,
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
    map['account_id'] = Variable<int>(accountId);
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
    if (!nullToAbsent || plannedEventId != null) {
      map['planned_event_id'] = Variable<int>(plannedEventId);
    }
    if (!nullToAbsent || plannedEventOn != null) {
      map['planned_event_on'] = Variable<String>(
        $EntriesTable.$converterplannedEventOnn.toSql(plannedEventOn),
      );
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
      accountId: Value(accountId),
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
      plannedEventId: plannedEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedEventId),
      plannedEventOn: plannedEventOn == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedEventOn),
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
      accountId: serializer.fromJson<int>(json['accountId']),
      label: serializer.fromJson<String?>(json['label']),
      note: serializer.fromJson<String?>(json['note']),
      receipt: serializer.fromJson<String?>(json['receipt']),
      recurringItemId: serializer.fromJson<int?>(json['recurringItemId']),
      plannedEventId: serializer.fromJson<int?>(json['plannedEventId']),
      plannedEventOn: serializer.fromJson<DateTime?>(json['plannedEventOn']),
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
      'accountId': serializer.toJson<int>(accountId),
      'label': serializer.toJson<String?>(label),
      'note': serializer.toJson<String?>(note),
      'receipt': serializer.toJson<String?>(receipt),
      'recurringItemId': serializer.toJson<int?>(recurringItemId),
      'plannedEventId': serializer.toJson<int?>(plannedEventId),
      'plannedEventOn': serializer.toJson<DateTime?>(plannedEventOn),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Entry copyWith({
    int? id,
    DateTime? occurredOn,
    EntryKind? kind,
    int? amount,
    String? categoryKey,
    int? accountId,
    Value<String?> label = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> receipt = const Value.absent(),
    Value<int?> recurringItemId = const Value.absent(),
    Value<int?> plannedEventId = const Value.absent(),
    Value<DateTime?> plannedEventOn = const Value.absent(),
    DateTime? createdAt,
  }) => Entry(
    id: id ?? this.id,
    occurredOn: occurredOn ?? this.occurredOn,
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    categoryKey: categoryKey ?? this.categoryKey,
    accountId: accountId ?? this.accountId,
    label: label.present ? label.value : this.label,
    note: note.present ? note.value : this.note,
    receipt: receipt.present ? receipt.value : this.receipt,
    recurringItemId: recurringItemId.present
        ? recurringItemId.value
        : this.recurringItemId,
    plannedEventId: plannedEventId.present
        ? plannedEventId.value
        : this.plannedEventId,
    plannedEventOn: plannedEventOn.present
        ? plannedEventOn.value
        : this.plannedEventOn,
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
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      label: data.label.present ? data.label.value : this.label,
      note: data.note.present ? data.note.value : this.note,
      receipt: data.receipt.present ? data.receipt.value : this.receipt,
      recurringItemId: data.recurringItemId.present
          ? data.recurringItemId.value
          : this.recurringItemId,
      plannedEventId: data.plannedEventId.present
          ? data.plannedEventId.value
          : this.plannedEventId,
      plannedEventOn: data.plannedEventOn.present
          ? data.plannedEventOn.value
          : this.plannedEventOn,
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
          ..write('accountId: $accountId, ')
          ..write('label: $label, ')
          ..write('note: $note, ')
          ..write('receipt: $receipt, ')
          ..write('recurringItemId: $recurringItemId, ')
          ..write('plannedEventId: $plannedEventId, ')
          ..write('plannedEventOn: $plannedEventOn, ')
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
    accountId,
    label,
    note,
    receipt,
    recurringItemId,
    plannedEventId,
    plannedEventOn,
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
          other.accountId == this.accountId &&
          other.label == this.label &&
          other.note == this.note &&
          other.receipt == this.receipt &&
          other.recurringItemId == this.recurringItemId &&
          other.plannedEventId == this.plannedEventId &&
          other.plannedEventOn == this.plannedEventOn &&
          other.createdAt == this.createdAt);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<int> id;
  final Value<DateTime> occurredOn;
  final Value<EntryKind> kind;
  final Value<int> amount;
  final Value<String> categoryKey;
  final Value<int> accountId;
  final Value<String?> label;
  final Value<String?> note;
  final Value<String?> receipt;
  final Value<int?> recurringItemId;
  final Value<int?> plannedEventId;
  final Value<DateTime?> plannedEventOn;
  final Value<DateTime> createdAt;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.occurredOn = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.categoryKey = const Value.absent(),
    this.accountId = const Value.absent(),
    this.label = const Value.absent(),
    this.note = const Value.absent(),
    this.receipt = const Value.absent(),
    this.recurringItemId = const Value.absent(),
    this.plannedEventId = const Value.absent(),
    this.plannedEventOn = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime occurredOn,
    required EntryKind kind,
    required int amount,
    required String categoryKey,
    required int accountId,
    this.label = const Value.absent(),
    this.note = const Value.absent(),
    this.receipt = const Value.absent(),
    this.recurringItemId = const Value.absent(),
    this.plannedEventId = const Value.absent(),
    this.plannedEventOn = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : occurredOn = Value(occurredOn),
       kind = Value(kind),
       amount = Value(amount),
       categoryKey = Value(categoryKey),
       accountId = Value(accountId);
  static Insertable<Entry> custom({
    Expression<int>? id,
    Expression<String>? occurredOn,
    Expression<String>? kind,
    Expression<int>? amount,
    Expression<String>? categoryKey,
    Expression<int>? accountId,
    Expression<String>? label,
    Expression<String>? note,
    Expression<String>? receipt,
    Expression<int>? recurringItemId,
    Expression<int>? plannedEventId,
    Expression<String>? plannedEventOn,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (occurredOn != null) 'occurred_on': occurredOn,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (categoryKey != null) 'category_key': categoryKey,
      if (accountId != null) 'account_id': accountId,
      if (label != null) 'label': label,
      if (note != null) 'note': note,
      if (receipt != null) 'receipt': receipt,
      if (recurringItemId != null) 'recurring_item_id': recurringItemId,
      if (plannedEventId != null) 'planned_event_id': plannedEventId,
      if (plannedEventOn != null) 'planned_event_on': plannedEventOn,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? occurredOn,
    Value<EntryKind>? kind,
    Value<int>? amount,
    Value<String>? categoryKey,
    Value<int>? accountId,
    Value<String?>? label,
    Value<String?>? note,
    Value<String?>? receipt,
    Value<int?>? recurringItemId,
    Value<int?>? plannedEventId,
    Value<DateTime?>? plannedEventOn,
    Value<DateTime>? createdAt,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      occurredOn: occurredOn ?? this.occurredOn,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      categoryKey: categoryKey ?? this.categoryKey,
      accountId: accountId ?? this.accountId,
      label: label ?? this.label,
      note: note ?? this.note,
      receipt: receipt ?? this.receipt,
      recurringItemId: recurringItemId ?? this.recurringItemId,
      plannedEventId: plannedEventId ?? this.plannedEventId,
      plannedEventOn: plannedEventOn ?? this.plannedEventOn,
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
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
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
    if (plannedEventId.present) {
      map['planned_event_id'] = Variable<int>(plannedEventId.value);
    }
    if (plannedEventOn.present) {
      map['planned_event_on'] = Variable<String>(
        $EntriesTable.$converterplannedEventOnn.toSql(plannedEventOn.value),
      );
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
          ..write('accountId: $accountId, ')
          ..write('label: $label, ')
          ..write('note: $note, ')
          ..write('receipt: $receipt, ')
          ..write('recurringItemId: $recurringItemId, ')
          ..write('plannedEventId: $plannedEventId, ')
          ..write('plannedEventOn: $plannedEventOn, ')
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
  late final GeneratedColumnWithTypeConverter<ListingState?, String>
  listingState = GeneratedColumn<String>(
    'listing_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<ListingState?>($GoalsTable.$converterlistingStaten);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String>
  listingCheckedOn = GeneratedColumn<String>(
    'listing_checked_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<DateTime?>($GoalsTable.$converterlistingCheckedOnn);
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
    listingState,
    listingCheckedOn,
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
      listingState: $GoalsTable.$converterlistingStaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}listing_state'],
        ),
      ),
      listingCheckedOn: $GoalsTable.$converterlistingCheckedOnn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}listing_checked_on'],
        ),
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
  static JsonTypeConverter2<ListingState, String, String>
  $converterlistingState = const EnumNameConverter<ListingState>(
    ListingState.values,
  );
  static JsonTypeConverter2<ListingState?, String?, String?>
  $converterlistingStaten = JsonTypeConverter2.asNullable(
    $converterlistingState,
  );
  static TypeConverter<DateTime, String> $converterlistingCheckedOn =
      const DayConverter();
  static TypeConverter<DateTime?, String?> $converterlistingCheckedOnn =
      NullAwareTypeConverter.wrap($converterlistingCheckedOn);
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

  /// Whether the listing was still up when last looked at, and on which day;
  /// both null until the user has looked.
  final ListingState? listingState;
  final DateTime? listingCheckedOn;
  final GoalStatus status;
  final DateTime? achievedOn;
  const Goal({
    required this.id,
    required this.name,
    required this.price,
    required this.targetDate,
    required this.priority,
    this.listingUrl,
    this.listingState,
    this.listingCheckedOn,
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
    if (!nullToAbsent || listingState != null) {
      map['listing_state'] = Variable<String>(
        $GoalsTable.$converterlistingStaten.toSql(listingState),
      );
    }
    if (!nullToAbsent || listingCheckedOn != null) {
      map['listing_checked_on'] = Variable<String>(
        $GoalsTable.$converterlistingCheckedOnn.toSql(listingCheckedOn),
      );
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
      listingState: listingState == null && nullToAbsent
          ? const Value.absent()
          : Value(listingState),
      listingCheckedOn: listingCheckedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(listingCheckedOn),
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
      listingState: $GoalsTable.$converterlistingStaten.fromJson(
        serializer.fromJson<String?>(json['listingState']),
      ),
      listingCheckedOn: serializer.fromJson<DateTime?>(
        json['listingCheckedOn'],
      ),
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
      'listingState': serializer.toJson<String?>(
        $GoalsTable.$converterlistingStaten.toJson(listingState),
      ),
      'listingCheckedOn': serializer.toJson<DateTime?>(listingCheckedOn),
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
    Value<ListingState?> listingState = const Value.absent(),
    Value<DateTime?> listingCheckedOn = const Value.absent(),
    GoalStatus? status,
    Value<DateTime?> achievedOn = const Value.absent(),
  }) => Goal(
    id: id ?? this.id,
    name: name ?? this.name,
    price: price ?? this.price,
    targetDate: targetDate ?? this.targetDate,
    priority: priority ?? this.priority,
    listingUrl: listingUrl.present ? listingUrl.value : this.listingUrl,
    listingState: listingState.present ? listingState.value : this.listingState,
    listingCheckedOn: listingCheckedOn.present
        ? listingCheckedOn.value
        : this.listingCheckedOn,
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
      listingState: data.listingState.present
          ? data.listingState.value
          : this.listingState,
      listingCheckedOn: data.listingCheckedOn.present
          ? data.listingCheckedOn.value
          : this.listingCheckedOn,
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
          ..write('listingState: $listingState, ')
          ..write('listingCheckedOn: $listingCheckedOn, ')
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
    listingState,
    listingCheckedOn,
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
          other.listingState == this.listingState &&
          other.listingCheckedOn == this.listingCheckedOn &&
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
  final Value<ListingState?> listingState;
  final Value<DateTime?> listingCheckedOn;
  final Value<GoalStatus> status;
  final Value<DateTime?> achievedOn;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.priority = const Value.absent(),
    this.listingUrl = const Value.absent(),
    this.listingState = const Value.absent(),
    this.listingCheckedOn = const Value.absent(),
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
    this.listingState = const Value.absent(),
    this.listingCheckedOn = const Value.absent(),
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
    Expression<String>? listingState,
    Expression<String>? listingCheckedOn,
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
      if (listingState != null) 'listing_state': listingState,
      if (listingCheckedOn != null) 'listing_checked_on': listingCheckedOn,
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
    Value<ListingState?>? listingState,
    Value<DateTime?>? listingCheckedOn,
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
      listingState: listingState ?? this.listingState,
      listingCheckedOn: listingCheckedOn ?? this.listingCheckedOn,
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
    if (listingState.present) {
      map['listing_state'] = Variable<String>(
        $GoalsTable.$converterlistingStaten.toSql(listingState.value),
      );
    }
    if (listingCheckedOn.present) {
      map['listing_checked_on'] = Variable<String>(
        $GoalsTable.$converterlistingCheckedOnn.toSql(listingCheckedOn.value),
      );
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
          ..write('listingState: $listingState, ')
          ..write('listingCheckedOn: $listingCheckedOn, ')
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

class $CoachSettingsTable extends CoachSettings
    with TableInfo<$CoachSettingsTable, CoachSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoachSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _faceMeta = const VerificationMeta('face');
  @override
  late final GeneratedColumn<String> face = GeneratedColumn<String>(
    'face',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('bajety'),
  );
  static const VerificationMeta _personalityMeta = const VerificationMeta(
    'personality',
  );
  @override
  late final GeneratedColumn<String> personality = GeneratedColumn<String>(
    'personality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('friendly'),
  );
  static const VerificationMeta _rememberMeta = const VerificationMeta(
    'remember',
  );
  @override
  late final GeneratedColumn<bool> remember = GeneratedColumn<bool>(
    'remember',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("remember" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, face, personality, remember];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coach_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoachSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('face')) {
      context.handle(
        _faceMeta,
        face.isAcceptableOrUnknown(data['face']!, _faceMeta),
      );
    }
    if (data.containsKey('personality')) {
      context.handle(
        _personalityMeta,
        personality.isAcceptableOrUnknown(
          data['personality']!,
          _personalityMeta,
        ),
      );
    }
    if (data.containsKey('remember')) {
      context.handle(
        _rememberMeta,
        remember.isAcceptableOrUnknown(data['remember']!, _rememberMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CoachSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoachSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      face: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}face'],
      )!,
      personality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}personality'],
      )!,
      remember: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remember'],
      )!,
    );
  }

  @override
  $CoachSettingsTable createAlias(String alias) {
    return $CoachSettingsTable(attachedDatabase, alias);
  }
}

class CoachSetting extends DataClass implements Insertable<CoachSetting> {
  final int id;

  /// Which avatar draws the coach, by its key, such as "bajety".
  final String face;

  /// Which personality it talks in, by its key, such as "friendly".
  final String personality;
  final bool remember;
  const CoachSetting({
    required this.id,
    required this.face,
    required this.personality,
    required this.remember,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['face'] = Variable<String>(face);
    map['personality'] = Variable<String>(personality);
    map['remember'] = Variable<bool>(remember);
    return map;
  }

  CoachSettingsCompanion toCompanion(bool nullToAbsent) {
    return CoachSettingsCompanion(
      id: Value(id),
      face: Value(face),
      personality: Value(personality),
      remember: Value(remember),
    );
  }

  factory CoachSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoachSetting(
      id: serializer.fromJson<int>(json['id']),
      face: serializer.fromJson<String>(json['face']),
      personality: serializer.fromJson<String>(json['personality']),
      remember: serializer.fromJson<bool>(json['remember']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'face': serializer.toJson<String>(face),
      'personality': serializer.toJson<String>(personality),
      'remember': serializer.toJson<bool>(remember),
    };
  }

  CoachSetting copyWith({
    int? id,
    String? face,
    String? personality,
    bool? remember,
  }) => CoachSetting(
    id: id ?? this.id,
    face: face ?? this.face,
    personality: personality ?? this.personality,
    remember: remember ?? this.remember,
  );
  CoachSetting copyWithCompanion(CoachSettingsCompanion data) {
    return CoachSetting(
      id: data.id.present ? data.id.value : this.id,
      face: data.face.present ? data.face.value : this.face,
      personality: data.personality.present
          ? data.personality.value
          : this.personality,
      remember: data.remember.present ? data.remember.value : this.remember,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoachSetting(')
          ..write('id: $id, ')
          ..write('face: $face, ')
          ..write('personality: $personality, ')
          ..write('remember: $remember')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, face, personality, remember);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoachSetting &&
          other.id == this.id &&
          other.face == this.face &&
          other.personality == this.personality &&
          other.remember == this.remember);
}

class CoachSettingsCompanion extends UpdateCompanion<CoachSetting> {
  final Value<int> id;
  final Value<String> face;
  final Value<String> personality;
  final Value<bool> remember;
  const CoachSettingsCompanion({
    this.id = const Value.absent(),
    this.face = const Value.absent(),
    this.personality = const Value.absent(),
    this.remember = const Value.absent(),
  });
  CoachSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.face = const Value.absent(),
    this.personality = const Value.absent(),
    this.remember = const Value.absent(),
  });
  static Insertable<CoachSetting> custom({
    Expression<int>? id,
    Expression<String>? face,
    Expression<String>? personality,
    Expression<bool>? remember,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (face != null) 'face': face,
      if (personality != null) 'personality': personality,
      if (remember != null) 'remember': remember,
    });
  }

  CoachSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? face,
    Value<String>? personality,
    Value<bool>? remember,
  }) {
    return CoachSettingsCompanion(
      id: id ?? this.id,
      face: face ?? this.face,
      personality: personality ?? this.personality,
      remember: remember ?? this.remember,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (face.present) {
      map['face'] = Variable<String>(face.value);
    }
    if (personality.present) {
      map['personality'] = Variable<String>(personality.value);
    }
    if (remember.present) {
      map['remember'] = Variable<bool>(remember.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoachSettingsCompanion(')
          ..write('id: $id, ')
          ..write('face: $face, ')
          ..write('personality: $personality, ')
          ..write('remember: $remember')
          ..write(')'))
        .toString();
  }
}

class $CoachThreadsTable extends CoachThreads
    with TableInfo<$CoachThreadsTable, CoachThread> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoachThreadsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _faceMeta = const VerificationMeta('face');
  @override
  late final GeneratedColumn<String> face = GeneratedColumn<String>(
    'face',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personalityMeta = const VerificationMeta(
    'personality',
  );
  @override
  late final GeneratedColumn<String> personality = GeneratedColumn<String>(
    'personality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    pinned,
    face,
    personality,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coach_threads';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoachThread> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('face')) {
      context.handle(
        _faceMeta,
        face.isAcceptableOrUnknown(data['face']!, _faceMeta),
      );
    } else if (isInserting) {
      context.missing(_faceMeta);
    }
    if (data.containsKey('personality')) {
      context.handle(
        _personalityMeta,
        personality.isAcceptableOrUnknown(
          data['personality']!,
          _personalityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_personalityMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CoachThread map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoachThread(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      face: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}face'],
      )!,
      personality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}personality'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CoachThreadsTable createAlias(String alias) {
    return $CoachThreadsTable(attachedDatabase, alias);
  }
}

class CoachThread extends DataClass implements Insertable<CoachThread> {
  final int id;

  /// Named after its first question unless the user renames it.
  final String title;
  final bool pinned;

  /// The avatar and the personality this chat uses, by their keys.
  final String face;
  final String personality;

  /// When it was started, in milliseconds since the epoch.
  final int createdAt;
  const CoachThread({
    required this.id,
    required this.title,
    required this.pinned,
    required this.face,
    required this.personality,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['pinned'] = Variable<bool>(pinned);
    map['face'] = Variable<String>(face);
    map['personality'] = Variable<String>(personality);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CoachThreadsCompanion toCompanion(bool nullToAbsent) {
    return CoachThreadsCompanion(
      id: Value(id),
      title: Value(title),
      pinned: Value(pinned),
      face: Value(face),
      personality: Value(personality),
      createdAt: Value(createdAt),
    );
  }

  factory CoachThread.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoachThread(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      face: serializer.fromJson<String>(json['face']),
      personality: serializer.fromJson<String>(json['personality']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'pinned': serializer.toJson<bool>(pinned),
      'face': serializer.toJson<String>(face),
      'personality': serializer.toJson<String>(personality),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CoachThread copyWith({
    int? id,
    String? title,
    bool? pinned,
    String? face,
    String? personality,
    int? createdAt,
  }) => CoachThread(
    id: id ?? this.id,
    title: title ?? this.title,
    pinned: pinned ?? this.pinned,
    face: face ?? this.face,
    personality: personality ?? this.personality,
    createdAt: createdAt ?? this.createdAt,
  );
  CoachThread copyWithCompanion(CoachThreadsCompanion data) {
    return CoachThread(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      face: data.face.present ? data.face.value : this.face,
      personality: data.personality.present
          ? data.personality.value
          : this.personality,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoachThread(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('pinned: $pinned, ')
          ..write('face: $face, ')
          ..write('personality: $personality, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, pinned, face, personality, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoachThread &&
          other.id == this.id &&
          other.title == this.title &&
          other.pinned == this.pinned &&
          other.face == this.face &&
          other.personality == this.personality &&
          other.createdAt == this.createdAt);
}

class CoachThreadsCompanion extends UpdateCompanion<CoachThread> {
  final Value<int> id;
  final Value<String> title;
  final Value<bool> pinned;
  final Value<String> face;
  final Value<String> personality;
  final Value<int> createdAt;
  const CoachThreadsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.pinned = const Value.absent(),
    this.face = const Value.absent(),
    this.personality = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CoachThreadsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.pinned = const Value.absent(),
    required String face,
    required String personality,
    required int createdAt,
  }) : title = Value(title),
       face = Value(face),
       personality = Value(personality),
       createdAt = Value(createdAt);
  static Insertable<CoachThread> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<bool>? pinned,
    Expression<String>? face,
    Expression<String>? personality,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (pinned != null) 'pinned': pinned,
      if (face != null) 'face': face,
      if (personality != null) 'personality': personality,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CoachThreadsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<bool>? pinned,
    Value<String>? face,
    Value<String>? personality,
    Value<int>? createdAt,
  }) {
    return CoachThreadsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      pinned: pinned ?? this.pinned,
      face: face ?? this.face,
      personality: personality ?? this.personality,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (face.present) {
      map['face'] = Variable<String>(face.value);
    }
    if (personality.present) {
      map['personality'] = Variable<String>(personality.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoachThreadsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('pinned: $pinned, ')
          ..write('face: $face, ')
          ..write('personality: $personality, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CoachMessagesTable extends CoachMessages
    with TableInfo<$CoachMessagesTable, CoachMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoachMessagesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  @override
  late final GeneratedColumn<int> threadId = GeneratedColumn<int>(
    'thread_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES coach_threads (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<int> sentAt = GeneratedColumn<int>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromUserMeta = const VerificationMeta(
    'fromUser',
  );
  @override
  late final GeneratedColumn<bool> fromUser = GeneratedColumn<bool>(
    'from_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("from_user" IN (0, 1))',
    ),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _faceMeta = const VerificationMeta('face');
  @override
  late final GeneratedColumn<String> face = GeneratedColumn<String>(
    'face',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lookedMeta = const VerificationMeta('looked');
  @override
  late final GeneratedColumn<String> looked = GeneratedColumn<String>(
    'looked',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _cardsMeta = const VerificationMeta('cards');
  @override
  late final GeneratedColumn<String> cards = GeneratedColumn<String>(
    'cards',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<bool> note = GeneratedColumn<bool>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("note" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    threadId,
    sentAt,
    fromUser,
    body,
    face,
    looked,
    cards,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coach_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoachMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_threadIdMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('from_user')) {
      context.handle(
        _fromUserMeta,
        fromUser.isAcceptableOrUnknown(data['from_user']!, _fromUserMeta),
      );
    } else if (isInserting) {
      context.missing(_fromUserMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('face')) {
      context.handle(
        _faceMeta,
        face.isAcceptableOrUnknown(data['face']!, _faceMeta),
      );
    }
    if (data.containsKey('looked')) {
      context.handle(
        _lookedMeta,
        looked.isAcceptableOrUnknown(data['looked']!, _lookedMeta),
      );
    }
    if (data.containsKey('cards')) {
      context.handle(
        _cardsMeta,
        cards.isAcceptableOrUnknown(data['cards']!, _cardsMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CoachMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoachMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}thread_id'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sent_at'],
      )!,
      fromUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}from_user'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      face: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}face'],
      ),
      looked: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}looked'],
      )!,
      cards: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cards'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $CoachMessagesTable createAlias(String alias) {
    return $CoachMessagesTable(attachedDatabase, alias);
  }
}

class CoachMessage extends DataClass implements Insertable<CoachMessage> {
  final int id;
  final int threadId;

  /// When it was sent, in milliseconds since the epoch, for the day labels
  /// and for spotting a question sent twice in a row.
  final int sentAt;
  final bool fromUser;
  final String body;

  /// The avatar that said it, so a reply keeps its face after a switch.
  final String? face;

  /// What the coach looked up for a reply, one label a line.
  final String looked;

  /// The reply's suggestion cards and what became of them, as JSON.
  final String cards;

  /// A line in the chat said by nobody, such as a change of personality.
  final bool note;
  const CoachMessage({
    required this.id,
    required this.threadId,
    required this.sentAt,
    required this.fromUser,
    required this.body,
    this.face,
    required this.looked,
    required this.cards,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['thread_id'] = Variable<int>(threadId);
    map['sent_at'] = Variable<int>(sentAt);
    map['from_user'] = Variable<bool>(fromUser);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || face != null) {
      map['face'] = Variable<String>(face);
    }
    map['looked'] = Variable<String>(looked);
    map['cards'] = Variable<String>(cards);
    map['note'] = Variable<bool>(note);
    return map;
  }

  CoachMessagesCompanion toCompanion(bool nullToAbsent) {
    return CoachMessagesCompanion(
      id: Value(id),
      threadId: Value(threadId),
      sentAt: Value(sentAt),
      fromUser: Value(fromUser),
      body: Value(body),
      face: face == null && nullToAbsent ? const Value.absent() : Value(face),
      looked: Value(looked),
      cards: Value(cards),
      note: Value(note),
    );
  }

  factory CoachMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoachMessage(
      id: serializer.fromJson<int>(json['id']),
      threadId: serializer.fromJson<int>(json['threadId']),
      sentAt: serializer.fromJson<int>(json['sentAt']),
      fromUser: serializer.fromJson<bool>(json['fromUser']),
      body: serializer.fromJson<String>(json['body']),
      face: serializer.fromJson<String?>(json['face']),
      looked: serializer.fromJson<String>(json['looked']),
      cards: serializer.fromJson<String>(json['cards']),
      note: serializer.fromJson<bool>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'threadId': serializer.toJson<int>(threadId),
      'sentAt': serializer.toJson<int>(sentAt),
      'fromUser': serializer.toJson<bool>(fromUser),
      'body': serializer.toJson<String>(body),
      'face': serializer.toJson<String?>(face),
      'looked': serializer.toJson<String>(looked),
      'cards': serializer.toJson<String>(cards),
      'note': serializer.toJson<bool>(note),
    };
  }

  CoachMessage copyWith({
    int? id,
    int? threadId,
    int? sentAt,
    bool? fromUser,
    String? body,
    Value<String?> face = const Value.absent(),
    String? looked,
    String? cards,
    bool? note,
  }) => CoachMessage(
    id: id ?? this.id,
    threadId: threadId ?? this.threadId,
    sentAt: sentAt ?? this.sentAt,
    fromUser: fromUser ?? this.fromUser,
    body: body ?? this.body,
    face: face.present ? face.value : this.face,
    looked: looked ?? this.looked,
    cards: cards ?? this.cards,
    note: note ?? this.note,
  );
  CoachMessage copyWithCompanion(CoachMessagesCompanion data) {
    return CoachMessage(
      id: data.id.present ? data.id.value : this.id,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      fromUser: data.fromUser.present ? data.fromUser.value : this.fromUser,
      body: data.body.present ? data.body.value : this.body,
      face: data.face.present ? data.face.value : this.face,
      looked: data.looked.present ? data.looked.value : this.looked,
      cards: data.cards.present ? data.cards.value : this.cards,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoachMessage(')
          ..write('id: $id, ')
          ..write('threadId: $threadId, ')
          ..write('sentAt: $sentAt, ')
          ..write('fromUser: $fromUser, ')
          ..write('body: $body, ')
          ..write('face: $face, ')
          ..write('looked: $looked, ')
          ..write('cards: $cards, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    threadId,
    sentAt,
    fromUser,
    body,
    face,
    looked,
    cards,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoachMessage &&
          other.id == this.id &&
          other.threadId == this.threadId &&
          other.sentAt == this.sentAt &&
          other.fromUser == this.fromUser &&
          other.body == this.body &&
          other.face == this.face &&
          other.looked == this.looked &&
          other.cards == this.cards &&
          other.note == this.note);
}

class CoachMessagesCompanion extends UpdateCompanion<CoachMessage> {
  final Value<int> id;
  final Value<int> threadId;
  final Value<int> sentAt;
  final Value<bool> fromUser;
  final Value<String> body;
  final Value<String?> face;
  final Value<String> looked;
  final Value<String> cards;
  final Value<bool> note;
  const CoachMessagesCompanion({
    this.id = const Value.absent(),
    this.threadId = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.fromUser = const Value.absent(),
    this.body = const Value.absent(),
    this.face = const Value.absent(),
    this.looked = const Value.absent(),
    this.cards = const Value.absent(),
    this.note = const Value.absent(),
  });
  CoachMessagesCompanion.insert({
    this.id = const Value.absent(),
    required int threadId,
    required int sentAt,
    required bool fromUser,
    required String body,
    this.face = const Value.absent(),
    this.looked = const Value.absent(),
    this.cards = const Value.absent(),
    this.note = const Value.absent(),
  }) : threadId = Value(threadId),
       sentAt = Value(sentAt),
       fromUser = Value(fromUser),
       body = Value(body);
  static Insertable<CoachMessage> custom({
    Expression<int>? id,
    Expression<int>? threadId,
    Expression<int>? sentAt,
    Expression<bool>? fromUser,
    Expression<String>? body,
    Expression<String>? face,
    Expression<String>? looked,
    Expression<String>? cards,
    Expression<bool>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (threadId != null) 'thread_id': threadId,
      if (sentAt != null) 'sent_at': sentAt,
      if (fromUser != null) 'from_user': fromUser,
      if (body != null) 'body': body,
      if (face != null) 'face': face,
      if (looked != null) 'looked': looked,
      if (cards != null) 'cards': cards,
      if (note != null) 'note': note,
    });
  }

  CoachMessagesCompanion copyWith({
    Value<int>? id,
    Value<int>? threadId,
    Value<int>? sentAt,
    Value<bool>? fromUser,
    Value<String>? body,
    Value<String?>? face,
    Value<String>? looked,
    Value<String>? cards,
    Value<bool>? note,
  }) {
    return CoachMessagesCompanion(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      sentAt: sentAt ?? this.sentAt,
      fromUser: fromUser ?? this.fromUser,
      body: body ?? this.body,
      face: face ?? this.face,
      looked: looked ?? this.looked,
      cards: cards ?? this.cards,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<int>(threadId.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<int>(sentAt.value);
    }
    if (fromUser.present) {
      map['from_user'] = Variable<bool>(fromUser.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (face.present) {
      map['face'] = Variable<String>(face.value);
    }
    if (looked.present) {
      map['looked'] = Variable<String>(looked.value);
    }
    if (cards.present) {
      map['cards'] = Variable<String>(cards.value);
    }
    if (note.present) {
      map['note'] = Variable<bool>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoachMessagesCompanion(')
          ..write('id: $id, ')
          ..write('threadId: $threadId, ')
          ..write('sentAt: $sentAt, ')
          ..write('fromUser: $fromUser, ')
          ..write('body: $body, ')
          ..write('face: $face, ')
          ..write('looked: $looked, ')
          ..write('cards: $cards, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $CheckinsTable extends Checkins with TableInfo<$CheckinsTable, Checkin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckinsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> checkedOn =
      GeneratedColumn<String>(
        'checked_on',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CheckinsTable.$convertercheckedOn);
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<int> balance = GeneratedColumn<int>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchedMeta = const VerificationMeta(
    'matched',
  );
  @override
  late final GeneratedColumn<bool> matched = GeneratedColumn<bool>(
    'matched',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("matched" IN (0, 1))',
    ),
  );
  static const VerificationMeta _untrackedMeta = const VerificationMeta(
    'untracked',
  );
  @override
  late final GeneratedColumn<int> untracked = GeneratedColumn<int>(
    'untracked',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startingAdjustmentMeta =
      const VerificationMeta('startingAdjustment');
  @override
  late final GeneratedColumn<int> startingAdjustment = GeneratedColumn<int>(
    'starting_adjustment',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _allowanceSpentMeta = const VerificationMeta(
    'allowanceSpent',
  );
  @override
  late final GeneratedColumn<int> allowanceSpent = GeneratedColumn<int>(
    'allowance_spent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _leftAfterBuyingMeta = const VerificationMeta(
    'leftAfterBuying',
  );
  @override
  late final GeneratedColumn<int> leftAfterBuying = GeneratedColumn<int>(
    'left_after_buying',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextTargetMeta = const VerificationMeta(
    'nextTarget',
  );
  @override
  late final GeneratedColumn<int> nextTarget = GeneratedColumn<int>(
    'next_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    checkedOn,
    balance,
    matched,
    untracked,
    startingAdjustment,
    allowanceSpent,
    leftAfterBuying,
    nextTarget,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checkins';
  @override
  VerificationContext validateIntegrity(
    Insertable<Checkin> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    } else if (isInserting) {
      context.missing(_balanceMeta);
    }
    if (data.containsKey('matched')) {
      context.handle(
        _matchedMeta,
        matched.isAcceptableOrUnknown(data['matched']!, _matchedMeta),
      );
    } else if (isInserting) {
      context.missing(_matchedMeta);
    }
    if (data.containsKey('untracked')) {
      context.handle(
        _untrackedMeta,
        untracked.isAcceptableOrUnknown(data['untracked']!, _untrackedMeta),
      );
    }
    if (data.containsKey('starting_adjustment')) {
      context.handle(
        _startingAdjustmentMeta,
        startingAdjustment.isAcceptableOrUnknown(
          data['starting_adjustment']!,
          _startingAdjustmentMeta,
        ),
      );
    }
    if (data.containsKey('allowance_spent')) {
      context.handle(
        _allowanceSpentMeta,
        allowanceSpent.isAcceptableOrUnknown(
          data['allowance_spent']!,
          _allowanceSpentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allowanceSpentMeta);
    }
    if (data.containsKey('left_after_buying')) {
      context.handle(
        _leftAfterBuyingMeta,
        leftAfterBuying.isAcceptableOrUnknown(
          data['left_after_buying']!,
          _leftAfterBuyingMeta,
        ),
      );
    }
    if (data.containsKey('next_target')) {
      context.handle(
        _nextTargetMeta,
        nextTarget.isAcceptableOrUnknown(data['next_target']!, _nextTargetMeta),
      );
    } else if (isInserting) {
      context.missing(_nextTargetMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {checkedOn};
  @override
  Checkin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Checkin(
      checkedOn: $CheckinsTable.$convertercheckedOn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}checked_on'],
        )!,
      ),
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance'],
      )!,
      matched: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}matched'],
      )!,
      untracked: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}untracked'],
      )!,
      startingAdjustment: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}starting_adjustment'],
      )!,
      allowanceSpent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}allowance_spent'],
      )!,
      leftAfterBuying: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}left_after_buying'],
      ),
      nextTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_target'],
      )!,
    );
  }

  @override
  $CheckinsTable createAlias(String alias) {
    return $CheckinsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $convertercheckedOn =
      const DayConverter();
}

class Checkin extends DataClass implements Insertable<Checkin> {
  final DateTime checkedOn;

  /// What bajet held across every account when the check-in was finished.
  final int balance;

  /// Every account was compared with what it really holds and agreed.
  final bool matched;

  /// Money logged as untracked at this check-in.
  final int untracked;

  /// The gap found at the very first check-in, from a starting balance that
  /// was slightly off. It is not missed logging, so it is kept apart.
  final int startingAdjustment;

  /// Flexible spending that week, Monday to the check-in.
  final int allowanceSpent;

  /// What the first goal leaves after buying; null without a goal.
  final int? leftAfterBuying;

  /// The balance the plan expected seven days after [checkedOn].
  final int nextTarget;
  const Checkin({
    required this.checkedOn,
    required this.balance,
    required this.matched,
    required this.untracked,
    required this.startingAdjustment,
    required this.allowanceSpent,
    this.leftAfterBuying,
    required this.nextTarget,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['checked_on'] = Variable<String>(
        $CheckinsTable.$convertercheckedOn.toSql(checkedOn),
      );
    }
    map['balance'] = Variable<int>(balance);
    map['matched'] = Variable<bool>(matched);
    map['untracked'] = Variable<int>(untracked);
    map['starting_adjustment'] = Variable<int>(startingAdjustment);
    map['allowance_spent'] = Variable<int>(allowanceSpent);
    if (!nullToAbsent || leftAfterBuying != null) {
      map['left_after_buying'] = Variable<int>(leftAfterBuying);
    }
    map['next_target'] = Variable<int>(nextTarget);
    return map;
  }

  CheckinsCompanion toCompanion(bool nullToAbsent) {
    return CheckinsCompanion(
      checkedOn: Value(checkedOn),
      balance: Value(balance),
      matched: Value(matched),
      untracked: Value(untracked),
      startingAdjustment: Value(startingAdjustment),
      allowanceSpent: Value(allowanceSpent),
      leftAfterBuying: leftAfterBuying == null && nullToAbsent
          ? const Value.absent()
          : Value(leftAfterBuying),
      nextTarget: Value(nextTarget),
    );
  }

  factory Checkin.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Checkin(
      checkedOn: serializer.fromJson<DateTime>(json['checkedOn']),
      balance: serializer.fromJson<int>(json['balance']),
      matched: serializer.fromJson<bool>(json['matched']),
      untracked: serializer.fromJson<int>(json['untracked']),
      startingAdjustment: serializer.fromJson<int>(json['startingAdjustment']),
      allowanceSpent: serializer.fromJson<int>(json['allowanceSpent']),
      leftAfterBuying: serializer.fromJson<int?>(json['leftAfterBuying']),
      nextTarget: serializer.fromJson<int>(json['nextTarget']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'checkedOn': serializer.toJson<DateTime>(checkedOn),
      'balance': serializer.toJson<int>(balance),
      'matched': serializer.toJson<bool>(matched),
      'untracked': serializer.toJson<int>(untracked),
      'startingAdjustment': serializer.toJson<int>(startingAdjustment),
      'allowanceSpent': serializer.toJson<int>(allowanceSpent),
      'leftAfterBuying': serializer.toJson<int?>(leftAfterBuying),
      'nextTarget': serializer.toJson<int>(nextTarget),
    };
  }

  Checkin copyWith({
    DateTime? checkedOn,
    int? balance,
    bool? matched,
    int? untracked,
    int? startingAdjustment,
    int? allowanceSpent,
    Value<int?> leftAfterBuying = const Value.absent(),
    int? nextTarget,
  }) => Checkin(
    checkedOn: checkedOn ?? this.checkedOn,
    balance: balance ?? this.balance,
    matched: matched ?? this.matched,
    untracked: untracked ?? this.untracked,
    startingAdjustment: startingAdjustment ?? this.startingAdjustment,
    allowanceSpent: allowanceSpent ?? this.allowanceSpent,
    leftAfterBuying: leftAfterBuying.present
        ? leftAfterBuying.value
        : this.leftAfterBuying,
    nextTarget: nextTarget ?? this.nextTarget,
  );
  Checkin copyWithCompanion(CheckinsCompanion data) {
    return Checkin(
      checkedOn: data.checkedOn.present ? data.checkedOn.value : this.checkedOn,
      balance: data.balance.present ? data.balance.value : this.balance,
      matched: data.matched.present ? data.matched.value : this.matched,
      untracked: data.untracked.present ? data.untracked.value : this.untracked,
      startingAdjustment: data.startingAdjustment.present
          ? data.startingAdjustment.value
          : this.startingAdjustment,
      allowanceSpent: data.allowanceSpent.present
          ? data.allowanceSpent.value
          : this.allowanceSpent,
      leftAfterBuying: data.leftAfterBuying.present
          ? data.leftAfterBuying.value
          : this.leftAfterBuying,
      nextTarget: data.nextTarget.present
          ? data.nextTarget.value
          : this.nextTarget,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Checkin(')
          ..write('checkedOn: $checkedOn, ')
          ..write('balance: $balance, ')
          ..write('matched: $matched, ')
          ..write('untracked: $untracked, ')
          ..write('startingAdjustment: $startingAdjustment, ')
          ..write('allowanceSpent: $allowanceSpent, ')
          ..write('leftAfterBuying: $leftAfterBuying, ')
          ..write('nextTarget: $nextTarget')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    checkedOn,
    balance,
    matched,
    untracked,
    startingAdjustment,
    allowanceSpent,
    leftAfterBuying,
    nextTarget,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Checkin &&
          other.checkedOn == this.checkedOn &&
          other.balance == this.balance &&
          other.matched == this.matched &&
          other.untracked == this.untracked &&
          other.startingAdjustment == this.startingAdjustment &&
          other.allowanceSpent == this.allowanceSpent &&
          other.leftAfterBuying == this.leftAfterBuying &&
          other.nextTarget == this.nextTarget);
}

class CheckinsCompanion extends UpdateCompanion<Checkin> {
  final Value<DateTime> checkedOn;
  final Value<int> balance;
  final Value<bool> matched;
  final Value<int> untracked;
  final Value<int> startingAdjustment;
  final Value<int> allowanceSpent;
  final Value<int?> leftAfterBuying;
  final Value<int> nextTarget;
  final Value<int> rowid;
  const CheckinsCompanion({
    this.checkedOn = const Value.absent(),
    this.balance = const Value.absent(),
    this.matched = const Value.absent(),
    this.untracked = const Value.absent(),
    this.startingAdjustment = const Value.absent(),
    this.allowanceSpent = const Value.absent(),
    this.leftAfterBuying = const Value.absent(),
    this.nextTarget = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CheckinsCompanion.insert({
    required DateTime checkedOn,
    required int balance,
    required bool matched,
    this.untracked = const Value.absent(),
    this.startingAdjustment = const Value.absent(),
    required int allowanceSpent,
    this.leftAfterBuying = const Value.absent(),
    required int nextTarget,
    this.rowid = const Value.absent(),
  }) : checkedOn = Value(checkedOn),
       balance = Value(balance),
       matched = Value(matched),
       allowanceSpent = Value(allowanceSpent),
       nextTarget = Value(nextTarget);
  static Insertable<Checkin> custom({
    Expression<String>? checkedOn,
    Expression<int>? balance,
    Expression<bool>? matched,
    Expression<int>? untracked,
    Expression<int>? startingAdjustment,
    Expression<int>? allowanceSpent,
    Expression<int>? leftAfterBuying,
    Expression<int>? nextTarget,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (checkedOn != null) 'checked_on': checkedOn,
      if (balance != null) 'balance': balance,
      if (matched != null) 'matched': matched,
      if (untracked != null) 'untracked': untracked,
      if (startingAdjustment != null) 'starting_adjustment': startingAdjustment,
      if (allowanceSpent != null) 'allowance_spent': allowanceSpent,
      if (leftAfterBuying != null) 'left_after_buying': leftAfterBuying,
      if (nextTarget != null) 'next_target': nextTarget,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CheckinsCompanion copyWith({
    Value<DateTime>? checkedOn,
    Value<int>? balance,
    Value<bool>? matched,
    Value<int>? untracked,
    Value<int>? startingAdjustment,
    Value<int>? allowanceSpent,
    Value<int?>? leftAfterBuying,
    Value<int>? nextTarget,
    Value<int>? rowid,
  }) {
    return CheckinsCompanion(
      checkedOn: checkedOn ?? this.checkedOn,
      balance: balance ?? this.balance,
      matched: matched ?? this.matched,
      untracked: untracked ?? this.untracked,
      startingAdjustment: startingAdjustment ?? this.startingAdjustment,
      allowanceSpent: allowanceSpent ?? this.allowanceSpent,
      leftAfterBuying: leftAfterBuying ?? this.leftAfterBuying,
      nextTarget: nextTarget ?? this.nextTarget,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (checkedOn.present) {
      map['checked_on'] = Variable<String>(
        $CheckinsTable.$convertercheckedOn.toSql(checkedOn.value),
      );
    }
    if (balance.present) {
      map['balance'] = Variable<int>(balance.value);
    }
    if (matched.present) {
      map['matched'] = Variable<bool>(matched.value);
    }
    if (untracked.present) {
      map['untracked'] = Variable<int>(untracked.value);
    }
    if (startingAdjustment.present) {
      map['starting_adjustment'] = Variable<int>(startingAdjustment.value);
    }
    if (allowanceSpent.present) {
      map['allowance_spent'] = Variable<int>(allowanceSpent.value);
    }
    if (leftAfterBuying.present) {
      map['left_after_buying'] = Variable<int>(leftAfterBuying.value);
    }
    if (nextTarget.present) {
      map['next_target'] = Variable<int>(nextTarget.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckinsCompanion(')
          ..write('checkedOn: $checkedOn, ')
          ..write('balance: $balance, ')
          ..write('matched: $matched, ')
          ..write('untracked: $untracked, ')
          ..write('startingAdjustment: $startingAdjustment, ')
          ..write('allowanceSpent: $allowanceSpent, ')
          ..write('leftAfterBuying: $leftAfterBuying, ')
          ..write('nextTarget: $nextTarget, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $TransfersTable transfers = $TransfersTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $RecurringItemsTable recurringItems = $RecurringItemsTable(this);
  late final $PlannedEventsTable plannedEvents = $PlannedEventsTable(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $WeeklyRulesTable weeklyRules = $WeeklyRulesTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $FavouritesTable favourites = $FavouritesTable(this);
  late final $CoachSettingsTable coachSettings = $CoachSettingsTable(this);
  late final $CoachThreadsTable coachThreads = $CoachThreadsTable(this);
  late final $CoachMessagesTable coachMessages = $CoachMessagesTable(this);
  late final $CheckinsTable checkins = $CheckinsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    accounts,
    transfers,
    categories,
    recurringItems,
    plannedEvents,
    entries,
    weeklyRules,
    goals,
    favourites,
    coachSettings,
    coachThreads,
    coachMessages,
    checkins,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'coach_threads',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('coach_messages', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      required DateTime openingDate,
      required int weeklyCap,
      required int buffer,
      Value<int?> totalCardColor,
      Value<CardFinish> totalCardFinish,
      Value<String?> userName,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<DateTime> openingDate,
      Value<int> weeklyCap,
      Value<int> buffer,
      Value<int?> totalCardColor,
      Value<CardFinish> totalCardFinish,
      Value<String?> userName,
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

  ColumnFilters<int> get totalCardColor => $composableBuilder(
    column: $table.totalCardColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CardFinish, CardFinish, String>
  get totalCardFinish => $composableBuilder(
    column: $table.totalCardFinish,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get userName => $composableBuilder(
    column: $table.userName,
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

  ColumnOrderings<int> get totalCardColor => $composableBuilder(
    column: $table.totalCardColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get totalCardFinish => $composableBuilder(
    column: $table.totalCardFinish,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userName => $composableBuilder(
    column: $table.userName,
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

  GeneratedColumnWithTypeConverter<DateTime, String> get openingDate =>
      $composableBuilder(
        column: $table.openingDate,
        builder: (column) => column,
      );

  GeneratedColumn<int> get weeklyCap =>
      $composableBuilder(column: $table.weeklyCap, builder: (column) => column);

  GeneratedColumn<int> get buffer =>
      $composableBuilder(column: $table.buffer, builder: (column) => column);

  GeneratedColumn<int> get totalCardColor => $composableBuilder(
    column: $table.totalCardColor,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CardFinish, String> get totalCardFinish =>
      $composableBuilder(
        column: $table.totalCardFinish,
        builder: (column) => column,
      );

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);
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
                Value<DateTime> openingDate = const Value.absent(),
                Value<int> weeklyCap = const Value.absent(),
                Value<int> buffer = const Value.absent(),
                Value<int?> totalCardColor = const Value.absent(),
                Value<CardFinish> totalCardFinish = const Value.absent(),
                Value<String?> userName = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                openingDate: openingDate,
                weeklyCap: weeklyCap,
                buffer: buffer,
                totalCardColor: totalCardColor,
                totalCardFinish: totalCardFinish,
                userName: userName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime openingDate,
                required int weeklyCap,
                required int buffer,
                Value<int?> totalCardColor = const Value.absent(),
                Value<CardFinish> totalCardFinish = const Value.absent(),
                Value<String?> userName = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                openingDate: openingDate,
                weeklyCap: weeklyCap,
                buffer: buffer,
                totalCardColor: totalCardColor,
                totalCardFinish: totalCardFinish,
                userName: userName,
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
typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      required AccountKind kind,
      required String name,
      Value<String?> nickname,
      Value<int> openingBalance,
      required int color,
      Value<int?> inkColor,
      Value<CardFinish> finish,
      Value<int> sortOrder,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      Value<AccountKind> kind,
      Value<String> name,
      Value<String?> nickname,
      Value<int> openingBalance,
      Value<int> color,
      Value<int?> inkColor,
      Value<CardFinish> finish,
      Value<int> sortOrder,
    });

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RecurringItemsTable, List<RecurringItem>>
  _recurringItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recurringItems,
    aliasName: 'accounts__id__recurring_items__account_id',
  );

  $$RecurringItemsTableProcessedTableManager get recurringItemsRefs {
    final manager = $$RecurringItemsTableTableManager(
      $_db,
      $_db.recurringItems,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_recurringItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EntriesTable, List<Entry>> _entriesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.entries,
    aliasName: 'accounts__id__entries__account_id',
  );

  $$EntriesTableProcessedTableManager get entriesRefs {
    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_entriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<AccountKind, AccountKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inkColor => $composableBuilder(
    column: $table.inkColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CardFinish, CardFinish, String> get finish =>
      $composableBuilder(
        column: $table.finish,
        builder: (column) => ColumnWithTypeConverterFilters(column),
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
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurringItems,
      getReferencedColumn: (t) => t.accountId,
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
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.accountId,
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

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inkColor => $composableBuilder(
    column: $table.inkColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finish => $composableBuilder(
    column: $table.finish,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccountKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<int> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get inkColor =>
      $composableBuilder(column: $table.inkColor, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CardFinish, String> get finish =>
      $composableBuilder(column: $table.finish, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> recurringItemsRefs<T extends Object>(
    Expression<T> Function($$RecurringItemsTableAnnotationComposer a) f,
  ) {
    final $$RecurringItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurringItems,
      getReferencedColumn: (t) => t.accountId,
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
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.accountId,
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

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({bool recurringItemsRefs, bool entriesRefs})
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<AccountKind> kind = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> nickname = const Value.absent(),
                Value<int> openingBalance = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<int?> inkColor = const Value.absent(),
                Value<CardFinish> finish = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                kind: kind,
                name: name,
                nickname: nickname,
                openingBalance: openingBalance,
                color: color,
                inkColor: inkColor,
                finish: finish,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required AccountKind kind,
                required String name,
                Value<String?> nickname = const Value.absent(),
                Value<int> openingBalance = const Value.absent(),
                required int color,
                Value<int?> inkColor = const Value.absent(),
                Value<CardFinish> finish = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                kind: kind,
                name: name,
                nickname: nickname,
                openingBalance: openingBalance,
                color: color,
                inkColor: inkColor,
                finish: finish,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, Account>(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({recurringItemsRefs = false, entriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (recurringItemsRefs) db.recurringItems,
                    if (entriesRefs) db.entries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (recurringItemsRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          RecurringItem
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._recurringItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).recurringItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (entriesRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          Entry
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._entriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).entriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
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

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({bool recurringItemsRefs, bool entriesRefs})
    >;
typedef $$TransfersTableCreateCompanionBuilder =
    TransfersCompanion Function({
      Value<int> id,
      required DateTime occurredOn,
      required int fromAccountId,
      required int toAccountId,
      required int amount,
      Value<String?> note,
      Value<DateTime> createdAt,
    });
typedef $$TransfersTableUpdateCompanionBuilder =
    TransfersCompanion Function({
      Value<int> id,
      Value<DateTime> occurredOn,
      Value<int> fromAccountId,
      Value<int> toAccountId,
      Value<int> amount,
      Value<String?> note,
      Value<DateTime> createdAt,
    });

final class $$TransfersTableReferences
    extends BaseReferences<_$AppDatabase, $TransfersTable, Transfer> {
  $$TransfersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _fromAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transfers__from_account_id__accounts__id');

  $$AccountsTableProcessedTableManager get fromAccountId {
    final $_column = $_itemColumn<int>('from_account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _toAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transfers__to_account_id__accounts__id');

  $$AccountsTableProcessedTableManager get toAccountId {
    final $_column = $_itemColumn<int>('to_account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransfersTableFilterComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableFilterComposer({
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

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get fromAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get toAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransfersTableOrderingComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableOrderingComposer({
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

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get fromAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get toAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransfersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableAnnotationComposer({
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

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get fromAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get toAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransfersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransfersTable,
          Transfer,
          $$TransfersTableFilterComposer,
          $$TransfersTableOrderingComposer,
          $$TransfersTableAnnotationComposer,
          $$TransfersTableCreateCompanionBuilder,
          $$TransfersTableUpdateCompanionBuilder,
          (Transfer, $$TransfersTableReferences),
          Transfer,
          PrefetchHooks Function({bool fromAccountId, bool toAccountId})
        > {
  $$TransfersTableTableManager(_$AppDatabase db, $TransfersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransfersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransfersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> occurredOn = const Value.absent(),
                Value<int> fromAccountId = const Value.absent(),
                Value<int> toAccountId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TransfersCompanion(
                id: id,
                occurredOn: occurredOn,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                amount: amount,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime occurredOn,
                required int fromAccountId,
                required int toAccountId,
                required int amount,
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TransfersCompanion.insert(
                id: id,
                occurredOn: occurredOn,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                amount: amount,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransfersTable, Transfer>(table),
                  $$TransfersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({fromAccountId = false, toAccountId = false}) {
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
                        if (fromAccountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.fromAccountId,
                                    referencedTable: $$TransfersTableReferences
                                        ._fromAccountIdTable(db),
                                    referencedColumn: $$TransfersTableReferences
                                        ._fromAccountIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (toAccountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.toAccountId,
                                    referencedTable: $$TransfersTableReferences
                                        ._toAccountIdTable(db),
                                    referencedColumn: $$TransfersTableReferences
                                        ._toAccountIdTable(db)
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

typedef $$TransfersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransfersTable,
      Transfer,
      $$TransfersTableFilterComposer,
      $$TransfersTableOrderingComposer,
      $$TransfersTableAnnotationComposer,
      $$TransfersTableCreateCompanionBuilder,
      $$TransfersTableUpdateCompanionBuilder,
      (Transfer, $$TransfersTableReferences),
      Transfer,
      PrefetchHooks Function({bool fromAccountId, bool toAccountId})
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
            bool plannedEventsRefs,
            bool entriesRefs,
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
                plannedEventsRefs = false,
                entriesRefs = false,
                favouritesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (recurringItemsRefs) db.recurringItems,
                    if (plannedEventsRefs) db.plannedEvents,
                    if (entriesRefs) db.entries,
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
        bool plannedEventsRefs,
        bool entriesRefs,
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
      required int accountId,
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
      Value<int> accountId,
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

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('recurring_items__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
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

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
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

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
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

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
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
          PrefetchHooks Function({
            bool categoryKey,
            bool accountId,
            bool entriesRefs,
          })
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
                Value<int> accountId = const Value.absent(),
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
                accountId: accountId,
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
                required int accountId,
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
                accountId: accountId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecurringItemsTable, RecurringItem>(table),
                  $$RecurringItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({categoryKey = false, accountId = false, entriesRefs = false}) {
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
                                    referencedTable:
                                        $$RecurringItemsTableReferences
                                            ._categoryKeyTable(db),
                                    referencedColumn:
                                        $$RecurringItemsTableReferences
                                            ._categoryKeyTable(db)
                                            .key,
                                  )
                                  as T;
                        }
                        if (accountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.accountId,
                                    referencedTable:
                                        $$RecurringItemsTableReferences
                                            ._accountIdTable(db),
                                    referencedColumn:
                                        $$RecurringItemsTableReferences
                                            ._accountIdTable(db)
                                            .id,
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
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
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
      PrefetchHooks Function({
        bool categoryKey,
        bool accountId,
        bool entriesRefs,
      })
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

  static MultiTypedResultKey<$EntriesTable, List<Entry>> _entriesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.entries,
    aliasName: 'planned_events__id__entries__planned_event_id',
  );

  $$EntriesTableProcessedTableManager get entriesRefs {
    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.plannedEventId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_entriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
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

  Expression<bool> entriesRefs(
    Expression<bool> Function($$EntriesTableFilterComposer f) f,
  ) {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.plannedEventId,
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

  Expression<T> entriesRefs<T extends Object>(
    Expression<T> Function($$EntriesTableAnnotationComposer a) f,
  ) {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.plannedEventId,
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
          PrefetchHooks Function({bool categoryKey, bool entriesRefs})
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
                return [
                  if (entriesRefs)
                    await $_getPrefetchedData<
                      PlannedEvent,
                      $PlannedEventsTable,
                      Entry
                    >(
                      currentTable: table,
                      referencedTable: $$PlannedEventsTableReferences
                          ._entriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PlannedEventsTableReferences(
                            db,
                            table,
                            p0,
                          ).entriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.plannedEventId == item.id,
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
      PrefetchHooks Function({bool categoryKey, bool entriesRefs})
    >;
typedef $$EntriesTableCreateCompanionBuilder =
    EntriesCompanion Function({
      Value<int> id,
      required DateTime occurredOn,
      required EntryKind kind,
      required int amount,
      required String categoryKey,
      required int accountId,
      Value<String?> label,
      Value<String?> note,
      Value<String?> receipt,
      Value<int?> recurringItemId,
      Value<int?> plannedEventId,
      Value<DateTime?> plannedEventOn,
      Value<DateTime> createdAt,
    });
typedef $$EntriesTableUpdateCompanionBuilder =
    EntriesCompanion Function({
      Value<int> id,
      Value<DateTime> occurredOn,
      Value<EntryKind> kind,
      Value<int> amount,
      Value<String> categoryKey,
      Value<int> accountId,
      Value<String?> label,
      Value<String?> note,
      Value<String?> receipt,
      Value<int?> recurringItemId,
      Value<int?> plannedEventId,
      Value<DateTime?> plannedEventOn,
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

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('entries__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
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

  static $PlannedEventsTable _plannedEventIdTable(_$AppDatabase db) => db
      .plannedEvents
      .createAlias('entries__planned_event_id__planned_events__id');

  $$PlannedEventsTableProcessedTableManager? get plannedEventId {
    final $_column = $_itemColumn<int>('planned_event_id');
    if ($_column == null) return null;
    final manager = $$PlannedEventsTableTableManager(
      $_db,
      $_db.plannedEvents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_plannedEventIdTable($_db));
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

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String>
  get plannedEventOn => $composableBuilder(
    column: $table.plannedEventOn,
    builder: (column) => ColumnWithTypeConverterFilters(column),
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

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
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

  $$PlannedEventsTableFilterComposer get plannedEventId {
    final $$PlannedEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedEventId,
      referencedTable: $db.plannedEvents,
      getReferencedColumn: (t) => t.id,
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

  ColumnOrderings<String> get plannedEventOn => $composableBuilder(
    column: $table.plannedEventOn,
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

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
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

  $$PlannedEventsTableOrderingComposer get plannedEventId {
    final $$PlannedEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedEventId,
      referencedTable: $db.plannedEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedEventsTableOrderingComposer(
            $db: $db,
            $table: $db.plannedEvents,
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

  GeneratedColumnWithTypeConverter<DateTime?, String> get plannedEventOn =>
      $composableBuilder(
        column: $table.plannedEventOn,
        builder: (column) => column,
      );

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

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
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

  $$PlannedEventsTableAnnotationComposer get plannedEventId {
    final $$PlannedEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedEventId,
      referencedTable: $db.plannedEvents,
      getReferencedColumn: (t) => t.id,
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
          PrefetchHooks Function({
            bool categoryKey,
            bool accountId,
            bool recurringItemId,
            bool plannedEventId,
          })
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
                Value<int> accountId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> receipt = const Value.absent(),
                Value<int?> recurringItemId = const Value.absent(),
                Value<int?> plannedEventId = const Value.absent(),
                Value<DateTime?> plannedEventOn = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                occurredOn: occurredOn,
                kind: kind,
                amount: amount,
                categoryKey: categoryKey,
                accountId: accountId,
                label: label,
                note: note,
                receipt: receipt,
                recurringItemId: recurringItemId,
                plannedEventId: plannedEventId,
                plannedEventOn: plannedEventOn,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime occurredOn,
                required EntryKind kind,
                required int amount,
                required String categoryKey,
                required int accountId,
                Value<String?> label = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> receipt = const Value.absent(),
                Value<int?> recurringItemId = const Value.absent(),
                Value<int?> plannedEventId = const Value.absent(),
                Value<DateTime?> plannedEventOn = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                occurredOn: occurredOn,
                kind: kind,
                amount: amount,
                categoryKey: categoryKey,
                accountId: accountId,
                label: label,
                note: note,
                receipt: receipt,
                recurringItemId: recurringItemId,
                plannedEventId: plannedEventId,
                plannedEventOn: plannedEventOn,
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
              ({
                categoryKey = false,
                accountId = false,
                recurringItemId = false,
                plannedEventId = false,
              }) {
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
                        if (accountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.accountId,
                                    referencedTable: $$EntriesTableReferences
                                        ._accountIdTable(db),
                                    referencedColumn: $$EntriesTableReferences
                                        ._accountIdTable(db)
                                        .id,
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
                        if (plannedEventId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.plannedEventId,
                                    referencedTable: $$EntriesTableReferences
                                        ._plannedEventIdTable(db),
                                    referencedColumn: $$EntriesTableReferences
                                        ._plannedEventIdTable(db)
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
      PrefetchHooks Function({
        bool categoryKey,
        bool accountId,
        bool recurringItemId,
        bool plannedEventId,
      })
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
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      Value<int> id,
      required String name,
      required int price,
      required DateTime targetDate,
      Value<int> priority,
      Value<String?> listingUrl,
      Value<ListingState?> listingState,
      Value<DateTime?> listingCheckedOn,
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
      Value<ListingState?> listingState,
      Value<DateTime?> listingCheckedOn,
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

  ColumnWithTypeConverterFilters<ListingState?, ListingState, String>
  get listingState => $composableBuilder(
    column: $table.listingState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String>
  get listingCheckedOn => $composableBuilder(
    column: $table.listingCheckedOn,
    builder: (column) => ColumnWithTypeConverterFilters(column),
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

  ColumnOrderings<String> get listingState => $composableBuilder(
    column: $table.listingState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listingCheckedOn => $composableBuilder(
    column: $table.listingCheckedOn,
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

  GeneratedColumnWithTypeConverter<ListingState?, String> get listingState =>
      $composableBuilder(
        column: $table.listingState,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get listingCheckedOn =>
      $composableBuilder(
        column: $table.listingCheckedOn,
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
                Value<ListingState?> listingState = const Value.absent(),
                Value<DateTime?> listingCheckedOn = const Value.absent(),
                Value<GoalStatus> status = const Value.absent(),
                Value<DateTime?> achievedOn = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                name: name,
                price: price,
                targetDate: targetDate,
                priority: priority,
                listingUrl: listingUrl,
                listingState: listingState,
                listingCheckedOn: listingCheckedOn,
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
                Value<ListingState?> listingState = const Value.absent(),
                Value<DateTime?> listingCheckedOn = const Value.absent(),
                Value<GoalStatus> status = const Value.absent(),
                Value<DateTime?> achievedOn = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                name: name,
                price: price,
                targetDate: targetDate,
                priority: priority,
                listingUrl: listingUrl,
                listingState: listingState,
                listingCheckedOn: listingCheckedOn,
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
typedef $$CoachSettingsTableCreateCompanionBuilder =
    CoachSettingsCompanion Function({
      Value<int> id,
      Value<String> face,
      Value<String> personality,
      Value<bool> remember,
    });
typedef $$CoachSettingsTableUpdateCompanionBuilder =
    CoachSettingsCompanion Function({
      Value<int> id,
      Value<String> face,
      Value<String> personality,
      Value<bool> remember,
    });

class $$CoachSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $CoachSettingsTable> {
  $$CoachSettingsTableFilterComposer({
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

  ColumnFilters<String> get face => $composableBuilder(
    column: $table.face,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personality => $composableBuilder(
    column: $table.personality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remember => $composableBuilder(
    column: $table.remember,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CoachSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $CoachSettingsTable> {
  $$CoachSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get face => $composableBuilder(
    column: $table.face,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personality => $composableBuilder(
    column: $table.personality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remember => $composableBuilder(
    column: $table.remember,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoachSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoachSettingsTable> {
  $$CoachSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get face =>
      $composableBuilder(column: $table.face, builder: (column) => column);

  GeneratedColumn<String> get personality => $composableBuilder(
    column: $table.personality,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get remember =>
      $composableBuilder(column: $table.remember, builder: (column) => column);
}

class $$CoachSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoachSettingsTable,
          CoachSetting,
          $$CoachSettingsTableFilterComposer,
          $$CoachSettingsTableOrderingComposer,
          $$CoachSettingsTableAnnotationComposer,
          $$CoachSettingsTableCreateCompanionBuilder,
          $$CoachSettingsTableUpdateCompanionBuilder,
          (
            CoachSetting,
            BaseReferences<_$AppDatabase, $CoachSettingsTable, CoachSetting>,
          ),
          CoachSetting,
          PrefetchHooks Function()
        > {
  $$CoachSettingsTableTableManager(_$AppDatabase db, $CoachSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoachSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoachSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoachSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> face = const Value.absent(),
                Value<String> personality = const Value.absent(),
                Value<bool> remember = const Value.absent(),
              }) => CoachSettingsCompanion(
                id: id,
                face: face,
                personality: personality,
                remember: remember,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> face = const Value.absent(),
                Value<String> personality = const Value.absent(),
                Value<bool> remember = const Value.absent(),
              }) => CoachSettingsCompanion.insert(
                id: id,
                face: face,
                personality: personality,
                remember: remember,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CoachSettingsTable, CoachSetting>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CoachSettingsTable,
                    CoachSetting
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CoachSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoachSettingsTable,
      CoachSetting,
      $$CoachSettingsTableFilterComposer,
      $$CoachSettingsTableOrderingComposer,
      $$CoachSettingsTableAnnotationComposer,
      $$CoachSettingsTableCreateCompanionBuilder,
      $$CoachSettingsTableUpdateCompanionBuilder,
      (
        CoachSetting,
        BaseReferences<_$AppDatabase, $CoachSettingsTable, CoachSetting>,
      ),
      CoachSetting,
      PrefetchHooks Function()
    >;
typedef $$CoachThreadsTableCreateCompanionBuilder =
    CoachThreadsCompanion Function({
      Value<int> id,
      required String title,
      Value<bool> pinned,
      required String face,
      required String personality,
      required int createdAt,
    });
typedef $$CoachThreadsTableUpdateCompanionBuilder =
    CoachThreadsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<bool> pinned,
      Value<String> face,
      Value<String> personality,
      Value<int> createdAt,
    });

final class $$CoachThreadsTableReferences
    extends BaseReferences<_$AppDatabase, $CoachThreadsTable, CoachThread> {
  $$CoachThreadsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CoachMessagesTable, List<CoachMessage>>
  _coachMessagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.coachMessages,
    aliasName: 'coach_threads__id__coach_messages__thread_id',
  );

  $$CoachMessagesTableProcessedTableManager get coachMessagesRefs {
    final manager = $$CoachMessagesTableTableManager(
      $_db,
      $_db.coachMessages,
    ).filter((f) => f.threadId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_coachMessagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CoachThreadsTableFilterComposer
    extends Composer<_$AppDatabase, $CoachThreadsTable> {
  $$CoachThreadsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get face => $composableBuilder(
    column: $table.face,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personality => $composableBuilder(
    column: $table.personality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> coachMessagesRefs(
    Expression<bool> Function($$CoachMessagesTableFilterComposer f) f,
  ) {
    final $$CoachMessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coachMessages,
      getReferencedColumn: (t) => t.threadId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoachMessagesTableFilterComposer(
            $db: $db,
            $table: $db.coachMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoachThreadsTableOrderingComposer
    extends Composer<_$AppDatabase, $CoachThreadsTable> {
  $$CoachThreadsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get face => $composableBuilder(
    column: $table.face,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personality => $composableBuilder(
    column: $table.personality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoachThreadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoachThreadsTable> {
  $$CoachThreadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<String> get face =>
      $composableBuilder(column: $table.face, builder: (column) => column);

  GeneratedColumn<String> get personality => $composableBuilder(
    column: $table.personality,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> coachMessagesRefs<T extends Object>(
    Expression<T> Function($$CoachMessagesTableAnnotationComposer a) f,
  ) {
    final $$CoachMessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coachMessages,
      getReferencedColumn: (t) => t.threadId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoachMessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.coachMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoachThreadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoachThreadsTable,
          CoachThread,
          $$CoachThreadsTableFilterComposer,
          $$CoachThreadsTableOrderingComposer,
          $$CoachThreadsTableAnnotationComposer,
          $$CoachThreadsTableCreateCompanionBuilder,
          $$CoachThreadsTableUpdateCompanionBuilder,
          (CoachThread, $$CoachThreadsTableReferences),
          CoachThread,
          PrefetchHooks Function({bool coachMessagesRefs})
        > {
  $$CoachThreadsTableTableManager(_$AppDatabase db, $CoachThreadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoachThreadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoachThreadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoachThreadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<String> face = const Value.absent(),
                Value<String> personality = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => CoachThreadsCompanion(
                id: id,
                title: title,
                pinned: pinned,
                face: face,
                personality: personality,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<bool> pinned = const Value.absent(),
                required String face,
                required String personality,
                required int createdAt,
              }) => CoachThreadsCompanion.insert(
                id: id,
                title: title,
                pinned: pinned,
                face: face,
                personality: personality,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CoachThreadsTable, CoachThread>(table),
                  $$CoachThreadsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({coachMessagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (coachMessagesRefs) db.coachMessages,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (coachMessagesRefs)
                    await $_getPrefetchedData<
                      CoachThread,
                      $CoachThreadsTable,
                      CoachMessage
                    >(
                      currentTable: table,
                      referencedTable: $$CoachThreadsTableReferences
                          ._coachMessagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CoachThreadsTableReferences(
                            db,
                            table,
                            p0,
                          ).coachMessagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.threadId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CoachThreadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoachThreadsTable,
      CoachThread,
      $$CoachThreadsTableFilterComposer,
      $$CoachThreadsTableOrderingComposer,
      $$CoachThreadsTableAnnotationComposer,
      $$CoachThreadsTableCreateCompanionBuilder,
      $$CoachThreadsTableUpdateCompanionBuilder,
      (CoachThread, $$CoachThreadsTableReferences),
      CoachThread,
      PrefetchHooks Function({bool coachMessagesRefs})
    >;
typedef $$CoachMessagesTableCreateCompanionBuilder =
    CoachMessagesCompanion Function({
      Value<int> id,
      required int threadId,
      required int sentAt,
      required bool fromUser,
      required String body,
      Value<String?> face,
      Value<String> looked,
      Value<String> cards,
      Value<bool> note,
    });
typedef $$CoachMessagesTableUpdateCompanionBuilder =
    CoachMessagesCompanion Function({
      Value<int> id,
      Value<int> threadId,
      Value<int> sentAt,
      Value<bool> fromUser,
      Value<String> body,
      Value<String?> face,
      Value<String> looked,
      Value<String> cards,
      Value<bool> note,
    });

final class $$CoachMessagesTableReferences
    extends BaseReferences<_$AppDatabase, $CoachMessagesTable, CoachMessage> {
  $$CoachMessagesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CoachThreadsTable _threadIdTable(_$AppDatabase db) => db.coachThreads
      .createAlias('coach_messages__thread_id__coach_threads__id');

  $$CoachThreadsTableProcessedTableManager get threadId {
    final $_column = $_itemColumn<int>('thread_id')!;

    final manager = $$CoachThreadsTableTableManager(
      $_db,
      $_db.coachThreads,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_threadIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CoachMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $CoachMessagesTable> {
  $$CoachMessagesTableFilterComposer({
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

  ColumnFilters<int> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fromUser => $composableBuilder(
    column: $table.fromUser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get face => $composableBuilder(
    column: $table.face,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get looked => $composableBuilder(
    column: $table.looked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cards => $composableBuilder(
    column: $table.cards,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$CoachThreadsTableFilterComposer get threadId {
    final $$CoachThreadsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.threadId,
      referencedTable: $db.coachThreads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoachThreadsTableFilterComposer(
            $db: $db,
            $table: $db.coachThreads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoachMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $CoachMessagesTable> {
  $$CoachMessagesTableOrderingComposer({
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

  ColumnOrderings<int> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fromUser => $composableBuilder(
    column: $table.fromUser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get face => $composableBuilder(
    column: $table.face,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get looked => $composableBuilder(
    column: $table.looked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cards => $composableBuilder(
    column: $table.cards,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoachThreadsTableOrderingComposer get threadId {
    final $$CoachThreadsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.threadId,
      referencedTable: $db.coachThreads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoachThreadsTableOrderingComposer(
            $db: $db,
            $table: $db.coachThreads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoachMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoachMessagesTable> {
  $$CoachMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<bool> get fromUser =>
      $composableBuilder(column: $table.fromUser, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get face =>
      $composableBuilder(column: $table.face, builder: (column) => column);

  GeneratedColumn<String> get looked =>
      $composableBuilder(column: $table.looked, builder: (column) => column);

  GeneratedColumn<String> get cards =>
      $composableBuilder(column: $table.cards, builder: (column) => column);

  GeneratedColumn<bool> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$CoachThreadsTableAnnotationComposer get threadId {
    final $$CoachThreadsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.threadId,
      referencedTable: $db.coachThreads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoachThreadsTableAnnotationComposer(
            $db: $db,
            $table: $db.coachThreads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoachMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoachMessagesTable,
          CoachMessage,
          $$CoachMessagesTableFilterComposer,
          $$CoachMessagesTableOrderingComposer,
          $$CoachMessagesTableAnnotationComposer,
          $$CoachMessagesTableCreateCompanionBuilder,
          $$CoachMessagesTableUpdateCompanionBuilder,
          (CoachMessage, $$CoachMessagesTableReferences),
          CoachMessage,
          PrefetchHooks Function({bool threadId})
        > {
  $$CoachMessagesTableTableManager(_$AppDatabase db, $CoachMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoachMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoachMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoachMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> threadId = const Value.absent(),
                Value<int> sentAt = const Value.absent(),
                Value<bool> fromUser = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> face = const Value.absent(),
                Value<String> looked = const Value.absent(),
                Value<String> cards = const Value.absent(),
                Value<bool> note = const Value.absent(),
              }) => CoachMessagesCompanion(
                id: id,
                threadId: threadId,
                sentAt: sentAt,
                fromUser: fromUser,
                body: body,
                face: face,
                looked: looked,
                cards: cards,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int threadId,
                required int sentAt,
                required bool fromUser,
                required String body,
                Value<String?> face = const Value.absent(),
                Value<String> looked = const Value.absent(),
                Value<String> cards = const Value.absent(),
                Value<bool> note = const Value.absent(),
              }) => CoachMessagesCompanion.insert(
                id: id,
                threadId: threadId,
                sentAt: sentAt,
                fromUser: fromUser,
                body: body,
                face: face,
                looked: looked,
                cards: cards,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CoachMessagesTable, CoachMessage>(table),
                  $$CoachMessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({threadId = false}) {
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
                    if (threadId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.threadId,
                                referencedTable: $$CoachMessagesTableReferences
                                    ._threadIdTable(db),
                                referencedColumn: $$CoachMessagesTableReferences
                                    ._threadIdTable(db)
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

typedef $$CoachMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoachMessagesTable,
      CoachMessage,
      $$CoachMessagesTableFilterComposer,
      $$CoachMessagesTableOrderingComposer,
      $$CoachMessagesTableAnnotationComposer,
      $$CoachMessagesTableCreateCompanionBuilder,
      $$CoachMessagesTableUpdateCompanionBuilder,
      (CoachMessage, $$CoachMessagesTableReferences),
      CoachMessage,
      PrefetchHooks Function({bool threadId})
    >;
typedef $$CheckinsTableCreateCompanionBuilder =
    CheckinsCompanion Function({
      required DateTime checkedOn,
      required int balance,
      required bool matched,
      Value<int> untracked,
      Value<int> startingAdjustment,
      required int allowanceSpent,
      Value<int?> leftAfterBuying,
      required int nextTarget,
      Value<int> rowid,
    });
typedef $$CheckinsTableUpdateCompanionBuilder =
    CheckinsCompanion Function({
      Value<DateTime> checkedOn,
      Value<int> balance,
      Value<bool> matched,
      Value<int> untracked,
      Value<int> startingAdjustment,
      Value<int> allowanceSpent,
      Value<int?> leftAfterBuying,
      Value<int> nextTarget,
      Value<int> rowid,
    });

class $$CheckinsTableFilterComposer
    extends Composer<_$AppDatabase, $CheckinsTable> {
  $$CheckinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get checkedOn =>
      $composableBuilder(
        column: $table.checkedOn,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get matched => $composableBuilder(
    column: $table.matched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get untracked => $composableBuilder(
    column: $table.untracked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startingAdjustment => $composableBuilder(
    column: $table.startingAdjustment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get allowanceSpent => $composableBuilder(
    column: $table.allowanceSpent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leftAfterBuying => $composableBuilder(
    column: $table.leftAfterBuying,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextTarget => $composableBuilder(
    column: $table.nextTarget,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CheckinsTableOrderingComposer
    extends Composer<_$AppDatabase, $CheckinsTable> {
  $$CheckinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get checkedOn => $composableBuilder(
    column: $table.checkedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get matched => $composableBuilder(
    column: $table.matched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get untracked => $composableBuilder(
    column: $table.untracked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startingAdjustment => $composableBuilder(
    column: $table.startingAdjustment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get allowanceSpent => $composableBuilder(
    column: $table.allowanceSpent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leftAfterBuying => $composableBuilder(
    column: $table.leftAfterBuying,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextTarget => $composableBuilder(
    column: $table.nextTarget,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CheckinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CheckinsTable> {
  $$CheckinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<DateTime, String> get checkedOn =>
      $composableBuilder(column: $table.checkedOn, builder: (column) => column);

  GeneratedColumn<int> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<bool> get matched =>
      $composableBuilder(column: $table.matched, builder: (column) => column);

  GeneratedColumn<int> get untracked =>
      $composableBuilder(column: $table.untracked, builder: (column) => column);

  GeneratedColumn<int> get startingAdjustment => $composableBuilder(
    column: $table.startingAdjustment,
    builder: (column) => column,
  );

  GeneratedColumn<int> get allowanceSpent => $composableBuilder(
    column: $table.allowanceSpent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get leftAfterBuying => $composableBuilder(
    column: $table.leftAfterBuying,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextTarget => $composableBuilder(
    column: $table.nextTarget,
    builder: (column) => column,
  );
}

class $$CheckinsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CheckinsTable,
          Checkin,
          $$CheckinsTableFilterComposer,
          $$CheckinsTableOrderingComposer,
          $$CheckinsTableAnnotationComposer,
          $$CheckinsTableCreateCompanionBuilder,
          $$CheckinsTableUpdateCompanionBuilder,
          (Checkin, BaseReferences<_$AppDatabase, $CheckinsTable, Checkin>),
          Checkin,
          PrefetchHooks Function()
        > {
  $$CheckinsTableTableManager(_$AppDatabase db, $CheckinsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> checkedOn = const Value.absent(),
                Value<int> balance = const Value.absent(),
                Value<bool> matched = const Value.absent(),
                Value<int> untracked = const Value.absent(),
                Value<int> startingAdjustment = const Value.absent(),
                Value<int> allowanceSpent = const Value.absent(),
                Value<int?> leftAfterBuying = const Value.absent(),
                Value<int> nextTarget = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CheckinsCompanion(
                checkedOn: checkedOn,
                balance: balance,
                matched: matched,
                untracked: untracked,
                startingAdjustment: startingAdjustment,
                allowanceSpent: allowanceSpent,
                leftAfterBuying: leftAfterBuying,
                nextTarget: nextTarget,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime checkedOn,
                required int balance,
                required bool matched,
                Value<int> untracked = const Value.absent(),
                Value<int> startingAdjustment = const Value.absent(),
                required int allowanceSpent,
                Value<int?> leftAfterBuying = const Value.absent(),
                required int nextTarget,
                Value<int> rowid = const Value.absent(),
              }) => CheckinsCompanion.insert(
                checkedOn: checkedOn,
                balance: balance,
                matched: matched,
                untracked: untracked,
                startingAdjustment: startingAdjustment,
                allowanceSpent: allowanceSpent,
                leftAfterBuying: leftAfterBuying,
                nextTarget: nextTarget,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CheckinsTable, Checkin>(table),
                  BaseReferences<_$AppDatabase, $CheckinsTable, Checkin>(
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

typedef $$CheckinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CheckinsTable,
      Checkin,
      $$CheckinsTableFilterComposer,
      $$CheckinsTableOrderingComposer,
      $$CheckinsTableAnnotationComposer,
      $$CheckinsTableCreateCompanionBuilder,
      $$CheckinsTableUpdateCompanionBuilder,
      (Checkin, BaseReferences<_$AppDatabase, $CheckinsTable, Checkin>),
      Checkin,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$TransfersTableTableManager get transfers =>
      $$TransfersTableTableManager(_db, _db.transfers);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$RecurringItemsTableTableManager get recurringItems =>
      $$RecurringItemsTableTableManager(_db, _db.recurringItems);
  $$PlannedEventsTableTableManager get plannedEvents =>
      $$PlannedEventsTableTableManager(_db, _db.plannedEvents);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$WeeklyRulesTableTableManager get weeklyRules =>
      $$WeeklyRulesTableTableManager(_db, _db.weeklyRules);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$FavouritesTableTableManager get favourites =>
      $$FavouritesTableTableManager(_db, _db.favourites);
  $$CoachSettingsTableTableManager get coachSettings =>
      $$CoachSettingsTableTableManager(_db, _db.coachSettings);
  $$CoachThreadsTableTableManager get coachThreads =>
      $$CoachThreadsTableTableManager(_db, _db.coachThreads);
  $$CoachMessagesTableTableManager get coachMessages =>
      $$CoachMessagesTableTableManager(_db, _db.coachMessages);
  $$CheckinsTableTableManager get checkins =>
      $$CheckinsTableTableManager(_db, _db.checkins);
}
