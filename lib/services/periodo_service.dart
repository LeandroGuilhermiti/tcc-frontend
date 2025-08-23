import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/periodo_model.dart';

class PeriodoService {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  /// Busca todos os períodos de trabalho de uma agenda/profissional específico.
  Future<List<Periodo>> getPeriodos(String idAgenda) async {
    // Endpoint para buscar períodos filtrando pelo ID da agenda
    final response = await http.get(Uri.parse('$baseUrl/periodos/agenda/$idAgenda'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Mapeia a lista de JSONs para uma lista de objetos Periodo
      return data.map((item) => Periodo.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar períodos de trabalho: ${response.body}');
    }
  }

  // futuros metodos para criar, atualizar e deletar períodos:
  // Future<Periodo> criarPeriodo(Periodo periodo) async { ... }
  // Future<void> atualizarPeriodo(Periodo periodo) async { ... }
  // Future<void> deletarPeriodo(String id) async { ... }
}