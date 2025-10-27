import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/bloqueio_model.dart';

class BloqueioService {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  Map<String, String> _getHeaders(String token) => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

  Future<List<Bloqueio>> getBloqueios(String idAgenda, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bloqueio/$idAgenda'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Bloqueio.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar bloqueios: ${response.body}');
    }
  }

  Future<Bloqueio> criarBloqueio(Bloqueio bloqueio, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bloqueio'),
      headers: _getHeaders(token),
      body: jsonEncode(bloqueio.toJson()),
    );

    if (response.statusCode == 201) {
      return Bloqueio.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao criar bloqueio: ${response.body}');
    }
  }

  Future<void> atualizarBloqueio(Bloqueio bloqueio, String token) async {
    if (bloqueio.id == null) throw Exception('ID do bloqueio não informado.');

    final response = await http.patch(
      Uri.parse('$baseUrl/bloqueio/${bloqueio.id}'),
      headers: _getHeaders(token),
      body: jsonEncode(bloqueio.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar bloqueio: ${response.body}');
    }
  }

  Future<void> deletarBloqueio(String id, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/bloqueio/$id'),
      headers: _getHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao excluir bloqueio: ${response.body}');
    }
  }
}