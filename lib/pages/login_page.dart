import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_controller.dart';
import '../models/user_model.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  // Limpa os controladores quando a página é descartada
  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 320,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Login', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 20),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: senhaController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha'),
                    ),
                    const SizedBox(height: 20),
                    if (auth.erro != null)
                      Text(auth.erro!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await auth.login(
                          emailController.text.trim(),
                          senhaController.text.trim(),
                        );
                        if (auth.isLogado) {
                          if (auth.tipoUsuario == UserRole.admin) {
                            Navigator.pushReplacementNamed(context, '/admin');
                          } else {
                            Navigator.pushReplacementNamed(context, '/cliente');
                          }
                        }
                      },
                      child: const Text('Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
