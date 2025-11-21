import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/agenda_model.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/menu_lateral_cliente.dart';
import '../../widgets/agenda_home_compartilhada.dart'; 
import '../../services/dialogo_agendamento_cliente.dart';

class HomePageCliente extends StatelessWidget {
  final Agenda agenda;
  const HomePageCliente({super.key, required this.agenda});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthController>();
    final String? currentUserId = authProvider.usuario?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(agenda.nome),
      ),
      drawer: const AppDrawerCliente(currentPage: null),
      body: SharedAgendaCalendar(
        agenda: agenda,

        // AÇÃO DE CLIQUE NO AGENDAMENTO (CLIENTE)
        onAppointmentTap: (appointment, ctx) {
          DialogoAgendamentoCliente.mostrarDialogoCliente(
            context: ctx,
            appointment: appointment,
            currentUserId: currentUserId,
            duracaoDaAgenda: agenda.duracao,
          );
        },

        // AÇÃO DE CLIQUE NO ESPAÇO VAZIO (CLIENTE)
        onSlotTap: (date, ctx) {
           if (date.hour == 0 && date.minute == 0) {
             DialogoAgendamentoCliente.mostrarDialogoApenasHoraCliente(
              context: ctx,
              diaSelecionado: date,
              idAgenda: agenda.id!,
              duracaoDaAgenda: agenda.duracao,
            );
           } else {
             DialogoAgendamentoCliente.mostrarDialogoNovoAgendamentoCliente(
              context: ctx,
              dataInicial: date,
              idAgenda: agenda.id!,
              duracaoDaAgenda: agenda.duracao,
            );
           }
        },
      ),
    );
  }
}