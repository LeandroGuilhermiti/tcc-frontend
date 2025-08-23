import 'package:flutter/material.dart';
import '../models/agendamento_model.dart';
import '../services/agendamento_service.dart';

class AgendamentoProvider extends ChangeNotifier {
  final AgendamentoService _service = AgendamentoService();
  
  // Lista privada de agendamentos
  List<Agendamento> _agendamentos = [];
  // Estado de carregamento
  bool _isLoading = false;
  // Para armazenar mensagens de erro
  String? _error;

  // Getters públicos para que a UI possa acessar os dados e estados
  List<Agendamento> get agendamentos => _agendamentos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Define o estado de carregamento e notifica a UI
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Define uma mensagem de erro e notifica a UI
  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  /// Carrega os agendamentos de uma agenda/profissional específico.
  Future<void> carregarAgendamentos(String idAgenda) async {
    _setError(null);
    _setLoading(true);

    try {
      _agendamentos = await _service.getAgendamentos(idAgenda);
    } catch (e) {
      _setError('Erro ao carregar agendamentos: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Adiciona um novo agendamento e atualiza a lista local.
  Future<void> adicionarAgendamento(Agendamento agendamento) async {
    _setError(null);
    _setLoading(true); // Pode ser útil para mostrar um loading no diálogo

    try {
      final novoAgendamento = await _service.criarAgendamento(agendamento);
      _agendamentos.add(novoAgendamento);
    } catch (e) {
      _setError('Erro ao adicionar agendamento: ${e.toString()}');
      rethrow; // Re-lança o erro para que o diálogo possa tratá-lo (ex: mostrar um SnackBar)
    } finally {
      _setLoading(false);
    }
  }

  /// Atualiza um agendamento existente na lista local.
  Future<void> atualizarAgendamento(Agendamento agendamento) async {
    _setError(null);
    
    try {
      await _service.atualizarAgendamento(agendamento);
      // Encontra o índice do agendamento antigo na lista
      final index = _agendamentos.indexWhere((a) => a.id == agendamento.id);
      if (index != -1) {
        // Substitui o agendamento antigo pelo atualizado
        _agendamentos[index] = agendamento;
        notifyListeners(); // Notifica a UI sobre a mudança
      }
    } catch (e) {
      _setError('Erro ao atualizar agendamento: ${e.toString()}');
      rethrow; // Permite que a UI saiba do erro
    }
  }

  /// Remove um agendamento da lista local.
  Future<void> removerAgendamento(String id) async {
    _setError(null);

    try {
      await _service.deletarAgendamento(id);
      // Remove o agendamento da lista local
      _agendamentos.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Erro ao remover agendamento: ${e.toString()}');
      rethrow;
    }
  }
}