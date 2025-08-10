import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/agenda_model.dart';

class AgendaService {
  final String baseUrl = dotenv.env['API_BASE_URL']!;
  /// Busca todas as agendas
  Future<List<Agenda>> getAgendas() async {
    final response = await http.get(Uri.parse('$baseUrl/agenda'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Agenda.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar agendas: ${response.body}');
    }
  }

  /// Salva uma nova agenda
  Future<void> salvarAgenda(Agenda agenda) async {
    final response = await http.post(
      Uri.parse('$baseUrl/agenda'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(agenda.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Erro ao salvar agenda: ${response.body}');
    }
  }

  /// Atualiza uma agenda existente
  Future<void> atualizarAgenda(Agenda agenda) async {
    if (agenda.id == null) {
      throw Exception('ID da agenda não informado para atualização.');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/agenda/${agenda.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(agenda.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar agenda: ${response.body}');
    }
  }

  /// Remove uma agenda
  Future<void> deletarAgenda(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/agenda/$id'));

    if (response.statusCode != 200) {
      throw Exception('Erro ao excluir agenda: ${response.body}');
    }
  }
}
