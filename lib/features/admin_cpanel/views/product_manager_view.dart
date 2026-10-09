import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/product_model.dart';
import '../../../services/ai/gemini_service.dart';
import '../controllers/admin_products_controller.dart';
import '../widgets/ocr_import_dialog.dart';

class ProductManagerView extends ConsumerStatefulWidget {
  const ProductManagerView({super.key});

  @override
  ConsumerState<ProductManagerView> createState() =>
      _ProductManagerViewState();
}

class _ProductManagerViewState extends ConsumerState<ProductManagerView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProductsControllerProvider);
    final ctrl = ref.read(adminProductsControllerProvider.notifier);
    final products = state.filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          // ── Barra de búsqueda + filtros ─────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: ctrl.setSearch,
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon:
                        const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              ctrl.setSearch('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryChip(
                        label: 'Todas',
                        selected: state.selectedCategoryId == null,
                        onTap: () => ctrl.setCategory(null),
                      ),
                      for (final c in state.categories)
                        _CategoryChip(
                          label: c.name,
                          selected: state.selectedCategoryId == c.id,
                          onTap: () => ctrl.setCategory(c.id),
                        ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: 'Solo activos',
                        selected: state.showOnlyActive,
                        onTap: ctrl.toggleOnlyActive,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Lista ───────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  )
                : state.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            state.error!,
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(color: AppColors.danger),
                          ),
                        ),
                      )
                    : products.isEmpty
                        ? const _EmptyState()
                        : RefreshIndicator(
                            onRefresh: ctrl.load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: products.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) => _ProductTile(
                                product: products[i],
                                onEdit: () => context
                                    .go('/admin/productos/${products[i].id}'),
                                onToggleActive: () =>
                                    _toggleActive(products[i]),
                                onToggleFeatured: () =>
                                    _toggleFeatured(products[i]),
                                onDelete: () => _confirmDelete(products[i]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'ocr',
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            onPressed: _openOcrDialog,
            tooltip: 'Importar desde captura',
            child: const Icon(Icons.auto_awesome_rounded),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'new',
            backgroundColor: AppColors.primary,
            onPressed: () => context.go('/admin/productos/nuevo'),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Nuevo producto',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(Product p) async {
    final ok = await ref
        .read(adminProductsControllerProvider.notifier)
        .toggleActive(p);
    if (!ok && mounted) _snack('No se pudo actualizar');
  }

  Future<void> _toggleFeatured(Product p) async {
    final ok = await ref
        .read(adminProductsControllerProvider.notifier)
        .toggleFeatured(p);
    if (!ok && mounted) _snack('No se pudo actualizar');
  }

  Future<void> _confirmDelete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Eliminar "${p.title}" definitivamente?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final deleted = await ref
        .read(adminProductsControllerProvider.notifier)
        .deleteProduct(p);
    if (mounted) {
      _snack(deleted ? 'Producto eliminado' : 'No se pudo eliminar');
    }
  }

  Future<void> _openOcrDialog() async {
    final draft = await showDialog<ProductDraft>(
      context: context,
      builder: (_) => const OcrImportDialog(),
    );
    if (draft == null || !mounted) return;

    context.go('/admin/productos/nuevo', extra: draft);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onEdit,
    required this.onToggleActive,
    required this.onToggleFeatured,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onToggleFeatured;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(product.price),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: product.isActive
                                  ? AppColors.success.withOpacity(0.15)
                                  : AppColors.textMuted.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.isActive ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: product.isActive
                                    ? AppColors.success
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                          if (product.isFeatured) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Destacado',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (v) {
                    switch (v) {
                      case 'active':
                        onToggleActive();
                        break;
                      case 'featured':
                        onToggleFeatured();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'active',
                      child: Row(
                        children: [
                          Icon(
                            product.isActive
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(product.isActive
                              ? 'Desactivar'
                              : 'Activar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'featured',
                      child: Row(
                        children: [
                          Icon(
                            product.isFeatured
                                ? Icons.star_border_rounded
                                : Icons.star_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(product.isFeatured
                              ? 'Quitar destacado'
                              : 'Marcar destacado'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Eliminar',
                              style:
                                  TextStyle(color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No hay productos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Creá uno nuevo o importá desde una captura.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}