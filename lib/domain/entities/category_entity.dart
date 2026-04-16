import 'package:equatable/equatable.dart';
import '../enums/category_type.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final int iconCode;
  final int colorValue;
  final CategoryType type;
  final bool isDefault;

  const Category({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.type,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [id, name, iconCode, colorValue, type, isDefault];
}
