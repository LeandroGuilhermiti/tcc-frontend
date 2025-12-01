import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:google_fonts/google_fonts.dart'; 

// Modelos
import '../models/agendamento_model.dart';
import '../models/bloqueio_model.dart';
import '../models/user_model.dart';

// Providers
import '../providers/agendamento_provider.dart';
import '../providers/bloqueio_provider.dart';
import '../providers/user_provider.dart';

// Serviços
import 'dialogo_agendamento_service.dart';

// Tema
import '../theme/app_theme.dart';

class DialogoAgendamentoAdmin {
  
  static void mostrarDialogoAdmin({
    required BuildContext context,
    required Appointment appointment,
    required int duracaoDaAgenda,
  }) {
    final dynamic appointmentData = appointment.resourceIds?.first;

    // // --- 1. GESTÃO DE BLOQUEIOS ---
    // if (appointmentData is Bloqueio) {
    //   _mostrarDialogoBloqueio(context, appointmentData, appointment.subject);
    //   return;
    // }

    // --- 2. GESTÃO DE AGENDAMENTOS ---
    if (appointmentData is Agendamento) {
      _mostrarDialogoAgendamento(
        context: context, 
        agendamento: appointmentData, 
        appointment: appointment,
        duracaoDaAgenda: duracaoDaAgenda
      );
      return;
    }
  }

  // --- DIÁLOGO DE AGENDAMENTO (ADMIN) ---
  static void _mostrarDialogoAgendamento({
    required BuildContext context,
    required Agendamento agendamento,
    required Appointment appointment,
    required int duracaoDaAgenda,
  }) {
    // Busca nome do usuário para exibir ao Admin
    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final user = userProvider.usuarios.cast<UserModel?>().firstWhere(
      (u) => u?.id == agendamento.idUsuario,
      orElse: () => null,
    );
    final nomePaciente = user != null 
        ? '${user.primeiroNome} ${user.sobrenome ?? ''}' 
        : 'Usuário ID: ${agendamento.idUsuario}';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: NnkColors.papelAntigo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: NnkColors.ouroAntigo, width: 2),
          ),
          title: Text(
            'Gerenciar Agendamento',
            style: GoogleFonts.cinzel(color: NnkColors.tintaCastanha, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Paciente:', nomePaciente),
              const SizedBox(height: 8),
              _buildInfoRow('Horário:', DateFormat('dd/MM/yyyy HH:mm').format(appointment.startTime)),
              const SizedBox(height: 8),
              _buildInfoRow('Duração:', '${agendamento.duracao} período${agendamento.duracao > 1 ? 's' : ''}'),
            ],
          ),
          actions: [
            // BOTÃO EXCLUIR
            TextButton(
              onPressed: () async {
                try {
                  await Provider.of<AgendamentoProvider>(context, listen: false)
                      .removerAgendamento(agendamento);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  _mostrarErro(context, e);
                }
              },
              child: Text('Excluir', style: GoogleFonts.cinzel(color: NnkColors.vermelhoLacre, fontWeight: FontWeight.bold)),
            ),

            // BOTÃO EDITAR (ADMIN)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                DialogoAgendamentoService.abrirEdicaoDireta(
                  context: context,
                  agendamento: agendamento,
                  duracaoDaAgenda: duracaoDaAgenda,
                  avisoAgendamento: null, // Admin não precisa do aviso
                );
              },
              child: Text('Editar', style: GoogleFonts.cinzel(color: NnkColors.azulSuave, fontWeight: FontWeight.bold)),
            ),

            // BOTÃO FECHAR
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Fechar', style: GoogleFonts.cinzel(color: NnkColors.tintaCastanha, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // // --- DIÁLOGO DE BLOQUEIO (ADMIN) ---
  // static void _mostrarDialogoBloqueio(BuildContext context, Bloqueio bloqueio, String titulo) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       backgroundColor: NnkColors.papelAntigo,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(16),
  //         side: const BorderSide(color: NnkColors.ouroAntigo, width: 2),
  //       ),
  //       title: Text('Gerenciar Bloqueio', style: GoogleFonts.cinzel(color: NnkColors.tintaCastanha, fontWeight: FontWeight.bold)),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(titulo, style: GoogleFonts.alegreya(fontSize: 18, fontWeight: FontWeight.bold, color: NnkColors.tintaCastanha)),
  //           const SizedBox(height: 8),
  //           Text(
  //             'Duração: ${bloqueio.duracao} horas',
  //             style: GoogleFonts.alegreya(fontSize: 16, color: NnkColors.tintaCastanha),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () async {
  //             try {
  //               await Provider.of<BloqueioProvider>(context, listen: false)
  //                   .excluirBloqueio(agenda.id!, bloqueio.dataHora);
  //               if (context.mounted) Navigator.pop(context);
  //             } catch (e) {
  //               _mostrarErro(context, e);
  //             }
  //           },
  //           child: Text('Excluir', style: GoogleFonts.cinzel(color: NnkColors.vermelhoLacre, fontWeight: FontWeight.bold)),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text('Fechar', style: GoogleFonts.cinzel(color: NnkColors.tintaCastanha)),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  static Widget _buildInfoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.alegreya(fontSize: 18, color: NnkColors.tintaCastanha),
        children: [
          TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: value),
        ],
      ),
    );
  }

  static void _mostrarErro(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro: $e', style: GoogleFonts.alegreya(color: Colors.white)),
        backgroundColor: NnkColors.vermelhoLacre,
      ),
    );
  }
}