import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Subida de imágenes de productos a Firebase Storage.
///
/// Las imágenes se comprimen antes de subir para no agotar los 5 GB
/// del plan Spark.
class StorageService {
  StorageService(this._storage);
  final FirebaseStorage _storage;

  static const int _maxWidth = 1200;
  static const int _quality = 80;

  /// Comprime y sube una imagen. Devuelve la URL pública.
  Future<String> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final compressed = await _compress(bytes);

    final ext = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : 'jpg';
    final path =
        'products/$productId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    final ref = _storage.ref(path);
    await ref.putData(
      compressed,
      SettableMetadata(contentType: 'image/$ext'),
    );

    return await ref.getDownloadURL();
  }

  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Si no existe, no hacemos nada.
    }
  }

  Future<Uint8List> _compress(Uint8List bytes) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: _maxWidth,
        minHeight: _maxWidth,
        quality: _quality,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (_) {
      return bytes;
    }
  }
}