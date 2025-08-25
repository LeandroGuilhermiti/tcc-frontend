import 'package:flutter/material.dart';
import '../models/periodo_model.dart';
import '../services/periodo_service.dart';

class PeriodoProvider extends ChangeNotifier {
  final PeriodoService _service = PeriodoService();

  // Lista privada de períodos
  List<Periodo> _periodos = [];
  // Estado de carregamento
  bool _isLoading = false;
  // Para armazenar mensagens de erro
  String? _error;

  // Getters públicos para a UI acessar os dados de forma segura
  List<Periodo> get periodos => _periodos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carrega os períodos de trabalho de uma agenda/profissional.
  Future<void> carregarPeriodos(String idAgenda) async {
    _error = null;
    _isLoading = true;
    notifyListeners(); // Notifica a UI que o carregamento começou

    try {
      _periodos = await _service.getPeriodos(idAgenda);
    } catch (e) {
      _error = 'Erro ao carregar períodos: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners(); // Notifica a UI que o carregamento terminou
    }
  }

  // Adiciona um novo período e atualiza a lista local.
  Future<void> adicionarPeriodo(Periodo periodo) async {
    try {
      final novoPeriodo = await _service.criarPeriodo(periodo);
      _periodos.add(novoPeriodo);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao adicionar período: ${e.toString()}';
      notifyListeners();
      rethrow; // Re-lança o erro para a UI tratar
    }
  }

  // Atualiza um período existente na lista local.
  Future<void> atualizarPeriodo(Periodo periodo) async {
    try {
      await _service.atualizarPeriodo(periodo);
      final index = _periodos.indexWhere((p) => p.id == periodo.id);
      if (index != -1) {
        _periodos[index] = periodo;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao atualizar período: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // Remove um período da lista local.
  Future<void> removerPeriodo(String id) async {
    try {
      await _service.deletarPeriodo(id);
      _periodos.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao remover período: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }
}
