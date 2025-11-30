import 'package:flutter/material.dart';
import 'package:tcc_frontend/models/agenda_model.dart';
import '../../widgets/menu_letral_admin.dart';
import '../../widgets/agenda_home_compartilhada.dart'; 
import 'package:tcc_frontend/services/dialogo_agendamento_service.dart'; 

class HomePageAdmin extends StatelessWidget {
  final String idAgenda;
  final int duracaoAgenda;

  const HomePageAdmin({
    super.key,
    required this.idAgenda,
    required this.duracaoAgenda,
  });

  @override
  Widget build(BuildContext context) {
    // Cria um objeto Agenda temporário para passar ao widget
    // (Idealmente, a HomePageAdmin deveria receber o objeto Agenda completo,
    // mas como você passa ID e Duração, montamos um aqui).
    final agenda = Agenda(
      id: idAgenda,
      nome:
          'Agenda do Profissional', // Título genérico ou passado por parâmetro
      descricao: '',
      duracao: duracaoAgenda,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda do Profissional'),
        actions: [
          // O botão refresh está dentro do SharedCalendar? Não, podemos por aqui se quisermos forçar refresh externo
          // Mas o SharedCalendar já tem a lógica no initState.
          // Se quiser um botão de refresh manual que funcione, precisaria de uma GlobalKey no SharedCalendar
          // ou passar o refresh para dentro. Por simplicidade, o SharedCalendar já carrega os dados.
        ],
      ),
      drawer: const AdminDrawer(),
      body: SharedAgendaCalendar(
        agenda: agenda,

        // AÇÃO DE CLIQUE NO AGENDAMENTO (ADMIN)
        onAppointmentTap: (appointment, ctx) {
          DialogoAgendamentoService.mostrarDialogoEdicaoAgendamento(
            context: ctx,
            appointment: appointment,
            duracaoDaAgenda: duracaoAgenda,
          );
        },

        // AÇÃO DE CLIQUE NO ESPAÇO VAZIO (ADMIN)
        onSlotTap: (date, ctx) {
          // Verifica se veio do mês (hora zerada) ou semana (hora definida)
          if (date.hour == 0 && date.minute == 0) {
            DialogoAgendamentoService.mostrarDialogoApenasHora(
              context: ctx,
              diaSelecionado: date,
              idAgenda: idAgenda,
              duracaoDaAgenda: duracaoAgenda,
            );
          } else {
            DialogoAgendamentoService.mostrarDialogoNovoAgendamento(
              context: ctx,
              dataInicial: date,
              idAgenda: idAgenda,
              duracaoDaAgenda: duracaoAgenda,
            );
          }
        },
      ),
    );
  }
}
