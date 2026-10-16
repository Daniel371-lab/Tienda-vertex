import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin_cpanel/views/admin_shell_view.dart';
import '../../features/admin_cpanel/views/blacklist_view.dart';
import '../../features/admin_cpanel/views/category_form_view.dart';
import '../../features/admin_cpanel/views/category_manager_view.dart';
import '../../features/admin_cpanel/views/coupon_manager_view.dart';
import '../../features/admin_cpanel/views/dashboard_view.dart';
import '../../features/admin_cpanel/views/login_view.dart';
import '../../features/admin_cpanel/views/order_detail_view.dart';
import '../../features/admin_cpanel/views/order_manager_view.dart';
import '../../features/admin_cpanel/views/product_form_view.dart';
import '../../features/admin_cpanel/views/product_manager_view.dart';
import '../../features/admin_cpanel/views/settings_view.dart';
import '../../features/admin_cpanel/views/subcategory_manager_view.dart';
import '../../features/client_store/controllers/store_controller.dart';
import '../../features/client_store/views/home_view.dart';
import '../../features/client_store/views/legal/about_view.dart';
import '../../features/client_store/views/legal/faq_view.dart';
import '../../features/client_store/views/legal/returns_view.dart';
import '../../features/client_store/views/legal/shipping_terms_view.dart';
import '../../features/client_store/views/not_found_view.dart';
import '../../features/client_store/views/product_detail_view.dart';
import '../../features/client_store/views/search_view.dart';
import '../../services/ai/gemini_service.dart';

const String kBaseHref = String.fromEnvironment('BASE_HREF', defaultValue: '/');

String stripBaseHref(String path) {
  if (kBaseHref == '/' || kBaseHref.isEmpty) return path;
  final base = kBaseHref.endsWith('/')
      ? kBaseHref.substring(0, kBaseHref.length - 1)
      : kBaseHref;
  if (path.startsWith(base)) {
    final stripped = path.substring(base.length);
    return stripped.isEmpty ? '/' : stripped;
  }
  return path;
}

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthRefreshNotifier(
    FirebaseAuth.instance.authStateChanges(),
  );
  ref.onDispose(authNotifier.dispose);

  final initialFromUrl = stripBaseHref(Uri.base.path);
  final initialLocation = kIsWeb
      ? (initialFromUrl.isEmpty ? '/' : initialFromUrl)
      : '/admin';

  return GoRouter(
    initialLocation: initialLocation,
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final goingToAdmin = state.matchedLocation.startsWith('/admin');
      final goingToLogin = state.matchedLocation == '/login';

      if (kIsWeb && (goingToAdmin || goingToLogin)) return '/';
      if (!kIsWeb && !isLoggedIn && goingToAdmin) return '/login';
      if (!kIsWeb && isLoggedIn && goingToLogin) return '/admin';
      return null;
    },
    routes: [
      // ── Páginas legales ─────────────────────────────────────
      GoRoute(path: '/nosotros', builder: (_, __) => const AboutView()),
      GoRoute(path: '/terminos', builder: (_, __) => const ShippingTermsView()),
      GoRoute(path: '/devoluciones', builder: (_, __) => const ReturnsView()),
      GoRoute(path: '/faq', builder: (_, __) => const FaqView()),

      // ── Rutas con parámetros ────────────────────────────────
      GoRoute(
        path: '/producto/:id',
        builder: (context, state) => ProductDetailView(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/buscar',
        builder: (context, state) => SearchView(
          initialQuery: state.uri.queryParameters['q'],
        ),
      ),

      // ── Admin ───────────────────────────────────────────────
      if (!kIsWeb) ...[
        GoRoute(path: '/login', builder: (_, __) => const LoginView()),
        ShellRoute(
          builder: (context, state, child) =>
              AdminShellView(child: child),
          routes: [
            GoRoute(path: '/admin', builder: (_, __) => const DashboardView()),
            GoRoute(
              path: '/admin/productos',
              builder: (_, __) => const ProductManagerView(),
              routes: [
                GoRoute(
                  path: 'nuevo',
                  builder: (context, state) => ProductFormView(
                    draft: state.extra is ProductDraft
                        ? state.extra as ProductDraft
                        : null,
                  ),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => ProductFormView(
                    productId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/admin/categorias',
              builder: (_, __) => const CategoryManagerView(),
              routes: [
                GoRoute(path: 'nueva', builder: (_, __) => const CategoryFormView()),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => CategoryFormView(
                    categoryId: state.pathParameters['id'],
                  ),
                  routes: [
                    GoRoute(
                      path: 'subcategorias',
                      builder: (context, state) => SubcategoryManagerView(
                        categoryId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/admin/pedidos',
              builder: (_, __) => const OrderManagerView(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => OrderDetailView(
                    orderId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(path: '/admin/cupones', builder: (_, __) => const CouponManagerView()),
            GoRoute(path: '/admin/blacklist', builder: (_, __) => const BlacklistView()),
            GoRoute(path: '/admin/ajustes', builder: (_, __) => const SettingsView()),
          ],
        ),
      ],

      // ── Tienda pública ──────────────────────────────────────
      // Home general o explore (`/?cat=perfumes`)
      GoRoute(
        path: '/',
        builder: (context, state) {
          final explore = state.uri.queryParameters['cat'];
          return HomeView(
            mode: explore != null ? HomeMode.explore : HomeMode.general,
            exploreCategorySlug: explore,
          );
        },
      ),
      // Tienda especializada (`/perfumes`)
      GoRoute(
        path: '/:slug',
        builder: (context, state) => HomeView(
          mode: HomeMode.specialized,
          categorySlug: state.pathParameters['slug'],
        ),
      ),
      // Subcategoría (`/perfumes/arabes`)
      GoRoute(
        path: '/:slug/:subSlug',
        builder: (context, state) => HomeView(
          mode: HomeMode.subcategory,
          categorySlug: state.pathParameters['slug'],
          subcategorySlug: state.pathParameters['subSlug'],
        ),
      ),

      // ── Fallback ────────────────────────────────────────────
      GoRoute(
        path: '/:rest(.*)',
        builder: (_, __) => const NotFoundView(),
      ),
    ],
    errorBuilder: (_, __) => const NotFoundView(),
  );
}