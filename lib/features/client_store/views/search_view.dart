import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../controllers/cart_controller.dart';
import '../controllers/store_controller.dart';
import '../widgets/grid/product_grid.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({
    super.key,
    this.initialQuery,
    this.categorySlug,
    this.subcategorySlug,
  });

  final String? initialQuery;
  final String? categorySlug;
  final String? subcategorySlug;

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  late final TextEditingController _controller;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery ?? '';
    _controller = TextEditingController(text: _query);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(storeControllerProvider.notifier).loadCategories();
      // Cargamos el contexto de búsqueda según la URL
      await ref.read(storeControllerProvider.notifier).loadSearchContext(
            categorySlug: widget.categorySlug,
            subcategorySlug: widget.subcategorySlug,
          );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Product> _filter(List<Product> source) {
    if (_query.trim().isEmpty) return const [];
    final q = _query.toLowerCase().trim();
    return source.where((p) {
      return p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _addToCart(Product product) async {
    await ref.read(cartControllerProvider.notifier).addProduct(product);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.title} agregado'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  void _goBack() {
    // Si hay historial, volvemos atrás. Si no, vamos al dashboard.
    if (context.canPop()) {
      context.pop();
    } else {
      if (widget.categorySlug != null) {
        if (widget.subcategorySlug != null) {
          context.go('/${widget.categorySlug}/${widget.subcategorySlug}');
        } else {
          context.go('/${widget.categorySlug}');
        }
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeControllerProvider);
    final sortOption = ref.watch(sortOptionProvider);
    final results = _filter(state.products);

    // Texto del título según el contexto
    String contextText = 'Buscar';
    if (widget.categorySlug != null) {
      final cat = state.categories
          .where((c) => c.slug == widget.categorySlug)
          .firstOrNull;
      if (cat != null) {
        contextText = 'Buscar en ${cat.name}';
        if (widget.subcategorySlug != null) {
          final sub = cat.subcategories
              .where((s) => s.slug == widget.subcategorySlug)
              .firstOrNull;
          if (sub != null) {
            contextText = 'Buscar en ${cat.name} · ${sub.name}';
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: contextText,
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: state.isLoadingProducts
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    )
                  : _query.trim().isEmpty
                      ? const _EmptySearch()
                      : results.isEmpty
                          ? const _NoResults()
                          : CustomScrollView(
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 8, 20, 0),
                                    child: Text(
                                      '${results.length} resultados',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                    ),
                                  ),
                                ),
                                ProductGrid(
                                  products: results,
                                  isLoading: false,
                                  sortOption: sortOption,
                                  showSortButton: true,
                                  onSortChanged: (option) {
                                    ref
                                        .read(sortOptionProvider.notifier)
                                        .state = option;
                                  },
                                  onTap: (p) =>
                                      context.go('/producto/${p.id}'),
                                  onAddToCart: _addToCart,
                                ),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();
  @override
  Widget build(BuildContext context) => Center(
        child: Icon(
          Icons.search_rounded,
          size: 56,
          color: AppColors.textMuted,
        ),
      );
}

class _NoResults extends StatelessWidget {
  const _NoResults();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 56, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                'Sin resultados',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
}