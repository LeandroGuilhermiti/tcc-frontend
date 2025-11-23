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
}