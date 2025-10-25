import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../config/app_config.dart';

/// Classe de serviço responsável pela comunicação com a API para operações de usuário.
class UsuarioService {
  final String _baseUrl = AppConfig.apiBaseUrl;

  /// Busca uma lista de todos os usuários do backend.
  /// Requer um [token] de autenticação de um usuário admin.
  ///
  /// ATUALIZADO: Esta função agora trata a paginação do endpoint /usuario.
  Future<List<UserModel>> buscarTodosUsuarios(String token) async {
    List<UserModel> todosUsuarios = [];
    int paginaAtual = 1;
    bool haMaisPaginas = true;
    const int limitePorPagina = 50; // Vamos buscar de 50 em 50 para eficiência.

    final String endpointBase = '$_baseUrl/usuario';

    try {
      // Loop para buscar todas as páginas de usuários
      while (haMaisPaginas) {
        // 2. CORREÇÃO: Adicionamos os parâmetros de query 'page' e 'limit'
        final Uri url = Uri.parse('$endpointBase?page=$paginaAtual&limit=$limitePorPagina');

        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> responseData = jsonDecode(response.body);

          // Se a lista retornada estiver vazia, paramos o loop
          if (responseData.isEmpty) {
            haMaisPaginas = false;
          } else {
            // Adiciona os usuários desta página à lista total
            todosUsuarios.addAll(responseData.map((data) => UserModel.fromJson(data)).toList());
            // Prepara para buscar a próxima página
            paginaAtual++;
          }
        } else {
          // Se falhar em qualquer página, lança um erro
          throw Exception('Falha ao carregar usuários (página $paginaAtual): ${response.body}');
        }
      }
      
      // Retorna a lista completa com usuários de todas as páginas
      return todosUsuarios;

    } catch (e) {
      // Captura erros de rede ou outras exceções.
      throw Exception('Erro de rede ao buscar usuários: $e');
    }
  }

  /// Cadastra um novo usuário no backend.
  /// Requer os [dadosNovoUsuario] em formato de Map e um [token] de autenticação.
  Future<UserModel> cadastrarUsuario(Map<String, dynamic> dadosNovoUsuario, String token) async {
    // 3. CORREÇÃO: Garantir que o endpoint de POST também está correto
    final Uri url = Uri.parse('$_baseUrl/usuario'); // Singular

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
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

  /// Atualiza os dados de um usuário existente.
  Future<void> atualizarUsuario(String id, Map<String, dynamic> dadosAtualizados, String token) async {
    // 4. CORREÇÃO: Garantir que o endpoint de PUT também está correto
    final Uri url = Uri.parse('$_baseUrl/usuario/$id'); // Singular

    try {
      final response = await http.put(
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
  Future<void> deletarUsuario(String id, String token) async {
    // 5. CORREÇÃO: Garantir que o endpoint de DELETE também está correto
    final Uri url = Uri.parse('$_baseUrl/usuario/$id'); // Singular

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204) {
        throw Exception('Falha ao deletar usuário: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro de rede ao deletar usuário: $e');
    }
  }
}
