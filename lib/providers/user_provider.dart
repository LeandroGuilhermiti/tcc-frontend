import 'package:flutter/material.dart';
import 'package:tcc_frontend/models/user_model.dart';

class UsuarioProvider with ChangeNotifier {
  List<UserModel> _usuarios = [];

  List<UserModel> get usuarios => _usuarios;

  void adicionarUsuario(UserModel usuario) {
    _usuarios.add(usuario);
    notifyListeners();
  }

  // Aqui você pode colocar lógica para salvar no backend também futuramente
}
