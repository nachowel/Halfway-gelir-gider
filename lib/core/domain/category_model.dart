import 'types.dart';

final class CategoryModel {
  CategoryModel._({
    required this.id,
    required this.type,
    required this.name,
    required this.icon,
    required this.colorToken,
    required this.sortOrder,
    required this.isArchived,
  });

  final String? id;
  final CategoryType type;
  final String name;
  final String? icon;
  final String? colorToken;
  final int sortOrder;
  final bool isArchived;

  factory CategoryModel.fromPayload({
    String? id,
    required String type,
    required String name,
    String? icon,
    String? colorToken,
    int sortOrder = 0,
    bool isArchived = false,
  }) {
    final String? normalizedId = normalizeOptionalText(id, 'category_id');
    final String normalizedName = requireTrimmedText(name, 'category_name');
    final String? normalizedIcon = normalizeOptionalText(icon, 'category_icon');
    final String? normalizedColorToken = normalizeOptionalText(
      colorToken,
      'category_color_token',
    );

    if (sortOrder < 0) {
      throw DomainValidationException(
        code: 'category.sort_order.invalid',
        message: 'Category sort_order must be zero or positive.',
      );
    }

    return CategoryModel._(
      id: normalizedId,
      type: CategoryTypeX.fromDbValue(type),
      name: normalizedName,
      icon: normalizedIcon,
      colorToken: normalizedColorToken,
      sortOrder: sortOrder,
      isArchived: isArchived,
    );
  }
}
