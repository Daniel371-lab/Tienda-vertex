import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/badge_chip.dart';
import '../../../../models/product_model.dart';

/// Card minimalista de producto.
///
/// · Sin botón de agregar (toda la card es clickeable)
/// · Imagen más panorámica (aspect 1.1) para no ocupar tanto espacio
/// · Precios en columna: anterior tachado arriba, actual grande abajo
/// · FittedBox para evitar overflow con precios largos
class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(_hovering ? 1.02 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.6),
            boxShadow: _hovering
                ? AppColors.cardShadowHover
                : AppColors.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Imagen más panorámica (1.1) ───────────────
                AspectRatio(
                  aspectRatio: 1.1,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Hero(
                          tag: 'product-image-${p.id}',
                          child: p.mainImage.isEmpty
                              ? Container(
                                  color: AppColors.surfaceAlt,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: AppColors.textMuted,
                                    size: 40,
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: p.mainImage,
                                  fit: BoxFit.cover,
                                  fadeInDuration:
                                      const Duration(milliseconds: 250),
                                  placeholder: (_, __) => Container(
                                    color: AppColors.surfaceAlt,
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: AppColors.surfaceAlt,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      if (p.hasDiscount)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: BadgeChip(
                            label: '-${p.discountPercent}%',
                            color: AppColors.danger,
                          ),
                        ),
                      if (p.stock <= 0)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white.withOpacity(0.7),
                            alignment: Alignment.center,
                            child: const BadgeChip(
                              label: 'SIN STOCK',
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Info ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título (máx 2 líneas)
                      SizedBox(
                        height: 34,
                        child: Text(
                          p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontSize: 13,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Precios
                      if (p.hasDiscount)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Precio anterior (chico, tachado)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(p.compareAtPrice!),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Precio actual (grande)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(p.price),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatter.format(p.price),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}