import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/agendamento_model.dart';

class AgendamentoService {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  // Cabeçalhos padrão para incluir o token de autenticação
  Map<String, String> _getHeaders(String token) => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

  Future<List<Agendamento>> getAgendamentos(String idAgenda, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/agendamentos/agenda/$idAgenda'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Agendamento.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar agendamentos: ${response.body}');
    }
  }

  Future<Agendamento> criarAgendamento(Agendamento agendamento, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/agendamentos'),
      headers: _getHeaders(token),
      body: jsonEncode(agendamento.toJson()),
    );

    if (response.statusCode == 201) {
      return Agendamento.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao criar agendamento: ${response.body}');
    }
  }

  Future<void> atualizarAgendamento(Agendamento agendamento, String token) async {
    if (agendamento.id == null) throw Exception('ID do agendamento não informado.');

    final response = await http.patch(
      Uri.parse('$baseUrl/agendamentos/${agendamento.id}'),
      headers: _getHeaders(token),
      body: jsonEncode(agendamento.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar agendamento: ${response.body}');
    }
  }

  Future<void> deletarAgendamento(String id, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/agendamentos/$id'),
      headers: _getHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao excluir agendamento: ${response.body}');
    }
  }
}
