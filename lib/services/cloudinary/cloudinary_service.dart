import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

/// Servicio para subir imágenes a Cloudinary.
/// Reemplaza a Firebase Storage (que ahora requiere plan Blaze).
class CloudinaryService {
  const CloudinaryService();

  static const String _cloudName = 'qcfyrfvo';
  static const String _uploadPreset = 'Tienda_vertex';

  static const int _maxWidth = 1200;
  static const int _quality = 80;

  /// Comprime y sube una imagen. Devuelve la URL pública.
  Future<String> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String filename,
  }) async {
    // 1. Comprimir antes de subir.
    final compressed = await _compress(bytes);

    // 2. Preparar request multipart.
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = 'tienda_vertex/products/$productId'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          compressed,
          filename: filename,
        ),
      );

    // 3. Enviar.
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Cloudinary error ${response.statusCode}: ${response.body}',
      );
    }

    // 4. Extraer URL segura.
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['secure_url'] as String?;

    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary no devolvió URL.');
    }

    return url;
  }

  /// Elimina una imagen por su URL (opcional).
  /// Sin firma, Cloudinary no permite borrar desde el cliente,
  /// así que este método queda vacío. Las imágenes se limpian
  /// manualmente desde el dashboard si es necesario.
  Future<void> deleteByUrl(String url) async {
    // No-op. Cloudinary requiere firma para eliminar.
    // Las imágenes se borran desde el dashboard cuando sea necesario.
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