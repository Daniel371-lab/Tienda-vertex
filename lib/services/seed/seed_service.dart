import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../app/constants/api_constants.dart';

/// Carga datos de prueba en Firestore la primera vez que se abre la app.
/// Se ejecuta automáticamente y solo si la base está vacía.
/// Se puede forzar una recarga incrementando `_currentSeedVersion`.
class SeedService {
  SeedService(this._db);
  final FirebaseFirestore _db;

  static const String _metaCollection = '_meta';
  static const String _metaDoc = 'seed_status';
  static const int _currentSeedVersion = 1;

  Future<void> runIfNeeded() async {
    try {
      final metaRef = _db.collection(_metaCollection).doc(_metaDoc);
      final metaSnap = await metaRef.get();

      final currentVersion = metaSnap.exists
          ? (metaSnap.data()?['version'] as num?)?.toInt() ?? 0
          : 0;

      if (currentVersion >= _currentSeedVersion) {
        // Ya se ejecutó esta versión del seed.
        return;
      }

      await _seedCategories();
      await _seedProducts();
      await _seedCoupons();
      await _seedSettings();

      await metaRef.set({
        'version': _currentSeedVersion,
        'seededAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Si falla el seed, no rompemos la app.
      // Se reintentará la próxima vez que se abra.
    }
  }

  Future<void> _seedCategories() async {
    final raw = await rootBundle.loadString('assets/seed/categories.json');
    final list = jsonDecode(raw) as List;
    final batch = _db.batch();

    for (final item in list) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map.remove('id') as String;
      map['createdAt'] = FieldValue.serverTimestamp();
      map['updatedAt'] = FieldValue.serverTimestamp();
      batch.set(
        _db.collection(ApiConstants.colCategories).doc(id),
        map,
      );
    }

    await batch.commit();
  }

  Future<void> _seedProducts() async {
    final raw = await rootBundle.loadString('assets/seed/products.json');
    final list = jsonDecode(raw) as List;
    final batch = _db.batch();

    for (final item in list) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map.remove('id') as String;
      map['createdAt'] = FieldValue.serverTimestamp();
      map['updatedAt'] = FieldValue.serverTimestamp();
      batch.set(
        _db.collection(ApiConstants.colProducts).doc(id),
        map,
      );
    }

    await batch.commit();
  }

  Future<void> _seedCoupons() async {
    final raw = await rootBundle.loadString('assets/seed/coupons.json');
    final list = jsonDecode(raw) as List;
    final batch = _db.batch();

    for (final item in list) {
      final map = Map<String, dynamic>.from(item as Map);
      final code = (map['code'] as String).toLowerCase();
      map['createdAt'] = FieldValue.serverTimestamp();
      batch.set(
        _db.collection(ApiConstants.colCoupons).doc('coup_$code'),
        map,
      );
    }

    await batch.commit();
  }

  Future<void> _seedSettings() async {
    final raw = await rootBundle.loadString('assets/seed/settings.json');
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    map['updatedAt'] = FieldValue.serverTimestamp();
    await _db
        .collection(ApiConstants.colSettings)
        .doc(ApiConstants.docSettings)
        .set(map);
  }
}