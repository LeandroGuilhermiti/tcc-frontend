class Agendamento {
  final String? id; // O ID único do agendamento (pode ser nulo ao criar um novo)
  final String idAgenda; // ID da agenda/profissional
  final String idUsuario; // ID do usuário/cliente
  final DateTime dataHora; // A data e hora exata do agendamento
  final int duracao; // Duração em minutos
  // final String? descricao; // Uma descrição ou nota opcional

  Agendamento({
    this.id,
    required this.idAgenda,
    required this.idUsuario,
    required this.dataHora,
    required this.duracao,
    // this.descricao,
  });

  // Construtor de fábrica para criar um Agendamento a partir de um mapa JSON (vindo da API)
  factory Agendamento.fromJson(Map<String, dynamic> json) {
    return Agendamento(
      // O backend pode retornar o ID como `id` ou `_id`
      id: json['id'] ?? json['_id'],
      idAgenda: json['id_agenda'],
      idUsuario: json['id_usuario'],
      // Converte a string de data que vem da API para um objeto DateTime do Dart
      dataHora: DateTime.parse(json['data_hora']),
      duracao: json['duracao'],
      // descricao: json['descricao'], // Este campo pode ser nulo
    );
  }

  // Converte o objeto Agendamento para um mapa JSON (para enviar para a API)
  Map<String, dynamic> toJson() {
    return {
      // O ID não é enviado ao criar um novo agendamento, pois o banco o gera
      if (id != null) 'id': id,
      'id_agenda': idAgenda,
      'id_usuario': idUsuario,
      // Converte o objeto DateTime para uma string no formato padrão ISO 8601
      // Ex: "2025-08-18T14:30:00.000Z" que é universalmente entendido por servidores
      'data_hora': dataHora.toIso8601String(),
      'duracao': duracao,
      // if (descricao != null) 'descricao': descricao,
    };
  }
}