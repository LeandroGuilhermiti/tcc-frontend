import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:google_fonts/google_fonts.dart'; 

// Modelos
import '../models/agendamento_model.dart';
import '../models/bloqueio_model.dart';

// Providers
import '../providers/agendamento_provider.dart';

// Serviços
import 'dialogo_agendamento_service.dart';

// Tema
import '../theme/app_theme.dart';

class DialogoAgendamentoCliente {
  
  static void mostrarDialogoCliente({
    required BuildContext context,
    required Appointment appointment,
    required String? currentUserId,
    required int duracaoDaAgenda,
    String? avisoAgendamento, 
  }) {
    final dynamic appointmentData = appointment.resourceIds?.first;

    // --- 1. SE FOR BLOQUEIO ---
    if (appointmentData is Bloqueio) {
      _mostrarDialogoSimples(
        context: context,
        titulo: 'Horário Indisponível',
        motivo: appointment.subject, // Ex: "Almoço", "Feriado"
        isError: true,
      );
      return;
    }

    // --- 2. SE FOR AGENDAMENTO ---
    if (appointmentData is Agendamento) {
      final Agendamento agendamento = appointmentData;
      
      // Verifica se o agendamento pertence ao usuário logado
      final bool isOwner = (currentUserId != null && agendamento.idUsuario == currentUserId);

      if (isOwner) {
        // Se for dono, abre o menu de gestão
        _mostrarDialogoDoDono(
          context: context,
          appointment: appointment,
          agendamento: agendamento,
          duracaoDaAgenda: duracaoDaAgenda,
          avisoAgendamento: avisoAgendamento,
        );
      } else {
        // Se não for dono, apenas avisa que está ocupado
        _mostrarDialogoSimples(
          context: context,
          titulo: 'Horário Ocupado',
          motivo: 'Este horário foi reservado por outro cliente.',
        );
      }
      return;
    }

    // Caso de erro ou tipo desconhecido
    _mostrarDialogoSimples(
      context: context,
      titulo: 'Erro',
      motivo: 'Não foi possível identificar este horário.',
      isError: true,
    );
  }

  // --- DIÁLOGO DE GESTÃO DO PRÓPRIO AGENDAMENTO ---
  static void _mostrarDialogoDoDono({
    required BuildContext context,
    required Appointment appointment,
    required Agendamento agendamento,
    required int duracaoDaAgenda,
    String? avisoAgendamento,
  }) {
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
            'Meu Agendamento',
            style: GoogleFonts.cinzel(color: NnkColors.tintaCastanha, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  await Provider.of<AgendamentoProvider>(
                    context,
                    listen: false,
                  ).removerAgendamento(agendamento);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  _mostrarErro(context, e);
                }
              },
              child: Text('Excluir', style: GoogleFonts.cinzel(color: NnkColors.vermelhoLacre, fontWeight: FontWeight.bold)),
            ),
            
            // BOTÃO EDITAR (Chama o Service para abrir a edição direta)
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fecha este diálogo primeiro
                DialogoAgendamentoService.abrirEdicaoDireta(
                  context: context,
                  agendamento: agendamento,
                  duracaoDaAgenda: duracaoDaAgenda,
                  avisoAgendamento: avisoAgendamento, 
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

  // --- AUXILIARES ---
  static void _mostrarDialogoSimples({
    required BuildContext context,
    required String titulo,
    required String motivo,
    bool isError = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NnkColors.papelAntigo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isError ? NnkColors.vermelhoLacre : NnkColors.ouroAntigo, width: 2),
        ),
        title: Text(
          titulo,
          style: GoogleFonts.cinzel(
            color: isError ? NnkColors.vermelhoLacre : NnkColors.tintaCastanha,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          motivo,
          style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar', style: GoogleFonts.cinzel(color: NnkColors.tintaCastanha, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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

  // --- MÉTODOS PÚBLICOS DE CRIAÇÃO (Wrappers) ---
  static void mostrarDialogoNovoAgendamentoCliente({
    required BuildContext context,
    required DateTime dataInicial,
    required String idAgenda,
    required int duracaoDaAgenda,
    String? avisoAgendamento, 
  }) {
    DialogoAgendamentoService.mostrarDialogoNovoAgendamento(
      context: context,
      dataInicial: dataInicial,
      idAgenda: idAgenda,
      duracaoDaAgenda: duracaoDaAgenda,
      avisoAgendamento: avisoAgendamento,
    );
  }

  static void mostrarDialogoApenasHoraCliente({
    required BuildContext context,
    required DateTime diaSelecionado,
    required String idAgenda,
    required int duracaoDaAgenda,
    String? avisoAgendamento, 
  }) {
    DialogoAgendamentoService.mostrarDialogoApenasHora(
      context: context,
      diaSelecionado: diaSelecionado,
      idAgenda: idAgenda,
      duracaoDaAgenda: duracaoDaAgenda,
      avisoAgendamento: avisoAgendamento,
    );
  }
}