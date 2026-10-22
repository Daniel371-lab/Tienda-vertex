import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../../cart/views/cart_drawer.dart';
import '../../checkout/views/checkout_view.dart';
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
    this.mode = HomeMode.general,
    this.categorySlug,
    this.subcategorySlug,
    this.exploreCategorySlug,
  });

  final HomeMode mode;
  final String? categorySlug;
  final String? subcategorySlug;
  final String? exploreCategorySlug;

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();

  bool _searchActive = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(storeControllerProvider.notifier);
      await notifier.loadCategories();
      await notifier.applyMode(
        mode: widget.mode,
        categorySlug: widget.categorySlug,
        subcategorySlug: widget.subcategorySlug,
        exploreCategorySlug: widget.exploreCategorySlug,
      );
    });
  }

  @override
  void didUpdateWidget(HomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode ||
        oldWidget.categorySlug != widget.categorySlug ||
        oldWidget.subcategorySlug != widget.subcategorySlug ||
        oldWidget.exploreCategorySlug != widget.exploreCategorySlug) {
      _searchActive = false;
      _searchController.clear();
      ref.read(storeControllerProvider.notifier).applyMode(
            mode: widget.mode,
            categorySlug: widget.categorySlug,
            subcategorySlug: widget.subcategorySlug,
            exploreCategorySlug: widget.exploreCategorySlug,
          );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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

  void _toggleSearch() {
    setState(() {
      _searchActive = !_searchActive;
      if (!_searchActive) {
        _searchController.clear();
        ref.read(storeControllerProvider.notifier).clearSearch();
      }
    });
  }

  void _executeSearch(String query) {
    if (query.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    ref.read(storeControllerProvider.notifier).search(query);
  }

  void _openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (cartContext) => CartDrawer(
        onCheckout: () {
          Navigator.of(cartContext).pop();
          Future.delayed(const Duration(milliseconds: 150), () {
            if (!mounted) return;
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const CheckoutView(),
            );
          });
        },
      ),
    );
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

    final canSearch = state.showSearchAndFilters;

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
                  final notifier = ref.read(storeControllerProvider.notifier);
                  await notifier.loadCategories();
                  await notifier.applyMode(
                    mode: widget.mode,
                    categorySlug: widget.categorySlug,
                    subcategorySlug: widget.subcategorySlug,
                    exploreCategorySlug: widget.exploreCategorySlug,
                  );
                },
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
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
                            onSearchTap: _toggleSearch,
                            showSearch: canSearch,
                          ),
                        ),

                        if (_searchActive)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                textInputAction: TextInputAction.search,
                                onSubmitted: _executeSearch,
                                decoration: InputDecoration(
                                  hintText: 'Enter para buscar',
                                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    onPressed: _toggleSearch,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        if (_titleFor(state).isNotEmpty && !_searchActive)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                              child: Text(
                                _titleFor(state),
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                            ),
                          ),

                        if (state.mode == HomeMode.explore && !_searchActive)
                          const SliverToBoxAdapter(child: SubcategoryChips()),

                        if (state.isLoadingProducts && state.products.isEmpty)
                          ProductGrid(
                            products: const [],
                            isLoading: true,
                            sortOption: SortOption.recent,
                            onSortChanged: (_) {},
                            showSortButton: false,
                            onTap: (_) {},
                            onAddToCart: (_) {},
                          )
                        else if (state.products.isEmpty && !state.isLoadingProducts)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyState(
                              isSearch: state.isSearching,
                              onRetry: () => ref
                                  .read(storeControllerProvider.notifier)
                                  .applyMode(
                                    mode: widget.mode,
                                    categorySlug: widget.categorySlug,
                                    subcategorySlug: widget.subcategorySlug,
                                    exploreCategorySlug: widget.exploreCategorySlug,
                                  ),
                            ),
                          )
                        else
                          ProductGrid(
                            products: state.visibleProducts,
                            isLoading: false,
                            sortOption: ref.watch(sortOptionProvider),
                            showSortButton: state.showSearchAndFilters && !state.isSearching,
                            onSortChanged: (option) {
                              ref.read(sortOptionProvider.notifier).state = option;
                            },
                            // FIX: Cambiamos go() por push() para que el botón de atrás funcione
                            onTap: (p) => context.push('/producto/${p.id}'),
                            onAddToCart: _addToCart,
                          ),

                        if (state.isLoadingMore && !state.isSearching)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
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
            ),
          ),
        ],
      ),
    );
  }

  String _titleFor(StoreState state) {
    if (state.mode == HomeMode.general) return '';
    if (state.mode == HomeMode.specialized) return '';
    if (state.mode == HomeMode.explore) return state.activeCategory?.name ?? '';
    if (state.mode == HomeMode.subcategory) {
      final catName = state.activeCategory?.name ?? '';
      if (state.activeSubcategory != null) {
        return '$catName · ${state.activeSubcategory!.name}';
      }
      return catName;
    }
    return '';
  }

  void _goToHome() {
    final notifier = ref.read(storeControllerProvider.notifier);
    notifier.selectSubcategory(null);

    if (widget.mode == HomeMode.specialized || widget.mode == HomeMode.subcategory) {
      context.go('/${widget.categorySlug}');
    } else {
      context.go('/');
    }

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.onRetry, this.isSearch = false});
  final VoidCallback onRetry;
  final bool isSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeControllerProvider);
    final errorMsg = state.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearch ? Icons.search_off_rounded : Icons.inventory_2_outlined,
              size: 56,
              color: errorMsg != null ? AppColors.danger : AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              isSearch ? 'Sin resultados para tu búsqueda' : (errorMsg ?? AppStrings.noProducts),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            if (!isSearch) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}