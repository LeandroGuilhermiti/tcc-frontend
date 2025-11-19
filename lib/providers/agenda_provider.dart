import 'package:flutter/material.dart';
import '../models/agenda_model.dart';
import '../models/periodo_model.dart';
import '../services/agenda_service.dart';
import 'auth_controller.dart';

class AgendaProvider with ChangeNotifier {
  final AgendaService _service = AgendaService();
  AuthController? _auth;

  List<Agenda> _agendas = [];
  bool _isLoading = false;
  String? _erro;

  AgendaProvider(this._auth);

  List<Agenda> get agendas => _agendas;
  bool get isLoading => _isLoading;
  String? get erro => _erro;

  void updateAuth(AuthController newAuth) {
    if (_auth?.isLogado != newAuth.isLogado) {
      _agendas = [];
      _erro = null;
    }
    _auth = newAuth;
  }

  Future<void> buscarTodasAgendas() async {
    final token = _auth?.usuario?.idToken;
    if (token == null) {
      _erro = "Autenticação necessária.";
      notifyListeners();
      return;
    }
    _isLoading = true;
    _erro = null;
    notifyListeners();
    try {
      _agendas = await _service.buscarTodasAgendas(token);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Periodo>> buscarPeriodosDaAgenda(String agendaId) async {
    final token = _auth?.usuario?.idToken;
    if (token == null) throw Exception("Autenticação necessária.");
    return await _service.buscarPeriodosPorAgenda(agendaId, token);
  }

  // --- MÉTODOS ANTIGO
  Future<void> adicionarAgendaCompleta(Agenda agenda, List<Periodo> periodos) async {
    final token = _auth?.usuario?.idToken;
    if (token == null) throw Exception("Login necessário.");
    await _service.criarAgendaCompleta(agenda, periodos, token);
  }

  // --- NOVO MÉTODO INTELIGENTE ---
  Future<void> salvarEdicaoInteligente({
    required Agenda agenda,
    required List<Map<String, dynamic>> adicionar,
    required List<Map<String, dynamic>> editar,
    required List<Map<String, dynamic>> excluir,
  }) async {
    final token = _auth?.usuario?.idToken;
    if (token == null) throw Exception("Autenticação necessária.");

    // Prepara os dados da agenda (apenas os campos editáveis)
    final dadosAgenda = {
      "id": int.parse(agenda.id!), // Garante que o ID vai como número
      "nome": agenda.nome,
      "descricao": agenda.descricao,
      "duracao": agenda.duracao,
      "avisoAgendamento": agenda.avisoAgendamento,
      "principal": agenda.principal,
    };

    await _service.salvarEdicaoAvancada(
      dadosAgenda: dadosAgenda,
      adicionar: adicionar,
      editar: editar,
      excluir: excluir,
      token: token,
    );
    
    // Atualiza a lista local após salvar
    await buscarTodasAgendas();
  }
}