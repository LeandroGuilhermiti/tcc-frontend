import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Importante para formatar a data
import '../models/bloqueio_model.dart';
import 'package:flutter/foundation.dart'; 

class BloqueioService {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  Map<String, String> _getHeaders(String token) => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

  Future<List<Bloqueio>> getBloqueios(String idAgenda, String token) async {
    // ... (o método getBloqueios permanece igual, pois funcionava) ...
    final uri = Uri.parse('$baseUrl/bloqueio/$idAgenda');
    debugPrint('[BloqueioService] Buscando em: ${uri.toString()}');

    final response = await http.get(uri, headers: _getHeaders(token));

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> dataList = body['data'] as List<dynamic>? ?? [];
      
      try {
         return dataList.map((item) => Bloqueio.fromJson(item)).toList();
      } catch (e) {
        debugPrint('[BloqueioService] Erro parse: $e');
        return [];
      }
    } else {
      throw Exception('Erro ao carregar bloqueios: ${response.body}');
    }
  }


  Future<void> criarBloqueio(Bloqueio bloqueio, String token) async {
    final uri = Uri.parse('$baseUrl/bloqueio');
    
    // 1. Clonar o mapa para podermos modificar os campos
    final Map<String, dynamic> payload = bloqueio.toJson();

    // 2. CORREÇÃO DE DATA: Formatar para "yyyy-MM-dd HH:mm:ss" (Igual ao Postman)
    // O Flutter padrão manda com 'T' e milissegundos, o que quebrava o backend (Erro 500)
    payload['dataHora'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(bloqueio.dataHora);

    // 3. Garantir que o ID é número (como visto antes)
    if (payload['idAgenda'] is String) {
      payload['idAgenda'] = int.tryParse(payload['idAgenda']) ?? payload['idAgenda'];
    }

    debugPrint('--- [CRIAR BLOQUEIO] Payload Corrigido ---');
    debugPrint(jsonEncode(payload));

    final response = await http.post(
      uri,
      headers: _getHeaders(token),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      debugPrint('Bloqueio criado com sucesso no backend.');
      return; 
    } else {
      debugPrint('[BloqueioService] Erro no Backend: ${response.body}');
      throw Exception('Erro ao criar bloqueio: ${response.body}');
    }
  }

  Future<void> atualizarBloqueio(Bloqueio bloqueio, String token) async {
    // 1. URL com o ID da Agenda (Parâmetro de rota)
    final uri = Uri.parse('$baseUrl/bloqueio/${bloqueio.idAgenda}');

    // 2. Body conforme sua imagem do Postman
    final Map<String, dynamic> payload = {
      "idAgenda": bloqueio.idAgenda, // Envia também no body se o back pedir
      "dataHora": DateFormat('yyyy-MM-dd HH:mm:ss').format(bloqueio.dataHora), // Chave de busca
      "duracao": bloqueio.duracao, // O que vai ser alterado
      "descricao": bloqueio.descricao // Opcional, se quiser permitir editar
    };

    debugPrint('--- [PATCH BLOQUEIO] ---');
    debugPrint('URL: $uri');
    debugPrint('Body: ${jsonEncode(payload)}');

    final response = await http.patch(
      uri,
      headers: _getHeaders(token),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar bloqueio: ${response.body}');
    }
  }

  Future<void> deletarBloqueio(int idAgenda, DateTime dataHora, String token) async {
    final uri = Uri.parse('$baseUrl/bloqueio/$idAgenda');
    final dataFormatada = DateFormat('yyyy-MM-dd HH:mm:ss').format(dataHora);

    final response = await http.delete(
      uri,
      headers: _getHeaders(token),
      body: jsonEncode({"dataHora": dataFormatada}), 
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao excluir bloqueio: ${response.body}');
    }
  }
}