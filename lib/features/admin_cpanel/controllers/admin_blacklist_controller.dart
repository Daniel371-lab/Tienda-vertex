import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/blacklist_model.dart';
import '../../../services/firebase/firebase_providers.dart';

class AdminBlacklistState {
  const AdminBlacklistState({
    this.entries = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final List<BlacklistEntry> entries;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  List<BlacklistEntry> get filteredEntries {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return entries;
    return entries.where((e) => e.phone.contains(q)).toList();
  }

  AdminBlacklistState copyWith({
    List<BlacklistEntry>? entries,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AdminBlacklistState(
        entries: entries ?? this.entries,
        searchQuery: searchQuery ?? this.searchQuery,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AdminBlacklistController extends StateNotifier<AdminBlacklistState> {
  AdminBlacklistController(this._ref) : super(const AdminBlacklistState()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final db = _ref.read(firestoreInstanceProvider);
      final snap = await db.collection('blacklist').get();
      final entries = snap.docs
          .map((d) => BlacklistEntry.fromFirestore(d))
          .toList()
        ..sort((a, b) {
          final aD = a.createdAt ?? DateTime(1970);
          final bD = b.createdAt ?? DateTime(1970);
          return bD.compareTo(aD);
        });

      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar la lista: $e',
      );
    }
  }

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  Future<bool> addEntry({
    required String phone,
    required String reason,
    String? createdByUid,
  }) async {
    try {
      final db = _ref.read(firestoreInstanceProvider);
      final id = BlacklistEntry.buildId(phone);

      final exists = await db.collection('blacklist').doc(id).get();
      if (exists.exists) {
        state = state.copyWith(
          error: 'Ese teléfono ya está en la lista negra.',
        );
        return false;
      }

      await db.collection('blacklist').doc(id).set({
        'phone': phone,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
        'createdByUid': createdByUid,
      });

      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'No se pudo agregar: $e');
      return false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    try {
      final db = _ref.read(firestoreInstanceProvider);
      await db.collection('blacklist').doc(id).delete();
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'No se pudo eliminar: $e');
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final adminBlacklistControllerProvider = StateNotifierProvider<
    AdminBlacklistController, AdminBlacklistState>((ref) {
  return AdminBlacklistController(ref);
});