import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/cloudinary_helper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/badge_chip.dart';
import '../../../../models/category_model.dart';
import '../../../../models/product_model.dart';
import '../../controllers/store_controller.dart'; // <-- RUTA CORREGIDA AQUÍ

class ProductCard extends ConsumerStatefulWidget {
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
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _hovering = false;

  String? _getAudienceLabel(List<Category> categories) {
    final p = widget.product;
    if (p.subcategoryIds.isEmpty) return null;

    for (final cat in categories) {
      for (final sub in cat.subcategories) {
        if (p.subcategoryIds.contains(sub.id)) {
          final name = sub.name.toLowerCase();
          if (name.contains('masculin')) return 'Masculino';
          if (name.contains('femenin')) return 'Femenino';
          if (name.contains('unisex')) return 'Unisex';
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final categories = ref.watch(storeControllerProvider).categories;
    final audience = _getAudienceLabel(categories);

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
                                  imageUrl: CloudinaryHelper.optimize(p.mainImage, width: 400),
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
                      
                      // Descuento a la izquierda
                      if (p.hasDiscount)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: BadgeChip(
                            label: '-${p.discountPercent}%',
                            color: AppColors.danger,
                          ),
                        ),
                      
                      // Etiqueta azul centrada arriba de la foto
                      if (audience != null)
                        Positioned(
                          top: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                audience.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
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

                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

                      if (p.hasDiscount)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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