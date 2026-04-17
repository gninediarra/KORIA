import 'package:flutter/foundation.dart';
import 'package:gabeseye/models/models.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  static const Map<UserRole, AppUser> _demoUsers = {
    UserRole.agriculteur: AppUser(
      id: 'u1',
      name: 'Ahmed Ben Salah',
      email: 'ahmed.bensalah@gabeseye.tn',
      role: UserRole.agriculteur,
      parcelle: 'Bahria Nord — Lot 12',
    ),
    UserRole.pecheur: AppUser(
      id: 'u2',
      name: 'Mohamed Trabelsi',
      email: 'm.trabelsi@gabeseye.tn',
      role: UserRole.pecheur,
      quartier: 'Port de Gabès',
    ),
    UserRole.autorite: AppUser(
      id: 'u3',
      name: 'Inspecteur Karim Gharbi',
      email: 'k.gharbi@anpe.tn',
      role: UserRole.autorite,
      quartier: 'Direction Régionale ANPE',
    ),
    UserRole.citoyen: AppUser(
      id: 'u4',
      name: 'Fatima Mansouri',
      email: 'f.mansouri@gabeseye.tn',
      role: UserRole.citoyen,
      quartier: 'Quartier Jara',
    ),
  };

  Future<bool> login(String email, String password, UserRole role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500));

    if (password.length < 4) {
      _error = 'Mot de passe incorrect';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _user = _demoUsers[role]!.copyWith(email: email.isEmpty ? _demoUsers[role]!.email : email);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}

extension AppUserCopyWith on AppUser {
  AppUser copyWith({String? email}) => AppUser(
        id: id,
        name: name,
        email: email ?? this.email,
        role: role,
        quartier: quartier,
        parcelle: parcelle,
      );
}
