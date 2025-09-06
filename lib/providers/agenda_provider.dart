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

  Future<void> buscarAgendasDoProfissional(String profissionalId) async {
    final token = _auth?.usuario?.token;
    if (token == null || token.isEmpty) {
      _erro = "Autenticação necessária.";
      notifyListeners();
      return;
    }
    _isLoading = true;
    _erro = null;
    notifyListeners();
    try {
      _agendas = await _service.buscarAgendasPorProfissional(profissionalId, token);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// NOVO: Busca os períodos de uma agenda específica. Retorna a lista de períodos.
  Future<List<Periodo>> buscarPeriodosDaAgenda(String agendaId) async {
    final token = _auth?.usuario?.token;
    if (token == null) {
      throw Exception("Autenticação necessária.");
    }
    return await _service.buscarPeriodosPorAgenda(agendaId, token);
  }

  Future<void> adicionarAgendaCompleta(Agenda agenda, List<Periodo> periodos) async {
    final token = _auth?.usuario?.token;
    if (token == null) throw Exception("Ação não permitida. Faça login.");
    await _service.criarAgendaCompleta(agenda, periodos, token);
  }

  Future<void> atualizarAgendaCompleta(Agenda agenda, List<Periodo> periodos) async {
    final token = _auth?.usuario?.token;
    if (token == null) throw Exception("Ação não permitida. Faça login.");
    await _service.atualizarAgendaCompleta(agenda, periodos, token);
  }
}

