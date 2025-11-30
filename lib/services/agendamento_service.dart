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
    if (response.statusCode == 400) {
      throw Exception('Erro 400: ${response.body}');
    }

    // Para outros erros, tentamos decodificar para ficar mais limpo
    try {
      final errorBody = jsonDecode(response.body);
      final String message = errorBody['message'] ?? response.body;
      throw Exception('Erro ${response.statusCode}: $message');
    } catch (e) {
      // Se não der para decodificar, vai o erro padrão HTTP
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

    final uri = Uri.parse('$baseUrl/agendamento')
        .replace(queryParameters: queryParameters);

    debugPrint('[AgendamentoService] Buscando em: ${uri.toString()}');

    try {
      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);
        List<dynamic> dataList;

        if (body is Map<String, dynamic> &&
            body.containsKey('data') &&
            body['data'] is List) {
          dataList = body['data'];
        } else if (body is List) {
          dataList = body;
        } else {
          debugPrint(
              '[AgendamentoService] Resposta 200, mas formato inesperado.');
          dataList = [];
        }

        final agendamentos =
            dataList.map((item) => Agendamento.fromJson(item)).toList();
        debugPrint(
            '[AgendamentoService] ${agendamentos.length} agendamentos carregados.');
        return agendamentos;
      } else {
        debugPrint(
            '[AgendamentoService] Erro ${response.statusCode} ao buscar: ${response.body}');
        _handleError(response);
        return [];
      }
    } catch (e) {
      debugPrint('[AgendamentoService] Exceção ao buscar: ${e.toString()}');
      rethrow;
    }
  }

  /// ROTA (POST)
  /// Cria um novo agendamento.
  Future<Agendamento> criarAgendamento(
      Agendamento agendamento, String token) async {
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

      if (response.statusCode == 201) {
        debugPrint('[AgendamentoService] Sucesso 201: ${response.body}');
        return agendamento;
      } else {
        debugPrint(
            '[AgendamentoService] Erro ${response.statusCode}: ${response.body}');
        // Aqui chamará o _handleError corrigido
        _handleError(response);
        throw Exception('Falha ao criar agendamento');
      }
    } catch (e) {
      debugPrint('[AgendamentoService] Exceção ao criar: ${e.toString()}');
      rethrow;
    }
  }

  /// ROTA (PATCH)
  /// Atualiza um agendamento.
  Future<void> atualizarAgendamento(
      Agendamento agendamento, String token) async {
    final Uri uri = Uri.parse('$baseUrl/agendamento/editar');
    final String body = jsonEncode(agendamento.toJson());

    debugPrint('[AgendamentoService] Atualizando em: ${uri.toString()}');
    debugPrint('[AgendamentoService] Body: $body');

    try {
      final response = await http.patch(
        uri,
        headers: _getHeaders(token),
        body: body,
      );

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