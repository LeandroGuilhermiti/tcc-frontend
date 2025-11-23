import 'package:flutter/material.dart';
import '../models/feriado_model.dart';
import '../services/feriado_service.dart';

class FeriadoProvider with ChangeNotifier {
  final FeriadoService _service = FeriadoService();
  
  List<FeriadoModel> _feriados = [];
  bool _isLoading = false;

  List<FeriadoModel> get feriados => _feriados;
  bool get isLoading => _isLoading;

  // Cache simples para evitar chamadas repetidas para o mesmo ano
  final Set<int> _anosCarregados = {};

  Future<void> carregarFeriados(int ano) async {
    if (_anosCarregados.contains(ano)) return;

    _isLoading = true;
    // Não notificamos aqui para evitar rebuilds desnecessários na inicialização
    // notifyListeners(); 

    try {
      final novosFeriados = await _service.getFeriados(ano);
      _feriados.addAll(novosFeriados);
      _anosCarregados.add(ano);
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}