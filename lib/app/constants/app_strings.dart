/// Textos de la interfaz — español paraguayo neutro, sin voseo.
abstract final class AppStrings {
  // ── Marca ─────────────────────────────────────────────────
  static const String appName        = 'Tienda Vertex';
  static const String tagline        = 'Perfumería · Relojería · Joyería · Electrónica';
  static const String footerCredit   = '© 2026 Tienda Vertex. Desarrollado por JPLABS.';

  // ── Header / Navegación ───────────────────────────────────
  static const String menuTooltip        = 'Abrir menú';
  static const String cartTooltip        = 'Ver carrito';
  static const String searchTooltip      = 'Buscar productos';
  static const String backToAllCategories = 'Ver todas las categorías';

  // ── Home ──────────────────────────────────────────────────
  static const String allProducts        = 'Todos los productos';
  static const String featuredProducts   = 'Destacados';
  static const String noProducts         = 'No hay productos disponibles';
  static const String filterAll          = 'Todos';
  static const String loadingError       = 'No pudimos cargar los datos. Intenta nuevamente.';

  // ── Carrito ───────────────────────────────────────────────
  static const String emptyCartTitle     = 'Tu carrito está vacío';
  static const String emptyCartSubtitle  = 'Agregá productos para comenzar.';
  static const String addToCart          = 'Agregar al carrito';
  static const String addedToCart        = 'Agregado al carrito';
  static const String checkout           = 'Finalizar compra';
  static const String continueShopping   = 'Seguir comprando';
  static const String subtotal           = 'Subtotal';
  static const String discount           = 'Descuento';
  static const String total              = 'Total';

  // ── Checkout ──────────────────────────────────────────────
  static const String checkoutTitle       = 'Confirmar pedido';
  static const String fieldFullName       = 'Nombre y apellido';
  static const String fieldPhone          = 'Teléfono celular';
  static const String fieldDepartment     = 'Departamento';
  static const String fieldCity           = 'Ciudad';
  static const String fieldAddress        = 'Dirección o referencia';
  static const String fieldCoupon         = 'Código de cupón (opcional)';
  static const String applyCoupon         = 'Aplicar';
  static const String couponApplied       = 'Cupón aplicado';
  static const String couponInvalid       = 'Cupón inválido o expirado';
  static const String confirmOrder        = 'Confirmar pedido';
  static const String orderCreatedTitle   = 'Pedido creado';
  static const String orderCreatedBody    = 'Te contactaremos por WhatsApp para confirmar el envío.';
  static const String genericError        = 'No pudimos procesar el pedido. Intenta nuevamente.';

  // ── Detalle producto ──────────────────────────────────────
  static const String description        = 'Descripción';
  static const String outOfStock         = 'Sin stock';
  static const String inStock            = 'Disponible';

  // ── Footer ────────────────────────────────────────────────
  static const String footerContact      = 'Contacto';
  static const String footerAbout        = 'Sobre nosotros';
  static const String footerLinks        = 'Enlaces útiles';
  static const String footerAboutText    = 'Tienda Vertex reúne galerías comerciales especializadas en un solo punto de encuentro.';
  static const String footerGuarantee    = 'Envíos a todo Paraguay con pago contra entrega.';
  static const String footerWhatsapp     = 'Atención por WhatsApp';
  static const String footerEmail        = 'Correo electrónico';
  static const String footerLocation     = 'Luque · Asunción, Paraguay';
  static const String linkShipping       = 'Términos de envío';
  static const String linkReturns        = 'Políticas de devolución';
  static const String linkFaq            = 'Preguntas frecuentes';

  // ── Errores / Estados ─────────────────────────────────────
  static const String notFoundTitle      = 'Página no encontrada';
  static const String notFoundBody       = 'La ruta que buscas no existe o fue movida.';
  static const String notFoundCta        = 'Volver al inicio';
}