enum UserRole { admin, cliente }

class UserModel {
  final String nome;
  final String email;
  final String cpf;
  final String cep;
  final String telefone;
  final UserRole role;

  UserModel({
    required this.nome,
    required this.email,
    required this.cpf,
    required this.cep,
    required this.telefone,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      nome: json['nome'],
      email: json['email'],
      cpf: json['cpf'],
      cep: json['cep'],
      telefone: json['telefone'],
      role: json['role'] == 'admin' ? UserRole.admin : UserRole.cliente,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'cep': cep,
      'telefone': telefone,
      'role': role.name, // 'admin' ou 'cliente'
    };
  }
}
