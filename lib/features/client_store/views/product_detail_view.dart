import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/badge_chip.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../models/product_model.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../../checkout/views/checkout_view.dart';
import '../controllers/cart_controller.dart';

final _productDetailProvider =
    FutureProvider.family<Product?, String>((ref, id) async {
  return ref.watch(firestoreServiceProvider).findProductById(id);
});

class ProductDetailView extends ConsumerStatefulWidget {
  const ProductDetailView({super.key, required this.productId});
  final String productId;

  @override
  ConsumerState<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<ProductDetailView> {
  int _imageIndex = 0;

  Future<void> _addToCart(Product product, int quantity) async {
    await ref.read(cartControllerProvider.notifier).addProduct(product, quantity: quantity);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.title} agregado'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
      ),
    );
    await ref.read(analyticsServiceProvider).logAddToCart(product, quantity);
  }

  Future<void> _buyNow(Product product, int quantity) async {
    // 1. Limpiamos el carrito actual para que solo se compre este producto
    await ref.read(cartControllerProvider.notifier).clear();
    
    // 2. Agregamos el producto con la cantidad seleccionada
    await ref.read(cartControllerProvider.notifier).addProduct(product, quantity: quantity);
    
    if (!mounted) return;

    // 3. Abrimos la ventana de Checkout directo
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CheckoutView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncProduct = ref.watch(_productDetailProvider(widget.productId));
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return Scaffold(
      body: SafeArea(
        child: asyncProduct.when(
          loading: () => const _DetailShimmer(),
          error: (_, __) => const _DetailError(),
          data: (product) {
            if (product == null || !product.isActive) {
              return const _DetailError();
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(analyticsServiceProvider)
                  .logItemViewed(product);
            });
            return _buildContent(product, isWide);
          },
        ),
      ),
    );
  }

  Widget _buildContent(Product product, bool isWide) {
    // Usamos una variable local para la cantidad
    int quantity = 1; 

    final content = StatefulBuilder(
      builder: (context, setState) {
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Galería ─────────────────────────────────────
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: product.images.isEmpty ? 1 : product.images.length,
                    onPageChanged: (i) => setState(() => _imageIndex = i),
                    itemBuilder: (context, i) {
                      final url = product.images.isEmpty
                          ? ''
                          : product.images[i];
                      if (url.isEmpty) {
                        return Container(
                          color: AppColors.surfaceAlt,
                          child: const Icon(
                            Icons.image_outlined,
                            size: 60,
                            color: AppColors.textMuted,
                          ),
                        );
                      }
                      return Hero(
                        tag: 'product-image-${product.id}',
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 250),
                          placeholder: (_, __) =>
                              Container(color: AppColors.surfaceAlt),
                        ),
                      );
                    },
                  ),
                  if (product.images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          product.images.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _imageIndex ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _imageIndex
                                  ? AppColors.primary
                                  : Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: BadgeChip(
                        label: '-${product.discountPercent}%',
                        color: AppColors.danger,
                      ),
                    ),
                ],
              ),
            ),

            // ── Info ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.stock > 0)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: BadgeChip(
                        label: 'DISPONIBLE',
                        color: AppColors.success,
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: BadgeChip(
                        label: 'SIN STOCK',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(product.price),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            CurrencyFormatter.format(product.compareAtPrice!),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.description,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isEmpty
                        ? 'Sin descripción disponible.'
                        : product.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Selector de cantidad
                  Row(
                    children: [
                      Text('Cantidad:', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: () {
                                if (quantity > 1) setState(() => quantity--);
                              },
                            ),
                            Text('$quantity', style: Theme.of(context).textTheme.titleMedium),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () {
                                if (quantity < product.stock) setState(() => quantity++);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // BOTONES
                  Row(
                    children: [
                      // Botón Agregar
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: product.stock > 0 ? () => _addToCart(product, quantity) : null,
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                          label: const Text('Agregar'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botón Comprar Ahora
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: product.stock > 0 ? () => _buyNow(product, quantity) : null,
                          icon: const Icon(Icons.flash_on_rounded, size: 20),
                          label: const Text('Comprar ahora'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

        return content;
      },
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: content),
                      ],
                    )
                  : content,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ShimmerBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 16,
            ),
          ),
          SizedBox(height: 24),
          ShimmerBox(width: 240, height: 20),
          SizedBox(height: 12),
          ShimmerBox(width: 120, height: 16),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Producto no disponible',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text(AppStrings.notFoundCta),
            ),
          ],
        ),
      ),
    );
  }
}