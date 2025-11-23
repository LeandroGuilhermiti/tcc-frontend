import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/feriado_model.dart';

class FeriadoService {
  // Busca feriados de um ano específico
  Future<List<FeriadoModel>> getFeriados(int ano) async {
    final url = Uri.parse('https://brasilapi.com.br/api/feriados/v1/$ano');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((e) => FeriadoModel.fromJson(e)).toList();
      } else {
        // Se der erro (ex: ano muito futuro que a API não tem), retorna vazio
        return [];
      }
    } catch (e) {
      print('Erro ao buscar feriados: $e');
      return [];
    }
  }
}