import 'package:flutter/material.dart';
import '../models/agenda_model.dart';
import '../services/agenda_service.dart';
import '../models/periodo_model.dart';

class AgendaProvider extends ChangeNotifier {
  final AgendaService _service = AgendaService();
  List<Agenda> _agendas = [];
  bool _isLoading = false;

  List<Agenda> get agendas => _agendas;
  bool get isLoading => _isLoading;

  /// Carrega todas as agendas
  Future<void> carregarAgendas() async {
    _isLoading = true;
    notifyListeners();

    try {
      _agendas = await _service.getAgendas();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adiciona nova agenda
  Future<void> adicionarAgenda(Agenda agenda) async {
    await _service.salvarAgenda(agenda);
    await carregarAgendas();
  }

  /// Adiciona uma nova agenda completa (com seus períodos)
  Future<void> adicionarAgendaCompleta(
    Agenda agenda,
    List<Periodo> periodos,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Não precisamos dos períodos no provider de agenda, apenas salvá-los
      await _service.salvarAgendaCompleta(agenda, periodos);
      // Após salvar, recarregamos a lista de agendas
      await carregarAgendas();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atualiza agenda existente
  Future<void> atualizarAgenda(Agenda agenda) async {
    await _service.atualizarAgenda(agenda);
    await carregarAgendas();
  }

  /// Remove agenda
  Future<void> removerAgenda(String id) async {
    await _service.deletarAgenda(id);
    await carregarAgendas();
  }
}
