import 'package:flutter/material.dart';
import '../models/bloqueio_model.dart';
import '../services/bloqueio_service.dart';
import 'auth_controller.dart'; // 1. Importar o AuthController

class BloqueioProvider extends ChangeNotifier {
  final BloqueioService _service = BloqueioService();
  AuthController? _auth; // 2. Adicionar referência

  List<Bloqueio> _bloqueios = [];
  bool _isLoading = false;
  String? _error;

  // 3. Modificar o construtor
  BloqueioProvider(this._auth);

  List<Bloqueio> get bloqueios => _bloqueios;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 4. Método para ser chamado pelo ProxyProvider
  void updateAuth(AuthController newAuth) {
    _auth = newAuth;
  }

  Future<void> carregarBloqueios(String idAgenda) async {
    // 5. TRAVA DE SEGURANÇA
    final token = _auth?.usuario?.idToken;
    if (token == null || token.isEmpty) {
      _error = "Autenticação necessária.";
      notifyListeners();
      return;
    }

    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      // Passe o token para o serviço
      _bloqueios = await _service.getBloqueios(idAgenda, token);
    } catch (e) {
      _error = 'Erro ao carregar bloqueios: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lembre-se de adicionar a trava de segurança nos outros métodos também
  Future<void> adicionarBloqueio(Bloqueio bloqueio) async {
    final token = _auth?.usuario?.idToken;
    if (token == null) return;
    // ... resto da lógica
  }
}
