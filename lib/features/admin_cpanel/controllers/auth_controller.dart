import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado del formulario de login.
class LoginState {
  const LoginState({
    this.email = '',
    this.password = '',
    this.isSubmitting = false,
    this.error,
    this.obscurePassword = true,
  });

  final String email;
  final String password;
  final bool isSubmitting;
  final String? error;
  final bool obscurePassword;

  LoginState copyWith({
    String? email,
    String? password,
    bool? isSubmitting,
    String? error,
    bool? obscurePassword,
    bool clearError = false,
  }) =>
      LoginState(
        email: email ?? this.email,
        password: password ?? this.password,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: clearError ? null : (error ?? this.error),
        obscurePassword: obscurePassword ?? this.obscurePassword,
      );
}

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._auth) : super(const LoginState());

  final FirebaseAuth _auth;

  void setEmail(String v) =>
      state = state.copyWith(email: v.trim(), clearError: true);

  void setPassword(String v) =>
      state = state.copyWith(password: v, clearError: true);

  void toggleObscure() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);

  Future<bool> signIn() async {
    if (state.email.isEmpty || state.password.isEmpty) {
      state = state.copyWith(error: 'Ingresá email y contraseña.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: state.email,
        password: state.password,
      );
      state = state.copyWith(isSubmitting: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: _mapError(e.code),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Error de conexión. Reintentá.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const LoginState();
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuario no encontrado.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email o contraseña incorrectos.';
      case 'invalid-email':
        return 'El email no es válido.';
      case 'user-disabled':
        return 'Esta cuenta fue deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Esperá unos minutos.';
      case 'network-request-failed':
        return 'Sin conexión. Verificá tu internet.';
      default:
        return 'No pudimos iniciar sesión. Reintentá.';
    }
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController(ref.watch(authInstanceProvider));
});