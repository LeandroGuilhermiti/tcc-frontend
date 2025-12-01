import 'package:flutter/material.dart';
import '../../models/agenda_model.dart';
import '../../providers/agenda_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import das fontes

import 'agenda_create_page.dart';
import 'agenda_edit_page.dart';
import 'home_page_admin.dart'; 
import 'list_user_page.dart';

import '../../widgets/menu_letral_admin.dart';
import '../../theme/app_theme.dart'; // Importa NnkColors

class AgendaListPage extends StatefulWidget {
  const AgendaListPage({super.key});

  @override
  State<AgendaListPage> createState() => _AgendaListPageState();
}

class _AgendaListPageState extends State<AgendaListPage> {
  // Mantemos as cores vivas como pedido
  final List<Color> _cardColors = NnkColors.coresVivas;

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
        backgroundColor: NnkColors.papelAntigo, // Fundo temático
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: NnkColors.ouroAntigo, width: 2),
        ),
        title: Text(
          'Excluir Agenda',
          style: GoogleFonts.cinzel(
            color: NnkColors.tintaCastanha, 
            fontWeight: FontWeight.bold
          ),
        ),
        content: Text(
          'Tem a certeza que deseja excluir a agenda "${agenda.nome}"?\nEsta ação não pode ser desfeita.',
          style: GoogleFonts.alegreya(
            color: NnkColors.tintaCastanha, 
            fontSize: 18
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar', 
              style: GoogleFonts.cinzel(color: NnkColors.tintaCastanha)
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: NnkColors.vermelhoLacre),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Excluir', 
              style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)
            ),
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
              backgroundColor: NnkColors.verdeErva,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: NnkColors.vermelhoLacre,
            ),
          );
        }
      }
    }
  }

  Future<void> _mostrarOpcoes(BuildContext context, Agenda agenda) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: NnkColors.papelAntigo, // Fundo temático
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  agenda.nome,
                  style: GoogleFonts.cinzel(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: NnkColors.tintaCastanha,
                  ),
                ),
              ),
              Divider(height: 1, color: NnkColors.ouroAntigo.withOpacity(0.5)),

              ListTile(
                leading: const Icon(Icons.calendar_month, color: NnkColors.azulSuave),
                title: Text(
                  'Ver Calendário',
                  style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha, fontSize: 18),
                ),
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
                leading: const Icon(Icons.edit, color: NnkColors.azulSuave),
                title: Text(
                  'Editar Agenda',
                  style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha, fontSize: 18),
                ),
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
                title: Text(
                  'Editar Bloqueios',
                  style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha, fontSize: 18),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed(
                    '/bloqueios/list',
                    arguments: agenda, 
                  );
                },
              ),
              
              Divider(color: NnkColors.ouroAntigo.withOpacity(0.3)),

              // --- OPÇÃO DE EXCLUIR ---
              ListTile(
                leading: const Icon(Icons.delete, color: NnkColors.vermelhoLacre),
                title: Text(
                  'Excluir Agenda',
                  style: GoogleFonts.alegreya(color: NnkColors.vermelhoLacre, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Future.delayed(const Duration(milliseconds: 200), () {
                     if (context.mounted) _confirmarExclusao(context, agenda);
                  });
                },
              ),

              ListTile(
                leading: const Icon(Icons.close, color: NnkColors.vermelhoLacre),
                title: Text(
                  'Cancelar',
                  style: GoogleFonts.alegreya(color: NnkColors.vermelhoLacre, fontSize: 18),
                ),
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
      backgroundColor: NnkColors.papelAntigo, // Fundo bege
      appBar: AppBar(
        backgroundColor: NnkColors.papelAntigo,
        iconTheme: const IconThemeData(color: NnkColors.tintaCastanha),
        title: Text(
          'Todas Agendas', 
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: NnkColors.tintaCastanha),
            onPressed: _fetchAgendas,
            tooltip: 'Recarregar Agendas',
          ),
        ],
      ),

      drawer: const AdminDrawer(),

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
                'Nenhuma agenda encontrada.\nClique no botão + para criar uma nova.',
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
                cor: cor, // Mantém a cor original do card
                onTap: () {
                  if (agenda.id != null) {
                    _mostrarOpcoes(context, agenda);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro: Agenda sem ID.'),
                        backgroundColor: NnkColors.vermelhoLacre,
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
        // --- ESTILO RPG DO BOTÃO ---
        backgroundColor: NnkColors.tintaCastanha, // Fundo Escuro para contraste
        foregroundColor: NnkColors.ouroAntigo, // Ícone Dourado
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: NnkColors.ouroAntigo, width: 2),
        ),
        tooltip: 'Criar Nova Agenda',
        child: const Icon(Icons.add, size: 32),
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
      color: cor, // Cor mantida
      elevation: 4,
      // Borda subtil para destacar no papel antigo
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1), 
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: Colors.white.withOpacity(0.9),
                size: 24,
              ),
              const Spacer(),
              Text(
                agenda.nome,
                style: GoogleFonts.cinzel( // Fonte temática, mas branca para contraste no card
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
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 14, // Ligeiramente maior para leitura
                  fontWeight: FontWeight.w500
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