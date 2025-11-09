import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../config/app_config.dart';

/// Classe de serviço responsável pela comunicação com a API para operações de usuário.
class UsuarioService {
  final String _baseUrl = AppConfig.apiBaseUrl;

  // Monta os cabeçalhos padrão com o Bearer Token
  Map<String, String> _getHeaders(String token) => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

  /// Busca uma lista de todos os usuários do backend.
  Future<List<UserModel>> buscarTodosUsuarios(String token) async {
    final Uri url = Uri.parse('$_baseUrl/usuario/buscar');
    debugPrint("[UsuarioService] Buscando usuários em: ${url.toString()}");

    try {
      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseObject = jsonDecode(response.body);
        final List<dynamic> responseData =
            responseObject['data'] as List<dynamic>? ?? [];

        if (responseData.isEmpty) {
          debugPrint(
            "[UsuarioService] Sucesso, mas a chave 'data' no backend /usuario/buscar está vazia.",
          );
          return [];
        }

        final usuarios =
            responseData.map((data) => UserModel.fromJson(data)).toList();
        debugPrint(
          "[UsuarioService] ${usuarios.length} usuários carregados com sucesso.",
        );
        return usuarios;
      } else {
        debugPrint(
          "[UsuarioService] Falha ao carregar usuários. Status: ${response.statusCode}, Body: ${response.body}",
        );
        throw Exception(
          'Falha ao carregar usuários do Cognito: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint(
        "[UsuarioService] Erro de rede ou parse ao buscar usuários: $e",
      );
      throw Exception(
        'Erro de rede ou formato de resposta ao buscar usuários: $e',
      );
    }
  }

  /// Cadastra um novo usuário no backend.
  Future<UserModel> cadastrarUsuario(
    Map<String, dynamic> dadosNovoUsuario,
    String token,
  ) async {
    // ... (código existente sem alterações) ...
    final Uri url = Uri.parse('$_baseUrl/usuario');

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode(dadosNovoUsuario),
      );

      if (response.statusCode == 201) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Falha ao cadastrar usuário: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro de rede ao cadastrar usuário: $e');
    }
  }

  /// Deleta um usuário do sistema.
  Future<void> deletarUsuario(String id, String token) async {
    // ... (código existente sem alterações) ...
    final Uri url = Uri.parse('$_baseUrl/usuario/$id');

    try {
      final response = await http.delete(url, headers: _getHeaders(token));

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Falha ao deletar usuário: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro de rede ao deletar usuário: $e');
    }
  }

  /// Atualiza os dados de um usuário existente.
  Future<void> atualizarUsuario(
    String id,
    Map<String, dynamic> dadosAtualizados,
    String token,
  ) async {
    final Uri url = Uri.parse('$_baseUrl/usuario/$id');
    debugPrint("[UsuarioService] Dados: ${jsonEncode(dadosAtualizados)}");
    debugPrint("[UsuarioService] Atualizando usuário em: ${url.toString()}");

    try {
      final response = await http.patch(
        url,
        headers: _getHeaders(token),
        body: jsonEncode(dadosAtualizados),
      );

      if (response.statusCode != 200) {
        debugPrint(
            "[UsuarioService] Erro ao atualizar: ${response.statusCode} -> ${response.body}");
        throw Exception('Falha ao atualizar dados: ${response.body}');
      }

      debugPrint("[UsuarioService] Sucesso ao atualizar.");

    } catch (e) {
      debugPrint("[UsuarioService] Erro de rede ao atualizar: $e");
      throw Exception('Erro de rede ao atualizar usuário: $e');
    }
  }
}