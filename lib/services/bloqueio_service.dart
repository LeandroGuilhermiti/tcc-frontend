// lib/services/bloqueio_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/bloqueio_model.dart';

class BloqueioService {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  // Busca todos os bloqueios de uma agenda/profissional específico.
  Future<List<Bloqueio>> getBloqueios(String idAgenda) async {
    final response = await http.get(Uri.parse('$baseUrl/bloqueios/agenda/$idAgenda'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Bloqueio.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar bloqueios: ${response.body}');
    }
  }

  // Cria um novo bloqueio de horário.
  Future<Bloqueio> criarBloqueio(Bloqueio bloqueio) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bloqueios'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bloqueio.toJson()),
    );

    if (response.statusCode == 201) {
      // Retorna o bloqueio criado (que agora inclui o ID gerado pelo banco)
      return Bloqueio.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao criar bloqueio: ${response.body}');
    }
  }

  // Atualiza um bloqueio existente.
  Future<void> atualizarBloqueio(Bloqueio bloqueio) async {
    if (bloqueio.id == null) {
      throw Exception('ID do bloqueio não informado para atualização.');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/bloqueios/${bloqueio.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bloqueio.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar bloqueio: ${response.body}');
    }
  }

  // Remove/deleta um bloqueio.
  Future<void> deletarBloqueio(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/bloqueios/$id'));

    if (response.statusCode != 200) {
      throw Exception('Erro ao excluir bloqueio: ${response.body}');
    }
  }
}