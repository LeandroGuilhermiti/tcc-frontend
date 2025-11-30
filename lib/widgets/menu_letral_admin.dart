import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tcc_frontend/providers/auth_controller.dart'; 

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context, listen: false);

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: const Text(
                    "Administrador", 
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  accountEmail: Text(
                    auth.usuario?.email ?? "admin@email.com",
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor, 
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      (auth.usuario?.primeiroNome ?? 'A')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.apps),
                  title: const Text('Agendas'),
                  onTap: () {
                    Navigator.pop(context);
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

                // --- NOVO ITEM: CRIAR BLOQUEIOS ---
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Criar bloqueios'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/bloqueios/create');
                  },
                ),
                // ----------------------------------

                const Divider(),

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
              ],
            ),
          ),

          const Divider(), 
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sair', 
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold
              )
            ),
            onTap: () {
              auth.logout();
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}