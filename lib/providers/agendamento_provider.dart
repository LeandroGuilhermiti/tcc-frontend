import 'package:flutter/material.dart';
import '../models/agendamento_model.dart';
import '../services/agendamento_service.dart';
import 'auth_controller.dart'; // 1. Importar o AuthController

class AgendamentoProvider extends ChangeNotifier {
  final AgendamentoService _service = AgendamentoService();
  AuthController? _auth; // 2. Adicionar referência ao AuthController

  List<Agendamento> _agendamentos = [];
  bool _isLoading = false;
  String? _error;

  // 3. Modificar o construtor para aceitar um AuthController nulo
  AgendamentoProvider(this._auth);

  List<Agendamento> get agendamentos => _agendamentos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 4. Método para ser chamado pelo ProxyProvider
  void updateAuth(AuthController newAuth) {
    _auth = newAuth;
  }

  Future<void> carregarAgendamentos(String idAgenda) async {
    // 5. TRAVA DE SEGURANÇA: Só continua se houver token
    final token = _auth?.usuario?.accessToken;
    if (token == null || token.isEmpty) {
      _error = "Autenticação necessária.";
      notifyListeners();
      return;
    }

    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      // Assumindo que seu service agora precisa do token
      _agendamentos = await _service.getAgendamentos(idAgenda, token);
    } catch (e) {
      _error = 'Erro ao carregar agendamentos: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Adicione a mesma trava de segurança para os outros métodos
  Future<void> adicionarAgendamento(Agendamento agendamento) async {
    final token = _auth?.usuario?.accessToken;
    if (token == null) return;
    // ... resto da lógica
  }

  Future<void> atualizarAgendamento(Agendamento agendamento) async {
    final token = _auth?.usuario?.accessToken;
    if (token == null) return;
    // ... resto da lógica
  }

  Future<void> removerAgendamento(String id) async {
    final token = _auth?.usuario?.accessToken;
    if (token == null) return;
    // ... resto da lógica
  }
}
