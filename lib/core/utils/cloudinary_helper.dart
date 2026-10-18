abstract final class CloudinaryHelper {
  /// Toma una URL de Cloudinary y le inyecta los parámetros de optimización.
  /// [width] define el ancho máximo de la imagen para ahorrar datos.
  static String optimize(String url, {int width = 600}) {
    if (url.isEmpty) return url;
    
    // Si la URL ya tiene optimizaciones, no hacemos nada
    if (url.contains('f_auto')) return url;

    // Busca el segmento "/upload/" y le inyecta los parámetros justo después
    if (url.contains('/upload/')) {
      return url.replaceFirst('/upload/', '/upload/w_$width,f_auto,q_auto/');
    }
    
    return url;
  }
}