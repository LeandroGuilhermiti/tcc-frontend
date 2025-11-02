class Bloqueio {
  final String? id; // O ID único do bloqueio (pode ser nulo ao criar um novo)
  final String idAgenda; 
  final DateTime dataHora; 
  final int duracao; 
  final String descricao; // Motivo do bloqueio (ex: "Folga", "Férias")

  Bloqueio({
    this.id,
    required this.idAgenda,
    required this.dataHora,
    required this.duracao,
    required this.descricao,
  });

  /// Construtor de fábrica para criar um Bloqueio a partir de um mapa JSON (vindo da API)
  factory Bloqueio.fromJson(Map<String, dynamic> json) {
    return Bloqueio(
      id: json['id'] ?? json['_id'],
      idAgenda: json['idAgenda'],
      // Converte a string de data que vem da API para um objeto DateTime do Dart
      dataHora: DateTime.parse(json['dataHora']),
      duracao: json['duracao'],
      descricao: json['descricao'],
    );
  }

  /// Converte o objeto Bloqueio para um mapa JSON (para enviar para a API)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'idAgenda': idAgenda,
      // Converte o objeto DateTime para uma string no formato padrão ISO 8601
      'dataHora': dataHora.toIso8601String(),
      'duracao': duracao,
      'descricao': descricao,
    };
  }
}