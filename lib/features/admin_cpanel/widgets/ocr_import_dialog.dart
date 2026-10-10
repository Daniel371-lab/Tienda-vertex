import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../services/ai/gemini_service.dart';
import '../../../services/firebase/firebase_providers.dart';

/// Diálogo que permite seleccionar 1 o 2 capturas, las envía a Gemini
/// y devuelve un ProductDraft con los datos extraídos.
class OcrImportDialog extends ConsumerStatefulWidget {
  const OcrImportDialog({super.key});

  @override
  ConsumerState<OcrImportDialog> createState() => _OcrImportDialogState();
}

class _OcrImportDialogState extends ConsumerState<OcrImportDialog> {
  final List<_PickedImage> _images = [];
  bool _processing = false;
  String? _error;

  Future<void> _pickImages(ImageSource source) async {
    try {
      final picker = ImagePicker();

      // Permitir hasta 2 imágenes en total.
      final remaining = 2 - _images.length;
      if (remaining <= 0) return;

      final files = await picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 2400,
        imageQuality: 85,
        limit: remaining,
      );

      if (files.isEmpty) return;

      for (final f in files) {
        if (_images.length >= 2) break;
        final bytes = await f.readAsBytes();
        _images.add(_PickedImage(name: f.name, bytes: bytes));
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al seleccionar imagen: $e';
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _process() async {
    if (_images.isEmpty) return;

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final settings =
          await ref.read(firestoreServiceProvider).fetchSettings();

      if (settings.geminiApiKey.isEmpty) {
        setState(() {
          _processing = false;
          _error = 'Falta configurar la API Key de Gemini en Ajustes.';
        });
        return;
      }

      final gemini = GeminiService(settings.geminiApiKey);
      final draft = await gemini.extractFromImages(
        _images.map((e) => e.bytes).toList(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(draft);
    } catch (e) {
      setState(() {
        _processing = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_processing) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 20),
                Text(
                  'Analizando ${_images.length} '
                  'imagen${_images.length == 1 ? "" : "es"}...',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'La IA está extrayendo los datos del producto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Importar desde capturas',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Subí hasta 2 capturas del producto (por ejemplo, '
                  'la parte de arriba con el título y precio, y la '
                  'parte de abajo con la descripción).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),

                // ── Preview de imágenes seleccionadas ──────
                if (_images.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => _ImagePreview(
                        image: _images[i],
                        onRemove: () => _removeImage(i),
                      ),
                    ),
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                // ── Botones de selección ───────────────────
                if (_images.length < 2)
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.photo_camera_outlined,
                          label: 'Cámara',
                          onTap: () => _pickImages(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.photo_library_outlined,
                          label: 'Galería',
                          onTap: () => _pickImages(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // ── Botón procesar ────────────────────────
                if (_images.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _process,
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        'Procesar ${_images.length} '
                        'imagen${_images.length == 1 ? "" : "es"}',
                      ),
                    ),
                  ),

                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PickedImage {
  const _PickedImage({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.image, required this.onRemove});
  final _PickedImage image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            image.bytes,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
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
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}