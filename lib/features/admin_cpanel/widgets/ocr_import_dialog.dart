import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../services/ai/gemini_service.dart';
import '../../../services/firebase/firebase_providers.dart';

/// Diálogo que abre la cámara/galería, envía la captura a Gemini
/// y devuelve un ProductDraft con los datos extraídos.
class OcrImportDialog extends ConsumerStatefulWidget {
  const OcrImportDialog({super.key});

  @override
  ConsumerState<OcrImportDialog> createState() => _OcrImportDialogState();
}

class _OcrImportDialogState extends ConsumerState<OcrImportDialog> {
  bool _processing = false;
  String? _error;

  Future<void> _pickAndProcess(ImageSource source) async {
    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 2400,
        imageQuality: 85,
      );
      if (file == null) {
        setState(() => _processing = false);
        return;
      }

      final bytes = await file.readAsBytes();

      // Leer settings para obtener la API key de Gemini.
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
      final draft = await gemini.extractFromImage(bytes);

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_processing) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                'Analizando imagen...',
                style: Theme.of(context).textTheme.titleMedium,
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
                'Importar desde captura',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Subí una captura del producto y la IA extraerá título, '
                'precio, descripción y categoría.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
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
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.photo_camera_outlined,
                      label: 'Cámara',
                      onTap: () => _pickAndProcess(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Galería',
                      onTap: () => _pickAndProcess(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ],
        ),
      ),
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