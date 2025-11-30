import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/agendamento_model.dart';

class AgendamentoService {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  Map<String, String> _getHeaders(String token) => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

  /// Lança uma exceção padronizada a partir da resposta HTTP.
  void _handleError(http.Response response) {
    // Tenta decodificar o corpo do erro
    try {
      final errorBody = jsonDecode(response.body);
      // Extrai a 'message' específica do backend, se existir
      final String message = errorBody['message'] ?? response.body;
      throw Exception(message);
    } catch (e) {
      // Se o corpo não for um JSON válido, lança o status code
      throw Exception('Erro ${response.statusCode}: ${response.reasonPhrase}');
    }
  }

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
      queryParameters['dataHora'] =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(dataHora);
    }

    final uri =
        Uri.parse('$baseUrl/agendamento').replace(queryParameters: queryParameters);

    debugPrint('[AgendamentoService] Buscando em: ${uri.toString()}');

    try {
      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        // --- CORREÇÃO: Tratar ambos os formatos de resposta ---
        final dynamic body = jsonDecode(response.body);
        List<dynamic> dataList;

        if (body is Map<String, dynamic> &&
            body.containsKey('data') &&
            body['data'] is List) {
          // Formato: { "data": [...] }
          dataList = body['data'];
        } else if (body is List) {
          // Formato: [ ... ]
          dataList = body;
        } else {
          // Formato inesperado
          debugPrint(
              '[AgendamentoService] Resposta 200, mas formato inesperado.');
          dataList = [];
        }
        // --- FIM DA CORREÇÃO ---

        final agendamentos =
            dataList.map((item) => Agendamento.fromJson(item)).toList();
        debugPrint(
            '[AgendamentoService] ${agendamentos.length} agendamentos carregados.');
        return agendamentos;
      } else {
        // Se a resposta não for 200, é um erro
        debugPrint(
            '[AgendamentoService] Erro ${response.statusCode} ao buscar: ${response.body}');
        _handleError(response);
        return []; // Nunca será atingido
      }
    } catch (e) {
      // Erro de rede ou de parsing
      debugPrint('[AgendamentoService] Exceção ao buscar: ${e.toString()}');
      rethrow; // Lança a exceção para o provider
    }
  }

  /// ROTA (POST)
  /// Cria um novo agendamento.
  Future<Agendamento> criarAgendamento(
      Agendamento agendamento, String token) async {
    // O seu template.yaml usa /agendamento/criar para a orquestração
    final Uri uri = Uri.parse('$baseUrl/agendamento/criar');
    final String body = jsonEncode(agendamento.toJson());

    debugPrint('[AgendamentoService] Criando agendamento em: ${uri.toString()}');
    debugPrint('[AgendamentoService] Body: $body');

    try {
      final response = await http.post(
        uri,
        headers: _getHeaders(token),
        body: body,
      );

      // --- CORREÇÃO PRINCIPAL AQUI ---
      // O seu backend (Orquestrador) retorna 201 (Created) em caso de sucesso.
      if (response.statusCode == 201) {
        debugPrint('[AgendamentoService] Sucesso 201: ${response.body}');
        
        // O backend confirma a criação, mas não retorna o objeto 'Agendamento'.
        // Portanto, retornamos o mesmo objeto 'agendamento' que enviamos,
        // pois ele é a representação do que foi salvo.
        return agendamento;

      } else {
        // Se não for 201, é um erro (ex: 400 Bad Request)
        debugPrint(
            '[AgendamentoService] Erro ${response.statusCode}: ${response.body}');
        _handleError(response);
        throw Exception(
            'Falha ao criar agendamento'); // Nunca será atingido
      }
    } catch (e) {
      // Erro de rede ou o _handleError
      debugPrint(
          '[AgendamentoService] Exceção ao criar: ${e.toString()}');
      rethrow; // Lança a exceção para o provider
    }
  }

  /// ROTA (PATCH)
  /// Atualiza um agendamento.
  Future<void> atualizarAgendamento(
      Agendamento agendamento, String token) async {
    // O seu template.yaml usa PATCH /agendamento
    final Uri uri = Uri.parse('$baseUrl/agendamento/editar');
    
    // --- ESTA É A CORREÇÃO ---
    // Em vez de montar um JSON manual, usamos o método .toJson()
    // que já existe no seu AgendamentoModel e que inclui o 'id'.
    final String body = jsonEncode(agendamento.toJson());
    // --- FIM DA CORREÇÃO ---

    debugPrint('[AgendamentoService] Atualizando em: ${uri.toString()}');
    debugPrint('[AgendamentoService] Body: $body'); // <-- Agora o 'id' deve aparecer aqui

    try {
      final response = await http.patch(
        uri,
        headers: _getHeaders(token),
        body: body,
      );

      // O seu backend de PATCH retorna 200
      if (response.statusCode != 200) {
        debugPrint(
            '[AgendamentoService] Erro ${response.statusCode} ao atualizar: ${response.body}');
        _handleError(response);
      } else {
        debugPrint(
            '[AgendamentoService] Sucesso 200 ao atualizar: ${response.body}');
      }
    } catch (e) {
      debugPrint(
          '[AgendamentoService] Exceção ao atualizar: ${e.toString()}');
      rethrow;
    }
  }

  /// ROTA (DELETE)
  /// Exclui um agendamento.
  Future<void> deletarAgendamento(
      Agendamento agendamento, String token) async {
    // O seu template.yaml usa DELETE /agendamento
    final Uri uri = Uri.parse('$baseUrl/agendamento');
    final body = jsonEncode({
      'idAgenda': agendamento.idAgenda,
      'idUsuario': agendamento.idUsuario,
      'dataHora': agendamento.dataHora.toIso8601String(),
    });

    debugPrint('[AgendamentoService] Deletando em: ${uri.toString()}');
    debugPrint('[AgendamentoService] Body: $body');

    try {
      final response = await http.delete(
        uri,
        headers: _getHeaders(token),
        body: body,
      );

      // O seu backend de DELETE retorna 200
      if (response.statusCode != 200) {
        debugPrint(
            '[AgendamentoService] Erro ${response.statusCode} ao deletar: ${response.body}');
        _handleError(response);
      } else {
        debugPrint(
            '[AgendamentoService] Sucesso 200 ao deletar: ${response.body}');
      }
    } catch (e) {
      debugPrint(
          '[AgendamentoService] Exceção ao deletar: ${e.toString()}');
      rethrow;
    }
  }
}
