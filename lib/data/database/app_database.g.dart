// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTableTable extends CategoriesTable
    with TableInfo<$CategoriesTableTable, CategoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _iconCodeMeta = const VerificationMeta(
    'iconCode',
  );
  @override
  late final GeneratedColumn<int> iconCode = GeneratedColumn<int>(
    'icon_code',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    iconCode,
    colorValue,
    type,
    isDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_code')) {
      context.handle(
        _iconCodeMeta,
        iconCode.isAcceptableOrUnknown(data['icon_code']!, _iconCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_iconCodeMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      iconCode:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}icon_code'],
          )!,
      colorValue:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}color_value'],
          )!,
      type:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}type'],
          )!,
      isDefault:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_default'],
          )!,
    );
  }

  @override
  $CategoriesTableTable createAlias(String alias) {
    return $CategoriesTableTable(attachedDatabase, alias);
  }
}

class CategoryData extends DataClass implements Insertable<CategoryData> {
  final String id;
  final String name;
  final int iconCode;
  final int colorValue;

  /// 'income', 'expense', or 'both'
  final String type;
  final bool isDefault;
  const CategoryData({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.type,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon_code'] = Variable<int>(iconCode);
    map['color_value'] = Variable<int>(colorValue);
    map['type'] = Variable<String>(type);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  CategoriesTableCompanion toCompanion(bool nullToAbsent) {
    return CategoriesTableCompanion(
      id: Value(id),
      name: Value(name),
      iconCode: Value(iconCode),
      colorValue: Value(colorValue),
      type: Value(type),
      isDefault: Value(isDefault),
    );
  }

  factory CategoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      iconCode: serializer.fromJson<int>(json['iconCode']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      type: serializer.fromJson<String>(json['type']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'iconCode': serializer.toJson<int>(iconCode),
      'colorValue': serializer.toJson<int>(colorValue),
      'type': serializer.toJson<String>(type),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  CategoryData copyWith({
    String? id,
    String? name,
    int? iconCode,
    int? colorValue,
    String? type,
    bool? isDefault,
  }) => CategoryData(
    id: id ?? this.id,
    name: name ?? this.name,
    iconCode: iconCode ?? this.iconCode,
    colorValue: colorValue ?? this.colorValue,
    type: type ?? this.type,
    isDefault: isDefault ?? this.isDefault,
  );
  CategoryData copyWithCompanion(CategoriesTableCompanion data) {
    return CategoryData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconCode: data.iconCode.present ? data.iconCode.value : this.iconCode,
      colorValue:
          data.colorValue.present ? data.colorValue.value : this.colorValue,
      type: data.type.present ? data.type.value : this.type,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconCode: $iconCode, ')
          ..write('colorValue: $colorValue, ')
          ..write('type: $type, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, iconCode, colorValue, type, isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryData &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconCode == this.iconCode &&
          other.colorValue == this.colorValue &&
          other.type == this.type &&
          other.isDefault == this.isDefault);
}

class CategoriesTableCompanion extends UpdateCompanion<CategoryData> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> iconCode;
  final Value<int> colorValue;
  final Value<String> type;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const CategoriesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.type = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesTableCompanion.insert({
    required String id,
    required String name,
    required int iconCode,
    required int colorValue,
    required String type,
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       iconCode = Value(iconCode),
       colorValue = Value(colorValue),
       type = Value(type);
  static Insertable<CategoryData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? iconCode,
    Expression<int>? colorValue,
    Expression<String>? type,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconCode != null) 'icon_code': iconCode,
      if (colorValue != null) 'color_value': colorValue,
      if (type != null) 'type': type,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? iconCode,
    Value<int>? colorValue,
    Value<String>? type,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return CategoriesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconCode.present) {
      map['icon_code'] = Variable<int>(iconCode.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconCode: $iconCode, ')
          ..write('colorValue: $colorValue, ')
          ..write('type: $type, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTableTable extends TransactionsTable
    with TableInfo<$TransactionsTableTable, TransactionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    type,
    amount,
    categoryId,
    note,
    date,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionData> instance, {
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
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
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
  TransactionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      type:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}type'],
          )!,
      amount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}amount'],
          )!,
      categoryId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}category_id'],
          )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      date:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}date'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $TransactionsTableTable createAlias(String alias) {
    return $TransactionsTableTable(attachedDatabase, alias);
  }
}

class TransactionData extends DataClass implements Insertable<TransactionData> {
  final String id;

  /// 'income' or 'expense'
  final String type;
  final double amount;
  final String categoryId;
  final String? note;

  /// User-selected date stored as epoch milliseconds (UTC midnight).
  final int date;

