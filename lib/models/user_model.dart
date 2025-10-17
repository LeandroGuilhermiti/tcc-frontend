enum UserRole { admin, cliente }

class UserModel {
  final String id;
  final String idToken;
  final String accessToken;
  final String refreshToken;
  final String primeiroNome;
  final String? sobrenome;
  final String cpf;
  final String cep;
  final String telefone;
  final UserRole role;

  // Construtor 
  UserModel({
    required this.id,
    required this.idToken,
    required this.accessToken,
    required this.refreshToken,
    required this.primeiroNome,
    this.sobrenome,
    required this.cpf,
    required this.cep,
    required this.telefone,
    required this.role,
  });

  /// Construtor de fábrica para criar um UserModel a partir de um JSON.
  /// Isso será usado quando você se conectar à sua API real.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Usa '??' para garantir que nunca seja nulo, mesmo se o JSON falhar.
      id: json['id'] ?? '',
      idToken: json['token'] ?? '',
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      primeiroNome: json['nome'] ?? json['primeiroNome'] ?? json['givenName'] ?? '',
      sobrenome: json['sobrenome'] ?? json['familyName'],
      cpf: json['cpf'] ?? '',
      cep: json['cep'] ?? '',
      telefone: json['telefone'] ?? '',

      // Converte o 'tipo' (que virá como 0 ou 1 do backend) para o enum.
      role: (json['tipo'] == 1) ? UserRole.admin : UserRole.cliente,
    );
  }

  /// Método para converter uma instância de UserModel em um Map (JSON).
  /// Útil se você precisar enviar o objeto de usuário para a sua API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idToken': idToken,
      'acessToken': accessToken,
      'refreshToken': refreshToken,
      'nome': primeiroNome + (sobrenome != null ? ' $sobrenome' : ''),
      'cpf': cpf,
      'cep': cep,
      'telefone': telefone,
      // Converte o enum de volta para uma string para ser salva no banco.
      'role': role == UserRole.admin ? 1 : 0, // 1 para admin, 0 para cliente
    };
  }
}