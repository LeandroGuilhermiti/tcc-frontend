import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/agendamento_model.dart';

class AgendamentoService {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  // CORREÇÃO 1: Adicionado "Bearer " ao token
  Map<String, String> _getHeaders(String token) => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

  /// ROTA (GET)
  /// Busca agendamentos.
  Future<List<Agendamento>> getAgendamentos({
    required String idAgenda,
    String? idUsuario,
    DateTime? dataHora,
    required String token,
  }) async {
    final Map<String, String> queryParameters = {
      'idAgenda': idAgenda,
    };
    if (idUsuario != null) {
      queryParameters['idUsuario'] = idUsuario;
    }
    if (dataHora != null) {
      queryParameters['dataHora'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(dataHora);
    }

    // O endpoint é /agendamento
    final uri = Uri.parse('$baseUrl/agendamento').replace(queryParameters: queryParameters);

    final response = await http.get(uri, headers: _getHeaders(token));

    if (response.statusCode == 200) {
      // O seu backend retorna um objeto { data: [...] }
      final Map<String, dynamic> body = jsonDecode(response.body);
      
      // Verificamos se 'data' existe e é uma lista
      if (body.containsKey('data') && body['data'] is List) {
         final List<dynamic> data = body['data'];
         return data.map((item) => Agendamento.fromJson(item)).toList();
      } else {
        // Se a resposta for 200 mas não tiver 'data' (ex: busca vazia)
        return [];
      }
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Erro ao carregar agendamentos');
    }
  }

  /// ROTA (POST)
  /// Cria um novo agendamento.
  Future<Agendamento> criarAgendamento(Agendamento agendamento, String token) async {
    
    // CORREÇÃO 2: O endpoint de criação é /agendamento (método POST)
    final Uri uri = Uri.parse('$baseUrl/agendamento/criar');

    print(jsonEncode(agendamento.toJson()));

    final response = await http.post(
      uri,
      headers: _getHeaders(token),
      body: jsonEncode(agendamento.toJson()),
    );

    // O seu backend Orquestrador (index.mjs) retorna 201 (Created)
    if (response.statusCode == 201) {
      // O seu backend (Orquestrador) já retorna o objeto { data: [agendamento], ... }
      final Map<String, dynamic> body = jsonDecode(response.body);
      final agendamentoCriado = Agendamento.fromJson(body['data'][0]);
      return agendamentoCriado;
    } else {
      // Captura a mensagem de erro específica do backend
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Erro ao criar agendamento');
    }
  }

  /// ROTA (PUT)
  /// Atualiza um agendamento.
  Future<void> atualizarAgendamento(Agendamento agendamento, String token) async {
    
    final Uri uri = Uri.parse('$baseUrl/agendamento'); // Método PUT

    // CORREÇÃO 3: O seu backend de UPDATE (terceiro index.mjs)
    // espera a chave (idAgenda, idUsuario, dataHora) E
    // a propriedade a ser mudada ("duracao").
    final body = jsonEncode({
      'idAgenda': agendamento.idAgenda,
      'idUsuario': agendamento.idUsuario,
      'dataHora': agendamento.dataHora.toIso8601String(),
      'duracao': agendamento.duracao, // O único campo que o seu backend permite
    });

    final response = await http.put(
      uri,
      headers: _getHeaders(token),
      body: body,
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Erro ao atualizar agendamento');
    }
  }

  /// ROTA (DELETE)
  /// Exclui um agendamento.
  Future<void> deletarAgendamento(Agendamento agendamento, String token) async {
    
    final Uri uri = Uri.parse('$baseUrl/agendamento'); // Método DELETE

    final body = jsonEncode({
      'idAgenda': agendamento.idAgenda,
      'idUsuario': agendamento.idUsuario,
      'dataHora': agendamento.dataHora.toIso8601String(),
    });

    final response = await http.delete(
      uri,
      headers: _getHeaders(token),
      body: body,
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Erro ao excluir agendamento');
    }
  }
}

