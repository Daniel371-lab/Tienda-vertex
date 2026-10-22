import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/cloudinary_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/badge_chip.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../models/category_model.dart';
import '../../../models/product_model.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../../checkout/views/checkout_view.dart';
import '../controllers/cart_controller.dart';
import '../controllers/store_controller.dart';

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
  final PageController _pageController = PageController();
  Timer? _autoplayTimer;
  int _imageIndex = 0;
  int _quantity = 1;

  @override
  void dispose() {
    _pageController.dispose();
    _autoplayTimer?.cancel();
    super.dispose();
  }

  void _startAutoplay(int totalImages) {
    _autoplayTimer?.cancel();
    if (totalImages <= 1) return;

    _autoplayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage >= totalImages) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoplay() {
    _autoplayTimer?.cancel();
  }

  Future<void> _addToCart(Product product) async {
    await ref.read(cartControllerProvider.notifier).addProduct(product, quantity: _quantity);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.title} agregado'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
      ),
    );
    await ref.read(analyticsServiceProvider).logAddToCart(product, _quantity);
  }

  Future<void> _buyNow(Product product) async {
    await ref.read(cartControllerProvider.notifier).clear();
    await ref.read(cartControllerProvider.notifier).addProduct(product, quantity: _quantity);
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CheckoutView(),
    );
  }

  // ── NUEVO: Buscador de público basado en subcategoría ──
  String? _getAudienceLabel(Product product, List<Category> categories) {
    if (product.subcategoryIds.isEmpty) return null;

    for (final cat in categories) {
      for (final sub in cat.subcategories) {
        if (product.subcategoryIds.contains(sub.id)) {
          final name = sub.name.toLowerCase();
          if (name.contains('masculin')) return 'Masculino';
          if (name.contains('femenin')) return 'Femenino';
          if (name.contains('unisex')) return 'Unisex';
        }
      }
    }
    return null;
  }
  // ─────────────────────────────────────────────────────

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
            
            if (_autoplayTimer == null || !_autoplayTimer!.isActive) {
              _startAutoplay(product.images.length);
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(analyticsServiceProvider).logItemViewed(product);
            });
            return _buildContent(product, isWide);
          },
        ),
      ),
    );
  }

  Widget _buildContent(Product product, bool isWide) {
    // Leemos las categorías para saber el nombre de la subcategoría
    final categories = ref.watch(storeControllerProvider).categories;
    final audience = _getAudienceLabel(product, categories);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Listener(
            onPointerDown: (_) => _stopAutoplay(),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: product.images.isEmpty ? 1 : product.images.length,
                  onPageChanged: (i) => setState(() => _imageIndex = i),
                  itemBuilder: (context, i) {
                    final url = product.images.isEmpty ? '' : product.images[i];
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
                        imageUrl: CloudinaryHelper.optimize(url, width: 800),
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 250),
                        placeholder: (_, __) => Container(color: AppColors.surfaceAlt),
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
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (product.stock > 0)
                    const BadgeChip(
                      label: 'DISPONIBLE',
                      color: AppColors.success,
                    )
                  else
                    const BadgeChip(
                      label: 'SIN STOCK',
                      color: AppColors.textSecondary,
                    ),
                  
                  // ── ETIQUETA AZUL (Basada en subcategoría) ──
                  if (audience != null) ...[
                    const SizedBox(width: 8),
                    BadgeChip(
                      label: audience.toUpperCase(),
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

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
                            if (_quantity > 1) setState(() => _quantity--);
                          },
                        ),
                        Text('$_quantity', style: Theme.of(context).textTheme.titleMedium),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: () {
                            if (_quantity < product.stock) setState(() => _quantity++);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              Row(
                children: [
                  SizedBox(
                    height: 50,
                    width: 60,
                    child: OutlinedButton(
                      onPressed: product.stock > 0 ? () => _addToCart(product) : null,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.add_shopping_cart_rounded, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: product.stock > 0 ? () => _buyNow(product) : null,
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

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
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