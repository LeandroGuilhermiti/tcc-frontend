import 'package:flutter/material.dart';
import '../models/agendamento_model.dart';
import '../services/agendamento_service.dart';
import 'auth_controller.dart';

class AgendamentoProvider extends ChangeNotifier {
  final AgendamentoService _service = AgendamentoService();
  AuthController? _auth;

  List<Agendamento> _agendamentos = [];
  bool _isLoading = false;
  String? _error;

  AgendamentoProvider(this._auth);

  List<Agendamento> get agendamentos => _agendamentos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateAuth(AuthController newAuth) {
    _auth = newAuth;
  }

  Future<void> carregarAgendamentos({
    required String idAgenda,
    String? idUsuario,
    DateTime? dataHora,
  }) async {
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
      _agendamentos = await _service.getAgendamentos(
        idAgenda: idAgenda,
        idUsuario: idUsuario,
        dataHora: dataHora,
        token: token,
      );
    } catch (e) {
      _error = 'Erro ao carregar agendamentos: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adicionarAgendamento(Agendamento agendamento) async {
    final token = _auth?.usuario?.idToken;
    if (token == null) throw Exception("Autenticação necessária.");
    try {
      final novoAgendamento = await _service.criarAgendamento(
        agendamento,
        token,
      );
      _agendamentos.add(novoAgendamento);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> atualizarAgendamento(Agendamento agendamento) async {
    final token = _auth?.usuario?.idToken;
    if (token == null) throw Exception("Autenticação necessária.");
    try {
      await _service.atualizarAgendamento(agendamento, token);
      final index = _agendamentos.indexWhere((a) => a.id == agendamento.id);
      if (index != -1) {
        _agendamentos[index] = agendamento;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- CORREÇÃO AQUI ---
  // A função agora espera o objeto Agendamento completo,
  // pois o serviço precisa da chave composta (idAgenda, idUsuario, dataHora).
  Future<void> removerAgendamento(Agendamento agendamento) async {
    final token = _auth?.usuario?.idToken;
    if (token == null) throw Exception("Autenticação necessária.");

    try {
      // Chama o serviço com o objeto completo
      await _service.deletarAgendamento(agendamento, token);

      // Remove da lista local pelo ID
      _agendamentos.removeWhere((a) => a.id == agendamento.id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
