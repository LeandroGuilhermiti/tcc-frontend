import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import das fontes
import 'package:tcc_frontend/providers/auth_controller.dart'; 
import '../../theme/app_theme.dart'; // Importa NnkColors

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context, listen: false);

    return Drawer(
      backgroundColor: NnkColors.papelAntigo,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // --- CABEÇALHO ADMIN ---
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(
                    color: NnkColors.tintaCastanha,
                    border: Border(
                      bottom: BorderSide(color: NnkColors.ouroAntigo, width: 2),
                    ),
                  ),
                  accountName: Text(
                    "Administrador", 
                    style: GoogleFonts.cinzel(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: NnkColors.ouroClaro,
                    ),
                  ),
                  accountEmail: Text(
                    auth.usuario?.email ?? "admin@sistema.com",
                    style: GoogleFonts.alegreya(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: NnkColors.ouroAntigo,
                    child: Text(
                      (auth.usuario?.primeiroNome ?? 'A')[0].toUpperCase(),
                      style: GoogleFonts.cinzel(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: NnkColors.tintaCastanha,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                _buildAdminTile(
                  context, 
                  icon: Icons.apps, 
                  title: 'Agendas',
                  route: '/agendas',
                ),

                _buildAdminTile(
                  context, 
                  icon: Icons.add_circle_outline, 
                  title: 'Criar Nova Agenda',
                  route: '/create',
                ),

                _buildAdminTile(
                  context, 
                  icon: Icons.block, 
                  title: 'Criar Bloqueios',
                  route: '/bloqueios/create',
                ),

                Divider(color: NnkColors.ouroAntigo.withOpacity(0.5)),

                _buildAdminTile(
                  context, 
                  icon: Icons.person_add_alt_1, 
                  title: 'Cadastrar Usuários',
                  route: '/cadastro',
                ),
                _buildAdminTile(
                  context, 
                  icon: Icons.people_outline, 
                  title: 'Consultar Pacientes',
                  route: '/pacientes',
                ),
              ],
            ),
          ),

          Divider(color: NnkColors.ouroAntigo.withOpacity(0.5)), 
          
          ListTile(
            leading: const Icon(Icons.logout, color: NnkColors.vermelhoLacre),
            title: Text(
              'Encerrar Sessão', 
              style: GoogleFonts.cinzel(
                color: NnkColors.vermelhoLacre,
                fontWeight: FontWeight.bold,
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

  Widget _buildAdminTile(BuildContext context, {required IconData icon, required String title, required String route}) {
    return ListTile(
      leading: Icon(icon, color: NnkColors.azulSuave),
      title: Text(
        title,
        style: GoogleFonts.alegreya(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: NnkColors.tintaCastanha,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route); 
      },
    );
  }
}