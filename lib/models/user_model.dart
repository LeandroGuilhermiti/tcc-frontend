enum UserRole { admin, cliente }

class UserModel {
  final String id;
  final String? idToken;
  final String? accessToken;
  final String? refreshToken;
  
  final String? primeiroNome;
  final String? sobrenome;
  final String? email;
  final String? cpf;
  final String? cep;
  final String? telefone;
  final UserRole role;

  final bool cadastroPendente; 

  UserModel({
    required this.id,
    this.idToken,
    this.accessToken,
    this.refreshToken,
    this.primeiroNome,
    this.sobrenome,
    this.email,
    this.cpf,
    this.cep,
    this.telefone,
    required this.role,
    this.cadastroPendente = false,
  });

  /// Construtor
  /// Lida com dados completos (login) ou parciais (lista de usuários).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Campos que sempre existem
      id: json['id'] ?? json['Username'] ?? '',
      
      // --- LÓGICA DE TRADUÇÃO DE NOME ---
      // Lê 'givenName' (do Cognito) ou 'primeiroNome' (do teu backend).
      // armazena 'null' corretamente se ambos forem nulos.
      primeiroNome: json['givenName'] ?? json['primeiroNome'] ?? json['nome'],
      sobrenome: json['familyName'] ?? json['sobrenome'],
      
      email: json['email'],

      // Se a flag não vier no JSON, assume false (usuário comum)
      cadastroPendente: json['cadastroPendente'] ?? false,

      // --- LÓGICA DE ROLE SIMPLIFICADA ---
      // Se não for '1' (admin), assume-se que é 'cliente'.
      role: (json['tipo'] == 1 || json['custom:role'] == '1')
          ? UserRole.admin
          : UserRole.cliente,

      // Campos que podem ser nulos
      idToken: json['idToken'],
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      cpf: json['cpf'],
      cep: json['cep'],
      telefone: json['telefone'],
    );
  }

  /// Método para converter uma instância de UserModel em um Map (JSON).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idToken': idToken,
      'accessToken': accessToken, 
      'refreshToken': refreshToken,
      'givenName': primeiroNome, 
      'familyName': sobrenome,
      'email': email,
      'cpf': cpf,
      'cep': cep,
      'telefone': telefone,
      'tipo': role == UserRole.admin ? 1 : 0,
      'cadastroPendente': cadastroPendente,
    };
  }
}