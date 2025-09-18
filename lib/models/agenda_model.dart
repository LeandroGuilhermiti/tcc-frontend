class Agenda {
  final String? id;
  final String nome;
  final String descricao;
  final String duracao;
  final String? avisoAgendamento;
  final bool principal;

  Agenda({
    this.id,
    required this.nome,
    required this.descricao,
    required this.duracao,
    this.avisoAgendamento,
    required this.principal,
  });

  factory Agenda.fromJson(Map<String, dynamic> json) {
    return Agenda(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      duracao: json['duracao'],
      avisoAgendamento: json['aviso_agendamento'] ?? '', 
      principal: json['principal'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id, // só inclui o id se não for nulo
      'nome': nome,
      'descricao': descricao,
      'duracao': duracao,
      if (avisoAgendamento != null && avisoAgendamento!.isNotEmpty) 'aviso_agendamento': avisoAgendamento,
      'principal': principal,
    };
  }
}
