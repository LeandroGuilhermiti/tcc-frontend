import 'package:flutter/material.dart';
import '../models/periodo_model.dart';
import '../services/periodo_service.dart';
import 'auth_controller.dart'; // 1. Importar o AuthController

class PeriodoProvider extends ChangeNotifier {
  final PeriodoService _service = PeriodoService();
  AuthController? _auth; // 2. Adicionar referência ao AuthController

  List<Periodo> _periodos = [];
  bool _isLoading = false;
  String? _error;
  
  // 3. Modificar o construtor
  PeriodoProvider(this._auth);

  List<Periodo> get periodos => _periodos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // 4. Método para ser chamado pelo ProxyProvider
  void updateAuth(AuthController newAuth) {
    _auth = newAuth;
  }

  Future<void> carregarPeriodos(String idAgenda) async {
    // 5. TRAVA DE SEGURANÇA
    final token = _auth?.usuario?.token;
    if (token == null || token.isEmpty) {
      _error = "Autenticação necessária.";
      notifyListeners();
      return;
    }

    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      // Passe o token para o seu serviço
      _periodos = await _service.getPeriodos(idAgenda, token);
    } catch (e) {
      _error = 'Erro ao carregar períodos: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lembre-se de adicionar a trava de segurança nos outros métodos também
  Future<void> adicionarPeriodo(Periodo periodo) async {
    final token = _auth?.usuario?.token;
    if (token == null) return;
    // ... resto da lógica
  }
}
