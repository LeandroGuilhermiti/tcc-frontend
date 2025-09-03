import '../models/user_model.dart';

class AuthService {
  // Variável para simular um usuário logado
  UserModel? _mockUser;

  Future<UserModel?> login(String email, String senha) async {
    // Simula um delay da rede
    await Future.delayed(const Duration(seconds: 1)); 

    if (email == 'admin' && senha == '1234') {
      _mockUser = UserModel(
        id: 'mock-admin-id-123',
        nome: 'Dra. Ana (Mock)',
        cpf: '00000000000',
        cep: '00000000',
        telefone: '11999999999',
        role: UserRole.admin,
        token: 'mock-jwt-token-para-admin',
      );
      return _mockUser;
    } else if (email == 'cliente' && senha == '1234') {
      _mockUser = UserModel(
        id: 'mock-client-id-456',
        nome: 'João Silva (Mock)',
        cpf: '11111111111',
        cep: '11111111',
        telefone: '11888888888',
        role: UserRole.cliente,
        token: 'mock-jwt-token-para-cliente',
      );
      return _mockUser;
    } else {
      _mockUser = null;
      return null;
    }
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockUser = null;
  }

  // Simula a verificação de um usuário já logado ao abrir o app
  UserModel? get currentUser => _mockUser;
}