import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/endereco_model.dart';

class CepService {
  /// Busca um endereço a partir de um CEP.
  /// Retorna um objeto [Endereco] ou `null` se o CEP não for encontrado.
  Future<Endereco?> buscarEndereco(String cep) async {
    // 1. Limpa o CEP, deixando apenas os números.
    final cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepLimpo.length != 8) {
      return null;
    }

    // 2. Monta a URL da API.
    final url = Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/');

    try {
      // 3. Faz a requisição HTTP GET.
      final response = await http.get(url);

      // 4. Se a resposta for bem-sucedida...
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 5. A API ViaCEP retorna um `{"erro": true}` se o CEP não existir.
        // Verificamos isso antes de tentar criar o modelo.
        if (data['erro'] == true) {
          return null;
        }

        // 6. Converte o JSON em um objeto Endereco e o retorna.
        return Endereco.fromJson(data);
      } else {
        // Se o servidor retornou um erro, lança uma exceção.
        throw Exception('Erro ao buscar CEP: Status ${response.statusCode}');
      }
    } catch (e) {
      // Captura erros de rede ou outras exceções.
      throw Exception('Erro de conexão ao buscar CEP.');
    }
  }

  /// Busca uma lista de CEPs a partir de um endereço.
  /// Retorna uma lista de objetos [Endereco].
  Future<List<Endereco>> buscarCepPorEndereco({
    required String uf,
    required String cidade,
    required String rua,
  }) async {
    // 1. Validação mínima para evitar buscas muito abertas.
    if (uf.isEmpty || cidade.isEmpty || rua.length < 3) {
      return []; // Retorna lista vazia se os dados forem insuficientes.
    }

    // 2. Monta a URL, codificando os componentes para lidar com espaços e acentos.
    final url = Uri.parse(
      'https://viacep.com.br/ws/${Uri.encodeComponent(uf)}/${Uri.encodeComponent(cidade)}/${Uri.encodeComponent(rua)}/json/',
    );

    try {
      // 3. Faz a requisição HTTP GET.
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // 4. A resposta é uma LISTA de objetos JSON.
        final List<dynamic> data = jsonDecode(response.body);

        // 5. Se a resposta não for uma lista ou estiver vazia, retorna uma lista vazia.
        if (data is! List || data.isEmpty) {
          return [];
        }

        // 6. Converte cada item da lista JSON em um objeto Endereco.
        return data.map((item) => Endereco.fromJson(item)).toList();
      } else {
        throw Exception(
          'Erro ao buscar endereço: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro de conexão ao buscar endereço.');
    }
  }
}
