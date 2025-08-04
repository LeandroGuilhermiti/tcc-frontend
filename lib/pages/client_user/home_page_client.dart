import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_controller.dart';

class HomePageClient extends StatelessWidget {
  const HomePageClient({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Página Inicial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              // Retorna para login
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Bem-vindo ao sistema de agendamento!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
