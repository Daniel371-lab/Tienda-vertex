import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

/// Borrador de producto que devuelve la IA tras analizar una captura.
class ProductDraft {
  const ProductDraft({
    this.title = '',
    this.description = '',
    this.price = 0,
    this.categoryHint = '',
    this.subcategoryHint = '',
    this.brand = '',
    this.tags = const [],
  });

  final String title;
  final String description;
  final int price;
  final String categoryHint;
  final String subcategoryHint;
  final String brand;
  final List<String> tags;

  factory ProductDraft.fromJson(Map<String, dynamic> map) {
    return ProductDraft(
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: _parsePrice(map['price']),
      categoryHint: map['category'] as String? ?? '',
      subcategoryHint: map['subcategory'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      tags: (map['tags'] as List?)?.whereType<String>().toList() ?? const [],
    );
  }

  static int _parsePrice(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toInt();
    final digits = raw.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }
}

/// Servicio que analiza capturas de pantalla de productos
/// y devuelve los datos estructurados listos para el formulario.
class GeminiService {
  GeminiService(this._apiKey);

  final String _apiKey;

  static const String _prompt = '''
Analizá esta captura de pantalla de un producto de e-commerce y extraé su información.

Devolvé ÚNICAMENTE un JSON válido (sin texto antes ni después, sin bloques de código) con esta estructura exacta:

{
  "title": "Nombre completo del producto con marca y modelo si es visible",
  "description": "Descripción breve con las características principales",
  "price": 280000,
  "category": "una de: perfumes, relojes, joyeria, electronica",
  "subcategory": "subcategoría específica si es evidente (ej: arabes, masculinos, deportivos)",
  "brand": "marca del producto si es visible",
  "tags": ["tag1", "tag2", "tag3"]
}

Reglas:
- El precio SIEMPRE en número entero, sin puntos ni símbolos (Guaraníes).
- Si no encontrás algún campo, dejalo como string vacío o array vacío.
- "category" debe ser una de las 4 opciones indicadas.
- Los tags son palabras clave útiles para búsqueda.
''';

  /// Analiza una imagen y devuelve el borrador del producto.
  Future<ProductDraft> extractFromImage(Uint8List imageBytes) async {
    if (_apiKey.isEmpty) {
      throw Exception('Falta configurar la API Key de Gemini en Ajustes.');
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );

    final content = [
      Content.multi([
        TextPart(_prompt),
        DataPart('image/jpeg', imageBytes),
      ]),
    ];

    final response = await model.generateContent(content);
    final text = response.text ?? '';

    if (text.isEmpty) {
      throw Exception('La IA no devolvió respuesta.');
    }

    final json = _cleanJson(text);

    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return ProductDraft.fromJson(decoded);
    } catch (e) {
      throw Exception('No pudimos interpretar la respuesta de la IA.');
    }
  }

  /// Limpia el texto por si la IA devuelve el JSON dentro de bloques ```
  String _cleanJson(String raw) {
    var clean = raw.trim();
    if (clean.startsWith('```')) {
      clean = clean.replaceFirst(RegExp(r'^```(json)?\s*'), '');
      clean = clean.replaceFirst(RegExp(r'\s*```$'), '');
    }
    return clean.trim();
  }
}