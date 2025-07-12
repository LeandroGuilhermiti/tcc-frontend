import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController with ChangeNotifier {
  final _auth = AuthService();

  UserModel? _usuario;
  String? _erro;

  bool get isLogado => _usuario != null;
  String? get erro => _erro;
  UserModel? get usuario => _usuario;
  UserRole? get tipoUsuario => _usuario?.role;

  Future<void> login(String email, String senha) async {
    final user = await _auth.login(email, senha);

    if (user != null) {
      _usuario = user;
      _erro = null;
    } else {
      _usuario = null;
      _erro = 'Usuário ou senha inválidos';
    }

    notifyListeners();
  }

  void logout() {
    _usuario = null;
    notifyListeners();
  }
}
