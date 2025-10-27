enum UserRole { admin, cliente }

class UserModel {
  final String id;
  final String? idToken;       
  final String? accessToken;   
  final String? refreshToken;  
  final String primeiroNome;
  final String? sobrenome;
  final String? email;         
  final String? cpf;           
  final String? cep;          
  final String? telefone;      
  final UserRole role;

  UserModel({
    required this.id,
    this.idToken,
    this.accessToken,
    this.refreshToken,
    required this.primeiroNome,
    this.sobrenome,
    this.email, 
    this.cpf,
    this.cep,
    this.telefone,
    required this.role,
  });

  /// Construtor 
  /// lida perfeitamente com dados completos (do login)
  /// ou dados parciais (da lista de usuários do Cognito).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Campos que sempre existem (do Cognito ou do seu banco)
      id: json['id'] ?? json['Username'] ?? '', // 'Username' é o ID na lista do Cognito
      
      // Procura 'givenName' (do Cognito), 'primeiroNome', e 'nome'.
      primeiroNome: json['givenName'] ?? json['primeiroNome'] ?? json['nome'] ?? '',
      
      sobrenome: json['familyName'] ?? json['sobrenome'],
      email: json['email'], 

      // Converte o 'tipo' (que virá como 0 ou 1 do backend) para o enum.
      // Usa 'custom:role' se vier do Cognito, ou 'tipo' se vier do seu banco.
      role: (json['tipo'] == 1 || json['custom:role'] == '1') 
            ? UserRole.admin 
            : UserRole.cliente,

      // Campos que SÓ existem no login ou no banco (serão nulos na lista)
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
      'acessToken': accessToken,
      'refreshToken': refreshToken,
      'givenName': primeiroNome, 
      'familyName': sobrenome, 
      'email': email,
      'cpf': cpf,
      'cep': cep,
      'telefone': telefone,
      'tipo': role == UserRole.admin ? 1 : 0, 
    };
  }
}
