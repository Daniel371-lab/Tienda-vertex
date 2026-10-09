import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/category_model.dart';
import '../controllers/admin_categories_controller.dart';

/// Gestión de subcategorías de una categoría específica.
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
        title: Text(category.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin/categorias'),
        ),
      ),
      body: category.subcategories.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: category.subcategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final sub = category.subcategories[i];
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.label_outline_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      sub.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '/${category.slug}/${sub.slug}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    trailing: IconButton(
                      onPressed: () => _confirmDelete(category, sub),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                );
              },
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

  Future<void> _showAddDialog(Category category) async {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva subcategoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              onChanged: (v) => slugCtrl.text = _slugify(v),
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Árabes',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: slugCtrl,
              decoration: const InputDecoration(
                labelText: 'Slug',
                prefixText: '/',
                hintText: 'arabes',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (nameCtrl.text.trim().isEmpty || slugCtrl.text.trim().isEmpty) return;

    final result = await ref
        .read(adminCategoriesControllerProvider.notifier)
        .addSubcategory(
          category: category,
          name: nameCtrl.text.trim(),
          slug: slugCtrl.text.trim().toLowerCase(),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Subcategoría creada' : 'No se pudo crear'),
          backgroundColor: result ? AppColors.success : AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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