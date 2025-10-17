import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_controller.dart';
import '../models/user_model.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bem-vindo!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              // O onPressed agora chama o novo método de login
              onPressed: auth.isLoading
                  ? null // Desabilita o botão enquanto carrega
                  : () async {
                      // Chama o método de login do seu AuthController,
                      // que por sua vez deve chamar o auth_service.loginComHostedUI()
                      await auth.loginComHostedUI();

                      // A lógica de navegação permanece a mesma
                      // if (auth.isLogado) {
                      //   if (auth.tipoUsuario == UserRole.admin) {
                      //     Navigator.pushReplacementNamed(context, '/admin');
                      //   } else {
                      //     Navigator.pushReplacementNamed(context, '/cliente');
                      //   }
                      // }
                    },
              child: auth.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Entrar ou Cadastrar'),
            ),
            const SizedBox(height: 20),
            // Mostra o erro, se houver
            if (auth.erro != null)
              Text(auth.erro!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
