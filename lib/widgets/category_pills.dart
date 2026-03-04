import 'package:flutter/material.dart';
import 'package:pos/models/category.dart';
import 'package:pos/theme/app_theme.dart';

/// Horizontal scrollable category pills. Optional [showAll] adds an "All" pill (id = null).
class CategoryPills extends StatelessWidget {
  final List<Category> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategorySelected;
  final bool showAll;

  const CategoryPills({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.showAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showAll) _Pill(
                label: 'All',
                isSelected: selectedCategoryId == null,
                onTap: () => onCategorySelected(null),
              ),
          if (showAll && categories.isNotEmpty) const SizedBox(width: 8),
          ...categories.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Pill(
                  label: c.name,
                  isSelected: selectedCategoryId == c.id,
                  onTap: () => onCategorySelected(c.id),
                ),
              )),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontSizeCaption,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
