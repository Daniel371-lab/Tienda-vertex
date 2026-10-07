import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_strategy/url_strategy.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Estrategia de URL:
  //  · Web producción: PathUrlStrategy → tiendavertex.com/perfumes
  //  · Web staging GH Pages: HashUrlStrategy → #/perfumes (evita 404)
  //    Se activa al compilar con: --dart-define=USE_HASH_URL=true
  const useHash = bool.fromEnvironment('USE_HASH_URL', defaultValue: false);
  setUrlStrategy(useHash ? const HashUrlStrategy() : const PathUrlStrategy());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Analytics en modo lazy: no bloquea el arranque.
  FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  // Modo Edge-to-Edge (móvil) con barras transparentes.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: TiendaVertexApp()));
}

class TiendaVertexApp extends ConsumerWidget {
  const TiendaVertexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Tienda Vertex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        // Edge-to-edge: SafeArea global con top/bottom true.
        // Las vistas que necesiten full-bleed (como el GlassHeader)
        // ya manejan su propio SafeArea interno.
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1).clamp(0.9, 1.3),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}