import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import das fontes
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
  // Cores mantidas
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
      Provider.of<AgendaProvider>(
        context,
        listen: false,
      ).buscarTodasAgendas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NnkColors.papelAntigo, // Fundo bege
      appBar: AppBar(
        backgroundColor: NnkColors.papelAntigo,
        iconTheme: const IconThemeData(color: NnkColors.tintaCastanha),
        title: Text(
          'Escolha um Profissional',
          style: GoogleFonts.cinzel(
            color: NnkColors.tintaCastanha,
            fontWeight: FontWeight.bold,
          )
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: NnkColors.ouroAntigo.withOpacity(0.5),
            height: 1.0,
          ),
        ),
      ),
      drawer: const AppDrawerCliente(currentPage: AppDrawerPage.agendas),
      body: Consumer<AgendaProvider>(
        builder: (context, agendaProvider, child) {
          if (agendaProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: NnkColors.ouroAntigo));
          }

          if (agendaProvider.erro != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Ocorreu um erro ao buscar as agendas:\n${agendaProvider.erro}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alegreya(color: NnkColors.vermelhoLacre, fontSize: 16),
                ),
              ),
            );
          }

          if (agendaProvider.agendas.isEmpty) {
            return Center(
              child: Text(
                'Nenhum profissional disponível no momento.',
                textAlign: TextAlign.center,
                style: GoogleFonts.alegreya(fontSize: 18, color: NnkColors.tintaCastanha),
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
                cor: cor, // Mantém a cor colorida
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Pequena borda translúcida para acabamento
        side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.3),
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
                    style: GoogleFonts.cinzel( // Fonte temática branca
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [const Shadow(color: Colors.black26, offset: Offset(1,1), blurRadius: 2)]
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    agenda.descricao,
                    style: GoogleFonts.alegreya(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}