import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importa as páginas para onde o menu vai navegar
import '../pages/client_user/selecao_agenda_page.dart';
import '../providers/auth_controller.dart';
import '../pages/client_user/editar_dados_cliente.dart';

// enum para identificar as páginas
// Isto ajuda o Drawer a saber qual item deve destacar
enum AppDrawerPage { agendas, perfil }

class AppDrawerCliente extends StatelessWidget {
  // variável para saber qual é a página atual
  final AppDrawerPage? currentPage;

  const AppDrawerCliente({
    super.key,
    this.currentPage, // Tornamos opcional
  });

  // --- NOVO (Passo 3) ---
  // O código que estava em `_buildDrawer` foi movido para aqui,
  // dentro do método `build` deste widget.
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context, listen: false);
    final nome = auth.usuario?.primeiroNome ?? 'Cliente';
    final email = auth.usuario?.email ?? '';

    // --- NOVO (Passo 4) ---
    // Verificamos qual é a página atual para destacar o item
    final bool isAgendas = currentPage == AppDrawerPage.agendas;
    final bool isPerfil = currentPage == AppDrawerPage.perfil;

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  accountEmail: Text(email),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      nome.isNotEmpty ? nome[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                ),

                // --- Opção 1: Agendas (com lógica de seleção) ---
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('Agendas'),
                  subtitle: const Text('Ver todos profissionais'),
                  selected: isAgendas, // Destaca o item se for a página atual
                  onTap: isAgendas
                      // Se já estiver na página, apenas fecha o menu
                      ? () => Navigator.pop(context)
                      // Se estiver noutra página, navega
                      : () {
                          Navigator.pop(context); // Fecha o menu
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const SelecaoAgendaPage(),
                            ),
                          );
                        },
                ),

                // --- Opção 2: Editar dados (com lógica de seleção) ---
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Editar dados'),
                  subtitle: const Text('Atualizar meu perfil'),
                  selected: isPerfil,
                  onTap: isPerfil
                      ? () => Navigator.pop(context) // Já está na página
                      : () {
                          Navigator.pop(context);
                          Navigator.of(context).pushReplacementNamed('/editar_dados_cliente');
                        },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/login');
              auth.logout();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
