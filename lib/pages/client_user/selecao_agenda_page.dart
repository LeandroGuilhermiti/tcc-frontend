import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/agenda_model.dart';
import '../../providers/agenda_provider.dart';
import 'home_page_cliente.dart';
import '../../widgets/menu_lateral_cliente.dart';
import '../../theme/app_theme.dart';

class SelecaoAgendaPage extends StatefulWidget {
  const SelecaoAgendaPage({super.key});

  @override
  State<SelecaoAgendaPage> createState() => _SelecaoAgendaPageState();
}

class _SelecaoAgendaPageState extends State<SelecaoAgendaPage> {
  final List<Color> _cardColors = [
    NnkColors.azulProfundo,
    NnkColors.verde,
    NnkColors.dourado.withOpacity(0.9),
    NnkColors.marromEscuro.withOpacity(0.8),
    NnkColors.azulProfundo.withOpacity(0.7),
    NnkColors.verde.withOpacity(0.7),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AgendaProvider>(
        context,
        listen: false,
      ).buscarTodasAgendas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolha um Profissional'),
      ),
      drawer: const AppDrawerCliente(currentPage: AppDrawerPage.agendas),
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
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            );
          }

          if (agendaProvider.agendas.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum profissional disponível no momento.',
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
                  Navigator.of(context).pushReplacement( 
                    MaterialPageRoute(
                      builder: (context) => HomePageCliente(
                        agenda: agenda,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
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
          child: Stack(
            children: [
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