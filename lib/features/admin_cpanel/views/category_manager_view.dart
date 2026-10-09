import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/category_model.dart';
import '../controllers/admin_categories_controller.dart';

class CategoryManagerView extends ConsumerStatefulWidget {
  const CategoryManagerView({super.key});

  @override
  ConsumerState<CategoryManagerView> createState() =>
      _CategoryManagerViewState();
}

class _CategoryManagerViewState
    extends ConsumerState<CategoryManagerView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminCategoriesControllerProvider);
    final ctrl = ref.read(adminCategoriesControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: state.isLoading && state.categories.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.categories.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: ctrl.load,
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.categories.length,
                    onReorder: (oldIndex, newIndex) async {
                      final ok = await ctrl.reorderCategories(
                        oldIndex,
                        newIndex,
                      );
                      if (!ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('No se pudo reordenar'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    },
                    itemBuilder: (context, i) {
                      final c = state.categories[i];
                      return _CategoryTile(
                        key: ValueKey(c.id),
                        category: c,
                        index: i,
                        onEdit: () => context.go('/admin/categorias/${c.id}'),
                        onDelete: () => _confirmDelete(c),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => context.go('/admin/categorias/nueva'),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nueva categoría',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Category c) async {
    final ctrl = ref.read(adminCategoriesControllerProvider.notifier);

    // Mostrar loading.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final productCount = await ctrl.countProductsInCategory(c.id);

    if (!mounted) return;
    Navigator.of(context).pop(); // Cerrar loading.

    if (productCount == 0) {
      // Confirmación simple.
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Eliminar "${c.name}"'),
          content: const Text(
            'Esta categoría no tiene productos. ¿Confirmás eliminarla?',
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

      final result = await ctrl.deleteCategory(category: c);
      if (mounted) {
        _snack(result ? 'Categoría eliminada' : 'No se pudo eliminar');
      }
      return;
    }

    // Tiene productos → diálogo con 3 opciones.
    final action = await showDialog<_DeleteAction>(
      context: context,
      builder: (_) => _DeleteWithProductsDialog(
        category: c,
        productCount: productCount,
        otherCategories:
            ref.read(adminCategoriesControllerProvider).categories
                .where((cat) => cat.id != c.id)
                .toList(),
      ),
    );

    if (action == null) return;

    switch (action.type) {
      case _DeleteActionType.cancel:
        return;
      case _DeleteActionType.reassign:
        final result = await ctrl.deleteCategory(
          category: c,
          reassignToCategoryId: action.targetCategoryId,
        );
        if (mounted) {
          _snack(result
              ? 'Productos reasignados y categoría eliminada'
              : 'No se pudo eliminar');
        }
        break;
      case _DeleteActionType.archive:
        final result = await ctrl.deleteCategory(
          category: c,
          archiveProducts: true,
        );
        if (mounted) {
          _snack(result
              ? 'Productos archivados y categoría eliminada'
              : 'No se pudo eliminar');
        }
        break;
    }
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    super.key,
    required this.category,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        onTap: onEdit,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.category_outlined,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            if (!category.isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Inactiva',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '/${category.slug} · ${category.subcategories.length} subcategorías',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle_rounded,
                color: AppColors.textMuted, size: 20),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 20, color: AppColors.danger),
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
            const Icon(Icons.category_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Sin categorías',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Creá tu primera categoría tocando el botón azul.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Diálogo de eliminación con productos
// ─────────────────────────────────────────────────────────────

enum _DeleteActionType { cancel, reassign, archive }

class _DeleteAction {
  const _DeleteAction({required this.type, this.targetCategoryId});
  final _DeleteActionType type;
  final String? targetCategoryId;
}

class _DeleteWithProductsDialog extends StatefulWidget {
  const _DeleteWithProductsDialog({
    required this.category,
    required this.productCount,
    required this.otherCategories,
  });

  final Category category;
  final int productCount;
  final List<Category> otherCategories;

  @override
  State<_DeleteWithProductsDialog> createState() =>
      _DeleteWithProductsDialogState();
}

class _DeleteWithProductsDialogState
    extends State<_DeleteWithProductsDialog> {
  _DeleteActionType _selected = _DeleteActionType.cancel;
  String? _reassignTarget;

  @override
  void initState() {
    super.initState();
    if (widget.otherCategories.isNotEmpty) {
      _reassignTarget = widget.otherCategories.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasOtherCategories = widget.otherCategories.isNotEmpty;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.danger, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Eliminar "${widget.category.name}"',
              style: const TextStyle(fontSize: 17),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Esta categoría tiene ${widget.productCount} '
                'producto${widget.productCount == 1 ? "" : "s"} '
                'y ${widget.category.subcategories.length} '
                'subcategoría${widget.category.subcategories.length == 1 ? "" : "s"}.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Elegí una acción:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),

            // ── Opción: Reasignar ─────────────────────
            if (hasOtherCategories)
              _OptionTile(
                selected: _selected == _DeleteActionType.reassign,
                title: 'Reasignar productos',
                subtitle:
                    'Los productos pasan a otra categoría que elijas.',
                onTap: () => setState(
                    () => _selected = _DeleteActionType.reassign),
              ),
            if (hasOtherCategories && _selected == _DeleteActionType.reassign)
              Padding(
                padding: const EdgeInsets.only(left: 36, bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _reassignTarget,
                  isExpanded: true,
                  items: widget.otherCategories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _reassignTarget = v),
                  decoration: const InputDecoration(
                    hintText: 'Elegir categoría',
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
              ),

            // ── Opción: Archivar ──────────────────────
            _OptionTile(
              selected: _selected == _DeleteActionType.archive,
              title: 'Archivar productos',
              subtitle:
                  'Los productos quedan inactivos (no se ven en la tienda).',
              onTap: () =>
                  setState(() => _selected = _DeleteActionType.archive),
            ),

            // ── Opción: Cancelar ─────────────────────
            _OptionTile(
              selected: _selected == _DeleteActionType.cancel,
              title: 'Cancelar',
              subtitle: 'No hacer nada.',
              onTap: () =>
                  setState(() => _selected = _DeleteActionType.cancel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        FilledButton(
          onPressed: () {
            if (_selected == _DeleteActionType.cancel) {
              Navigator.of(context).pop();
              return;
            }
            Navigator.of(context).pop(
              _DeleteAction(
                type: _selected,
                targetCategoryId: _selected == _DeleteActionType.reassign
                    ? _reassignTarget
                    : null,
              ),
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: _selected == _DeleteActionType.cancel
                ? AppColors.textMuted
                : AppColors.danger,
          ),
          child: Text(
            _selected == _DeleteActionType.cancel
                ? 'Cancelar'
                : 'Eliminar categoría',
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) => onTap(),
              activeColor: AppColors.primary,
              materialTapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}