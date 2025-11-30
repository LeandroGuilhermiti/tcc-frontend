class Agenda {
  final String? id;
  final String nome;
  final String descricao;
  final int duracao;
  final String? avisoAgendamento;

  Agenda({
    this.id,
    required this.nome,
    required this.descricao,
    required this.duracao,
    this.avisoAgendamento,
  });

  factory Agenda.fromJson(Map<String, dynamic> json) {
    int duracaoConvertida = 0;
    final dynamic duracaoJson = json['duracao'];

    if (duracaoJson is int) {
      duracaoConvertida = duracaoJson;
    } else if (duracaoJson is String) {
      duracaoConvertida = int.tryParse(duracaoJson) ?? 0;
    }

    return Agenda(
      id: json['id']?.toString(),
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      duracao: duracaoConvertida,
      avisoAgendamento: json['avisoAgendamento']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'descricao': descricao,
      'duracao': duracao,
      if (avisoAgendamento != null && avisoAgendamento!.isNotEmpty)
        'avisoAgendamento': avisoAgendamento,
    };
  }
}