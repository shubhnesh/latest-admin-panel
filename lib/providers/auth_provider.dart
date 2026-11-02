import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  /// True as soon as any Firebase app has been initialized. When Firebase
  /// isn't configured yet (see firebase_options.dart), this stays false and
  /// [isLoggedIn] auto-bypasses the login screen so the rest of the app —
  /// including the mock-data Dashboard — is still reachable for preview.
  static bool get _firebaseReady => Firebase.apps.isNotEmpty;

  AuthService? _service;
  bool _previewSignedOut = false;
  AuthService? get _safeService {
    if (!_firebaseReady) return null;
    return _service ??= AuthService();
  }

  User? get user => _safeService?.currentUser;
  bool get isLoggedIn => !_firebaseReady ? !_previewSignedOut : user != null;

  bool isLoading = false;
  String? errorMessage;

  AuthProvider() {
    final service = _safeService;
    if (service != null) {
      service.authStateChanges.listen((_) => notifyListeners());
    }
  }

  Future<bool> signIn(String email, String password) async {
    final service = _safeService;
    if (service == null) {
      errorMessage = 'Firebase is not configured yet — running with mock data.';
      notifyListeners();
      return false;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await service.signIn(email, password);
      _previewSignedOut = false;
      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? 'Login failed';
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    final service = _safeService;
    if (service == null) {
      errorMessage = 'Firebase is not configured yet — running with mock data.';
      notifyListeners();
      return false;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await service.register(email, password);
      _previewSignedOut = false;
      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? 'Registration failed';
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    final service = _safeService;
    if (service == null) {
      _previewSignedOut = true;
    } else {
      await service.signOut();
    }
    notifyListeners();
  }

  Future<bool> sendPasswordReset(String email) async {
    final service = _safeService;

    if (service == null) {
      errorMessage = 'Firebase is not configured yet — running with mock data.';
      notifyListeners();
      return false;
    }

    try {
      await service.sendPasswordReset(email);
      errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? 'Unable to send reset link.';
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

/// Riverpod provider wrapping [AuthProvider].
final authProvider = ChangeNotifierProvider<AuthProvider>(
  (ref) => AuthProvider(),
);
