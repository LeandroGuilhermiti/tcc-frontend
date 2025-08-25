import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/periodo_model.dart';

class PeriodoService {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  /// Busca todos os períodos de trabalho de uma agenda/profissional específico.
  Future<List<Periodo>> getPeriodos(String idAgenda) async {
    // Endpoint para buscar períodos filtrando pelo ID da agenda
    final response = await http.get(
      Uri.parse('$baseUrl/periodos/agenda/$idAgenda'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Mapeia a lista de JSONs para uma lista de objetos Periodo
      return data.map((item) => Periodo.fromJson(item)).toList();
    } else {
      throw Exception(
        'Erro ao carregar períodos de trabalho: ${response.body}',
      );
    }
  }

  // Cria um novo período de trabalho.
  Future<Periodo> criarPeriodo(Periodo periodo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/periodos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(periodo.toJson()),
    );

    if (response.statusCode == 201) {
      // Retorna o período criado (incluindo o ID gerado pelo banco)
      return Periodo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao criar período: ${response.body}');
    }
  }

  // Atualiza um período de trabalho existente.
  Future<void> atualizarPeriodo(Periodo periodo) async {
    if (periodo.id == null) {
      throw Exception('ID do período não informado para atualização.');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/periodos/${periodo.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(periodo.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar período: ${response.body}');
    }
  }

  // Remove/deleta um período de trabalho.
  Future<void> deletarPeriodo(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/periodos/$id'));

    if (response.statusCode != 200) {
      throw Exception('Erro ao excluir período: ${response.body}');
    }
  }
}
