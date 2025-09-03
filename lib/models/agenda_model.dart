class Agenda {
  final String? id;
  final String nome;
  final String descricao;
  final String duracao;
  // final String aviso;

  Agenda({
    this.id,
    required this.nome,
    required this.descricao,
    required this.duracao,
    // required this.aviso,
  });

  factory Agenda.fromJson(Map<String, dynamic> json) {
    return Agenda(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      duracao: json['duracao'],
      // aviso: json['aviso'], 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id, // só inclui o id se não for nulo
      'nome': nome,
      'descricao': descricao,
      'duracao': duracao,
      // 'aviso': aviso,
    };
  }
}
