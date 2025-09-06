import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/agenda_provider.dart';
import '../../providers/auth_controller.dart';
import 'agenda_create_page.dart';
import 'agenda_edit_page.dart';

class AgendaListPage extends StatefulWidget {
  const AgendaListPage({super.key});

  @override
  State<AgendaListPage> createState() => _AgendaListPageState();
}

class _AgendaListPageState extends State<AgendaListPage> {
  @override
  void initState() {
    super.initState();
    // Garante que o provider é chamado depois do build inicial.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAgendas();
    });
  }

  Future<void> _fetchAgendas() async {
    // Apanha o ID do utilizador logado para buscar as suas agendas.
    final userId = Provider.of<AuthController>(
      context,
      listen: false,
    ).usuario?.id;
    if (userId != null) {
      // Chama o provider para buscar os dados.
      await Provider.of<AgendaProvider>(
        context,
        listen: false,
      ).buscarAgendasDoProfissional(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Agendas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAgendas,
            tooltip: 'Recarregar Agendas',
          ),
        ],
      ),
      body: Consumer<AgendaProvider>(
        builder: (context, agendaProvider, child) {
          if (agendaProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (agendaProvider.erro != null) {
            return Center(
              child: Text('Ocorreu um erro: ${agendaProvider.erro}'),
            );
          }

          if (agendaProvider.agendas.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma agenda encontrada.\nClique no botão + para criar uma nova.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: agendaProvider.agendas.length,
            itemBuilder: (context, index) {
              final agenda = agendaProvider.agendas[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    agenda.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(agenda.descricao),
                  trailing: agenda.principal
                      ? const Chip(
                          label: Text('Principal'),
                          backgroundColor: Colors.greenAccent,
                        )
                      : null,
                  onTap: () {
                    // Navega para a página de edição, passando a agenda selecionada.
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AgendaEditPage(agenda: agenda),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navega para a página de criação de agenda.
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AgendaCreatePage()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Criar Nova Agenda',
      ),
    );
  }
}
