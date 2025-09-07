class Endereco {
  final String cep;
  final String logradouro; // Nome da rua
  final String complemento;
  final String bairro;
  final String localidade; // Cidade
  final String uf; // Estado

  Endereco({
    required this.cep,
    required this.logradouro,
    required this.complemento,
    required this.bairro,
    required this.localidade,
    required this.uf,
  });

  /// Construtor de fábrica para criar um Endereco a partir de um JSON.
  factory Endereco.fromJson(Map<String, dynamic> json) {
    return Endereco(
      cep: json['cep'] ?? '',
      logradouro: json['logradouro'] ?? '',
      complemento: json['complemento'] ?? '',
      bairro: json['bairro'] ?? '',
      localidade: json['localidade'] ?? '',
      uf: json['uf'] ?? '',
    );
  }
}