import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _usuario;
  String? _erro;
  bool _isLoading = false;

  AuthController(this._usuario);

  bool get isLogado => _usuario != null;
  UserModel? get usuario => _usuario;
  UserRole? get tipoUsuario => _usuario?.role;
  String? get erro => _erro;
  bool get isLoading => _isLoading;

  Future<void> loginComHostedUI() async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      final user = await _authService.login();
      // _usuario = user;
    } catch (e) {
      _erro = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _usuario = null;
    _erro = null;
    notifyListeners();
  }

  /// ATUALIZA o UserModel local com novos dados, PRESERVANDO OS TOKENS.

  void atualizarDadosLocais(Map<String, dynamic> novosDados) {
    if (_usuario == null) return; // Não deve acontecer se estiver logado

    // Cria um novo UserModel baseado no ANTIGO, mas atualiza
    // os campos que vieram no mapa 'novosDados'.
    _usuario = UserModel(
      id: _usuario!.id,
      idToken: _usuario!.idToken, // <-- O TOKEN É PRESERVADO
      accessToken: _usuario!.accessToken, // <-- O TOKEN É PRESERVADO
      refreshToken: _usuario!.refreshToken, // <-- O TOKEN É PRESERVADO
      
      // Dados antigos
      primeiroNome: _usuario!.primeiroNome,
      sobrenome: _usuario!.sobrenome,
      email: _usuario!.email,
      cpf: _usuario!.cpf,
      role: _usuario!.role,

      // Dados novos (que podem ter sido atualizados)
      // O 'novosDados.containsKey' garante que só atualiza o que veio no map
      cep: novosDados.containsKey('cep')
          ? novosDados['cep']
          : _usuario!.cep,
      telefone: novosDados.containsKey('telefone')
          ? novosDados['telefone']
          : _usuario!.telefone,
    );
    
    // Notifica a aplicação (ex: a PerfilClientePage) que os dados mudaram
    notifyListeners();
  }

  // Adicione este método na classe AuthController
  void atualizarUsuarioLocalmente({
    required bool cadastroPendente, 
    String? cpf, 
    String? telefone, 
    String? cep
  }) {
    if (_usuario != null) {
      // Cria uma cópia do usuário atual com os novos dados
      // Precisas garantir que teu UserModel tenha um método copyWith ou criar um novo manualmente
      // Como não vi copyWith no teu código, vou criar um novo manual:
      
      _usuario = UserModel(
        id: _usuario!.id,
        idToken: _usuario!.idToken,
        accessToken: _usuario!.accessToken,
        refreshToken: _usuario!.refreshToken,
        primeiroNome: _usuario!.primeiroNome,
        sobrenome: _usuario!.sobrenome,
        email: _usuario!.email,
        role: _usuario!.role,
        
        // Atualizando os campos novos
        cadastroPendente: cadastroPendente,
        cpf: cpf ?? _usuario!.cpf,
        telefone: telefone ?? _usuario!.telefone,
        cep: cep ?? _usuario!.cep,
      );
      
      notifyListeners(); // ISSO É IMPORTANTE! Vai avisar o main.dart para reconstruir
    }
  }
}