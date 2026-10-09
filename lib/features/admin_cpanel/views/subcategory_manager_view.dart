import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/category_model.dart';
import '../controllers/admin_categories_controller.dart';

class SubcategoryManagerView extends ConsumerStatefulWidget {
  const SubcategoryManagerView({super.key, required this.categoryId});
  final String categoryId;

  @override
  ConsumerState<SubcategoryManagerView> createState() =>
      _SubcategoryManagerViewState();
}

class _SubcategoryManagerViewState
    extends ConsumerState<SubcategoryManagerView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminCategoriesControllerProvider);
    final ctrl = ref.read(adminCategoriesControllerProvider.notifier);

    final category = state.categories
        .where((c) => c.id == widget.categoryId)
        .firstOrNull;

    if (category == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Subcategorías · ${category.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin/categorias/${category.id}'),
        ),
      ),
      body: category.subcategories.isEmpty
          ? const _EmptyState()
          : Column(
              children: [
                Container(
                  color: AppColors.primarySoft,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Arrastrá para reordenar. El orden define cómo aparecen en la tienda pública.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.primary,
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: category.subcategories.length,
                    onReorder: (oldIndex, newIndex) async {
                      final ok = await ctrl.reorderSubcategories(
                        category: category,
                        oldIndex: oldIndex,
                        newIndex: newIndex,
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
                      final sub = category.subcategories[i];
                      return _SubcategoryTile(
                        key: ValueKey(sub.id),
                        subcategory: sub,
                        position: i + 1,
                        onEdit: () => _showEditDialog(category, sub),
                        onDelete: () => _confirmDelete(category, sub),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddDialog(category),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nueva subcategoría',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Crear ─────────────────────────────────────────────────

  Future<void> _showAddDialog(Category category) async {
    final result = await showModalBottomSheet<_SubcategoryFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SubcategoryFormSheet(),
    );

    if (result == null || !mounted) return;

    final ok = await ref
        .read(adminCategoriesControllerProvider.notifier)
        .addSubcategory(
          category: category,
          name: result.name,
          slug: result.slug,
        );

    if (!mounted) return;

    if (!ok) {
      final error = ref.read(adminCategoriesControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'No se pudo crear'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subcategoría creada'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Editar ────────────────────────────────────────────────

  Future<void> _showEditDialog(
    Category category,
    Subcategory sub,
  ) async {
    final result = await showModalBottomSheet<_SubcategoryFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubcategoryFormSheet(existing: sub),
    );

    if (result == null || !mounted) return;

    final updated = sub.copyWith(
      name: result.name,
      slug: result.slug,
    );

    final ok = await ref
        .read(adminCategoriesControllerProvider.notifier)
        .updateSubcategory(category: category, subcategory: updated);

    if (!mounted) return;

    if (!ok) {
      final error = ref.read(adminCategoriesControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'No se pudo actualizar'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subcategoría actualizada'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Eliminar ──────────────────────────────────────────────

  Future<void> _confirmDelete(Category c, Subcategory sub) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar "${sub.name}"'),
        content: const Text(
          'Los productos con esta subcategoría quedarán sin subcategoría '
          'asignada, pero seguirán en la categoría principal.',
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

    final result = await ref
        .read(adminCategoriesControllerProvider.notifier)
        .deleteSubcategory(category: c, subcategoryId: sub.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              result ? 'Subcategoría eliminada' : 'No se pudo eliminar'),
          backgroundColor: result ? AppColors.success : AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Tile con drag handle
// ─────────────────────────────────────────────────────────────

class _SubcategoryTile extends StatelessWidget {
  const _SubcategoryTile({
    super.key,
    required this.subcategory,
    required this.position,
    required this.onEdit,
    required this.onDelete,
  });

  final Subcategory subcategory;
  final int position;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$position',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          subcategory.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          '/${subcategory.slug}',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Editar',
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 20, color: AppColors.danger),
              tooltip: 'Eliminar',
            ),
            const Icon(Icons.drag_handle_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Formulario (bottom sheet)
// ─────────────────────────────────────────────────────────────

class _SubcategoryFormResult {
  const _SubcategoryFormResult({required this.name, required this.slug});
  final String name;
  final String slug;
}

class _SubcategoryFormSheet extends StatefulWidget {
  const _SubcategoryFormSheet({this.existing});
  final Subcategory? existing;

  @override
  State<_SubcategoryFormSheet> createState() =>
      _SubcategoryFormSheetState();
}

class _SubcategoryFormSheetState extends State<_SubcategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _slugCtrl.text = widget.existing!.slug;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isEditing ? 'Editar subcategoría' : 'Nueva subcategoría',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (v) {
                    if (!isEditing) {
                      _slugCtrl.text = _slugify(v);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej: Árabes',
                  ),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Nombre inválido'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _slugCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Slug',
                    prefixText: '/',
                    hintText: 'arabes',
                    helperText: 'Aparece en la URL de la tienda',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Slug requerido';
                    }
                    if (!RegExp(r'^[a-z0-9\-]+$').hasMatch(v)) {
                      return 'Solo minúsculas, números y guiones';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.of(context).pop(
                              _SubcategoryFormResult(
                                name: _nameCtrl.text.trim(),
                                slug:
                                    _slugCtrl.text.trim().toLowerCase(),
                              ),
                            );
                          }
                        },
                        child: Text(isEditing ? 'Guardar' : 'Crear'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _slugify(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }
}

// ─────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────

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
            const Icon(Icons.label_outline_rounded,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Sin subcategorías',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Agregá la primera subcategoría con el botón azul.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}