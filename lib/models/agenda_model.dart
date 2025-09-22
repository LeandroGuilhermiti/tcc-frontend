import 'dart:ffi';

class Agenda {
  final String? id;
  final String nome;
  final String descricao;
  final int duracao;
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

  // Método para converter JSON (vindo do servidor) para um objeto Agenda
  factory Agenda.fromJson(Map<String, dynamic> json) {
    return Agenda(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      duracao: int.tryParse(json['duracao']?.toString() ?? '0') ?? 0,
      avisoAgendamento: json['avisoAgendamento'] ?? '', 
      principal: json['principal'] ?? false,
    );
  }

  // Método para converter o objeto Agenda para JSON (para enviar ao servidor)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id, // só inclui o id se não for nulo
      'nome': nome,
      'descricao': descricao,
      'duracao': duracao,
      if (avisoAgendamento != null && avisoAgendamento!.isNotEmpty) 'avisoAgendamento': avisoAgendamento,
      'principal': principal,
    };
  }
}