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
}