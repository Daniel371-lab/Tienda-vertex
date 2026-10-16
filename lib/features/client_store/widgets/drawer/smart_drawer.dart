import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/vertex_logo.dart';
import '../../../../models/category_model.dart';
import '../../controllers/store_controller.dart';

class SmartDrawer extends ConsumerWidget {
  const SmartDrawer({
    super.key,
    this.onNavigate,
    this.isPersistent = false,
  });

  final VoidCallback? onNavigate;
  final bool isPersistent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeControllerProvider);
    final notifier = ref.read(storeControllerProvider.notifier);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: isPersistent
            ? const Border(
                right: BorderSide(color: AppColors.border, width: 0.6),
              )
            : null,
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Encabezado ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: isPersistent
                  ? const VertexLogo()
                  : Row(
                      children: [
                        const VertexLogo(),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            if (onNavigate != null) {
                              onNavigate!();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
            ),
            const Divider(),

            // ── Contenido según modo ────────────────────────
            Expanded(
              child: state.showSubcategoriesInDrawer
                  ? _SubcategoriesList(
                      state: state,
                      onNavigate: onNavigate,
                      onBackToGlobal: () {
                        notifier.selectSubcategory(null);
                        context.go('/');
                        onNavigate?.call();
                      },
                      onSelectSubcategory: (sub) {
                        notifier.selectSubcategory(sub.id);
                        context.go(
                          '/${state.activeCategory!.slug}/${sub.slug}',
                        );
                        onNavigate?.call();
                      },
                      onSelectAll: () {
                        notifier.selectSubcategory(null);
                        context.go('/${state.activeCategory!.slug}');
                        onNavigate?.call();
                      },
                    )
                  : _CategoriesList(
                      categories: state.categories,
                      isLoading: state.isLoadingCategories,
                      onSelect: (slug) {
                        notifier.selectSubcategory(null);
                        context.go('/?cat=$slug');
                        onNavigate?.call();
                      },
                    ),
            ),

            // ── Pie ─────────────────────────────────────────
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                AppStrings.footerCredit,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODO GENERAL / EXPLORE — Lista de categorías principales
// ─────────────────────────────────────────────────────────────

class _CategoriesList extends StatelessWidget {
  const _CategoriesList({
    required this.categories,
    required this.isLoading,
    required this.onSelect,
  });

  final List<Category> categories;
  final bool isLoading;
  final void Function(String slug) onSelect;

  @override
  Widget build(BuildContext context) {
    if (isLoading && categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'No hay categorías disponibles.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(
            'CATEGORÍAS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        for (final cat in categories)
          _DrawerTile(
            label: cat.name,
            icon: _iconForCategory(cat.icon),
            onTap: () => onSelect(cat.slug),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODO SPECIALIZED / SUBCATEGORY — Lista de subcategorías
// ─────────────────────────────────────────────────────────────

class _SubcategoriesList extends StatelessWidget {
  const _SubcategoriesList({
    required this.state,
    required this.onBackToGlobal,
    required this.onSelectSubcategory,
    required this.onSelectAll,
    this.onNavigate,
  });

  final StoreState state;
  final VoidCallback onBackToGlobal;
  final void Function(Subcategory) onSelectSubcategory;
  final VoidCallback onSelectAll;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final category = state.activeCategory!;
    final selectedId = state.selectedSubcategoryId;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _DrawerTile(
          label: AppStrings.backToAllCategories,
          icon: Icons.arrow_back_rounded,
          iconColor: AppColors.primary,
          textColor: AppColors.primary,
          onTap: onBackToGlobal,
        ),
        const Divider(),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            category.name.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),

        _DrawerTile(
          label: AppStrings.filterAll,
          icon: Icons.grid_view_rounded,
          selected: selectedId == null,
          onTap: onSelectAll,
        ),

        for (final sub in category.subcategories)
          _DrawerTile(
            label: sub.name,
            icon: Icons.circle_outlined,
            iconSize: 8,
            selected: selectedId == sub.id,
            onTap: () => onSelectSubcategory(sub),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tile genérico
// ─────────────────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.iconColor,
    this.textColor,
    this.iconSize = 20,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final Color? iconColor;
  final Color? textColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: selected ? AppColors.primarySoft : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ??
                  (selected ? AppColors.primary : AppColors.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor ??
                          (selected
                              ? AppColors.primary
                              : AppColors.textPrimary),
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForCategory(String icon) {
  switch (icon) {
    case 'perfume_icon':
      return Icons.spa_outlined;
    case 'watch_icon':
      return Icons.watch_outlined;
    case 'jewelry_icon':
      return Icons.diamond_outlined;
    case 'electronics_icon':
      return Icons.devices_other_outlined;
    case 'bag_icon':
      return Icons.shopping_bag_outlined;
    default:
      return Icons.category_outlined;
  }
}