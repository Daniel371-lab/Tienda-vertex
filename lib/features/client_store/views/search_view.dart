import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../controllers/cart_controller.dart';
import '../controllers/store_controller.dart';
import '../widgets/grid/product_grid.dart';

/// Búsqueda client-side sobre el catálogo ya cargado.
/// Cero lecturas extra a Firestore.
class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key, this.initialQuery});
  final String? initialQuery;

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
      await ref.read(storeControllerProvider.notifier).applyNiche(
            const NicheContextStub(),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeControllerProvider);
    final results = _filter(state.products);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Barra de búsqueda ─────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: (v) {
                        setState(() => _query = v);
                      },
                      decoration: const InputDecoration(
                        hintText: 'Buscar productos...',
                        prefixIcon: Icon(Icons.search_rounded, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Resultados ────────────────────────────────
            Expanded(
              child: _query.trim().isEmpty
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
              Icon(Icons.search_off_rounded,
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

/// Stub para forzar carga del catálogo global al entrar a búsqueda.
class NicheContextStub {
  const NicheContextStub();
}