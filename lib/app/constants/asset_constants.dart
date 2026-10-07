/// Rutas de assets estáticos.
///
/// Por ahora usamos SVGs generados en código (VertexLogo).
/// Los archivos reales se agregan aquí cuando estén listos.
abstract final class AssetConstants {
  static const String _images = 'assets/images';

  static const String placeholderProduct = '$_images/placeholder_product.png';
  static const String placeholderHero    = '$_images/placeholder_hero.png';
  static const String emptyCart          = '$_images/empty_cart.svg';
  static const String emptyResults       = '$_images/empty_results.svg';
}