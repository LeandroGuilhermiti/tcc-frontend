enum UserRole { admin, cliente }

class UserModel {
  final String nome;
  final String email;
  final UserRole role;

  UserModel({
    required this.nome,
    required this.email,
    required this.role,
  });

  // Caso deseje converter de JSON:
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      nome: json['nome'],
      email: json['email'],
      role: json['role'] == 'admin' ? UserRole.admin : UserRole.cliente,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'email': email,
      'role': role.name, // converte para 'admin' ou 'cliente'
    };
  }
}
