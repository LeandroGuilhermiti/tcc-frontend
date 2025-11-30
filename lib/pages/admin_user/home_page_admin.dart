import 'package:flutter/material.dart';
import '../../models/agenda_model.dart';
import '../../widgets/menu_letral_admin.dart';
import '../../widgets/agenda_home_compartilhada.dart'; 
import '../../services/dialogo_agendamento_service.dart'; 

class HomePageAdmin extends StatelessWidget {
  final Agenda agenda;

  const HomePageAdmin({
    super.key,
    required this.agenda,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(agenda.nome),
        scrolledUnderElevation: 0, 
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
        elevation: 0, 
      ),
      drawer: const AdminDrawer(),
      body: SharedAgendaCalendar(
        agenda: agenda,

        onAppointmentTap: (appointment, ctx) {
          DialogoAgendamentoService.mostrarDialogoEdicaoAgendamento(
            context: ctx,
            appointment: appointment,
            duracaoDaAgenda: agenda.duracao,
            avisoAgendamento: agenda.avisoAgendamento,
          );
        },

        onSlotTap: (date, ctx) {
          if (date.hour == 0 && date.minute == 0) {
            DialogoAgendamentoService.mostrarDialogoApenasHora(
              context: ctx,
              diaSelecionado: date,
              idAgenda: agenda.id!,
              duracaoDaAgenda: agenda.duracao,
              avisoAgendamento: agenda.avisoAgendamento,
            );
          } else {
            DialogoAgendamentoService.mostrarDialogoNovoAgendamento(
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