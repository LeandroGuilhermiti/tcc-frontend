import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'auth_controller.dart'; // Essencial para obter o token de autenticação

/// Provider que gerencia o estado dos dados dos usuários na aplicação.
///
/// Ele usa o [UsuarioService] para interagir com a API e o [AuthController]
/// para obter o token de autenticação necessário para as requisições.
class UsuarioProvider with ChangeNotifier {
  final UsuarioService _usuarioService = UsuarioService();
  final AuthController? _auth; // Armazena a instância do AuthController

  List<UserModel> _usuarios = [];
  bool _isLoading = false;
  String? _erro;

  /// Construtor que recebe o AuthController.
  /// A melhor forma de instanciar este provider é usando um ChangeNotifierProxyProvider.
  UsuarioProvider(this._auth);

  // Getters para a UI acessar o estado de forma segura.
  List<UserModel> get usuarios => _usuarios;
  bool get isLoading => _isLoading;
  String? get erro => _erro;

  /// Busca a lista completa de usuários.
  /// Requer que um usuário (geralmente um admin) esteja logado.
  Future<void> buscarUsuarios() async {
    // Verifica se temos um token válido para fazer a requisição.
    final token = _auth?.usuario?.token;
    if (token == null || token.isEmpty) {
      _erro = "Usuário não autenticado. Não é possível buscar dados.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      // Chama o método do serviço para buscar os dados na API.
      _usuarios = await _usuarioService.buscarTodosUsuarios(token);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adiciona um novo usuário ao sistema.
  /// Requer os dados do novo usuário e um token de admin.
  Future<bool> adicionarUsuario(Map<String, dynamic> dadosUsuario) async {
    final token = _auth?.usuario?.token;
    if (token == null || token.isEmpty) {
      _erro = "Usuário não autenticado. Não é possível cadastrar.";
      notifyListeners();
      return false; // Retorna false indicando falha
    }

    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      await _usuarioService.cadastrarUsuario(dadosUsuario, token);
      // Após o sucesso, atualiza a lista de usuários para refletir a mudança.
      await buscarUsuarios();
      return true; // Retorna true indicando sucesso
    } catch (e) {
      _erro = e.toString();
      _isLoading = false;
      notifyListeners();
      return false; // Retorna false indicando falha
    }
  }

  /// Deleta um usuário do sistema.
  Future<void> deletarUsuario(String id) async {
    final token = _auth?.usuario?.token;
    if (token == null || token.isEmpty) {
      _erro = "Usuário não autenticado. Não é possível deletar.";
      notifyListeners();
      return;
    }

    try {
      await _usuarioService.deletarUsuario(id, token);
      // Remove o usuário da lista local para uma atualização instantânea da UI.
      _usuarios.removeWhere((usuario) => usuario.id == id);
      notifyListeners();
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
    }
  }
}
