import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart'; 
import '../../providers/user_provider.dart';
import '../../widgets/menu_letral_admin.dart'; 
import 'edit_user_page.dart'; 

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
      appBar: AppBar(
        title: const Text('Consultar Pacientes'),
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // 1. Barra de Pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Pesquisar paciente...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                suffixIcon: _filtro.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
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
          return const Center(child: CircularProgressIndicator());
        }

        if (userProvider.error != null) {
          return Center(child: Text('Erro: ${userProvider.error}'));
        }

        // --- LÓGICA DE FILTRO ---
        final List<UserModel> pacientes = userProvider.usuarios;
            // .where((user) => user.role == UserRole.cliente)
            // .toList();

        final List<UserModel> pacientesFiltrados = pacientes.where((paciente) {
          // Constrói o nome completo seguro para a pesquisa
          final nomeCompleto = [paciente.primeiroNome, paciente.sobrenome]
              .where((n) => n != null && n.isNotEmpty)
              .join(' ')
              .toLowerCase();
          
          final email = paciente.email?.toLowerCase() ?? '';

          return nomeCompleto.contains(_filtro) || email.contains(_filtro);
        }).toList();

        if (pacientesFiltrados.isEmpty) {
          return const Center(
            child: Text('Nenhum paciente encontrado.'),
          );
        }
        // --- FIM DA LÓGICA DE FILTRO ---

        // Constrói a lista
        return ListView.builder(
          itemCount: pacientesFiltrados.length,
          itemBuilder: (context, index) {
            final paciente = pacientesFiltrados[index];

            // --- ESTA É A CORREÇÃO ---
            // 1. Junta o primeiro e o último nome numa lista.
            final nomeCompleto = [paciente.primeiroNome, paciente.sobrenome]
                // 2. Remove todos os 'null' ou strings vazias.
                .where((n) => n != null && n.isNotEmpty)
                // 3. Junta o que sobrar com um espaço.
                .join(' ');
            // --- FIM DA CORREÇÃO ---

            return Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: const Icon(Icons.person_outline, size: 30),
                
                // 4. Se 'nomeCompleto' estiver vazio, mostra o texto correto.
                //    Isto substitui o teu código que mostrava "null".
                title: Text(
                  nomeCompleto.isEmpty ? 'Nome não cadastrado' : nomeCompleto,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                
                subtitle: Text(paciente.email ?? 'Email não cadastrado'),
                
                // O conteúdo que aparece ao expandir
                children: [
                  _buildDetalhesPaciente(paciente, nomeCompleto),
                ],
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
      color: Colors.black.withOpacity(0.03), // Fundo levemente cinza
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
          const SizedBox(height: 16),

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
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value),
      ],
    );
  }
}