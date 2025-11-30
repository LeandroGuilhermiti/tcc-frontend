import 'package:flutter/material.dart';
import '../../models/agenda_model.dart';

import '../../providers/agenda_provider.dart';
import 'package:provider/provider.dart';

import 'agenda_create_page.dart';
import 'agenda_edit_page.dart';
import 'home_page_admin.dart'; 
import 'list_user_page.dart';

import '../../widgets/menu_letral_admin.dart';

class AgendaListPage extends StatefulWidget {
  const AgendaListPage({super.key});

  @override
  State<AgendaListPage> createState() => _AgendaListPageState();
}

class _AgendaListPageState extends State<AgendaListPage> {
  final List<Color> _cardColors = [
    Colors.pink.shade300,
    Colors.purple.shade300,
    Colors.orange.shade300,
    Colors.teal.shade300,
    Colors.blue.shade300,
    Colors.red.shade300,
    Colors.indigo.shade300,
    Colors.green.shade300,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAgendas();
    });
  }

  Future<void> _fetchAgendas() async {
    await Provider.of<AgendaProvider>(
      context,
      listen: false,
    ).buscarTodasAgendas();
  }

  Future<void> _confirmarExclusao(BuildContext context, Agenda agenda) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Agenda'),
        content: Text('Tem a certeza que deseja excluir a agenda "${agenda.nome}"?\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await Provider.of<AgendaProvider>(context, listen: false)
            .excluirAgenda(agenda.id!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agenda excluída com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _mostrarOpcoes(BuildContext context, Agenda agenda) async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  agenda.nome,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),

              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Ver Calendário'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => HomePageAdmin(agenda: agenda),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar Agenda'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AgendaEditPage(agenda: agenda),
                    ),
                  );
                  _fetchAgendas();
                },
              ),

              ListTile(
                leading: const Icon(Icons.block, color: Colors.orange),
                title: const Text('Editar Bloqueios'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed(
                    '/bloqueios/list',
                    arguments: agenda, 
                  );
                },
              ),
              
              const Divider(),

              // --- NOVA OPÇÃO DE EXCLUIR ---
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Excluir Agenda',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx); // Fecha o menu primeiro
                  // Chama a confirmação após fechar o menu
                  Future.delayed(const Duration(milliseconds: 200), () {
                     if (context.mounted) _confirmarExclusao(context, agenda);
                  });
                },
              ),

              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancelar'),
                onTap: () {
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todas Agendas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAgendas,
            tooltip: 'Recarregar Agendas',
          ),
        ],
      ),

      drawer: const AdminDrawer(),

      body: Consumer<AgendaProvider>(
        builder: (context, agendaProvider, child) {
          if (agendaProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (agendaProvider.erro != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Ocorreu um erro ao buscar as agendas:\n${agendaProvider.erro}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
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

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: agendaProvider.agendas.length,
            itemBuilder: (context, index) {
              final agenda = agendaProvider.agendas[index];
              final cor = _cardColors[index % _cardColors.length];

              return _AgendaCard(
                agenda: agenda,
                cor: cor,
                onTap: () {
                  if (agenda.id != null) {
                    _mostrarOpcoes(context, agenda);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro: Agenda sem ID.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AgendaCreatePage()),
          );
          _fetchAgendas();
        },
        child: const Icon(Icons.add),
        tooltip: 'Criar Nova Agenda',
      ),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  final Agenda agenda;
  final Color cor;
  final VoidCallback onTap;

  const _AgendaCard({
    required this.agenda,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: Colors.white.withOpacity(0.8),
                size: 24,
              ),
              const Spacer(),
              Text(
                agenda.nome,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                agenda.descricao,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}