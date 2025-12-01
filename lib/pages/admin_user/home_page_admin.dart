import 'package:flutter/material.dart';
import '../../models/agenda_model.dart';
import '../../widgets/menu_letral_admin.dart';
import '../../widgets/agenda_home_compartilhada.dart'; 
import '../../services/dialogo_agendamento_service.dart'; // Mantido para criação (onSlotTap)
import '../../services/dialogo_agendamento_admin.dart'; // <--- NOVO IMPORT
import '../../theme/app_theme.dart';

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
      ),
      drawer: const AdminDrawer(),
      body: SharedAgendaCalendar(
        agenda: agenda,

        // --- ALTERAÇÃO AQUI: Usa o novo diálogo de Admin ---
        onAppointmentTap: (appointment, ctx) {
          DialogoAgendamentoAdmin.mostrarDialogoAdmin(
            context: ctx,
            appointment: appointment,
            duracaoDaAgenda: agenda.duracao,
          );
        },

        // A criação de novos horários (onSlotTap) mantém-se igual,
        // usando o serviço base, pois a criação é igual para todos.
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