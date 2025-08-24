import 'package:flutter/material.dart';
import '../models/bloqueio_model.dart';
import '../services/bloqueio_service.dart';

class BloqueioProvider extends ChangeNotifier {
  final BloqueioService _service = BloqueioService();

  List<Bloqueio> _bloqueios = [];
  bool _isLoading = false;
  String? _error;

  // Getters públicos para a UI acessar os dados
  List<Bloqueio> get bloqueios => _bloqueios;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Carrega os bloqueios de uma agenda/profissional específico.
  Future<void> carregarBloqueios(String idAgenda) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      _bloqueios = await _service.getBloqueios(idAgenda);
    } catch (e) {
      _error = 'Erro ao carregar bloqueios: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Adiciona um novo bloqueio e atualiza a lista local.
  Future<void> adicionarBloqueio(Bloqueio bloqueio) async {
    _error = null;
    
    try {
      final novoBloqueio = await _service.criarBloqueio(bloqueio);
      _bloqueios.add(novoBloqueio);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao adicionar bloqueio: ${e.toString()}';
      rethrow; // Re-lança o erro para a UI poder tratá-lo
    }
  }

  // Atualiza um bloqueio existente na lista local.
  Future<void> atualizarBloqueio(Bloqueio bloqueio) async {
    _error = null;
    
    try {
      await _service.atualizarBloqueio(bloqueio);
      final index = _bloqueios.indexWhere((b) => b.id == bloqueio.id);
      if (index != -1) {
        _bloqueios[index] = bloqueio;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao atualizar bloqueio: ${e.toString()}';
      rethrow;
    }
  }

  /// Remove um bloqueio da lista local.
  Future<void> removerBloqueio(String id) async {
    _error = null;
    
    try {
      await _service.deletarBloqueio(id);
      _bloqueios.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao remover bloqueio: ${e.toString()}';
      rethrow;
    }
  }
}