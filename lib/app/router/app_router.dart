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
import '../../features/client_store/views/home_view.dart';
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

      if (!kIsWeb) ...[
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginView(),
        ),
        ShellRoute(
          builder: (context, state, child) =>
              AdminShellView(child: child),
          routes: [
            GoRoute(
              path: '/admin',
              builder: (context, state) => const DashboardView(),
            ),

            // ── Productos ────────────────────────────────
            GoRoute(
              path: '/admin/productos',
              builder: (context, state) => const ProductManagerView(),
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

            // ── Categorías ───────────────────────────────
            GoRoute(
              path: '/admin/categorias',
              builder: (context, state) => const CategoryManagerView(),
              routes: [
                GoRoute(
                  path: 'nueva',
                  builder: (context, state) => const CategoryFormView(),
                ),
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

            // ── Pedidos ──────────────────────────────────
            GoRoute(
              path: '/admin/pedidos',
              builder: (context, state) => const OrderManagerView(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => OrderDetailView(
                    orderId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),

            // ── Otros ────────────────────────────────────
            GoRoute(
              path: '/admin/cupones',
              builder: (context, state) => const CouponManagerView(),
            ),
            GoRoute(
              path: '/admin/blacklist',
              builder: (context, state) => const BlacklistView(),
            ),
            GoRoute(
              path: '/admin/ajustes',
              builder: (context, state) => const SettingsView(),
            ),
          ],
        ),
      ],

      GoRoute(
        path: '/',
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: '/:slug',
        builder: (context, state) => HomeView(
          categorySlug: state.pathParameters['slug'],
        ),
      ),
      GoRoute(
        path: '/:slug/:subSlug',
        builder: (context, state) => HomeView(
          categorySlug: state.pathParameters['slug'],
          subcategorySlug: state.pathParameters['subSlug'],
        ),
      ),

      GoRoute(
        path: '/:rest(.*)',
        builder: (context, state) => const NotFoundView(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundView(),
  );
});