  /// Row creation timestamp as epoch milliseconds.
  final int createdAt;
  const TransactionData({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.note,
    required this.date,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<double>(amount);
    map['category_id'] = Variable<String>(categoryId);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['date'] = Variable<int>(date);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  TransactionsTableCompanion toCompanion(bool nullToAbsent) {
    return TransactionsTableCompanion(
      id: Value(id),
      type: Value(type),
      amount: Value(amount),
      categoryId: Value(categoryId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      date: Value(date),
      createdAt: Value(createdAt),
    );
  }

  factory TransactionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionData(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<double>(json['amount']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      note: serializer.fromJson<String?>(json['note']),
      date: serializer.fromJson<int>(json['date']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<double>(amount),
      'categoryId': serializer.toJson<String>(categoryId),
      'note': serializer.toJson<String?>(note),
      'date': serializer.toJson<int>(date),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  TransactionData copyWith({
    String? id,
    String? type,
    double? amount,
    String? categoryId,
    Value<String?> note = const Value.absent(),
    int? date,
    int? createdAt,
  }) => TransactionData(
    id: id ?? this.id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    categoryId: categoryId ?? this.categoryId,
    note: note.present ? note.value : this.note,
    date: date ?? this.date,
    createdAt: createdAt ?? this.createdAt,
  );
  TransactionData copyWithCompanion(TransactionsTableCompanion data) {
    return TransactionData(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      note: data.note.present ? data.note.value : this.note,
      date: data.date.present ? data.date.value : this.date,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionData(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, amount, categoryId, note, date, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionData &&
          other.id == this.id &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.categoryId == this.categoryId &&
          other.note == this.note &&
          other.date == this.date &&
          other.createdAt == this.createdAt);
}

class TransactionsTableCompanion extends UpdateCompanion<TransactionData> {
  final Value<String> id;
  final Value<String> type;
  final Value<double> amount;
  final Value<String> categoryId;
  final Value<String?> note;
  final Value<int> date;
  final Value<int> createdAt;
  final Value<int> rowid;
  const TransactionsTableCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.note = const Value.absent(),
    this.date = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsTableCompanion.insert({
    required String id,
    required String type,
    required double amount,
    required String categoryId,
    this.note = const Value.absent(),
    required int date,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       amount = Value(amount),
       categoryId = Value(categoryId),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<TransactionData> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<double>? amount,
    Expression<String>? categoryId,
    Expression<String>? note,
    Expression<int>? date,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (categoryId != null) 'category_id': categoryId,
      if (note != null) 'note': note,
      if (date != null) 'date': date,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<double>? amount,
    Value<String>? categoryId,
    Value<String?>? note,
    Value<int>? date,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return TransactionsTableCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
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
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsTableCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HutangTableTable extends HutangTable
    with TableInfo<$HutangTableTable, HutangData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HutangTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _namaKrediturMeta = const VerificationMeta(
    'namaKreditur',
  );
  @override
  late final GeneratedColumn<String> namaKreditur = GeneratedColumn<String>(
    'nama_kreditur',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jumlahAwalMeta = const VerificationMeta(
    'jumlahAwal',
  );
  @override
  late final GeneratedColumn<double> jumlahAwal = GeneratedColumn<double>(
    'jumlah_awal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sisaHutangMeta = const VerificationMeta(
    'sisaHutang',
  );
  @override
  late final GeneratedColumn<double> sisaHutang = GeneratedColumn<double>(
    'sisa_hutang',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tanggalPinjamMeta = const VerificationMeta(
    'tanggalPinjam',
  );
  @override
  late final GeneratedColumn<int> tanggalPinjam = GeneratedColumn<int>(
    'tanggal_pinjam',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tanggalJatuhTempoMeta = const VerificationMeta(
    'tanggalJatuhTempo',
  );
  @override
  late final GeneratedColumn<int> tanggalJatuhTempo = GeneratedColumn<int>(
    'tanggal_jatuh_tempo',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _catatanMeta = const VerificationMeta(
    'catatan',
  );
  @override
  late final GeneratedColumn<String> catatan = GeneratedColumn<String>(
    'catatan',
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
    requiredDuringInsert: false,
    defaultValue: const Constant('aktif'),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    namaKreditur,
    jumlahAwal,
    sisaHutang,
    tanggalPinjam,
    tanggalJatuhTempo,
    catatan,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hutang';
  @override
  VerificationContext validateIntegrity(
    Insertable<HutangData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nama_kreditur')) {
      context.handle(
        _namaKrediturMeta,
        namaKreditur.isAcceptableOrUnknown(
          data['nama_kreditur']!,
          _namaKrediturMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_namaKrediturMeta);
    }
    if (data.containsKey('jumlah_awal')) {
      context.handle(
        _jumlahAwalMeta,
        jumlahAwal.isAcceptableOrUnknown(data['jumlah_awal']!, _jumlahAwalMeta),
      );
    } else if (isInserting) {
      context.missing(_jumlahAwalMeta);
    }
    if (data.containsKey('sisa_hutang')) {
      context.handle(
        _sisaHutangMeta,
        sisaHutang.isAcceptableOrUnknown(data['sisa_hutang']!, _sisaHutangMeta),
      );
    } else if (isInserting) {
      context.missing(_sisaHutangMeta);
    }
    if (data.containsKey('tanggal_pinjam')) {
      context.handle(
        _tanggalPinjamMeta,
        tanggalPinjam.isAcceptableOrUnknown(
          data['tanggal_pinjam']!,
          _tanggalPinjamMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tanggalPinjamMeta);
    }
    if (data.containsKey('tanggal_jatuh_tempo')) {
      context.handle(
        _tanggalJatuhTempoMeta,
        tanggalJatuhTempo.isAcceptableOrUnknown(
          data['tanggal_jatuh_tempo']!,
          _tanggalJatuhTempoMeta,
        ),
      );
    }
    if (data.containsKey('catatan')) {
      context.handle(
        _catatanMeta,
        catatan.isAcceptableOrUnknown(data['catatan']!, _catatanMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HutangData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HutangData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      namaKreditur:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}nama_kreditur'],
          )!,
      jumlahAwal:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}jumlah_awal'],
          )!,
      sisaHutang:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}sisa_hutang'],
          )!,
      tanggalPinjam:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}tanggal_pinjam'],
          )!,
      tanggalJatuhTempo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tanggal_jatuh_tempo'],
      ),
      catatan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catatan'],
      ),
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $HutangTableTable createAlias(String alias) {
    return $HutangTableTable(attachedDatabase, alias);
  }
}

class HutangData extends DataClass implements Insertable<HutangData> {
  final String id;
  final String namaKreditur;
  final double jumlahAwal;
  final double sisaHutang;
  final int tanggalPinjam;
  final int? tanggalJatuhTempo;
  final String? catatan;
  final String status;
  final int createdAt;
  final int updatedAt;
  const HutangData({
    required this.id,
    required this.namaKreditur,
    required this.jumlahAwal,
    required this.sisaHutang,
    required this.tanggalPinjam,
    this.tanggalJatuhTempo,
    this.catatan,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nama_kreditur'] = Variable<String>(namaKreditur);
    map['jumlah_awal'] = Variable<double>(jumlahAwal);
    map['sisa_hutang'] = Variable<double>(sisaHutang);
    map['tanggal_pinjam'] = Variable<int>(tanggalPinjam);
    if (!nullToAbsent || tanggalJatuhTempo != null) {
      map['tanggal_jatuh_tempo'] = Variable<int>(tanggalJatuhTempo);
    }
    if (!nullToAbsent || catatan != null) {
      map['catatan'] = Variable<String>(catatan);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  HutangTableCompanion toCompanion(bool nullToAbsent) {
    return HutangTableCompanion(
      id: Value(id),
      namaKreditur: Value(namaKreditur),
      jumlahAwal: Value(jumlahAwal),
      sisaHutang: Value(sisaHutang),
      tanggalPinjam: Value(tanggalPinjam),
      tanggalJatuhTempo:
          tanggalJatuhTempo == null && nullToAbsent
              ? const Value.absent()
              : Value(tanggalJatuhTempo),
      catatan:
          catatan == null && nullToAbsent
              ? const Value.absent()
              : Value(catatan),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HutangData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HutangData(
      id: serializer.fromJson<String>(json['id']),
      namaKreditur: serializer.fromJson<String>(json['namaKreditur']),
      jumlahAwal: serializer.fromJson<double>(json['jumlahAwal']),
      sisaHutang: serializer.fromJson<double>(json['sisaHutang']),
      tanggalPinjam: serializer.fromJson<int>(json['tanggalPinjam']),
      tanggalJatuhTempo: serializer.fromJson<int?>(json['tanggalJatuhTempo']),
      catatan: serializer.fromJson<String?>(json['catatan']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'namaKreditur': serializer.toJson<String>(namaKreditur),
      'jumlahAwal': serializer.toJson<double>(jumlahAwal),
      'sisaHutang': serializer.toJson<double>(sisaHutang),
      'tanggalPinjam': serializer.toJson<int>(tanggalPinjam),
      'tanggalJatuhTempo': serializer.toJson<int?>(tanggalJatuhTempo),
      'catatan': serializer.toJson<String?>(catatan),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  HutangData copyWith({
    String? id,
    String? namaKreditur,
    double? jumlahAwal,
    double? sisaHutang,
    int? tanggalPinjam,
    Value<int?> tanggalJatuhTempo = const Value.absent(),
    Value<String?> catatan = const Value.absent(),
    String? status,
    int? createdAt,
    int? updatedAt,
  }) => HutangData(
    id: id ?? this.id,
    namaKreditur: namaKreditur ?? this.namaKreditur,
    jumlahAwal: jumlahAwal ?? this.jumlahAwal,
    sisaHutang: sisaHutang ?? this.sisaHutang,
    tanggalPinjam: tanggalPinjam ?? this.tanggalPinjam,
    tanggalJatuhTempo:
        tanggalJatuhTempo.present
            ? tanggalJatuhTempo.value
            : this.tanggalJatuhTempo,
    catatan: catatan.present ? catatan.value : this.catatan,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HutangData copyWithCompanion(HutangTableCompanion data) {
    return HutangData(
      id: data.id.present ? data.id.value : this.id,
      namaKreditur:
          data.namaKreditur.present
              ? data.namaKreditur.value
              : this.namaKreditur,
      jumlahAwal:
          data.jumlahAwal.present ? data.jumlahAwal.value : this.jumlahAwal,
      sisaHutang:
          data.sisaHutang.present ? data.sisaHutang.value : this.sisaHutang,
      tanggalPinjam:
          data.tanggalPinjam.present
              ? data.tanggalPinjam.value
              : this.tanggalPinjam,
      tanggalJatuhTempo:
          data.tanggalJatuhTempo.present
              ? data.tanggalJatuhTempo.value
              : this.tanggalJatuhTempo,
      catatan: data.catatan.present ? data.catatan.value : this.catatan,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HutangData(')
          ..write('id: $id, ')
          ..write('namaKreditur: $namaKreditur, ')
          ..write('jumlahAwal: $jumlahAwal, ')
          ..write('sisaHutang: $sisaHutang, ')
          ..write('tanggalPinjam: $tanggalPinjam, ')
          ..write('tanggalJatuhTempo: $tanggalJatuhTempo, ')
          ..write('catatan: $catatan, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    namaKreditur,
    jumlahAwal,
    sisaHutang,
    tanggalPinjam,
    tanggalJatuhTempo,
    catatan,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HutangData &&
          other.id == this.id &&
          other.namaKreditur == this.namaKreditur &&
          other.jumlahAwal == this.jumlahAwal &&
          other.sisaHutang == this.sisaHutang &&
          other.tanggalPinjam == this.tanggalPinjam &&
          other.tanggalJatuhTempo == this.tanggalJatuhTempo &&
          other.catatan == this.catatan &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HutangTableCompanion extends UpdateCompanion<HutangData> {
  final Value<String> id;
  final Value<String> namaKreditur;
  final Value<double> jumlahAwal;
  final Value<double> sisaHutang;
  final Value<int> tanggalPinjam;
  final Value<int?> tanggalJatuhTempo;
  final Value<String?> catatan;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const HutangTableCompanion({
    this.id = const Value.absent(),
    this.namaKreditur = const Value.absent(),
    this.jumlahAwal = const Value.absent(),
    this.sisaHutang = const Value.absent(),
    this.tanggalPinjam = const Value.absent(),
    this.tanggalJatuhTempo = const Value.absent(),
    this.catatan = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HutangTableCompanion.insert({
    required String id,
    required String namaKreditur,
    required double jumlahAwal,
    required double sisaHutang,
    required int tanggalPinjam,
    this.tanggalJatuhTempo = const Value.absent(),
    this.catatan = const Value.absent(),
    this.status = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       namaKreditur = Value(namaKreditur),
       jumlahAwal = Value(jumlahAwal),
       sisaHutang = Value(sisaHutang),
       tanggalPinjam = Value(tanggalPinjam),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<HutangData> custom({
    Expression<String>? id,
    Expression<String>? namaKreditur,
    Expression<double>? jumlahAwal,
    Expression<double>? sisaHutang,
    Expression<int>? tanggalPinjam,
    Expression<int>? tanggalJatuhTempo,
    Expression<String>? catatan,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (namaKreditur != null) 'nama_kreditur': namaKreditur,
      if (jumlahAwal != null) 'jumlah_awal': jumlahAwal,
      if (sisaHutang != null) 'sisa_hutang': sisaHutang,
      if (tanggalPinjam != null) 'tanggal_pinjam': tanggalPinjam,
      if (tanggalJatuhTempo != null) 'tanggal_jatuh_tempo': tanggalJatuhTempo,
      if (catatan != null) 'catatan': catatan,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HutangTableCompanion copyWith({
    Value<String>? id,
    Value<String>? namaKreditur,
    Value<double>? jumlahAwal,
    Value<double>? sisaHutang,
    Value<int>? tanggalPinjam,
    Value<int?>? tanggalJatuhTempo,
    Value<String?>? catatan,
    Value<String>? status,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return HutangTableCompanion(
      id: id ?? this.id,
      namaKreditur: namaKreditur ?? this.namaKreditur,
      jumlahAwal: jumlahAwal ?? this.jumlahAwal,
      sisaHutang: sisaHutang ?? this.sisaHutang,
      tanggalPinjam: tanggalPinjam ?? this.tanggalPinjam,
      tanggalJatuhTempo: tanggalJatuhTempo ?? this.tanggalJatuhTempo,
      catatan: catatan ?? this.catatan,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (namaKreditur.present) {
      map['nama_kreditur'] = Variable<String>(namaKreditur.value);
    }
    if (jumlahAwal.present) {
      map['jumlah_awal'] = Variable<double>(jumlahAwal.value);
    }
    if (sisaHutang.present) {
      map['sisa_hutang'] = Variable<double>(sisaHutang.value);
    }
    if (tanggalPinjam.present) {
      map['tanggal_pinjam'] = Variable<int>(tanggalPinjam.value);
    }
    if (tanggalJatuhTempo.present) {
      map['tanggal_jatuh_tempo'] = Variable<int>(tanggalJatuhTempo.value);
    }
    if (catatan.present) {
      map['catatan'] = Variable<String>(catatan.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HutangTableCompanion(')
          ..write('id: $id, ')
          ..write('namaKreditur: $namaKreditur, ')
          ..write('jumlahAwal: $jumlahAwal, ')
          ..write('sisaHutang: $sisaHutang, ')
          ..write('tanggalPinjam: $tanggalPinjam, ')
          ..write('tanggalJatuhTempo: $tanggalJatuhTempo, ')
          ..write('catatan: $catatan, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PiutangTableTable extends PiutangTable
    with TableInfo<$PiutangTableTable, PiutangData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PiutangTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _namaPeminjamMeta = const VerificationMeta(
    'namaPeminjam',
  );
  @override
  late final GeneratedColumn<String> namaPeminjam = GeneratedColumn<String>(
    'nama_peminjam',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jumlahAwalMeta = const VerificationMeta(
    'jumlahAwal',
  );
  @override
  late final GeneratedColumn<double> jumlahAwal = GeneratedColumn<double>(
    'jumlah_awal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sisaPiutangMeta = const VerificationMeta(
    'sisaPiutang',
  );
  @override
  late final GeneratedColumn<double> sisaPiutang = GeneratedColumn<double>(
    'sisa_piutang',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tanggalPinjamMeta = const VerificationMeta(
    'tanggalPinjam',
  );
  @override
  late final GeneratedColumn<int> tanggalPinjam = GeneratedColumn<int>(
    'tanggal_pinjam',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tanggalJatuhTempoMeta = const VerificationMeta(
    'tanggalJatuhTempo',
  );
  @override
  late final GeneratedColumn<int> tanggalJatuhTempo = GeneratedColumn<int>(
    'tanggal_jatuh_tempo',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _catatanMeta = const VerificationMeta(
    'catatan',
  );
  @override
  late final GeneratedColumn<String> catatan = GeneratedColumn<String>(
    'catatan',
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
    requiredDuringInsert: false,
    defaultValue: const Constant('aktif'),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    namaPeminjam,
    jumlahAwal,
    sisaPiutang,
    tanggalPinjam,
    tanggalJatuhTempo,
    catatan,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'piutang';
  @override
  VerificationContext validateIntegrity(
    Insertable<PiutangData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nama_peminjam')) {
      context.handle(
        _namaPeminjamMeta,
        namaPeminjam.isAcceptableOrUnknown(
          data['nama_peminjam']!,
          _namaPeminjamMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_namaPeminjamMeta);
    }
    if (data.containsKey('jumlah_awal')) {
      context.handle(
        _jumlahAwalMeta,
        jumlahAwal.isAcceptableOrUnknown(data['jumlah_awal']!, _jumlahAwalMeta),
      );
    } else if (isInserting) {
      context.missing(_jumlahAwalMeta);
    }
    if (data.containsKey('sisa_piutang')) {
      context.handle(
        _sisaPiutangMeta,
        sisaPiutang.isAcceptableOrUnknown(
          data['sisa_piutang']!,
          _sisaPiutangMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sisaPiutangMeta);
    }
    if (data.containsKey('tanggal_pinjam')) {
      context.handle(
        _tanggalPinjamMeta,
        tanggalPinjam.isAcceptableOrUnknown(
          data['tanggal_pinjam']!,
          _tanggalPinjamMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tanggalPinjamMeta);
    }
    if (data.containsKey('tanggal_jatuh_tempo')) {
      context.handle(
        _tanggalJatuhTempoMeta,
        tanggalJatuhTempo.isAcceptableOrUnknown(
          data['tanggal_jatuh_tempo']!,
          _tanggalJatuhTempoMeta,
        ),
      );
    }
    if (data.containsKey('catatan')) {
      context.handle(
        _catatanMeta,
        catatan.isAcceptableOrUnknown(data['catatan']!, _catatanMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PiutangData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PiutangData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      namaPeminjam:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}nama_peminjam'],
          )!,
      jumlahAwal:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}jumlah_awal'],
          )!,
      sisaPiutang:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}sisa_piutang'],
          )!,
      tanggalPinjam:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}tanggal_pinjam'],
          )!,
      tanggalJatuhTempo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tanggal_jatuh_tempo'],
      ),
      catatan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catatan'],
      ),
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $PiutangTableTable createAlias(String alias) {
    return $PiutangTableTable(attachedDatabase, alias);
  }
}

class PiutangData extends DataClass implements Insertable<PiutangData> {
  final String id;
  final String namaPeminjam;
  final double jumlahAwal;
  final double sisaPiutang;
  final int tanggalPinjam;
  final int? tanggalJatuhTempo;
  final String? catatan;
  final String status;
  final int createdAt;
  final int updatedAt;
  const PiutangData({
    required this.id,
    required this.namaPeminjam,
    required this.jumlahAwal,
    required this.sisaPiutang,
    required this.tanggalPinjam,
    this.tanggalJatuhTempo,
    this.catatan,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nama_peminjam'] = Variable<String>(namaPeminjam);
    map['jumlah_awal'] = Variable<double>(jumlahAwal);
    map['sisa_piutang'] = Variable<double>(sisaPiutang);
    map['tanggal_pinjam'] = Variable<int>(tanggalPinjam);
    if (!nullToAbsent || tanggalJatuhTempo != null) {
      map['tanggal_jatuh_tempo'] = Variable<int>(tanggalJatuhTempo);
    }
    if (!nullToAbsent || catatan != null) {
      map['catatan'] = Variable<String>(catatan);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PiutangTableCompanion toCompanion(bool nullToAbsent) {
    return PiutangTableCompanion(
      id: Value(id),
      namaPeminjam: Value(namaPeminjam),
      jumlahAwal: Value(jumlahAwal),
      sisaPiutang: Value(sisaPiutang),
      tanggalPinjam: Value(tanggalPinjam),
      tanggalJatuhTempo:
          tanggalJatuhTempo == null && nullToAbsent
              ? const Value.absent()
              : Value(tanggalJatuhTempo),
      catatan:
          catatan == null && nullToAbsent
              ? const Value.absent()
              : Value(catatan),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PiutangData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PiutangData(
      id: serializer.fromJson<String>(json['id']),
      namaPeminjam: serializer.fromJson<String>(json['namaPeminjam']),
      jumlahAwal: serializer.fromJson<double>(json['jumlahAwal']),
      sisaPiutang: serializer.fromJson<double>(json['sisaPiutang']),
      tanggalPinjam: serializer.fromJson<int>(json['tanggalPinjam']),
      tanggalJatuhTempo: serializer.fromJson<int?>(json['tanggalJatuhTempo']),
      catatan: serializer.fromJson<String?>(json['catatan']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'namaPeminjam': serializer.toJson<String>(namaPeminjam),
      'jumlahAwal': serializer.toJson<double>(jumlahAwal),
      'sisaPiutang': serializer.toJson<double>(sisaPiutang),
      'tanggalPinjam': serializer.toJson<int>(tanggalPinjam),
      'tanggalJatuhTempo': serializer.toJson<int?>(tanggalJatuhTempo),
      'catatan': serializer.toJson<String?>(catatan),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  PiutangData copyWith({
    String? id,
    String? namaPeminjam,
    double? jumlahAwal,
    double? sisaPiutang,
    int? tanggalPinjam,
    Value<int?> tanggalJatuhTempo = const Value.absent(),
    Value<String?> catatan = const Value.absent(),
    String? status,
    int? createdAt,
    int? updatedAt,
  }) => PiutangData(
    id: id ?? this.id,
    namaPeminjam: namaPeminjam ?? this.namaPeminjam,
    jumlahAwal: jumlahAwal ?? this.jumlahAwal,
    sisaPiutang: sisaPiutang ?? this.sisaPiutang,
    tanggalPinjam: tanggalPinjam ?? this.tanggalPinjam,
    tanggalJatuhTempo:
        tanggalJatuhTempo.present
            ? tanggalJatuhTempo.value
            : this.tanggalJatuhTempo,
    catatan: catatan.present ? catatan.value : this.catatan,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PiutangData copyWithCompanion(PiutangTableCompanion data) {
    return PiutangData(
      id: data.id.present ? data.id.value : this.id,
      namaPeminjam:
          data.namaPeminjam.present
              ? data.namaPeminjam.value
              : this.namaPeminjam,
      jumlahAwal:
          data.jumlahAwal.present ? data.jumlahAwal.value : this.jumlahAwal,
      sisaPiutang:
          data.sisaPiutang.present ? data.sisaPiutang.value : this.sisaPiutang,
      tanggalPinjam:
          data.tanggalPinjam.present
              ? data.tanggalPinjam.value
              : this.tanggalPinjam,
      tanggalJatuhTempo:
          data.tanggalJatuhTempo.present
              ? data.tanggalJatuhTempo.value
              : this.tanggalJatuhTempo,
      catatan: data.catatan.present ? data.catatan.value : this.catatan,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PiutangData(')
          ..write('id: $id, ')
          ..write('namaPeminjam: $namaPeminjam, ')
          ..write('jumlahAwal: $jumlahAwal, ')
          ..write('sisaPiutang: $sisaPiutang, ')
          ..write('tanggalPinjam: $tanggalPinjam, ')
          ..write('tanggalJatuhTempo: $tanggalJatuhTempo, ')
          ..write('catatan: $catatan, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    namaPeminjam,
    jumlahAwal,
    sisaPiutang,
    tanggalPinjam,
    tanggalJatuhTempo,
    catatan,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PiutangData &&
          other.id == this.id &&
          other.namaPeminjam == this.namaPeminjam &&
          other.jumlahAwal == this.jumlahAwal &&
          other.sisaPiutang == this.sisaPiutang &&
          other.tanggalPinjam == this.tanggalPinjam &&
          other.tanggalJatuhTempo == this.tanggalJatuhTempo &&
          other.catatan == this.catatan &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PiutangTableCompanion extends UpdateCompanion<PiutangData> {
  final Value<String> id;
  final Value<String> namaPeminjam;
  final Value<double> jumlahAwal;
  final Value<double> sisaPiutang;
  final Value<int> tanggalPinjam;
  final Value<int?> tanggalJatuhTempo;
  final Value<String?> catatan;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const PiutangTableCompanion({
    this.id = const Value.absent(),
    this.namaPeminjam = const Value.absent(),
    this.jumlahAwal = const Value.absent(),
    this.sisaPiutang = const Value.absent(),
    this.tanggalPinjam = const Value.absent(),
    this.tanggalJatuhTempo = const Value.absent(),
    this.catatan = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PiutangTableCompanion.insert({
    required String id,
    required String namaPeminjam,
    required double jumlahAwal,
    required double sisaPiutang,
    required int tanggalPinjam,
    this.tanggalJatuhTempo = const Value.absent(),
    this.catatan = const Value.absent(),
    this.status = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       namaPeminjam = Value(namaPeminjam),
       jumlahAwal = Value(jumlahAwal),
       sisaPiutang = Value(sisaPiutang),
       tanggalPinjam = Value(tanggalPinjam),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PiutangData> custom({
    Expression<String>? id,
    Expression<String>? namaPeminjam,
    Expression<double>? jumlahAwal,
    Expression<double>? sisaPiutang,
    Expression<int>? tanggalPinjam,
    Expression<int>? tanggalJatuhTempo,
    Expression<String>? catatan,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (namaPeminjam != null) 'nama_peminjam': namaPeminjam,
      if (jumlahAwal != null) 'jumlah_awal': jumlahAwal,
      if (sisaPiutang != null) 'sisa_piutang': sisaPiutang,
      if (tanggalPinjam != null) 'tanggal_pinjam': tanggalPinjam,
      if (tanggalJatuhTempo != null) 'tanggal_jatuh_tempo': tanggalJatuhTempo,
      if (catatan != null) 'catatan': catatan,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PiutangTableCompanion copyWith({
    Value<String>? id,
    Value<String>? namaPeminjam,
    Value<double>? jumlahAwal,
    Value<double>? sisaPiutang,
    Value<int>? tanggalPinjam,
    Value<int?>? tanggalJatuhTempo,
    Value<String?>? catatan,
    Value<String>? status,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return PiutangTableCompanion(
      id: id ?? this.id,
      namaPeminjam: namaPeminjam ?? this.namaPeminjam,
      jumlahAwal: jumlahAwal ?? this.jumlahAwal,
      sisaPiutang: sisaPiutang ?? this.sisaPiutang,
      tanggalPinjam: tanggalPinjam ?? this.tanggalPinjam,
      tanggalJatuhTempo: tanggalJatuhTempo ?? this.tanggalJatuhTempo,
      catatan: catatan ?? this.catatan,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (namaPeminjam.present) {
      map['nama_peminjam'] = Variable<String>(namaPeminjam.value);
    }
    if (jumlahAwal.present) {
      map['jumlah_awal'] = Variable<double>(jumlahAwal.value);
    }
    if (sisaPiutang.present) {
      map['sisa_piutang'] = Variable<double>(sisaPiutang.value);
    }
    if (tanggalPinjam.present) {
      map['tanggal_pinjam'] = Variable<int>(tanggalPinjam.value);
    }
    if (tanggalJatuhTempo.present) {
      map['tanggal_jatuh_tempo'] = Variable<int>(tanggalJatuhTempo.value);
    }
    if (catatan.present) {
      map['catatan'] = Variable<String>(catatan.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PiutangTableCompanion(')
          ..write('id: $id, ')
          ..write('namaPeminjam: $namaPeminjam, ')
          ..write('jumlahAwal: $jumlahAwal, ')
          ..write('sisaPiutang: $sisaPiutang, ')
          ..write('tanggalPinjam: $tanggalPinjam, ')
          ..write('tanggalJatuhTempo: $tanggalJatuhTempo, ')
          ..write('catatan: $catatan, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentHistoryTableTable extends PaymentHistoryTable
    with TableInfo<$PaymentHistoryTableTable, PaymentHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceIdMeta = const VerificationMeta(
    'referenceId',
  );
  @override
  late final GeneratedColumn<String> referenceId = GeneratedColumn<String>(
    'reference_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceTypeMeta = const VerificationMeta(
    'referenceType',
  );
  @override
  late final GeneratedColumn<String> referenceType = GeneratedColumn<String>(
    'reference_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<int> paidAt = GeneratedColumn<int>(
    'paid_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catatanMeta = const VerificationMeta(
    'catatan',
  );
  @override
  late final GeneratedColumn<String> catatan = GeneratedColumn<String>(
    'catatan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    referenceId,
    referenceType,
    amount,
    paidAt,
    catatan,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payment_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('reference_id')) {
      context.handle(
        _referenceIdMeta,
        referenceId.isAcceptableOrUnknown(
          data['reference_id']!,
          _referenceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceIdMeta);
    }
    if (data.containsKey('reference_type')) {
      context.handle(
        _referenceTypeMeta,
        referenceType.isAcceptableOrUnknown(
          data['reference_type']!,
          _referenceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceTypeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('paid_at')) {
      context.handle(
        _paidAtMeta,
        paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta),
      );
    } else if (isInserting) {
      context.missing(_paidAtMeta);
    }
    if (data.containsKey('catatan')) {
      context.handle(
        _catatanMeta,
        catatan.isAcceptableOrUnknown(data['catatan']!, _catatanMeta),
      );
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
  PaymentHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentHistoryData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      referenceId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}reference_id'],
          )!,
      referenceType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}reference_type'],
          )!,
      amount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}amount'],
          )!,
      paidAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}paid_at'],
          )!,
      catatan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catatan'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $PaymentHistoryTableTable createAlias(String alias) {
    return $PaymentHistoryTableTable(attachedDatabase, alias);
  }
}

class PaymentHistoryData extends DataClass
    implements Insertable<PaymentHistoryData> {
  final String id;
  final String referenceId;
  final String referenceType;
  final double amount;
  final int paidAt;
  final String? catatan;
  final int createdAt;
  const PaymentHistoryData({
    required this.id,
    required this.referenceId,
    required this.referenceType,
    required this.amount,
    required this.paidAt,
    this.catatan,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['reference_id'] = Variable<String>(referenceId);
    map['reference_type'] = Variable<String>(referenceType);
    map['amount'] = Variable<double>(amount);
    map['paid_at'] = Variable<int>(paidAt);
    if (!nullToAbsent || catatan != null) {
      map['catatan'] = Variable<String>(catatan);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PaymentHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return PaymentHistoryTableCompanion(
      id: Value(id),
      referenceId: Value(referenceId),
      referenceType: Value(referenceType),
      amount: Value(amount),
      paidAt: Value(paidAt),
      catatan:
          catatan == null && nullToAbsent
              ? const Value.absent()
              : Value(catatan),
      createdAt: Value(createdAt),
    );
  }

  factory PaymentHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentHistoryData(
      id: serializer.fromJson<String>(json['id']),
      referenceId: serializer.fromJson<String>(json['referenceId']),
      referenceType: serializer.fromJson<String>(json['referenceType']),
      amount: serializer.fromJson<double>(json['amount']),
      paidAt: serializer.fromJson<int>(json['paidAt']),
      catatan: serializer.fromJson<String?>(json['catatan']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'referenceId': serializer.toJson<String>(referenceId),
      'referenceType': serializer.toJson<String>(referenceType),
      'amount': serializer.toJson<double>(amount),
      'paidAt': serializer.toJson<int>(paidAt),
      'catatan': serializer.toJson<String?>(catatan),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PaymentHistoryData copyWith({
    String? id,
    String? referenceId,
    String? referenceType,
    double? amount,
    int? paidAt,
    Value<String?> catatan = const Value.absent(),
    int? createdAt,
  }) => PaymentHistoryData(
    id: id ?? this.id,
    referenceId: referenceId ?? this.referenceId,
    referenceType: referenceType ?? this.referenceType,
    amount: amount ?? this.amount,
    paidAt: paidAt ?? this.paidAt,
    catatan: catatan.present ? catatan.value : this.catatan,
    createdAt: createdAt ?? this.createdAt,
  );
  PaymentHistoryData copyWithCompanion(PaymentHistoryTableCompanion data) {
    return PaymentHistoryData(
      id: data.id.present ? data.id.value : this.id,
      referenceId:
          data.referenceId.present ? data.referenceId.value : this.referenceId,
      referenceType:
          data.referenceType.present
              ? data.referenceType.value
              : this.referenceType,
      amount: data.amount.present ? data.amount.value : this.amount,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      catatan: data.catatan.present ? data.catatan.value : this.catatan,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentHistoryData(')
          ..write('id: $id, ')
          ..write('referenceId: $referenceId, ')
          ..write('referenceType: $referenceType, ')
          ..write('amount: $amount, ')
          ..write('paidAt: $paidAt, ')
          ..write('catatan: $catatan, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    referenceId,
    referenceType,
    amount,
    paidAt,
    catatan,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentHistoryData &&
          other.id == this.id &&
          other.referenceId == this.referenceId &&
          other.referenceType == this.referenceType &&
          other.amount == this.amount &&
          other.paidAt == this.paidAt &&
          other.catatan == this.catatan &&
          other.createdAt == this.createdAt);
}

class PaymentHistoryTableCompanion extends UpdateCompanion<PaymentHistoryData> {
  final Value<String> id;
  final Value<String> referenceId;
  final Value<String> referenceType;
  final Value<double> amount;
  final Value<int> paidAt;
  final Value<String?> catatan;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PaymentHistoryTableCompanion({
    this.id = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.referenceType = const Value.absent(),
    this.amount = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.catatan = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentHistoryTableCompanion.insert({
    required String id,
    required String referenceId,
    required String referenceType,
    required double amount,
    required int paidAt,
    this.catatan = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       referenceId = Value(referenceId),
       referenceType = Value(referenceType),
       amount = Value(amount),
       paidAt = Value(paidAt),
       createdAt = Value(createdAt);
  static Insertable<PaymentHistoryData> custom({
    Expression<String>? id,
    Expression<String>? referenceId,
    Expression<String>? referenceType,
    Expression<double>? amount,
    Expression<int>? paidAt,
    Expression<String>? catatan,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (referenceId != null) 'reference_id': referenceId,
      if (referenceType != null) 'reference_type': referenceType,
      if (amount != null) 'amount': amount,
      if (paidAt != null) 'paid_at': paidAt,
      if (catatan != null) 'catatan': catatan,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentHistoryTableCompanion copyWith({
    Value<String>? id,
    Value<String>? referenceId,
    Value<String>? referenceType,
    Value<double>? amount,
    Value<int>? paidAt,
    Value<String?>? catatan,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return PaymentHistoryTableCompanion(
      id: id ?? this.id,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      amount: amount ?? this.amount,
      paidAt: paidAt ?? this.paidAt,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (referenceId.present) {
      map['reference_id'] = Variable<String>(referenceId.value);
    }
    if (referenceType.present) {
      map['reference_type'] = Variable<String>(referenceType.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<int>(paidAt.value);
    }
    if (catatan.present) {
      map['catatan'] = Variable<String>(catatan.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentHistoryTableCompanion(')
          ..write('id: $id, ')
          ..write('referenceId: $referenceId, ')
          ..write('referenceType: $referenceType, ')
          ..write('amount: $amount, ')
          ..write('paidAt: $paidAt, ')
          ..write('catatan: $catatan, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTableTable categoriesTable = $CategoriesTableTable(
    this,
  );
  late final $TransactionsTableTable transactionsTable =
      $TransactionsTableTable(this);
  late final $HutangTableTable hutangTable = $HutangTableTable(this);
  late final $PiutangTableTable piutangTable = $PiutangTableTable(this);
  late final $PaymentHistoryTableTable paymentHistoryTable =
      $PaymentHistoryTableTable(this);
  late final CategoryDao categoryDao = CategoryDao(this as AppDatabase);
  late final TransactionDao transactionDao = TransactionDao(
    this as AppDatabase,
  );
  late final HutangDao hutangDao = HutangDao(this as AppDatabase);
  late final PiutangDao piutangDao = PiutangDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categoriesTable,
    transactionsTable,
    hutangTable,
    piutangTable,
    paymentHistoryTable,
  ];
}

typedef $$CategoriesTableTableCreateCompanionBuilder =
    CategoriesTableCompanion Function({
      required String id,
      required String name,
      required int iconCode,
      required int colorValue,
      required String type,
      Value<bool> isDefault,
      Value<int> rowid,
    });
typedef $$CategoriesTableTableUpdateCompanionBuilder =
    CategoriesTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> iconCode,
      Value<int> colorValue,
      Value<String> type,
      Value<bool> isDefault,
      Value<int> rowid,
    });

final class $$CategoriesTableTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTableTable, CategoryData> {
  $$CategoriesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TransactionsTableTable, List<TransactionData>>
  _transactionsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transactionsTable,
        aliasName: $_aliasNameGenerator(
          db.categoriesTable.id,
          db.transactionsTable.categoryId,
        ),
      );

  $$TransactionsTableTableProcessedTableManager get transactionsTableRefs {
    final manager = $$TransactionsTableTableTableManager(
      $_db,
      $_db.transactionsTable,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsTableRefs(
    Expression<bool> Function($$TransactionsTableTableFilterComposer f) f,
  ) {
    final $$TransactionsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionsTable,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableTableFilterComposer(
            $db: $db,
            $table: $db.transactionsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get iconCode =>
      $composableBuilder(column: $table.iconCode, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  Expression<T> transactionsTableRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionsTable,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CategoriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTableTable,
          CategoryData,
          $$CategoriesTableTableFilterComposer,
          $$CategoriesTableTableOrderingComposer,
          $$CategoriesTableTableAnnotationComposer,
          $$CategoriesTableTableCreateCompanionBuilder,
          $$CategoriesTableTableUpdateCompanionBuilder,
          (CategoryData, $$CategoriesTableTableReferences),
          CategoryData,
          PrefetchHooks Function({bool transactionsTableRefs})
        > {
  $$CategoriesTableTableTableManager(
    _$AppDatabase db,
    $CategoriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$CategoriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CategoriesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$CategoriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> iconCode = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesTableCompanion(
                id: id,
                name: name,
                iconCode: iconCode,
                colorValue: colorValue,
                type: type,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int iconCode,
                required int colorValue,
                required String type,
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesTableCompanion.insert(
                id: id,
                name: name,
                iconCode: iconCode,
                colorValue: colorValue,
                type: type,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$CategoriesTableTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({transactionsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (transactionsTableRefs) db.transactionsTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsTableRefs)
                    await $_getPrefetchedData<
                      CategoryData,
                      $CategoriesTableTable,
                      TransactionData
                    >(
                      currentTable: table,
                      referencedTable: $$CategoriesTableTableReferences
                          ._transactionsTableRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$CategoriesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsTableRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.categoryId == item.id,
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

typedef $$CategoriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTableTable,
      CategoryData,
      $$CategoriesTableTableFilterComposer,
      $$CategoriesTableTableOrderingComposer,
      $$CategoriesTableTableAnnotationComposer,
      $$CategoriesTableTableCreateCompanionBuilder,
      $$CategoriesTableTableUpdateCompanionBuilder,
      (CategoryData, $$CategoriesTableTableReferences),
      CategoryData,
      PrefetchHooks Function({bool transactionsTableRefs})
    >;
typedef $$TransactionsTableTableCreateCompanionBuilder =
    TransactionsTableCompanion Function({
      required String id,
      required String type,
      required double amount,
      required String categoryId,
      Value<String?> note,
      required int date,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableTableUpdateCompanionBuilder =
    TransactionsTableCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<double> amount,
      Value<String> categoryId,
      Value<String?> note,
      Value<int> date,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$TransactionsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TransactionsTableTable,
          TransactionData
        > {
  $$TransactionsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CategoriesTableTable _categoryIdTable(_$AppDatabase db) =>
      db.categoriesTable.createAlias(
        $_aliasNameGenerator(
          db.transactionsTable.categoryId,
          db.categoriesTable.id,
        ),
      );

  $$CategoriesTableTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$CategoriesTableTableTableManager(
      $_db,
      $_db.categoriesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableFilterComposer({
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

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableTableFilterComposer get categoryId {
    final $$CategoriesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categoriesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableTableFilterComposer(
            $db: $db,
            $table: $db.categoriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableOrderingComposer({
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

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableTableOrderingComposer get categoryId {
    final $$CategoriesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categoriesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableTableOrderingComposer(
            $db: $db,
            $table: $db.categoriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableAnnotationComposer({
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

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CategoriesTableTableAnnotationComposer get categoryId {
    final $$CategoriesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categoriesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.categoriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTableTable,
          TransactionData,
          $$TransactionsTableTableFilterComposer,
          $$TransactionsTableTableOrderingComposer,
          $$TransactionsTableTableAnnotationComposer,
          $$TransactionsTableTableCreateCompanionBuilder,
          $$TransactionsTableTableUpdateCompanionBuilder,
          (TransactionData, $$TransactionsTableTableReferences),
          TransactionData,
          PrefetchHooks Function({bool categoryId})
        > {
  $$TransactionsTableTableTableManager(
    _$AppDatabase db,
    $TransactionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$TransactionsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$TransactionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$TransactionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsTableCompanion(
                id: id,
                type: type,
                amount: amount,
                categoryId: categoryId,
                note: note,
                date: date,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required double amount,
                required String categoryId,
                Value<String?> note = const Value.absent(),
                required int date,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TransactionsTableCompanion.insert(
                id: id,
                type: type,
                amount: amount,
                categoryId: categoryId,
                note: note,
                date: date,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$TransactionsTableTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                if (categoryId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$TransactionsTableTableReferences
                                ._categoryIdTable(db),
                            referencedColumn:
                                $$TransactionsTableTableReferences
                                    ._categoryIdTable(db)
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

typedef $$TransactionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTableTable,
      TransactionData,
      $$TransactionsTableTableFilterComposer,
      $$TransactionsTableTableOrderingComposer,
      $$TransactionsTableTableAnnotationComposer,
      $$TransactionsTableTableCreateCompanionBuilder,
      $$TransactionsTableTableUpdateCompanionBuilder,
      (TransactionData, $$TransactionsTableTableReferences),
      TransactionData,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$HutangTableTableCreateCompanionBuilder =
    HutangTableCompanion Function({
      required String id,
      required String namaKreditur,
      required double jumlahAwal,
      required double sisaHutang,
      required int tanggalPinjam,
      Value<int?> tanggalJatuhTempo,
      Value<String?> catatan,
      Value<String> status,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$HutangTableTableUpdateCompanionBuilder =
    HutangTableCompanion Function({
      Value<String> id,
      Value<String> namaKreditur,
      Value<double> jumlahAwal,
      Value<double> sisaHutang,
      Value<int> tanggalPinjam,
      Value<int?> tanggalJatuhTempo,
      Value<String?> catatan,
      Value<String> status,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$HutangTableTableFilterComposer
    extends Composer<_$AppDatabase, $HutangTableTable> {
  $$HutangTableTableFilterComposer({
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

  ColumnFilters<String> get namaKreditur => $composableBuilder(
    column: $table.namaKreditur,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get jumlahAwal => $composableBuilder(
    column: $table.jumlahAwal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sisaHutang => $composableBuilder(
    column: $table.sisaHutang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tanggalPinjam => $composableBuilder(
    column: $table.tanggalPinjam,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tanggalJatuhTempo => $composableBuilder(
    column: $table.tanggalJatuhTempo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HutangTableTableOrderingComposer
    extends Composer<_$AppDatabase, $HutangTableTable> {
  $$HutangTableTableOrderingComposer({
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

  ColumnOrderings<String> get namaKreditur => $composableBuilder(
    column: $table.namaKreditur,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get jumlahAwal => $composableBuilder(
    column: $table.jumlahAwal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sisaHutang => $composableBuilder(
    column: $table.sisaHutang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tanggalPinjam => $composableBuilder(
    column: $table.tanggalPinjam,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tanggalJatuhTempo => $composableBuilder(
    column: $table.tanggalJatuhTempo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HutangTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $HutangTableTable> {
  $$HutangTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get namaKreditur => $composableBuilder(
    column: $table.namaKreditur,
    builder: (column) => column,
  );

  GeneratedColumn<double> get jumlahAwal => $composableBuilder(
    column: $table.jumlahAwal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sisaHutang => $composableBuilder(
    column: $table.sisaHutang,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tanggalPinjam => $composableBuilder(
    column: $table.tanggalPinjam,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tanggalJatuhTempo => $composableBuilder(
    column: $table.tanggalJatuhTempo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get catatan =>
      $composableBuilder(column: $table.catatan, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$HutangTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HutangTableTable,
          HutangData,
          $$HutangTableTableFilterComposer,
          $$HutangTableTableOrderingComposer,
          $$HutangTableTableAnnotationComposer,
          $$HutangTableTableCreateCompanionBuilder,
          $$HutangTableTableUpdateCompanionBuilder,
          (
            HutangData,
            BaseReferences<_$AppDatabase, $HutangTableTable, HutangData>,
          ),
          HutangData,
          PrefetchHooks Function()
        > {
  $$HutangTableTableTableManager(_$AppDatabase db, $HutangTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$HutangTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$HutangTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$HutangTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> namaKreditur = const Value.absent(),
                Value<double> jumlahAwal = const Value.absent(),
                Value<double> sisaHutang = const Value.absent(),
                Value<int> tanggalPinjam = const Value.absent(),
                Value<int?> tanggalJatuhTempo = const Value.absent(),
                Value<String?> catatan = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HutangTableCompanion(
                id: id,
                namaKreditur: namaKreditur,
                jumlahAwal: jumlahAwal,
                sisaHutang: sisaHutang,
                tanggalPinjam: tanggalPinjam,
                tanggalJatuhTempo: tanggalJatuhTempo,
                catatan: catatan,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String namaKreditur,
                required double jumlahAwal,
                required double sisaHutang,
                required int tanggalPinjam,
                Value<int?> tanggalJatuhTempo = const Value.absent(),
                Value<String?> catatan = const Value.absent(),
                Value<String> status = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => HutangTableCompanion.insert(
                id: id,
                namaKreditur: namaKreditur,
                jumlahAwal: jumlahAwal,
                sisaHutang: sisaHutang,
                tanggalPinjam: tanggalPinjam,
                tanggalJatuhTempo: tanggalJatuhTempo,
                catatan: catatan,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HutangTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HutangTableTable,
      HutangData,
      $$HutangTableTableFilterComposer,
      $$HutangTableTableOrderingComposer,
      $$HutangTableTableAnnotationComposer,
      $$HutangTableTableCreateCompanionBuilder,
      $$HutangTableTableUpdateCompanionBuilder,
      (
        HutangData,
        BaseReferences<_$AppDatabase, $HutangTableTable, HutangData>,
      ),
      HutangData,
      PrefetchHooks Function()
    >;
typedef $$PiutangTableTableCreateCompanionBuilder =
    PiutangTableCompanion Function({
      required String id,
      required String namaPeminjam,
      required double jumlahAwal,
      required double sisaPiutang,
      required int tanggalPinjam,
      Value<int?> tanggalJatuhTempo,
      Value<String?> catatan,
      Value<String> status,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$PiutangTableTableUpdateCompanionBuilder =
    PiutangTableCompanion Function({
      Value<String> id,
      Value<String> namaPeminjam,
      Value<double> jumlahAwal,
      Value<double> sisaPiutang,
      Value<int> tanggalPinjam,
      Value<int?> tanggalJatuhTempo,
      Value<String?> catatan,
      Value<String> status,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$PiutangTableTableFilterComposer
    extends Composer<_$AppDatabase, $PiutangTableTable> {
  $$PiutangTableTableFilterComposer({
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

  ColumnFilters<String> get namaPeminjam => $composableBuilder(
    column: $table.namaPeminjam,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get jumlahAwal => $composableBuilder(
    column: $table.jumlahAwal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sisaPiutang => $composableBuilder(
    column: $table.sisaPiutang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tanggalPinjam => $composableBuilder(
    column: $table.tanggalPinjam,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tanggalJatuhTempo => $composableBuilder(
    column: $table.tanggalJatuhTempo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PiutangTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PiutangTableTable> {
  $$PiutangTableTableOrderingComposer({
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

  ColumnOrderings<String> get namaPeminjam => $composableBuilder(
    column: $table.namaPeminjam,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get jumlahAwal => $composableBuilder(
    column: $table.jumlahAwal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sisaPiutang => $composableBuilder(
    column: $table.sisaPiutang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tanggalPinjam => $composableBuilder(
    column: $table.tanggalPinjam,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tanggalJatuhTempo => $composableBuilder(
    column: $table.tanggalJatuhTempo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PiutangTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PiutangTableTable> {
  $$PiutangTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get namaPeminjam => $composableBuilder(
    column: $table.namaPeminjam,
    builder: (column) => column,
  );

  GeneratedColumn<double> get jumlahAwal => $composableBuilder(
    column: $table.jumlahAwal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sisaPiutang => $composableBuilder(
    column: $table.sisaPiutang,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tanggalPinjam => $composableBuilder(
    column: $table.tanggalPinjam,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tanggalJatuhTempo => $composableBuilder(
    column: $table.tanggalJatuhTempo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get catatan =>
      $composableBuilder(column: $table.catatan, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PiutangTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PiutangTableTable,
          PiutangData,
          $$PiutangTableTableFilterComposer,
          $$PiutangTableTableOrderingComposer,
          $$PiutangTableTableAnnotationComposer,
          $$PiutangTableTableCreateCompanionBuilder,
          $$PiutangTableTableUpdateCompanionBuilder,
          (
            PiutangData,
            BaseReferences<_$AppDatabase, $PiutangTableTable, PiutangData>,
          ),
          PiutangData,
          PrefetchHooks Function()
        > {
  $$PiutangTableTableTableManager(_$AppDatabase db, $PiutangTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PiutangTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$PiutangTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$PiutangTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> namaPeminjam = const Value.absent(),
                Value<double> jumlahAwal = const Value.absent(),
                Value<double> sisaPiutang = const Value.absent(),
                Value<int> tanggalPinjam = const Value.absent(),
                Value<int?> tanggalJatuhTempo = const Value.absent(),
                Value<String?> catatan = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PiutangTableCompanion(
                id: id,
                namaPeminjam: namaPeminjam,
                jumlahAwal: jumlahAwal,
                sisaPiutang: sisaPiutang,
                tanggalPinjam: tanggalPinjam,
                tanggalJatuhTempo: tanggalJatuhTempo,
                catatan: catatan,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String namaPeminjam,
                required double jumlahAwal,
                required double sisaPiutang,
                required int tanggalPinjam,
                Value<int?> tanggalJatuhTempo = const Value.absent(),
                Value<String?> catatan = const Value.absent(),
                Value<String> status = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PiutangTableCompanion.insert(
                id: id,
                namaPeminjam: namaPeminjam,
                jumlahAwal: jumlahAwal,
                sisaPiutang: sisaPiutang,
                tanggalPinjam: tanggalPinjam,
                tanggalJatuhTempo: tanggalJatuhTempo,
                catatan: catatan,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PiutangTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PiutangTableTable,
      PiutangData,
      $$PiutangTableTableFilterComposer,
      $$PiutangTableTableOrderingComposer,
      $$PiutangTableTableAnnotationComposer,
      $$PiutangTableTableCreateCompanionBuilder,
      $$PiutangTableTableUpdateCompanionBuilder,
      (
        PiutangData,
        BaseReferences<_$AppDatabase, $PiutangTableTable, PiutangData>,
      ),
      PiutangData,
      PrefetchHooks Function()
    >;
typedef $$PaymentHistoryTableTableCreateCompanionBuilder =
    PaymentHistoryTableCompanion Function({
      required String id,
      required String referenceId,
      required String referenceType,
      required double amount,
      required int paidAt,
      Value<String?> catatan,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$PaymentHistoryTableTableUpdateCompanionBuilder =
    PaymentHistoryTableCompanion Function({
      Value<String> id,
      Value<String> referenceId,
      Value<String> referenceType,
      Value<double> amount,
      Value<int> paidAt,
      Value<String?> catatan,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$PaymentHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentHistoryTableTable> {
  $$PaymentHistoryTableTableFilterComposer({
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

  ColumnFilters<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaymentHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentHistoryTableTable> {
  $$PaymentHistoryTableTableOrderingComposer({
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

  ColumnOrderings<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaymentHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentHistoryTableTable> {
  $$PaymentHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumn<String> get catatan =>
      $composableBuilder(column: $table.catatan, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PaymentHistoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentHistoryTableTable,
          PaymentHistoryData,
          $$PaymentHistoryTableTableFilterComposer,
          $$PaymentHistoryTableTableOrderingComposer,
          $$PaymentHistoryTableTableAnnotationComposer,
          $$PaymentHistoryTableTableCreateCompanionBuilder,
          $$PaymentHistoryTableTableUpdateCompanionBuilder,
          (
            PaymentHistoryData,
            BaseReferences<
              _$AppDatabase,
              $PaymentHistoryTableTable,
              PaymentHistoryData
            >,
          ),
          PaymentHistoryData,
          PrefetchHooks Function()
        > {
  $$PaymentHistoryTableTableTableManager(
    _$AppDatabase db,
    $PaymentHistoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PaymentHistoryTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$PaymentHistoryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$PaymentHistoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> referenceId = const Value.absent(),
                Value<String> referenceType = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<int> paidAt = const Value.absent(),
                Value<String?> catatan = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentHistoryTableCompanion(
                id: id,
                referenceId: referenceId,
                referenceType: referenceType,
                amount: amount,
                paidAt: paidAt,
                catatan: catatan,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String referenceId,
                required String referenceType,
                required double amount,
                required int paidAt,
                Value<String?> catatan = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PaymentHistoryTableCompanion.insert(
                id: id,
                referenceId: referenceId,
                referenceType: referenceType,
                amount: amount,
                paidAt: paidAt,
                catatan: catatan,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaymentHistoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentHistoryTableTable,
      PaymentHistoryData,
      $$PaymentHistoryTableTableFilterComposer,
      $$PaymentHistoryTableTableOrderingComposer,
      $$PaymentHistoryTableTableAnnotationComposer,
      $$PaymentHistoryTableTableCreateCompanionBuilder,
      $$PaymentHistoryTableTableUpdateCompanionBuilder,
      (
        PaymentHistoryData,
        BaseReferences<
          _$AppDatabase,
          $PaymentHistoryTableTable,
          PaymentHistoryData
        >,
      ),
      PaymentHistoryData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableTableManager get categoriesTable =>
      $$CategoriesTableTableTableManager(_db, _db.categoriesTable);
  $$TransactionsTableTableTableManager get transactionsTable =>
      $$TransactionsTableTableTableManager(_db, _db.transactionsTable);
  $$HutangTableTableTableManager get hutangTable =>
      $$HutangTableTableTableManager(_db, _db.hutangTable);
  $$PiutangTableTableTableManager get piutangTable =>
      $$PiutangTableTableTableManager(_db, _db.piutangTable);
  $$PaymentHistoryTableTableTableManager get paymentHistoryTable =>
      $$PaymentHistoryTableTableTableManager(_db, _db.paymentHistoryTable);
}
