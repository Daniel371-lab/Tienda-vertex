import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'firebase_options.dart';
import 'services/firebase/firebase_providers.dart';
import 'services/seed/seed_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Captura de errores de widgets: muestra el error en pantalla
  // en vez de la caja gris por defecto.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      color: Colors.red,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Text(
          'ERROR EN WIDGET:\n\n${details.exception}\n\n${details.stack}',
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ),
    );
  };

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Carga datos de prueba la primera vez (solo si Firestore está vacío).
  final container = ProviderContainer();
  await SeedService(container.read(firestoreInstanceProvider)).runIfNeeded();
  container.dispose();

  FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

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