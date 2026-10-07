import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/client_store/views/home_view.dart';
import '../../features/client_store/views/not_found_view.dart';
import '../../features/client_store/views/product_detail_view.dart';
import '../../features/client_store/views/search_view.dart';

/// Prefijo del base-href al compilar para GitHub Pages.
/// · Staging: --dart-define=BASE_HREF=/tienda_vertex/
/// · Prod:    --dart-define=BASE_HREF=/
const String kBaseHref = String.fromEnvironment('BASE_HREF', defaultValue: '/');

/// Remueve el prefijo base-href del path leído por el navegador
/// para que GoRouter trabaje siempre con rutas lógicas (/perfumes).
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

final appRouterProvider = Provider<GoRouter>((ref) {
  final initialLocation = stripBaseHref(Uri.base.path);

  return GoRouter(
    initialLocation: initialLocation.isEmpty ? '/' : initialLocation,
    debugLogDiagnostics: false,
    routes: [
      // ── Específicas primero (mayor prioridad de match) ──────
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

      // ── Admin bloqueado en web ──────────────────────────────
      if (!kIsWeb) ...[
        // Fase 4 — se agregan aquí LoginView, DashboardView, etc.
      ],

      // ── Raíz ────────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeView(),
      ),

      // ── Rutas dinámicas de nicho ────────────────────────────
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

      // ── Fallback ────────────────────────────────────────────
      GoRoute(
        path: '/:rest(.*)',
        builder: (context, state) => const NotFoundView(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundView(),
  );
});