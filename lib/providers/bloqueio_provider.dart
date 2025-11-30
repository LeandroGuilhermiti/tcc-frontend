import 'package:flutter/material.dart';
import '../models/bloqueio_model.dart';
import '../services/bloqueio_service.dart';
import 'auth_controller.dart'; 

class BloqueioProvider extends ChangeNotifier {
  final BloqueioService _service = BloqueioService();
  AuthController? _auth; 

  List<Bloqueio> _bloqueios = [];
  bool _isLoading = false;
  String? _error;

  BloqueioProvider(this._auth);

  List<Bloqueio> get bloqueios => _bloqueios;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateAuth(AuthController newAuth) {
    _auth = newAuth;
  }

  Future<void> carregarBloqueios(String idAgenda) async {
    final token = _auth?.usuario?.idToken;
    if (token == null || token.isEmpty) return;

    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      _bloqueios = await _service.getBloqueios(idAgenda, token);
    } catch (e) {
      _error = 'Erro ao carregar: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cadastrarBloqueio(Bloqueio bloqueio) async {
    final token = _auth?.usuario?.idToken;
    if (token == null || token == "null" || token.isEmpty) {
       throw Exception("Sessão expirada. Faça login novamente.");
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _service.criarBloqueio(bloqueio, token);
      await carregarBloqueios(bloqueio.idAgenda.toString());
    } catch (e) {
      _error = e.toString();
      rethrow; 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> excluirBloqueio(int idAgenda, DateTime dataHora) async {
    final token = _auth?.usuario?.idToken;
    if (token == null) throw Exception("Autenticação necessária.");

    _isLoading = true;
    notifyListeners();

    try {
      // Chama o serviço passando a data
      await _service.deletarBloqueio(idAgenda, dataHora, token);
      
      // REMOÇÃO LOCAL SEM ID:
      // Removemos o item da lista que tem a mesma dataHora e mesma agenda
      _bloqueios.removeWhere((b) => 
          b.idAgenda == idAgenda && 
          b.dataHora.isAtSameMomentAs(dataHora)
      );
      
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- NOVO MÉTODO: ATUALIZAR ---
  Future<void> atualizarBloqueio(Bloqueio bloqueio) async {
    final token = _auth?.usuario?.idToken;
    if (token == null) throw Exception("Autenticação necessária.");

    _isLoading = true;
    notifyListeners();

    try {
      await _service.atualizarBloqueio(bloqueio, token);
      
      // Atualiza localmente
      // Como não tem ID, procura pela dataHora
      final index = _bloqueios.indexWhere((b) => 
          b.idAgenda == bloqueio.idAgenda && 
          b.dataHora.isAtSameMomentAs(bloqueio.dataHora)
      );
      
      if (index != -1) {
        _bloqueios[index] = bloqueio;
      }
      
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}