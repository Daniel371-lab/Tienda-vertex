import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/category_model.dart';
import '../../../models/product_model.dart';
import '../../../services/ai/gemini_service.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../controllers/admin_products_controller.dart';

class ProductFormView extends ConsumerStatefulWidget {
  const ProductFormView({
    super.key,
    this.productId,
    this.draft,
  });

  final String? productId;
  final ProductDraft? draft;

  @override
  ConsumerState<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends ConsumerState<ProductFormView> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _compareCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '100');
  final _tagsCtrl = TextEditingController();

  // Listas para guardar las selecciones múltiples
  final Set<String> _selectedCategoryIds = {};
  final Set<String> _selectedSubcategoryIds = {};
  final Set<String> _featuredInCategories = {};

  bool _isActive = true;
  bool _isFeaturedGeneral = false;
  final List<String> _images = [];

  bool _loading = true;
  bool _saving = false;
  bool _uploadingImage = false;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _compareCtrl.dispose();
    _stockCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (widget.draft != null) {
      final d = widget.draft!;
      _titleCtrl.text = d.title;
      _descCtrl.text = d.description;
      _priceCtrl.text = d.price > 0 ? d.price.toString() : '';
      if (d.tags.isNotEmpty) _tagsCtrl.text = d.tags.join(', ');
    }

    if (_isEditing) {
      try {
        final p = await ref.read(firestoreServiceProvider).findProductById(widget.productId!);
        if (p != null) {
          _titleCtrl.text = p.title;
          _descCtrl.text = p.description;
          _priceCtrl.text = p.price.toString();
          _compareCtrl.text = p.compareAtPrice?.toString() ?? '';
          _stockCtrl.text = p.stock.toString();
          _tagsCtrl.text = p.tags.join(', ');
          
          _selectedCategoryIds
            ..clear()
            ..addAll(p.categoryIds);
          _selectedSubcategoryIds
            ..clear()
            ..addAll(p.subcategoryIds);
          
          _isActive = p.isActive;
          _isFeaturedGeneral = p.isFeaturedGeneral;
          _featuredInCategories
            ..clear()
            ..addAll(p.isFeaturedInCategories);
          _images
            ..clear()
            ..addAll(p.images);
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProductsControllerProvider);
    final categories = state.categories;

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
        title: Text(_isEditing ? 'Editar producto' : 'Nuevo producto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin/productos'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Imágenes ───────────────────────────────────
            _label(context, 'Imágenes'),
            const SizedBox(height: 10),
            _buildImagesRow(),
            const SizedBox(height: 20),

            // ── Título ─────────────────────────────────────
            _label(context, 'Título'),
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ej: Club de Nuit Intense Man 105ml',
              ),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Ingresá un título válido' : null,
            ),
            const SizedBox(height: 16),

            // ── Descripción ────────────────────────────────
            _label(context, 'Descripción'),
            TextFormField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Características, notas, materiales...',
              ),
            ),
            const SizedBox(height: 16),

            // ── Precios ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(context, 'Precio (₲)'),
                      TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(hintText: '280000'),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Precio inválido';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(context, 'Precio anterior'),
                      TextFormField(
                        controller: _compareCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(hintText: 'Opcional'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Stock + Tags ───────────────────────────────
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(context, 'Stock'),
                      TextFormField(
                        controller: _stockCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(hintText: '100'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(context, 'Tags (separados por coma)'),
                      TextFormField(
                        controller: _tagsCtrl,
                        decoration: const InputDecoration(
                          hintText: 'perfume, arabe, masculino',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── CATEGORÍAS Y SUBCATEGORÍAS (CHECKBOXES) ──
            _label(context, 'Categorías y Subcategorías'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (final cat in categories) ...[
                    CheckboxListTile(
                      title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      value: _selectedCategoryIds.contains(cat.id),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedCategoryIds.add(cat.id);
                          } else {
                            _selectedCategoryIds.remove(cat.id);
                            // Si desmarca la categoría, desmarcamos sus subcategorías
                            for (final sub in cat.subcategories) {
                              _selectedSubcategoryIds.remove(sub.id);
                              _featuredInCategories.remove(sub.slug);
                            }
                            _featuredInCategories.remove(cat.slug);
                          }
                        });
                      },
                      activeColor: AppColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    // Si la categoría está seleccionada, mostramos sus subcategorías
                    if (_selectedCategoryIds.contains(cat.id))
                      Padding(
                        padding: const EdgeInsets.only(left: 32, bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final sub in cat.subcategories)
                              CheckboxListTile(
                                title: Text(sub.name, style: const TextStyle(fontSize: 13)),
                                value: _selectedSubcategoryIds.contains(sub.id),
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedSubcategoryIds.add(sub.id);
                                    } else {
                                      _selectedSubcategoryIds.remove(sub.id);
                                    }
                                  });
                                },
                                activeColor: AppColors.primary,
                                controlAffinity: ListTileControlAffinity.leading,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Toggles ────────────────────────────────────
            _label(context, 'Visibilidad y Destacados'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Producto activo'),
                    subtitle: const Text('Visible en la tienda'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Destacar en home general'),
                    subtitle: const Text('Aparece en la portada principal (/)'),
                    value: _isFeaturedGeneral,
                    onChanged: (v) => setState(() => _isFeaturedGeneral = v),
                  ),
                ],
              ),
            ),

            // ── Destacar en tiendas específicas ──────────
            if (_selectedCategoryIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Text(
                        'Destacar en tiendas específicas',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    for (final cat in categories.where((c) => _selectedCategoryIds.contains(c.id)))
                      CheckboxListTile(
                        value: _featuredInCategories.contains(cat.slug),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _featuredInCategories.add(cat.slug);
                            } else {
                              _featuredInCategories.remove(cat.slug);
                            }
                          });
                        },
                        title: Text(cat.name),
                        activeColor: AppColors.primary,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Guardando...' : 'Guardar producto'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesRow() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _buildImageItems(),
      ),
    );
  }

  List<Widget> _buildImageItems() {
    final items = <Widget>[];
    for (final url in _images) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _ImageThumb(
            url: url,
            onRemove: () => setState(() => _images.remove(url)),
          ),
        ),
      );
    }
    if (_images.length < 6) {
      items.add(_AddImageButton(
        isUploading: _uploadingImage,
        onTap: _pickImage,
      ));
    }
    return items;
  }

  TextStyle? _labelStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .labelMedium
      ?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600);

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(text, style: _labelStyle(context)),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 2400,
        imageQuality: 85,
      );
      if (files.isEmpty) return;

      setState(() => _uploadingImage = true);

      final cloudinary = ref.read(cloudinaryServiceProvider);
      final pid = widget.productId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';

      for (final f in files) {
        if (_images.length >= 6) break;
        final bytes = await f.readAsBytes();
        final url = await cloudinary.uploadProductImage(
          productId: pid,
          bytes: bytes,
          filename: f.name,
        );
        _images.add(url);
      }

      if (mounted) setState(() => _uploadingImage = false);
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debés seleccionar al menos una categoría'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final tags = _tagsCtrl.text
          .split(',')
          .map((t) => t.trim().toLowerCase())
          .where((t) => t.isNotEmpty)
          .toList();

      final product = Product(
        id: widget.productId ?? '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: int.tryParse(_priceCtrl.text) ?? 0,
        compareAtPrice: int.tryParse(_compareCtrl.text),
        categoryIds: _selectedCategoryIds.toList(),
        subcategoryIds: _selectedSubcategoryIds.toList(),
        images: _images,
        stock: int.tryParse(_stockCtrl.text) ?? 0,
        isActive: _isActive,
        isFeaturedGeneral: _isFeaturedGeneral,
        isFeaturedInCategories: _featuredInCategories.toList(),
        tags: tags,
      );

      final ok = await ref.read(adminProductsControllerProvider.notifier).saveProduct(product);

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Producto actualizado' : 'Producto creado'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/admin/productos');
      } else {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar'), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    }
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.url, required this.onRemove});
  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            url,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 100,
              height: 100,
              color: AppColors.surfaceAlt,
              child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddImageButton extends StatelessWidget {
  const _AddImageButton({required this.isUploading, required this.onTap});
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: isUploading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                  SizedBox(height: 4),
                  Text(
                    'Agregar',
                    style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}