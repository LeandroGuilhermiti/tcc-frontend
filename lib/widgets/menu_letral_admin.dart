import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tcc_frontend/providers/auth_controller.dart'; // para o Logout

/*
 * Este é o seu Widget de Menu Lateral Reutilizável.
 * * Ele pode ser chamado em qualquer página de admin 
 * (dentro do 'Scaffold') usando:
 * * drawer: AdminDrawer(),
 * */
class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos o Provider para aceder ao AuthController
    final auth = Provider.of<AuthController>(context, listen: false);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              "Administrador", // mudar isto ou buscar o nome do user
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              auth.usuario?.email ?? "admin@email.com",// Mostra o email do user
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade800, 
            ),
          ),

          ListTile(
            leading: const Icon(Icons.apps), // Ícone de "grelha"
            title: const Text('Minhas Agendas'),
            onTap: () {
              Navigator.pop(context);
              //'pushReplacementNamed' para não empilhar páginas
              Navigator.pushReplacementNamed(context, '/agendas');
            },
          ),

          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Criar nova agenda'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/create');
            },
          ),

          const Divider(), // Uma linha para separar
          ListTile(
            leading: const Icon(Icons.person_add_alt_1),
            title: const Text('Cadastrar usuários'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/cadastro');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Consultar pacientes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/pacientes');
            },
          ),

          const Divider(),

          // Botão de Sair (Logout) ---
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () async {
              // Fecha o menu
              Navigator.pop(context);
              // Chama a função de logout do seu AuthController
              await auth.logout();
              // Envia o utilizador de volta para a página de login
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
