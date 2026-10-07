import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../models/category_model.dart';
import '../../controllers/store_controller.dart';

/// Carrusel horizontal de chips de subcategorías.
/// El filtrado es reactivo en memoria: sin navegación ni recarga.
class SubcategoryChips extends ConsumerWidget {
  const SubcategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeControllerProvider);
    final notifier = ref.read(storeControllerProvider.notifier);
    final category = state.activeCategory;

    // No mostramos chips en la vista global ni si no hay subcategorías.
    if (category == null || category.subcategories.isEmpty) {
      return const SizedBox.shrink();
    }

    final subs = category.subcategories;
    final selectedId = state.selectedSubcategoryId;

    return Container(
      height: 56,
      margin: const EdgeInsets.only(top: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: subs.length + 1,
        itemBuilder: (context, index) {
          // Chip "Todos" en la posición 0
          if (index == 0) {
            return _Chip(
              label: AppStrings.filterAll,
              selected: selectedId == null,
              onTap: () {
                notifier.selectSubcategory(null);
                context.go('/${category.slug}');
              },
            );
          }
          final sub = subs[index - 1];
          return _Chip(
            label: sub.name,
            selected: selectedId == sub.id,
            onTap: () {
              notifier.selectSubcategory(sub.id);
              context.go('/${category.slug}/${sub.slug}');
            },
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}