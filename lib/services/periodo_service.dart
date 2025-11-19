import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    final uri = Uri.parse('$baseUrl/periodo/$idAgenda');
    debugPrint('[PeriodoService] Buscando em: ${uri.toString()}');

    final response = await http.get(uri, headers: _getHeaders(token));

    debugPrint('[PeriodoService] status: ${response.statusCode}');
    debugPrint('[PeriodoService] body: ${response.body}');

    if (response.statusCode != 200) {
      debugPrint('[PeriodoService] Erro HTTP: ${response.statusCode} -> ${response.body}');
      throw Exception('Erro ao carregar períodos: ${response.body}');
    }

    try {
      final parsed = jsonDecode(response.body);
      debugPrint('[PeriodoService] parsed.runtimeType: ${parsed.runtimeType}');
      debugPrint('[PeriodoService] parsed is Map? ${parsed is Map} | is List? ${parsed is List}');

      // Extrai a lista de itens de forma segura:
      List<dynamic> dataList = [];

      if (parsed is List) {
        dataList = parsed;
      } else if (parsed is Map) {
        // normalize para Map<String, dynamic>
        final Map<String, dynamic> parsedMap = Map<String, dynamic>.from(parsed);
        final dynamic dataField = parsedMap['data'];
        debugPrint('[PeriodoService] dataField.runtimeType: ${dataField?.runtimeType}');

        if (dataField is List) {
          dataList = dataField;
        } else if (dataField is Map) {
          dataList = [dataField];
        } else if (dataField == null) {
          dataList = [];
        } else {
          debugPrint('[PeriodoService] campo "data" em formato inesperado: ${dataField.runtimeType}');
          dataList = [];
        }
      } else {
        debugPrint('[PeriodoService] Formato de response inesperado: ${parsed.runtimeType}');
        dataList = [];
      }

      if (dataList.isEmpty) {
        debugPrint('[PeriodoService] Nenhum período encontrado.');
        return [];
      }

      final List<Periodo> periodos = [];
      for (var item in dataList) {
        try {
          final Map<String, dynamic> mapItem = item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item as Map);
          periodos.add(Periodo.fromJson(mapItem));
        } catch (e, st) {
          debugPrint('[PeriodoService] Ignorando item inválido ao converter para Periodo: $e\n$item\n$st');
        }
      }

      return periodos;
    } on FormatException catch (e, st) {
      debugPrint('[PeriodoService] JSON inválido: $e\n$st');
      throw Exception('Resposta inválida do servidor (JSON malformado)');
    } catch (e, st) {
      debugPrint('[PeriodoService] Erro ao decodificar/transformar JSON: $e\n$st');
      throw Exception('Resposta inválida do servidor: $e');
    }
  }

  Future<Periodo> criarPeriodo(Periodo periodo, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/periodo'),
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
      Uri.parse('$baseUrl/periodo/${periodo.id}'),
      headers: _getHeaders(token),
      body: jsonEncode(periodo.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar período: ${response.body}');
    }
  }

  Future<void> deletarPeriodo(String id, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/periodo/$id'),
      headers: _getHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao excluir período: ${response.body}');
    }
  }
}