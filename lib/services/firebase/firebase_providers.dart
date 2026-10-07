import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_service.dart';
import '../whatsapp/whatsapp_service.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

// ── Instancias Firebase ────────────────────────────────────────

final firestoreInstanceProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final authInstanceProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final storageInstanceProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

final analyticsInstanceProvider = Provider<FirebaseAnalytics>(
  (ref) => FirebaseAnalytics.instance,
);

// ── Servicios ─────────────────────────────────────────────────

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(ref.watch(firestoreInstanceProvider)),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(authInstanceProvider)),
);

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(ref.watch(analyticsInstanceProvider)),
);

final whatsappServiceProvider = Provider<WhatsappService>(
  (ref) => const WhatsappService(),
);

// ── Estado de auth (para guard del cPanel) ────────────────────

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);