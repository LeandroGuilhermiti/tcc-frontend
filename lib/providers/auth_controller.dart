import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// AuthController gerencia o estado de autenticação do usuário na aplicação.
// Este controlador usa a Hosted UI do Cognito através do AuthService, simplificando a lógica e removendo a necessidade de gerenciar cadastro e confirmação de usuário diretamente no app.
class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _usuario;
  String? _erro;
  bool _isLoading = false;

  AuthController(this._usuario);

  // Getters para a UI acessar o estado de forma segura e reativa.
  bool get isLogado => _usuario != null;
  UserModel? get usuario => _usuario;
  UserRole? get tipoUsuario => _usuario?.role;
  String? get erro => _erro;
  bool get isLoading => _isLoading;

  // Inicia o processo de login usando a Hosted UI do Cognito.
  // Este método irá abrir um navegador para o usuário realizar a autenticação de forma segura. Após o sucesso, o estado do controlador é atualizado com as informações do usuário.
  Future<void> loginComHostedUI() async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      // Chama o método de login do nosso novo AuthService
      final user = await _authService.login();
      // _usuario = user;
    } catch (e) {
      // Captura qualquer erro que possa ocorrer durante o fluxo de autenticação
      _erro = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Realiza o logout do usuário.
  // Limpa a sessão no Cognito e redefine o estado de autenticação local no app.
  Future<void> logout() async {
    await _authService.logout();
    _usuario = null;
    _erro = null;
    notifyListeners();
  }
}
