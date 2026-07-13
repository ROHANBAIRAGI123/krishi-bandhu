import 'package:flutter/foundation.dart';
import '../../data/services/auth_service.dart';
import '../../domain/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  User? _currentUser;
  bool _isLoggedIn = false;

  AuthProvider(this._authService);

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> initialize() async {
    await _authService.initialize();
    _isLoggedIn = _authService.isLoggedIn();
    _currentUser = _authService.getCurrentUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final success = await _authService.login(email, password);
    if (success) {
      _currentUser = _authService.getCurrentUser();
      _isLoggedIn = true;
      notifyListeners();
    }
    return success;
  }

  Future<bool> register(User user) async {
    final success = await _authService.register(user);
    if (success) {
      _currentUser = _authService.getCurrentUser();
      _isLoggedIn = true;
      notifyListeners();
    }
    return success;
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      _currentUser = null;
      _isLoggedIn = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
      // Still clear local state even if service fails
      _currentUser = null;
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(User updatedUser) async {
    final success = await _authService.updateUserProfile(updatedUser);
    if (success) {
      _currentUser = updatedUser;
      notifyListeners();
    }
    return success;
  }

  // Set a demo user directly (for OTP-based demo login)
  void setDemoUser(User user) {
    _currentUser = user;
    _isLoggedIn = true;
    notifyListeners();
  }
}
