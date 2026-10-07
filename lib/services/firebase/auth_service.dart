import 'package:firebase_auth/firebase_auth.dart';

/// Autenticación exclusiva para el cPanel admin.
/// No se usa para clientes — el checkout es guest.
class AuthService {
  AuthService(this._auth);
  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No hay usuario autenticado.');
    await user.updatePassword(newPassword);
  }

  /// Verifica el custom claim `admin` en el token del usuario.
  /// Los usuarios admin se crean manualmente desde la consola Firebase.
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult(true);
    return token.claims?['admin'] == true;
  }
}