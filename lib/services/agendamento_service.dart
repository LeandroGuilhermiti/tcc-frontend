import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/agendamento_model.dart';

class AgendamentoService {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  // Busca todos os agendamentos de uma agenda/profissional específico.
  Future<List<Agendamento>> getAgendamentos(String idAgenda) async {
    // Endpoint para buscar agendamentos filtrando pelo ID da agenda/profissional
    final response = await http.get(Uri.parse('$baseUrl/agendamentos/agenda/$idAgenda'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Agendamento.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar agendamentos: ${response.body}');
    }
  }

  // Cria um novo agendamento.
  Future<Agendamento> criarAgendamento(Agendamento agendamento) async {
    final response = await http.post(
      Uri.parse('$baseUrl/agendamentos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(agendamento.toJson()),
    );

    // 201 (Created) é o status de sucesso padrão para POST
    if (response.statusCode == 201) {
      // Retorna o agendamento criado (que agora inclui o ID gerado pelo banco)
      return Agendamento.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao criar agendamento: ${response.body}');
    }
  }

  // Atualiza um agendamento existente.
  Future<void> atualizarAgendamento(Agendamento agendamento) async {
    if (agendamento.id == null) {
      throw Exception('ID do agendamento não informado para atualização.');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/agendamentos/${agendamento.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(agendamento.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar agendamento: ${response.body}');
    }
  }

  // Remove/deleta um agendamento.
  Future<void> deletarAgendamento(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/agendamentos/$id'));

    if (response.statusCode != 200) {
      throw Exception('Erro ao excluir agendamento: ${response.body}');
    }
  }
}