import '../models/user_model.dart';

class AuthService {
  Future<UserModel?> login(String email, String senha) async {
    await Future.delayed(Duration(seconds: 1)); // Simula API

    if (email == 'admin' && senha == '1234') {
      return UserModel(
        nome: 'Dra. Ana',
        email: email,
        role: UserRole.admin,
        cpf: '00000000000',
        cep: '00000000',
        telefone: '11999999999',
      );
    } else if (email == 'client' && senha == '1234') {
      return UserModel(
        nome: 'João',
        email: email,
        role: UserRole.cliente,
        cpf: '11111111111',
        cep: '11111111',
        telefone: '11888888888',
      );
    } else {
      return null;
    }
  }
}
