// File generated manually — editar solo si cambia la configuración del proyecto.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // WEB
  // ─────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCsjc69UqMG2SbIver-L5jOpuivU4I3wNs',
    appId: '1:999067611562:web:53a01ac50af1672c45bbd3',
    messagingSenderId: '999067611562',
    projectId: 'vertex-tienda',
    authDomain: 'vertex-tienda.firebaseapp.com',
    storageBucket: 'vertex-tienda.firebasestorage.app',
    measurementId: 'G-KXEWTRTRQS',
  );

  // ─────────────────────────────────────────────────────────────
  // ANDROID
  // ─────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA_vqhIf-A6A1g83E8rppHgUr_ecgzn4jk',
    appId: '1:999067611562:android:00d9b255dc56950045bbd3',
    messagingSenderId: '999067611562',
    projectId: 'vertex-tienda',
    storageBucket: 'vertex-tienda.firebasestorage.app',
  );

  // ─────────────────────────────────────────────────────────────
  // iOS — pendiente (Fase 5, cuando compilemos iOS)
  // ─────────────────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'PENDIENTE',
    appId: 'PENDIENTE',
    messagingSenderId: '999067611562',
    projectId: 'vertex-tienda',
    storageBucket: 'vertex-tienda.firebasestorage.app',
    iosBundleId: 'com.jplabs.tiendavertex',
  );

  static const FirebaseOptions macos = ios;
  static const FirebaseOptions windows = ios;
  static const FirebaseOptions linux = ios;
}