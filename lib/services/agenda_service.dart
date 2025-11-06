import 'dart:convert';
import 'package:flutter/foundation.dart'; // Importar para debugPrint
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

  // --- ALTERAÇÃO AQUI ---
  /// Busca TODAS as agendas (removido o filtro de profissional).
  Future<List<Agenda>> buscarTodasAgendas(String token) async {
  // --- FIM DA ALTERAÇÃO ---
    
    // A rota GET /agenda já busca todas as agendas (ou todas as que o token permite)
    final uri = Uri.parse('$_baseUrl/agenda');
    debugPrint('[AgendaService] Buscando em: ${uri.toString()}');

    final response = await http.get(
      uri, // Usa a URI
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {

      // --- CORREÇÃO PRINCIPAL (Como no UsuarioService) ---
      // 1. A API retorna um Objeto (Map) e não uma Lista.
      final Map<String, dynamic> responseObject = jsonDecode(response.body);

      // 2. Pegamos a lista que está dentro da chave "data".
      //    Se a chave "data" não existir, usamos uma lista vazia.
      final List<dynamic> dataList =
          responseObject['data'] as List<dynamic>? ?? [];
      // --- FIM DA CORREÇÃO ---

      if (dataList.isEmpty) {
        debugPrint(
          "[AgendaService] Sucesso, mas a chave 'data' no backend /agenda está vazia ou não existe.",
        );
        return [];
      }
      
      // 3. Mapeia a lista de dados para a lista de Agendas
      final agendas = dataList.map((item) => Agenda.fromJson(item)).toList();
      debugPrint("[AgendaService] ${agendas.length} agendas carregadas.");
      return agendas;

    } else {
      debugPrint('[AgendaService] Erro ao carregar agendas: ${response.body}');
      throw Exception('Erro ao carregar agendas: ${response.body}');
    }
  }

  /// Busca todos os períodos de uma agenda específica.
  Future<List<Periodo>> buscarPeriodosPorAgenda(
    String agendaId,
    String token,
  ) async {
    final uri = Uri.parse('$_baseUrl/periodo/$agendaId');
    debugPrint('[AgendaService] BuscarPeriodosPorAgenda em: ${uri.toString()}');

    final response = await http.get(uri, headers: _getHeaders(token));

    if (response.statusCode != 200) {
      debugPrint('[AgendaService] Erro ao carregar períodos: ${response.statusCode} -> ${response.body}');
      throw Exception('Erro ao carregar períodos: ${response.body}');
    }

    try {
      final parsed = jsonDecode(response.body);
      debugPrint('[AgendaService] parsed.runtimeType: ${parsed.runtimeType}');

      List<dynamic> dataList;
      if (parsed is List) {
        dataList = parsed;
      } else if (parsed is Map<String, dynamic>) {
        final dynamic dataField = parsed['data'];
        if (dataField is List) {
          dataList = dataField;
        } else if (dataField is Map) {
          dataList = [dataField];
        } else {
          dataList = [];
        }
      } else {
        dataList = [];
      }

      final List<Periodo> periodos = [];
      for (var item in dataList) {
        try {
          final Map<String, dynamic> mapItem = item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item as Map);
          periodos.add(Periodo.fromJson(mapItem));
        } catch (e, st) {
          debugPrint('[AgendaService] Ignorando item inválido de período: $e\n$item\n$st');
        }
      }

      return periodos;
    } catch (e, st) {
      debugPrint('[AgendaService] Erro ao decodificar/transformar JSON: $e\n$st');
      throw Exception('Resposta inválida do servidor ao buscar períodos');
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