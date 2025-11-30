import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
      await _authService.login();
      final user = await tentaRecuperarSessao();
      _usuario = user;
      
      // SALVAR SESSÃO: Se o login for bem sucedido, salvamos no disco
      if (_usuario != null) {
        await salvarSessaoEstatica(_usuario!);
      }
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
    
    // LIMPAR SESSÃO: Removemos do disco ao sair
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    
    notifyListeners();
  }

  /// ATUALIZA o UserModel local com novos dados, PRESERVANDO OS TOKENS.
  void atualizarDadosLocais(Map<String, dynamic> novosDados) {
    if (_usuario == null) return; 

    _usuario = UserModel(
      id: _usuario!.id,
      idToken: _usuario!.idToken, 
      accessToken: _usuario!.accessToken, 
      refreshToken: _usuario!.refreshToken, 
      
      primeiroNome: _usuario!.primeiroNome,
      sobrenome: _usuario!.sobrenome,
      email: _usuario!.email,
      cpf: _usuario!.cpf,
      role: _usuario!.role,
      cadastroPendente: _usuario!.cadastroPendente, // Mantém o status

      cep: novosDados.containsKey('cep')
          ? novosDados['cep']
          : _usuario!.cep,
      telefone: novosDados.containsKey('telefone')
          ? novosDados['telefone']
          : _usuario!.telefone,
    );
    
    // Atualiza também no disco para persistir a mudança
    salvarSessaoEstatica(_usuario!);
    notifyListeners();
  }

  void atualizarUsuarioLocalmente({
    required bool cadastroPendente, 
    String? cpf, 
    String? telefone, 
    String? cep
  }) {
    if (_usuario != null) {
      _usuario = UserModel(
        id: _usuario!.id,
        idToken: _usuario!.idToken,
        accessToken: _usuario!.accessToken,
        refreshToken: _usuario!.refreshToken,
        primeiroNome: _usuario!.primeiroNome,
        sobrenome: _usuario!.sobrenome,
        email: _usuario!.email,
        role: _usuario!.role,
        
        cadastroPendente: cadastroPendente,
        cpf: cpf ?? _usuario!.cpf,
        telefone: telefone ?? _usuario!.telefone,
        cep: cep ?? _usuario!.cep,
      );
      
      // Atualiza também no disco
      salvarSessaoEstatica(_usuario!);
      notifyListeners(); 
    }
  }

  // --- MÉTODOS ESTÁTICOS DE PERSISTÊNCIA ---

  /// Salva o usuário no SharedPreferences
  static Future<void> salvarSessaoEstatica(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convertemos o UserRole enum para inteiro para salvar
    final roleIndex = user.role?.index ?? 0; 

    final userData = json.encode({
      'id': user.id,
      'idToken': user.idToken,
      'accessToken': user.accessToken,
      'refreshToken': user.refreshToken,
      'primeiroNome': user.primeiroNome,
      'sobrenome': user.sobrenome,
      'email': user.email,
      'roleIndex': roleIndex, // Salvamos o índice do Enum
      'cadastroPendente': user.cadastroPendente,
      'cpf': user.cpf,
      'telefone': user.telefone,
      'cep': user.cep,
    });
    
    await prefs.setString('userData', userData);
  }

  /// Tenta recuperar o usuário do SharedPreferences
  static Future<UserModel?> tentaRecuperarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!prefs.containsKey('userData')) {
      return null;
    }

    try {
      final data = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
      
      // Recupera o Enum pelo índice
      final roleIndex = data['roleIndex'] as int? ?? 0;
      UserRole userRole;
      if (roleIndex < UserRole.values.length) {
        userRole = UserRole.values[roleIndex];
      } else {
        userRole = UserRole.cliente; // Fallback
      }

      return UserModel(
        id: data['id'],
        idToken: data['idToken'],
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
        primeiroNome: data['primeiroNome'],
        sobrenome: data['sobrenome'],
        email: data['email'],
        role: userRole,
        cadastroPendente: data['cadastroPendente'] ?? false,
        cpf: data['cpf'],
        telefone: data['telefone'],
        cep: data['cep'],
      );
    } catch (e) {
      debugPrint("Erro ao recuperar sessão: $e");
      return null;
    }
  }
}