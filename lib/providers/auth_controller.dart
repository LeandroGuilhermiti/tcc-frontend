import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController with ChangeNotifier {
  final _auth = AuthService();

  UserModel? _usuario;
  String? _erro;
  bool _isLoading = false;

  // Construtor para verificar o estado inicial do login
  AuthController() {
    _usuario = _auth.currentUser;
  }

  bool get isLogado => _usuario != null;
  UserModel? get usuario => _usuario;
  UserRole? get tipoUsuario => _usuario?.role;
  String? get erro => _erro;
  bool get isLoading => _isLoading;

  Future<void> login(String email, String senha) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    final user = await _auth.login(email, senha);

    if (user != null) {
      _usuario = user;
    } else {
      _erro = 'Usuário ou senha inválidos';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.logout();
    _usuario = null;
    notifyListeners();
  }
}