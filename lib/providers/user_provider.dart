import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'auth_controller.dart'; // Essencial para obter o token e ID

class UsuarioProvider with ChangeNotifier {
  final UsuarioService _usuarioService = UsuarioService();
  final AuthController? _auth;

  List<UserModel> _usuarios = [];
  bool _isLoading = false;
  String? _erro;

  UsuarioProvider(this._auth);

  List<UserModel> get usuarios => _usuarios;
  bool get isLoading => _isLoading;
  String? get erro => _erro;

  Future<void> buscarUsuarios() async {
    final token = _auth?.usuario?.idToken;
    if (token == null || token.isEmpty) {
      _erro = "Usuário não autenticado. Não é possível buscar dados.";
      notifyListeners();
      return;
    }
    _isLoading = true;
    _erro = null;
    notifyListeners();
    try {
      _usuarios = await _usuarioService.buscarTodosUsuarios(token);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> adicionarUsuario(Map<String, dynamic> dadosUsuario) async {
    final token = _auth?.usuario?.idToken;
    if (token == null || token.isEmpty) {
      _erro = "Usuário não autenticado. Não é possível cadastrar.";
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _erro = null;
    notifyListeners();
    try {
      await _usuarioService.cadastrarUsuario(dadosUsuario, token);
      await buscarUsuarios();
      return true;
    } catch (e) {
      _erro = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deletarUsuario(String id) async {
    final token = _auth?.usuario?.idToken;
    if (token == null || token.isEmpty) {
      _erro = "Usuário não autenticado. Não é possível deletar.";
      notifyListeners();
      return;
    }

    try {
      await _usuarioService.deletarUsuario(id, token);
      _usuarios.removeWhere((usuario) => usuario.id == id);
      notifyListeners();
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
    }
  }

  /// Atualiza os dados do usuário logado.
  Future<bool> atualizarUsuario(Map<String, dynamic> dadosAtualizados) async {
    final token = _auth?.usuario?.idToken;
    final id = _auth?.usuario?.id;

    if (token == null || id == null) {
      _erro = "Usuário não autenticado.";
      notifyListeners();
      return false;
    }

    final authController = _auth;
    if (authController == null) {
      _erro = "Erro interno de autenticação.";
      return false;
    }

    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      // 1. Chama o serviço para enviar o PATCH
      await _usuarioService.atualizarUsuario(
        id,
        dadosAtualizados,
        token,
      );

      // 2. Chama o AuthController para ATUALIZAR OS DADOS LOCAIS
      // Passamos os dados que acabámos de enviar
      authController.atualizarDadosLocais(dadosAtualizados);

      return true;
    } catch (e) {
      _erro = e.toString().replaceFirst("Exception: ", "");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}