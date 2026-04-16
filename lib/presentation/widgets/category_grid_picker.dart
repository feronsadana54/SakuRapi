import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/responsive/app_spacing.dart';
import '../../core/responsive/app_type_scale.dart';
import '../../core/responsive/breakpoints.dart';
import '../../domain/entities/category_entity.dart';

/// Scrollable grid of [Category] tiles. Selected tile shows an accent border.
class CategoryGridPicker extends StatelessWidget {
  final List<Category> categories;
  final Category? selected;
  final ValueChanged<Category> onSelected;

  const CategoryGridPicker({
    required this.categories,
    required this.onSelected,
    this.selected,
    super.key,
  });

  int _columns(BuildContext context) => switch (context.screenClass) {
        ScreenClass.smallMobile => 3,
        ScreenClass.normalMobile => 4,
        ScreenClass.largeMobile || ScreenClass.tablet => 5,
      };

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Tidak ada kategori.')),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns(context),
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        final isSelected = selected?.id == cat.id;
        final catColor = Color(cat.colorValue);

        return GestureDetector(
          onTap: () => onSelected(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? catColor.withValues(alpha: 0.12)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? catColor : AppColors.divider,
                width: isSelected ? 2 : 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? catColor.withValues(alpha: 0.2)
                        : AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.fromCode(cat.iconCode),
                    size: 20,
                    color: catColor,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    cat.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppTypeScale.caption(context),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? catColor : AppColors.textSecondary,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
