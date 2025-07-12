import '../models/user_model.dart';

class AuthService {
  Future<UserModel?> login(String email, String senha) async {
    await Future.delayed(Duration(seconds: 1)); // Simula API

    if (email == 'admin' && senha == '1234') {
      return UserModel(
        nome: 'Dra. Ana',
        email: email,
        role: UserRole.admin,
      );
    } else if (email == 'client' && senha == '1234') {
      return UserModel(
        nome: 'João',
        email: email,
        role: UserRole.cliente,
      );
    } else {
      return null;
    }
  }
}
