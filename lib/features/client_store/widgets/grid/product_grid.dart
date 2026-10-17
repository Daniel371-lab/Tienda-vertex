import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../models/product_model.dart';
import 'product_card.dart';

enum SortOption {
  recent('Más recientes'),
  priceAsc('Precio: menor a mayor'),
  priceDesc('Precio: mayor a menor');

  const SortOption(this.label);
  final String label;
}

final sortOptionProvider = StateProvider<SortOption>((ref) => SortOption.recent);

class ProductGrid extends ConsumerWidget {
  const ProductGrid({
    super.key,
    required this.products,
    required this.isLoading,
    required this.onTap,
    required this.onAddToCart,
    required this.sortOption,
    required this.onSortChanged,
    this.showSortButton = false,
  });

  final List<Product> products;
  final bool isLoading;
  final void Function(Product) onTap;
  final void Function(Product) onAddToCart;
  final SortOption sortOption;
  final void Function(SortOption) onSortChanged;
  final bool showSortButton;

  int _columns(double width) {
    if (width < 600) return 2;
    if (width < 1024) return 3;
    if (width < 1440) return 4;
    return 5;
  }

  List<Product> _sorted(List<Product> source) {
    final list = [...source];
    switch (sortOption) {
      case SortOption.recent:
        list.sort((a, b) {
          final aD = a.createdAt ?? DateTime(1970);
          final bD = b.createdAt ?? DateTime(1970);
          return bD.compareTo(aD);
        });
        break;
      case SortOption.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final sorted = _sorted(products);

    return SliverMainAxisGroup(
      slivers: [
        if (showSortButton)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${sorted.length} producto${sorted.length == 1 ? "" : "s"}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ),
                  _SortButton(
                    current: sortOption,
                    onChanged: onSortChanged,
                  ),
                ],
              ),
            ),
          ),
        SliverPadding(
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
                final p = sorted[index];
                return ProductCard(
                  product: p,
                  onTap: () => onTap(p),
                  onAddToCart: () => onAddToCart(p),
                );
              },
              childCount: sorted.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.current, required this.onChanged});
  final SortOption current;
  final void Function(SortOption) onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showSortSheet(context),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              'Ordenar',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Ordenar por', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final option in SortOption.values)
              RadioListTile<SortOption>(
                value: option,
                groupValue: current,
                onChanged: (v) {
                  if (v != null) {
                    onChanged(v);
                    Navigator.of(sheetCtx).pop();
                  }
                },
                title: Text(option.label),
                activeColor: AppColors.primary,
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}