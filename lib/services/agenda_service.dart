import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/agenda_model.dart';
import '../models/periodo_model.dart';

class AgendaService {
  late final String _baseUrl;

  AgendaService() {
    _baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    if (_baseUrl.isEmpty) {
      throw Exception('API_BASE_URL não encontrada no ficheiro .env');
    }
  }

  Map<String, String> _getHeaders(String token) => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $token',
  };

  /// Busca todas as agendas associadas a um ID de profissional.
  Future<List<Agenda>> buscarAgendasPorProfissional(
    String profissionalId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/agendas/profissional/$profissionalId'),
      headers: _getHeaders(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Agenda.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar agendas: ${response.body}');
    }
  }

  ///Busca todos os períodos de uma agenda específica.
  Future<List<Periodo>> buscarPeriodosPorAgenda(
    String agendaId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/periodos/agenda/$agendaId'),
      headers: _getHeaders(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Periodo.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar períodos: ${response.body}');
    }
  }

  /// Cria uma nova agenda e os seus períodos associados.
  Future<void> criarAgendaCompleta(
    Agenda agenda,
    List<Periodo> periodos,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/agendas/completa'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'agenda': agenda.toJson(),
        'periodos': periodos.map((p) => p.toJson()).toList(),
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Erro ao criar agenda completa: ${response.body}');
    }
  }

  /// Atualiza uma agenda existente e os seus períodos.
  Future<void> atualizarAgendaCompleta(
    Agenda agenda,
    List<Periodo> periodos,
    String token,
  ) async {
    if (agenda.id == null) throw Exception('ID da agenda não informado.');
    final response = await http.put(
      Uri.parse('$_baseUrl/agendas/completa/${agenda.id}'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'agenda': agenda.toJson(),
        'periodos': periodos.map((p) => p.toJson()).toList(),
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar agenda completa: ${response.body}');
    }
  }
}
