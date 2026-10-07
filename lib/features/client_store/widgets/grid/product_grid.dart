import 'package:flutter/material.dart';

import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../models/product_model.dart';
import 'product_card.dart';

/// Grilla responsiva de productos.
///   · < 600px  → 2 columnas
///   · 600-1024 → 3 columnas
///   · > 1024   → 4 columnas
///   · > 1440   → 5 columnas
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    required this.isLoading,
    required this.onTap,
    required this.onAddToCart,
  });

  final List<Product> products;
  final bool isLoading;
  final void Function(Product) onTap;
  final void Function(Product) onAddToCart;

  int _columns(double width) {
    if (width < 600) return 2;
    if (width < 1024) return 3;
    if (width < 1440) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = _columns(width);

    if (isLoading && products.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, __) => const ProductCardShimmer(),
            childCount: cols * 2,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final p = products[index];
            return ProductCard(
              product: p,
              onTap: () => onTap(p),
              onAddToCart: () => onAddToCart(p),
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }
}