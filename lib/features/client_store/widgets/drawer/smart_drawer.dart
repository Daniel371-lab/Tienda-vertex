import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/vertex_logo.dart';
import '../../../../models/category_model.dart';
import '../../controllers/store_controller.dart';

/// Menú lateral inteligente que adapta su contenido según el nicho activo.
///
/// · Escenario A (ruta raíz): lista de categorías principales.
/// · Escenario B (nicho activo): opción "Ver todas" + subcategorías.
/// · En pantallas anchas (>1024px) se renderiza como panel persistente.
class SmartDrawer extends ConsumerWidget {
  const SmartDrawer({
    super.key,
    this.onNavigate,
    this.isPersistent = false,
  });

  /// Callback invocado tras una navegación.
  /// En modo overlay cierra el drawer; en modo persistente no hace nada.
  final VoidCallback? onNavigate;
  final bool isPersistent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeControllerProvider);
    final notifier = ref.read(storeControllerProvider.notifier);
    final activeCat = state.activeCategory;

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
            // ── Encabezado del drawer ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: isPersistent
                  ? const VertexLogo()
                  : Row(
                      children: [
                        const VertexLogo(),
                        const Spacer(),
                        IconButton(
                          onPressed: () =>
                              onNavigate?.call() ?? Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
            ),
            const Divider(),

            // ── Contenido según escenario ────────────────────
            Expanded(
              child: activeCat == null
                  ? _GlobalList(
                      categories: state.categories,
                      isLoading: state.isLoadingCategories,
                      onSelect: (slug) {
                        notifier.selectSubcategory(null);
                        context.go('/$slug');
                        onNavigate?.call();
                      },
                    )
                  : _NicheList(
                      category: activeCat,
                      selectedSubcategoryId: state.selectedSubcategoryId,
                      onBackToGlobal: () {
                        notifier.selectSubcategory(null);
                        context.go('/');
                        onNavigate?.call();
                      },
                      onSelectSubcategory: (sub) {
                        notifier.selectSubcategory(sub.id);
                        context.go('/${activeCat.slug}/${sub.slug}');
                        onNavigate?.call();
                      },
                      onSelectAll: () {
                        notifier.selectSubcategory(null);
                        context.go('/${activeCat.slug}');
                        onNavigate?.call();
                      },
                    ),
            ),

            // ── Pie del drawer ───────────────────────────────
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
// ESCENARIO A — Lista global de categorías principales
// ─────────────────────────────────────────────────────────────

class _GlobalList extends StatelessWidget {
  const _GlobalList({
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
// ESCENARIO B — Subcategorías del nicho activo
// ─────────────────────────────────────────────────────────────

class _NicheList extends StatelessWidget {
  const _NicheList({
    required this.category,
    required this.selectedSubcategoryId,
    required this.onBackToGlobal,
    required this.onSelectSubcategory,
    required this.onSelectAll,
  });

  final Category category;
  final String? selectedSubcategoryId;
  final VoidCallback onBackToGlobal;
  final void Function(Subcategory) onSelectSubcategory;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Vía de escape global
        _DrawerTile(
          label: AppStrings.backToAllCategories,
          icon: Icons.arrow_back_rounded,
          iconColor: AppColors.primary,
          textColor: AppColors.primary,
          onTap: onBackToGlobal,
        ),
        const Divider(),

        // Nombre del nicho activo
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

        // Opción "Todas las subcategorías"
        _DrawerTile(
          label: AppStrings.filterAll,
          icon: Icons.grid_view_rounded,
          selected: selectedSubcategoryId == null,
          onTap: onSelectAll,
        ),

        // Subcategorías del nicho
        for (final sub in category.subcategories)
          _DrawerTile(
            label: sub.name,
            icon: Icons.circle_outlined,
            iconSize: 8,
            selected: selectedSubcategoryId == sub.id,
            onTap: () => onSelectSubcategory(sub),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tile genérico del drawer
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

/// Mapea el nombre del ícono (guardado en Firestore) a un IconData.
/// Los nombres coinciden con lo que el cPanel guarda en `icon`.
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