import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import das fontes

// Importa as páginas e providers
import '../pages/client_user/selecao_agenda_page.dart';
import '../providers/auth_controller.dart';
import '../pages/client_user/editar_dados_cliente.dart';
import '../theme/app_theme.dart'; // Importa NnkColors

// Enum para identificar as páginas
enum AppDrawerPage { agendas, perfil }

class AppDrawerCliente extends StatelessWidget {
  final AppDrawerPage? currentPage;

  const AppDrawerCliente({
    super.key,
    this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context, listen: false);
    final nome = auth.usuario?.primeiroNome ?? 'Aventureiro';
    final email = auth.usuario?.email ?? '';

    final bool isAgendas = currentPage == AppDrawerPage.agendas;
    final bool isPerfil = currentPage == AppDrawerPage.perfil;

    return Drawer(
      backgroundColor: NnkColors.papelAntigo,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // --- CABEÇALHO (Estilo Igual ao Admin) ---
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(
                    color: NnkColors.tintaCastanha, 
                    border: Border(
                      bottom: BorderSide(color: NnkColors.ouroAntigo, width: 2), 
                    ),
                  ),
                  accountName: Text(
                    nome,
                    style: GoogleFonts.cinzel(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: NnkColors.ouroClaro,
                    ),
                  ),
                  accountEmail: Text(
                    email,
                    style: GoogleFonts.alegreya(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: NnkColors.ouroAntigo,
                    child: Text(
                      nome.isNotEmpty ? nome[0].toUpperCase() : 'C',
                      style: GoogleFonts.cinzel(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: NnkColors.tintaCastanha,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // --- ITEM 1: AGENDAS ---
                _buildClientTile(
                  context: context,
                  icon: Icons.calendar_month_outlined,
                  iconColor: NnkColors.azulSuave,
                  title: 'Agendas',
                  isSelected: isAgendas,
                  onTap: () {
                    if (isAgendas) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const SelecaoAgendaPage()),
                      );
                    }
                  },
                ),

                // --- ITEM 2: PERFIL ---
                _buildClientTile(
                  context: context,
                  icon: Icons.person_outline,
                  iconColor: NnkColors.azulSuave,
                  title: 'Editar Meus Dados',
                  isSelected: isPerfil,
                  onTap: () {
                    if (isPerfil) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacementNamed('/editar_dados_cliente');
                    }
                  },
                ),
              ],
            ),
          ),
          
          Divider(color: NnkColors.ouroAntigo.withOpacity(0.5)),
          
          // --- ITEM: SAIR ---
          ListTile(
            leading: const Icon(Icons.logout, color: NnkColors.vermelhoLacre),
            title: Text(
              'Encerrar Sessão', 
              style: GoogleFonts.cinzel(
                color: NnkColors.vermelhoLacre, 
                fontWeight: FontWeight.bold
              )
            ),
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

  Widget _buildClientTile({
    required BuildContext context,
    required IconData icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: NnkColors.ouroAntigo.withOpacity(0.15), // Destaque sutil
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8) // Bordas arredondadas leves
      ),
      leading: Icon(
        icon,
        color: iconColor ?? (isSelected ? NnkColors.tintaCastanha : NnkColors.ouroAntigo),
      ),
      title: Text(
        title,
        style: GoogleFonts.cinzel(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: NnkColors.tintaCastanha,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.alegreya(
                color: NnkColors.tintaCastanha.withOpacity(0.7),
                fontSize: 14,
              ),
            )
          : null,
      onTap: onTap,
    );
  }
  }
