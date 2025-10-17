import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../config/app_config.dart';

/// Classe de serviço responsável pela comunicação com a API para operações de usuário.
class UsuarioService {

  final String _baseUrl = AppConfig.apiBaseUrl;

  /// Busca uma lista de todos os usuários do backend.
  /// Requer um [token] de autenticação de um usuário admin.
  Future<List<UserModel>> buscarTodosUsuarios(String token) async {
    final Uri url = Uri.parse('$_baseUrl/usuarios');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          // O token é enviado no cabeçalho para autorizar a requisição.
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Decodifica a resposta JSON, que deve ser uma lista de objetos.
        final List<dynamic> responseData = jsonDecode(response.body);
        // Converte cada objeto da lista em um UserModel.
        return responseData.map((data) => UserModel.fromJson(data)).toList();
      } else {
        // Se o servidor retornou um erro, lança uma exceção com a mensagem.
        throw Exception('Falha ao carregar usuários: ${response.body}');
      }
    } catch (e) {
      // Captura erros de rede ou outras exceções.
      throw Exception('Erro de rede ao buscar usuários: $e');
    }
  }

  /// Cadastra um novo usuário no backend.
  /// Requer os [dadosNovoUsuario] em formato de Map e um [token] de autenticação.
  Future<UserModel> cadastrarUsuario(Map<String, dynamic> dadosNovoUsuario, String token) async {
    final Uri url = Uri.parse('$_baseUrl/usuarios');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        // Envia os dados do novo usuário no corpo da requisição.
        body: jsonEncode(dadosNovoUsuario),
      );

      if (response.statusCode == 201) { // 201 Created é o status de sucesso para POST
        // Se o backend retornar o usuário criado, o decodificamos e retornamos.
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Falha ao cadastrar usuário: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro de rede ao cadastrar usuário: $e');
    }
  }

  /// Atualiza os dados de um usuário existente.
  /// Requer o [id] do usuário, os [dadosAtualizados] e o [token] de autenticação.
  Future<void> atualizarUsuario(String id, Map<String, dynamic> dadosAtualizados, String token) async {
    final Uri url = Uri.parse('$_baseUrl/usuarios/$id');

    try {
      final response = await http.put( // ou http.patch, dependendo da sua API
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(dadosAtualizados),
      );

      if (response.statusCode != 200) {
        throw Exception('Falha ao atualizar usuário: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro de rede ao atualizar usuário: $e');
    }
  }

  /// Deleta um usuário do sistema.
  /// Requer o [id] do usuário a ser deletado e o [token] de autenticação.
  Future<void> deletarUsuario(String id, String token) async {
    final Uri url = Uri.parse('$_baseUrl/usuarios/$id');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204) { // 204 No Content é um status de sucesso comum para DELETE
        throw Exception('Falha ao deletar usuário: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro de rede ao deletar usuário: $e');
    }
  }
}
