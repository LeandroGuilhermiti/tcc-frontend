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
    // Se o usuário mudou, limpa os agendamentos antigos
    if (_auth?.usuario?.id != newAuth.usuario?.id) {
      _agendamentos = [];
      _error = null;
      _isLoading = false;
    }
    _auth = newAuth;
  }

  // --- MÉTODO ATUALIZADO PARA ACEITAR FILTROS ---
  Future<void> carregarAgendamentos({
    required String idAgenda,
    String? idUsuario, // Parâmetro opcional para filtrar por usuário
    DateTime? dataHora, // Parâmetro opcional para filtrar por data/hora
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
      // Passa todos os filtros para o serviço.
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

  // --- ALTERAÇÃO AQUI ---
  Future<void> adicionarAgendamento(Agendamento agendamento) async {
    final token = _auth?.usuario?.idToken;
    if (token == null) throw Exception("Autenticação necessária.");

    try {
      // 1. Chama o serviço para criar o agendamento no banco
      await _service.criarAgendamento(agendamento, token);
      
      // 2. Em vez de adicionar localmente, recarrega a lista inteira
      //    chamando a função 'carregarAgendamentos'.
      //    Isto garante que a UI será "recarregada" com os dados do servidor.
      await carregarAgendamentos(idAgenda: agendamento.idAgenda);
      
      // 'carregarAgendamentos' já chama notifyListeners(), 
      // então não precisamos de outro aqui.

    } catch (e) {
      rethrow; // O 'dialogo_agendamento_service' irá tratar de mostrar o erro
    }
  }

  Future<void> atualizarAgendamento(Agendamento agendamento) async {
    final token = _auth?.usuario?.idToken;
    if (token == null) throw Exception("Autenticação necessária.");

    try {
      await _service.atualizarAgendamento(agendamento, token);

      // --- ALTERAÇÃO AQUI TAMBÉM (para consistência) ---
      // Recarrega a lista inteira após atualizar.
      await carregarAgendamentos(idAgenda: agendamento.idAgenda);

    } catch (e) {
      rethrow;
    }
  }

  // --- ALTERAÇÃO AQUI ---
  Future<void> removerAgendamento(Agendamento agendamento) async {
    final token = _auth?.usuario?.idToken;
    if (token == null) throw Exception("Autenticação necessária.");

    try {
      // 1. Chama o serviço para apagar do banco de dados
      await _service.deletarAgendamento(agendamento, token);

      // 2. Em vez de remover localmente, recarrega a lista inteira
      //    Isto corrige o bug de "desaparecer" e garante a atualização.
      await carregarAgendamentos(idAgenda: agendamento.idAgenda);

    } catch (e) {
      rethrow;
    }
  }
}

