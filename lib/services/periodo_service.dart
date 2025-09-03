import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/periodo_model.dart';

class PeriodoService {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  Map<String, String> _getHeaders(String token) => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

  Future<List<Periodo>> getPeriodos(String idAgenda, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/periodos/agenda/$idAgenda'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Periodo.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar períodos: ${response.body}');
    }
  }

  Future<Periodo> criarPeriodo(Periodo periodo, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/periodos'),
      headers: _getHeaders(token),
      body: jsonEncode(periodo.toJson()),
    );

    if (response.statusCode == 201) {
      return Periodo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao criar período: ${response.body}');
    }
  }

  Future<void> atualizarPeriodo(Periodo periodo, String token) async {
    if (periodo.id == null) throw Exception('ID do período não informado.');

    final response = await http.patch(
      Uri.parse('$baseUrl/periodos/${periodo.id}'),
      headers: _getHeaders(token),
      body: jsonEncode(periodo.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar período: ${response.body}');
    }
  }

  Future<void> deletarPeriodo(String id, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/periodos/$id'),
      headers: _getHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao excluir período: ${response.body}');
    }
  }
}