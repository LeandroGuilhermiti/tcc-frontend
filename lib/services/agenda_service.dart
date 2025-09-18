import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/agenda_model.dart';
import '../models/periodo_model.dart';

class AgendaService {
  late final String _baseUrl;

  AgendaService() {
    // Carrega a URL base do seu arquivo .env
    _baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    if (_baseUrl.isEmpty) {
      throw Exception('API_BASE_URL não encontrada no ficheiro .env');
    }
  }

  // Monta os cabeçalhos padrão para as requisições
  Map<String, String> _getHeaders(String token) => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $token', // Assumindo autenticação via Bearer Token
  };

  /// Busca todas as agendas.
  /// NOTA: O endpoint foi ajustado para GET /agenda. A lógica de filtrar por profissional deve ser feita no backend ou, temporariamente, no frontend.
  Future<List<Agenda>> buscarAgendasPorProfissional(
    String profissionalId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/agenda'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Aqui pode ser necessário filtrar as agendas pelo profissionalId no frontend se o backend não o fizer.
      return data.map((item) => Agenda.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar agendas: ${response.body}');
    }
  }

  /// Busca todos os períodos de uma agenda específica.
  Future<List<Periodo>> buscarPeriodosPorAgenda(
    String agendaId,
    String token,
  ) async {
    // Assumindo que a rota para isto seja /periodo/{idAgenda}
    // Verifique se este endpoint existe no seu API Gateway.
    final response = await http.get(
      Uri.parse('$_baseUrl/periodo/$agendaId'), // Verifique esta rota
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
    // ROTA AJUSTADA: De /agendas/completa para /agenda/criar
    final response = await http.post(
      Uri.parse('$_baseUrl/agenda/criar'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'agenda': agenda.toJson(),
        'periodos': periodos.map((p) => p.toJson()).toList(),
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      // Aceita 201 ou 200
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

    // ROTA AJUSTADA: De PUT /agendas/completa/{id} para PATCH /agenda/{id}
    final response = await http.patch(
      Uri.parse('$_baseUrl/agenda/${agenda.id}'),
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
