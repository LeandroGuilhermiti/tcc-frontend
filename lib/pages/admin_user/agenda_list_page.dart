import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/agenda_model.dart'; // Importa seu modelo
import '../../providers/agenda_provider.dart'; // Importa seu provider
import '../../providers/auth_controller.dart';
import 'agenda_create_page.dart';
import 'agenda_edit_page.dart';

class AgendaListPage extends StatefulWidget {
  const AgendaListPage({super.key});

  @override
  State<AgendaListPage> createState() => _AgendaListPageState();
}

class _AgendaListPageState extends State<AgendaListPage> {
  // Lista de cores para os cartões, inspirada na sua imagem
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
    // Chama o provider para buscar todas as agendas
    await Provider.of<AgendaProvider>(
      context,
      listen: false,
    ).buscarTodasAgendas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. AppBar
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
      
      // 2. Body
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

          // --- GRIDVIEW ---
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              
              // --- ALTERAÇÃO PRINCIPAL AQUI ---
              // Mudar de 3 para 4 colunas para ficarem menores
              crossAxisCount: 4, 
              // --- FIM DA ALTERAÇÃO ---
              
              crossAxisSpacing: 16, // Espaçamento horizontal
              mainAxisSpacing: 16, // Espaçamento vertical
              
              // Mantém a proporção quadrada (1.0)
              // Se preferir que fiquem mais "chatos", aumente este valor (ex: 1.3)
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AgendaEditPage(agenda: agenda),
                    ),
                  );
                },
              );
            },
          );
          // --- FIM DA MUDANÇA ---
        },
      ),
      
      // 3. FloatingActionButton
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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

/// --- WIDGET CUSTOMIZADO (Sem alterações) ---
/// Este é o widget que desenha o cartão colorido.
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
          child: Stack(
            children: [
              // Conteúdo (Ícone e Texto)
              Column(
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
              // Chip "Principal" (se for o caso)
              if (agenda.principal)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Chip(
                    label: const Text('Principal'),
                    labelStyle: const TextStyle(fontSize: 10),
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white.withOpacity(0.8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
