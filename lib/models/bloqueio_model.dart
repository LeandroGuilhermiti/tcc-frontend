class Bloqueio {
  final String? id; // O ID único do bloqueio (pode ser nulo ao criar um novo)
  final String idAgenda;
  final DateTime dataHora;
  final int duracao;
  final String descricao; 

  Bloqueio({
    this.id,
    required this.idAgenda,
    required this.dataHora,
    required this.duracao,
    required this.descricao,
  });

  /// Construtor para criar um Bloqueio a partir de um mapa JSON (vindo da API)
  factory Bloqueio.fromJson(Map<String, dynamic> json) {
    
    final idValue = json['id'] ?? json['_id'];
    final idAgendaValue = json['idAgenda'];

    if (json['dataHora'] == null) {
      throw Exception("Erro de parsing do Bloqueio: 'dataHora' está nulo.");
    }

    return Bloqueio(
      id: idValue?.toString(), // Converte int para String
      idAgenda: idAgendaValue?.toString() ?? '', // Converte int para String
      dataHora: DateTime.parse(json['dataHora']),
      duracao: json['duracao'],
      descricao: json['descricao'] ?? '',
    );
  }

  /// Converte o objeto Bloqueio para um mapa JSON (para enviar para a API)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'idAgenda': idAgenda,
      'dataHora': dataHora.toIso8601String(),
      'duracao': duracao,
      'descricao': descricao,
    };
  }
}