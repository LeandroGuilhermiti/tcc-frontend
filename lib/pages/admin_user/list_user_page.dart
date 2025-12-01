import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import necessário para as fontes
import '../../models/user_model.dart'; 
import '../../providers/user_provider.dart';
import '../../widgets/menu_letral_admin.dart'; 
import 'edit_user_page.dart'; 
import '../../theme/app_theme.dart'; // Import do tema NnkColors

class PacientesListPage extends StatefulWidget {
  const PacientesListPage({super.key});

  @override
  State<PacientesListPage> createState() => _PacientesListPageState();
}

class _PacientesListPageState extends State<PacientesListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Busca os usuários assim que a página carregar
      Provider.of<UsuarioProvider>(context, listen: false).buscarUsuarios();
    });

    // Atualiza a lista filtrada sempre que o texto de pesquisa mudar
    _searchController.addListener(() {
      setState(() {
        _filtro = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NnkColors.papelAntigo, // Fundo RPG
      appBar: AppBar(
        backgroundColor: NnkColors.papelAntigo,
        iconTheme: const IconThemeData(color: NnkColors.tintaCastanha),
        title: Text(
          'Consultar Pacientes',
          style: GoogleFonts.cinzel(
            color: NnkColors.tintaCastanha,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        // Linha dourada abaixo do AppBar (igual ao agenda_edit)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: NnkColors.ouroAntigo.withOpacity(0.5),
            height: 1.0,
          ),
        ),
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // 1. Barra de Pesquisa Estilizada
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.alegreya(
                fontSize: 18, 
                color: NnkColors.tintaCastanha
              ),
              decoration: InputDecoration(
                labelText: 'Pesquisar paciente...',
                labelStyle: GoogleFonts.alegreya(color: NnkColors.tintaCastanha.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: NnkColors.ouroAntigo),
                filled: true,
                fillColor: Colors.white.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: NnkColors.ouroAntigo),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: NnkColors.ouroAntigo),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: NnkColors.tintaCastanha, width: 2),
                ),
                suffixIcon: _filtro.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: NnkColors.vermelhoLacre),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // 2. Lista de Pacientes
          Expanded(
            child: _buildListaPacientes(),
          ),
        ],
      ),
    );
  }

  // Widget que constrói a lista
  Widget _buildListaPacientes() {
    return Consumer<UsuarioProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: NnkColors.ouroAntigo)
          );
        }

        if (userProvider.error != null) {
          return Center(
            child: Text(
              'Erro: ${userProvider.error}',
              style: GoogleFonts.alegreya(color: NnkColors.vermelhoLacre),
            )
          );
        }

        // --- LÓGICA DE FILTRO ---
        final List<UserModel> pacientes = userProvider.usuarios;
        
        final List<UserModel> pacientesFiltrados = pacientes.where((paciente) {
          final nomeCompleto = [paciente.primeiroNome, paciente.sobrenome]
              .where((n) => n != null && n.isNotEmpty)
              .join(' ')
              .toLowerCase();
          
          final email = paciente.email?.toLowerCase() ?? '';

          return nomeCompleto.contains(_filtro) || email.contains(_filtro);
        }).toList();

        if (pacientesFiltrados.isEmpty) {
          return Center(
            child: Text(
              'Nenhum paciente encontrado.',
              style: GoogleFonts.cinzel(
                color: NnkColors.tintaCastanha,
                fontSize: 18,
                fontWeight: FontWeight.bold
              ),
            ),
          );
        }
        // --- FIM DA LÓGICA DE FILTRO ---

        // Constrói a lista
        return ListView.builder(
          itemCount: pacientesFiltrados.length,
          itemBuilder: (context, index) {
            final paciente = pacientesFiltrados[index];

            final nomeCompleto = [paciente.primeiroNome, paciente.sobrenome]
                .where((n) => n != null && n.isNotEmpty)
                .join(' ');

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: Colors.white,
              elevation: 2,
              shadowColor: NnkColors.tintaCastanha.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
                side: BorderSide(color: NnkColors.ouroAntigo.withOpacity(0.4), width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                // Remove a linha divisória padrão do ExpansionTile
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  backgroundColor: NnkColors.papelAntigo.withOpacity(0.3),
                  collapsedIconColor: NnkColors.ouroAntigo,
                  iconColor: NnkColors.tintaCastanha,
                  leading: CircleAvatar(
                    backgroundColor: NnkColors.ouroClaro,
                    child: const Icon(Icons.person_outline, color: NnkColors.tintaCastanha),
                  ),
                  
                  title: Text(
                    nomeCompleto.isEmpty ? 'Nome não cadastrado' : nomeCompleto,
                    style: GoogleFonts.cinzel(
                      fontWeight: FontWeight.bold,
                      color: NnkColors.tintaCastanha,
                      fontSize: 16,
                    ),
                  ),
                  
                  subtitle: Text(
                    paciente.email ?? 'Email não cadastrado',
                    style: GoogleFonts.alegreya(
                      color: NnkColors.tintaCastanha.withOpacity(0.7)
                    ),
                  ),
                  
                  // O conteúdo que aparece ao expandir
                  children: [
                    _buildDetalhesPaciente(paciente, nomeCompleto),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Widget que constrói os detalhes (a caixa expandida)
  Widget _buildDetalhesPaciente(UserModel paciente, String nomeCompletoSeguro) {
    return Container(
      // Fundo levemente dourado/creme em vez de cinza
      color: NnkColors.ouroClaro.withOpacity(0.3),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Linha do Nome
          _buildInfoRow(
            'Nome Completo:',
            nomeCompletoSeguro.isEmpty
                ? 'Não informado'
                : nomeCompletoSeguro,
          ),
          const SizedBox(height: 8),

          // Linha do Email
          _buildInfoRow(
            'Email:',
            paciente.email ?? 'Não informado',
          ),
          const SizedBox(height: 8),

          // Linha do Telefone
          _buildInfoRow(
            'Telefone:',
            paciente.telefone ?? 'Não informado',
          ),
          const SizedBox(height: 8),

          // Linha do CPF
          _buildInfoRow(
            'CPF:',
            paciente.cpf ?? 'Não informado',
          ),
          const SizedBox(height: 8),

          // Linha do CEP
          _buildInfoRow(
            'CEP:',
            paciente.cep ?? 'Não informado',
          ),
          const SizedBox(height: 20),

          // Botão de Editar
          ElevatedButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar Dados'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey, // Cor temática
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PacienteEditPage(paciente: paciente),
                ),
              );

              if (context.mounted) {
                Provider.of<UsuarioProvider>(context, listen: false).buscarUsuarios();
              }
            },
          ),
          // Botão de Editar Estilizado
          SizedBox(
            height: 45,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: Text(
                'Editar Dados',
                style: GoogleFonts.cinzel(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: NnkColors.tintaCastanha, // Fundo escuro
                foregroundColor: NnkColors.ouroAntigo,    // Texto dourado
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: const BorderSide(color: NnkColors.ouroAntigo),
                ),
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PacienteEditPage(paciente: paciente),
                  ),
                );
                if (context.mounted) {
                  Provider.of<UsuarioProvider>(context, listen: false).buscarUsuarios();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para criar as linhas "Título: Valor"
  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.alegreya(
            fontWeight: FontWeight.bold,
            color: NnkColors.tintaCastanha,
            fontSize: 16
          ),
        ),
        Text(
          value,
          style: GoogleFonts.alegreya(
            color: NnkColors.tintaCastanha.withOpacity(0.8),
            fontSize: 16
          ),
        ),
      ],
    );
  }
}