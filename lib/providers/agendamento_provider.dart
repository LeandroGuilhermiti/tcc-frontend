import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    if (_auth?.usuario?.id != newAuth.usuario?.id) {
      _agendamentos = [];
      _error = null;
      _isLoading = false;
    }
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
      debugPrint('[AgendamentoProvider] Erro ao carregar: ${e.toString()}');
      _error = e.toString().replaceFirst("Exception: ", "");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adicionarAgendamento(Agendamento agendamento) async {
    final token = _auth?.usuario?.idToken;
    if (token == null) throw Exception("Autenticação necessária.");

    try {
      await _service.criarAgendamento(agendamento, token);
      await carregarAgendamentos(idAgenda: agendamento.idAgenda);
    } catch (e) {
      rethrow; 
    }
  }

  // --- NOVO MÉTODO: SUBSTITUIÇÃO (Excluir Antigo -> Criar Novo) ---
  Future<void> editarViaSubstituicao(Agendamento antigo, Agendamento novo) async {
    final token = _auth?.usuario?.idToken;
    if (token == null) throw Exception("Autenticação necessária.");

    try {
      // 1. Remove o agendamento antigo (o backend usa dataHora antiga para encontrar)
      await _service.deletarAgendamento(antigo, token);

      // 2. Cria o novo agendamento com os dados atualizados (nova dataHora)
      await _service.criarAgendamento(novo, token);

      // 3. Atualiza a lista na tela
      await carregarAgendamentos(idAgenda: novo.idAgenda);

    } catch (e) {
      rethrow;
    }
  }

  Future<void> removerAgendamento(Agendamento agendamento) async {
    final token = _auth?.usuario?.idToken;
    if (token == null) throw Exception("Autenticação necessária.");

    try {
      await _service.deletarAgendamento(agendamento, token);
      await carregarAgendamentos(idAgenda: agendamento.idAgenda);
    } catch (e) {
      rethrow;
    }
  }
}