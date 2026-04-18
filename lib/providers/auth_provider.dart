import 'package:flutter/foundation.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool     _isLoading = false;
  String?  _error;

  AppUser? get user        => _user;
  bool     get isLoading   => _isLoading;
  String?  get error       => _error;
  bool     get isAuthenticated => _user != null;

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    final result = await ApiService.login(email, password);

    _isLoading = false;

    if (result == null || result.containsKey('network_error')) {
      _error = 'Serveur indisponible. Vérifiez votre connexion et réessayez.';
      notifyListeners();
      return false;
    }

    if (result.containsKey('error')) {
      _error = result['error'] as String;
      notifyListeners();
      return false;
    }

    ApiService.setToken(result['access_token'] as String);
    _user = AppUser.fromJson(result['user'] as Map<String, dynamic>);
    notifyListeners();
    return true;
  }

  // ── Refresh user from backend ─────────────────────────────────────────────

  Future<void> refreshUser() async {
    final data = await ApiService.getMe();
    if (data != null) {
      _user = AppUser.fromJson(data);
      notifyListeners();
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  void logout() {
    ApiService.setToken(null);
    _user  = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
