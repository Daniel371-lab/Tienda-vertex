import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/category_model.dart';
import '../controllers/admin_categories_controller.dart';

/// Formulario para crear o editar una categoría (nicho).
class CategoryFormView extends ConsumerStatefulWidget {
  const CategoryFormView({super.key, this.categoryId});

  /// Si es null → creación. Si tiene valor → edición.
  final String? categoryId;

  @override
  ConsumerState<CategoryFormView> createState() => _CategoryFormViewState();
}

class _CategoryFormViewState extends ConsumerState<CategoryFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();

  String _iconKey = 'category_icon';
  bool _isActive = true;
  bool _loading = true;
  bool _saving = false;

  // Íconos disponibles.
  static const Map<String, IconData> _icons = {
    'perfume_icon': Icons.spa_outlined,
    'watch_icon': Icons.watch_outlined,
    'jewelry_icon': Icons.diamond_outlined,
    'electronics_icon': Icons.devices_other_outlined,
    'bag_icon': Icons.shopping_bag_outlined,
    'category_icon': Icons.category_outlined,
    'shirt_icon': Icons.checkroom_outlined,
    'home_icon': Icons.chair_outlined,
    'beauty_icon': Icons.face_retouching_natural_outlined,
    'sport_icon': Icons.sports_soccer_outlined,
  };

  bool get _isEditing => widget.categoryId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_isEditing) {
      try {
        final db = ref.read(firestoreServiceProvider);
        final c = await db.findCategoryById(widget.categoryId!);
        if (c != null) {
          _nameCtrl.text = c.name;
          _slugCtrl.text = c.slug;
          _iconKey = c.icon.isEmpty ? 'category_icon' : c.icon;
          _isActive = c.isActive;
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
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
        title: Text(_isEditing ? 'Editar categoría' : 'Nueva categoría'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin/categorias'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label(context, 'Nombre'),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              onChanged: (v) {
                // Auto-generar slug si no está editando manualmente.
                if (!_isEditing || _slugCtrl.text.isEmpty) {
                  _slugCtrl.text = _slugify(v);
                }
              },
              decoration: const InputDecoration(
                hintText: 'Ej: Perfumería',
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 3) ? 'Nombre inválido' : null,
            ),
            const SizedBox(height: 16),

            _label(context, 'Slug (URL)'),
            TextFormField(
              controller: _slugCtrl,
              enabled: !_isEditing, // El slug no se puede cambiar una vez creado
              decoration: InputDecoration(
                hintText: 'perfumes',
                prefixText: '/',
                helperText: _isEditing
                    ? 'El slug no se puede cambiar'
                    : 'Se usa en la URL de la categoría',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Slug requerido';
                if (!RegExp(r'^[a-z0-9\-]+$').hasMatch(v)) {
                  return 'Solo minúsculas, números y guiones';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            _label(context, 'Ícono'),
            _IconPicker(
              icons: _icons,
              selected: _iconKey,
              onSelect: (k) => setState(() => _iconKey = k),
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile(
                title: const Text('Categoría activa'),
                subtitle: const Text('Visible en la tienda pública'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Guardando...' : 'Guardar categoría'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle? _labelStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .labelMedium
      ?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      );

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(text, style: _labelStyle(context)),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final ctrl = ref.read(adminCategoriesControllerProvider.notifier);
    final categories =
        ref.read(adminCategoriesControllerProvider).categories;

    bool ok;
    if (_isEditing) {
      final existing = categories.firstWhere((c) => c.id == widget.categoryId);
      final updated = existing.copyWith(
        name: _nameCtrl.text.trim(),
        icon: _iconKey,
        isActive: _isActive,
      );
      ok = await ctrl.updateCategory(updated);
    } else {
      ok = await ctrl.createCategory(
        name: _nameCtrl.text.trim(),
        slug: _slugCtrl.text.trim().toLowerCase(),
        icon: _iconKey,
      );
    }

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Categoría actualizada'
              : 'Categoría creada'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/admin/categorias');
    } else {
      setState(() => _saving = false);
      final error = ref.read(adminCategoriesControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'No se pudo guardar'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.icons,
    required this.selected,
    required this.onSelect,
  });

  final Map<String, IconData> icons;
  final String selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: icons.entries.map((e) {
        final isSelected = e.key == selected;
        return InkWell(
          onTap: () => onSelect(e.key),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primarySoft
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.border,
                width: isSelected ? 1.8 : 1,
              ),
            ),
            child: Icon(
              e.value,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: 24,
            ),
          ),
        );
      }).toList(),
    );
  }
}