import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/router/niche_context.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../../cart/views/cart_drawer.dart';
import '../controllers/cart_controller.dart';
import '../controllers/store_controller.dart';
import '../widgets/drawer/smart_drawer.dart';
import '../widgets/footer/store_footer.dart';
import '../widgets/grid/product_grid.dart';
import '../widgets/header/glass_header.dart';
import '../widgets/subcategories/subcategory_chips.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({
    super.key,
    this.categorySlug,
    this.subcategorySlug,
  });

  final String? categorySlug;
  final String? subcategorySlug;

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(storeControllerProvider.notifier);
      await notifier.loadCategories();
      await notifier.applyNiche(
        NicheContext(
          categorySlug: widget.categorySlug,
          subcategorySlug: widget.subcategorySlug,
        ),
      );
    });
  }

  @override
  void didUpdateWidget(HomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categorySlug != widget.categorySlug ||
        oldWidget.subcategorySlug != widget.subcategorySlug) {
      ref.read(storeControllerProvider.notifier).applyNiche(
            NicheContext(
              categorySlug: widget.categorySlug,
              subcategorySlug: widget.subcategorySlug,
            ),
          );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      ref.read(storeControllerProvider.notifier).loadMore();
    }
  }

  void _openDrawer() {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1024) return;
    _scaffoldKey.currentState?.openDrawer();
  }

  void _openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CartDrawer(),
    );
  }

  void _openSearch() {
    context.go('/buscar');
  }

  Future<void> _addToCart(Product product) async {
    await ref.read(cartControllerProvider.notifier).addProduct(product);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.title} agregado'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
      ),
    );
    await ref.read(analyticsServiceProvider).logAddToCart(product, 1);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1024;
    final cartCount = ref.watch(cartCountProvider);
    final state = ref.watch(storeControllerProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: isWide
          ? null
          : Drawer(
              width: 300,
              backgroundColor: AppColors.surface,
              child: SmartDrawer(
                onNavigate: () => _scaffoldKey.currentState?.closeDrawer(),
              ),
            ),
      body: Row(
        children: [
          if (isWide) const SmartDrawer(isPersistent: true),

          Expanded(
            child: SafeArea(
              top: false,
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  final notifier =
                      ref.read(storeControllerProvider.notifier);
                  await notifier.loadCategories();
                  await notifier.applyNiche(
                    NicheContext(
                      categorySlug: widget.categorySlug,
                      subcategorySlug: widget.subcategorySlug,
                    ),
                  );
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      floating: false,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      automaticallyImplyLeading: false,
                      expandedHeight: 64,
                      toolbarHeight: 64,
                      backgroundColor: Colors.transparent,
                      flexibleSpace: GlassHeader(
                        cartCount: cartCount,
                        onMenuTap: _openDrawer,
                        onLogoTap: _goToHome,
                        onCartTap: _openCart,
                        onSearchTap: _openSearch,
                        showSearch: isWide,
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Text(
                          _titleFor(state.activeCategory?.name),
                          style:
                              Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: SubcategoryChips(),
                    ),

                    if (state.isLoadingProducts && state.products.isEmpty)
                      ProductGrid(
                        products: const [],
                        isLoading: true,
                        onTap: (_) {},
                        onAddToCart: (_) {},
                      )
                    else if (!state.hasProducts && !state.isLoadingProducts)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          onRetry: () => ref
                              .read(storeControllerProvider.notifier)
                              .applyNiche(
                                NicheContext(
                                  categorySlug: widget.categorySlug,
                                  subcategorySlug: widget.subcategorySlug,
                                ),
                              ),
                        ),
                      )
                    else
                      ProductGrid(
                        products: state.visibleProducts,
                        isLoading: false,
                        onTap: (p) => context.go('/producto/${p.id}'),
                        onAddToCart: _addToCart,
                      ),

                    if (state.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: StoreFooter()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _titleFor(String? categoryName) {
    if (categoryName == null || categoryName.isEmpty) {
      return AppStrings.allProducts;
    }
    return categoryName;
  }

  void _goToHome() {
    final notifier = ref.read(storeControllerProvider.notifier);
    notifier.selectSubcategory(null);
    if (widget.categorySlug != null) {
      context.go('/${widget.categorySlug}');
    } else {
      context.go('/');
    }
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeControllerProvider);
    final errorMsg = state.error;
    final debug = 'Cat: ${state.categories.length} · '
        'Prod: ${state.products.length} · '
        'Err: ${errorMsg ?? "ninguno"}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              errorMsg ?? AppStrings.noProducts,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: errorMsg != null
                        ? AppColors.danger
                        : AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                debug,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}