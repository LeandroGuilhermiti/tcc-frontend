import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  Future<List<Agenda>> buscarTodasAgendas(String token) async {
    // Mantivemos o limit=100 da correção anterior
    final uri = Uri.parse('$_baseUrl/agenda?limit=100');
    final response = await http.get(uri, headers: _getHeaders(token));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseObject = jsonDecode(response.body);
      final List<dynamic> dataList =
          responseObject['data'] as List<dynamic>? ?? [];

      if (dataList.isEmpty) return [];

      return dataList.map((item) => Agenda.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar agendas: ${response.body}');
    }
  }

  Future<List<Periodo>> buscarPeriodosPorAgenda(
    String agendaId,
    String token,
  ) async {
    final uri = Uri.parse('$_baseUrl/periodo/$agendaId');
    final response = await http.get(uri, headers: _getHeaders(token));

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar períodos: ${response.body}');
    }

    try {
      final parsed = jsonDecode(response.body);
      List<dynamic> dataList = [];

      if (parsed is Map<String, dynamic>) {
        final dynamic dataField = parsed['data'];
        if (dataField is List) dataList = dataField;
      } else if (parsed is List) {
        dataList = parsed;
      }

      return dataList.map((item) => Periodo.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Resposta inválida ao buscar períodos');
    }
  }

  Future<Agenda> criarAgendaCompleta(
    Agenda agenda,
    List<Periodo> periodos,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/agenda/criar'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'agenda': agenda.toJson(),
        'periodos': periodos.map((p) => p.toJson()).toList(),
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      return Agenda.fromJson(jsonResponse);
    } else {
      throw Exception('Erro ao criar agenda completa: ${response.body}');
    }
  }

  Future<void> salvarEdicaoAvancada({
    required Map<String, dynamic> dadosAgenda,
    required List<Map<String, dynamic>> adicionar,
    required List<Map<String, dynamic>> editar,
    required List<Map<String, dynamic>> excluir,
    required String token,
  }) async {
    final uri = Uri.parse('$_baseUrl/agenda/editar');

    final Map<String, dynamic> body = {
      "agenda": dadosAgenda,
      "periodos": {
        "adicionar": adicionar,
        "editar": editar,
        "excluir": excluir,
      },
    };

    debugPrint(
      '[AgendaService] Enviando Payload de Edição: ${jsonEncode(body)}',
    );

    final response = await http.post(
      uri,
      headers: _getHeaders(token),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao editar agenda: ${response.body}');
    }
  }

  // EXCLUIR AGENDA 
  Future<void> excluirAgenda(String id, String token) async {
    final uri = Uri.parse('$_baseUrl/agenda/$id');
    
    final response = await http.delete(uri, headers: _getHeaders(token));

    // Aceita 200 (OK) ou 204 (No Content) como sucesso
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao excluir agenda: ${response.body}');
    }
  }
}