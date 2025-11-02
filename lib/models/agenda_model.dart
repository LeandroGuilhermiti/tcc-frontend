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
    // --- Lógica robusta para 'duracao' ---
    int duracaoConvertida = 0; // Padrão é 0
    final dynamic duracaoJson = json['duracao'];

    if (duracaoJson is int) {
      duracaoConvertida = duracaoJson; // Se já for int, usa direto
    } else if (duracaoJson is String) {
      duracaoConvertida =
          int.tryParse(duracaoJson) ?? 0; // Se for String, tenta converter
    }
    // --- Fim da lógica 'duracao' ---

    return Agenda(
      // --- CORREÇÃO PRINCIPAL AQUI ---
      // O JSON envia 'id' como int (ex: 1), mas o modelo espera String?
      // Nós convertemos manualmente para String.
      id: json['id']?.toString(),

      // --- FIM DA CORREÇÃO ---
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      duracao: duracaoConvertida, // <-- Usa o valor convertido
      // Lógica defensiva para avisoAgendamento (força a ser String)
      avisoAgendamento: json['avisoAgendamento']?.toString() ?? '',

      // O 'principal' não está a vir do teu JSON,
      // então '?? false' garante que não falha.
      principal: json['principal'] ?? false,
    );
  }

  // Método para converter o objeto Agenda para JSON (para enviar ao servidor)
  Map<String, dynamic> toJson() {
    return {
      // Ao enviar, o ID (se existir) já é uma String, então está correto
      if (id != null) 'id': id,
      'nome': nome,
      'descricao': descricao,
      'duracao': duracao,
      if (avisoAgendamento != null && avisoAgendamento!.isNotEmpty)
        'avisoAgendamento': avisoAgendamento,
      'principal': principal,
    };
  }
}
