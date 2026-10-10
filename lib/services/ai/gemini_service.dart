import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

/// Borrador de producto que devuelve la IA tras analizar las capturas.
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

  static const String _model = 'gemini-flash-latest';

  static const String _prompt = '''
Analizá la o las capturas de pantalla de un producto de e-commerce y extraé su información.

Podés recibir 1 o 2 imágenes del mismo producto (por ejemplo, la parte superior con el título y precio, y la parte inferior con la descripción). Combiná la información de todas las imágenes.

Devolvé ÚNICAMENTE un JSON válido (sin texto antes ni después, sin bloques de código) con esta estructura exacta:

{
  "title": "Nombre completo del producto con marca y modelo si es visible",
  "description": "Descripción breve pero completa del producto. Si la captura no incluye una descripción textual, generá una descripción atractiva y coherente basada en la marca, tipo de producto y características visibles. Debe tener entre 40 y 120 palabras.",
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
- Los tags son palabras clave útiles para búsqueda (3 a 5 tags).
- Si no hay descripción visible en ninguna captura, GENERÁ una descripción profesional y atractiva basada en lo que sabés del producto.
''';

  /// Analiza 1 o 2 imágenes y devuelve el borrador del producto.
  /// Todas las imágenes se envían en un solo request.
  Future<ProductDraft> extractFromImages(List<Uint8List> images) async {
    if (_apiKey.isEmpty) {
      throw Exception('Falta configurar la API Key de Gemini en Ajustes.');
    }
    if (images.isEmpty) {
      throw Exception('No se recibió ninguna imagen.');
    }

    final model = GenerativeModel(
      model: _model,
      apiKey: _apiKey,
    );

    final parts = <Part>[TextPart(_prompt)];
    for (final img in images) {
      parts.add(DataPart('image/jpeg', img));
    }

    final content = [Content.multi(parts)];

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

  String _cleanJson(String raw) {
    var clean = raw.trim();
    if (clean.startsWith('```')) {
      clean = clean.replaceFirst(RegExp(r'^```(json)?\s*'), '');
      clean = clean.replaceFirst(RegExp(r'\s*```$'), '');
    }
    return clean.trim();
  }
}