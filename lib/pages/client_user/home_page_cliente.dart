import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/agenda_model.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/menu_lateral_cliente.dart';
import '../../widgets/agenda_home_compartilhada.dart'; 
import '../../services/dialogo_agendamento_cliente.dart';
import '../../theme/app_theme.dart'; // Importa NnkColors

class HomePageCliente extends StatelessWidget {
  final Agenda agenda;
  const HomePageCliente({super.key, required this.agenda});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthController>();
    final String? currentUserId = authProvider.usuario?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          agenda.nome.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: NnkColors.ouroAntigo.withOpacity(0.5),
            height: 1.0,
          ),
        ),
        scrolledUnderElevation: 0, 
        backgroundColor: NnkColors.papelAntigo,
        iconTheme: const IconThemeData(color: NnkColors.tintaCastanha),
        actions: [
          
          IconButton(
            icon: const Icon(Icons.info_outline),
            color: NnkColors.ouroAntigo,
            tooltip: 'Informações da Agenda',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: NnkColors.papelAntigo,
                  title: Text(agenda.nome, style: const TextStyle(fontFamily: 'Cinzel', color: NnkColors.tintaCastanha)),
                  content: Text(
                    agenda.descricao.isNotEmpty ? agenda.descricao : "Sem descrição disponível.",
                    style: const TextStyle(fontFamily: 'Alegreya', fontSize: 18, color: NnkColors.tintaCastanha),
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Fechar", style: TextStyle(color: NnkColors.tintaCastanha)),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawerCliente(currentPage: null),
      body: SharedAgendaCalendar(
        agenda: agenda,

        onAppointmentTap: (appointment, ctx) {
          DialogoAgendamentoCliente.mostrarDialogoCliente(
            context: ctx,
            appointment: appointment,
            currentUserId: currentUserId,
            duracaoDaAgenda: agenda.duracao,
            avisoAgendamento: agenda.avisoAgendamento,
          );
        },

        onSlotTap: (date, ctx) {
           if (date.hour == 0 && date.minute == 0) {
             DialogoAgendamentoCliente.mostrarDialogoApenasHoraCliente(
              context: ctx,
              diaSelecionado: date,
              idAgenda: agenda.id!,
              duracaoDaAgenda: agenda.duracao,
              avisoAgendamento: agenda.avisoAgendamento,
            );
           } else {
             DialogoAgendamentoCliente.mostrarDialogoNovoAgendamentoCliente(
              context: ctx,
              dataInicial: date,
              idAgenda: agenda.id!,
              duracaoDaAgenda: agenda.duracao,
              avisoAgendamento: agenda.avisoAgendamento,
            );
           }
        },
      ),
    );
  }
}