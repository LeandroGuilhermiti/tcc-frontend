import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:google_fonts/google_fonts.dart'; // Import das fontes
import 'dart:convert';

// Modelos
import '../models/agendamento_model.dart';
import '../models/bloqueio_model.dart';
import '../models/user_model.dart';

// Providers
import '../providers/agendamento_provider.dart';
import '../providers/auth_controller.dart';

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

    if (appointmentData is Bloqueio) {
      _mostrarDialogoSimples(
        context: context,
        titulo: 'Horário Indisponível',
        motivo: appointment.subject,
        isError: true,
      );
      return;
    }

    if (appointmentData is Agendamento) {
      final Agendamento agendamento = appointmentData;
      final bool isOwner = (agendamento.idUsuario == currentUserId);

      if (isOwner) {
        _mostrarDialogoDoDono(
          context: context,
          appointment: appointment,
          agendamento: agendamento,
          duracaoDaAgenda: duracaoDaAgenda,
          avisoAgendamento: avisoAgendamento,
        );
      } else {
        _mostrarDialogoSimples(
          context: context,
          titulo: 'Horário Ocupado',
          motivo: 'Reservado por outro cliente.',
        );
      }
      return;
    }

    _mostrarDialogoSimples(
      context: context,
      titulo: 'Erro',
      motivo: 'Não foi possível identificar este horário.',
      isError: true,
    );
  }

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
              Text(
                'Horário: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.startTime)}',
                style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha, fontSize: 18),
              ),
              Text(
                'Duração: ${agendamento.duracao} período${agendamento.duracao > 1 ? 's' : ''}',
                style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha, fontSize: 18),
              ),
            ],
          ),
          actions: [
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
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                DialogoAgendamentoService.mostrarDialogoEdicaoAgendamento(
                  context: context,
                  appointment: appointment,
                  duracaoDaAgenda: duracaoDaAgenda,
                  avisoAgendamento: avisoAgendamento, 
                );
              },
              child: Text('Editar', style: GoogleFonts.cinzel(color: NnkColors.azulSuave, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Fechar', style: GoogleFonts.cinzel(color: NnkColors.tintaCastanha, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  static void mostrarDialogoNovoAgendamentoCliente({
    required BuildContext context,
    required DateTime dataInicial,
    required String idAgenda,
    required int duracaoDaAgenda,
    String? avisoAgendamento, 
  }) {
    _mostrarDialogoNovoCliente(
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
  }) async {
    TimeOfDay horaAtual = TimeOfDay.now();
    int duracao = duracaoDaAgenda;
    if (duracao <= 0) duracao = 30;
    int minutoCorrigido = (horaAtual.minute / duracao).floor() * duracao;

    final dataHoraInicial = DateTime(
      diaSelecionado.year,
      diaSelecionado.month,
      diaSelecionado.day,
      horaAtual.hour,
      minutoCorrigido,
    );

    _mostrarDialogoNovoCliente(
      context: context,
      dataInicial: dataHoraInicial,
      idAgenda: idAgenda,
      duracaoDaAgenda: duracaoDaAgenda,
      avisoAgendamento: avisoAgendamento, 
    );
  }

  static void _mostrarDialogoNovoCliente({
    required BuildContext context,
    required DateTime dataInicial,
    required String idAgenda,
    required int duracaoDaAgenda,
    String? avisoAgendamento, 
  }) {
    final auth = Provider.of<AuthController>(context, listen: false);
    final UserModel? usuarioLogado = auth.usuario;

    if (usuarioLogado == null) {
      _mostrarErro(context, "Erro: Usuário não encontrado. Faça login novamente.");
      return;
    }

    final String idUsuarioSelecionado = usuarioLogado.id;
    final String nomeUsuario =
        '${usuarioLogado.primeiroNome} ${usuarioLogado.sobrenome ?? ''}';

    final formKey = GlobalKey<FormState>();
    DateTime dataHoraAgendamento = dataInicial;
    int duracaoSelecionada = 1;

    // Helper de estilo para inputs
    InputDecoration _inputDeco(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.alegreya(color: NnkColors.tintaCastanha.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: NnkColors.ouroAntigo),
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: NnkColors.ouroAntigo)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: NnkColors.ouroAntigo)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: NnkColors.tintaCastanha, width: 2)),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: NnkColors.papelAntigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: NnkColors.ouroAntigo, width: 2),
              ),
              title: Text(
                'Novo Agendamento',
                style: GoogleFonts.cinzel(color: NnkColors.tintaCastanha, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: NnkColors.ouroAntigo),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Horário:',
                            style: GoogleFonts.alegreya(fontWeight: FontWeight.bold, color: NnkColors.tintaCastanha, fontSize: 16),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.access_time, color: NnkColors.ouroAntigo),
                            onPressed: () async {
                              TimeOfDay? novaHora;
                              DateTime? novaData = dataHoraAgendamento;
                              final TimeOfDay initialTime =
                                  TimeOfDay.fromDateTime(dataHoraAgendamento);

                              if (context.mounted) {
                                novaHora = await showTimePicker(
                                  context: context,
                                  initialTime: initialTime,
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        timePickerTheme: TimePickerThemeData(
                                          backgroundColor: NnkColors.papelAntigo,
                                          dialHandColor: NnkColors.tintaCastanha,
                                          dialBackgroundColor: NnkColors.ouroClaro,
                                          hourMinuteTextColor: NnkColors.tintaCastanha,
                                          entryModeIconColor: NnkColors.ouroAntigo,
                                        ),
                                        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: NnkColors.tintaCastanha)),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                              }
                              if (novaHora != null) {
                                int duracao = duracaoDaAgenda;
                                if (duracao <= 0) duracao = 30;
                                int novoMinutoCorrigido =
                                    (novaHora.minute / duracao).floor() * duracao;
                                final horaCorrigida = TimeOfDay(
                                  hour: novaHora.hour,
                                  minute: novoMinutoCorrigido,
                                );
                                setDialogState(() {
                                  dataHoraAgendamento = DateTime(
                                    novaData.year,
                                    novaData.month,
                                    novaData.day,
                                    horaCorrigida.hour,
                                    horaCorrigida.minute,
                                  );
                                });
                              }
                            },
                            label: Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(dataHoraAgendamento),
                              style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: nomeUsuario,
                      readOnly: true,
                      style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha, fontSize: 16),
                      decoration: _inputDeco('Nome do Paciente', Icons.person).copyWith(
                        fillColor: NnkColors.cinzaSuave.withOpacity(0.2), // Visual desabilitado
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: duracaoSelecionada,
                      dropdownColor: NnkColors.papelAntigo,
                      style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha, fontSize: 16),
                      decoration: _inputDeco('Períodos (Duração)', Icons.layers_outlined),
                      items: [1, 2, 3, 4].map((int valor) {
                        return DropdownMenuItem<int>(
                          value: valor,
                          child: Text(
                            '$valor período${valor > 1 ? 's' : ''} (${valor * duracaoDaAgenda} min)',
                          ),
                        );
                      }).toList(),
                      onChanged: (int? novoValor) {
                        if (novoValor != null) {
                          setDialogState(() {
                            duracaoSelecionada = novoValor;
                          });
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Selecione a duração' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar', style: GoogleFonts.cinzel(color: NnkColors.vermelhoLacre, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NnkColors.tintaCastanha,
                    foregroundColor: NnkColors.ouroAntigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: NnkColors.ouroAntigo),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() => isSaving = true);
                            try {
                              final provider = Provider.of<AgendamentoProvider>(
                                context,
                                listen: false,
                              );

                              final agendamentoParaSalvar = Agendamento(
                                id: null,
                                idAgenda: idAgenda,
                                idUsuario: idUsuarioSelecionado,
                                dataHora: dataHoraAgendamento,
                                duracao: duracaoSelecionada,
                              );

                              await provider.adicionarAgendamento(agendamentoParaSalvar);

                              if (context.mounted) {
                                if (avisoAgendamento != null && avisoAgendamento.trim().isNotEmpty) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctxAviso) => AlertDialog(
                                      backgroundColor: NnkColors.papelAntigo,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: NnkColors.ouroAntigo, width: 2)),
                                      title: Row(
                                        children: [
                                          const Icon(Icons.info_outline, color: NnkColors.azulSuave),
                                          const SizedBox(width: 8),
                                          Text('Aviso da Agenda', style: GoogleFonts.cinzel(color: NnkColors.tintaCastanha)),
                                        ],
                                      ),
                                      content: Text(
                                        avisoAgendamento,
                                        style: GoogleFonts.alegreya(fontSize: 18, color: NnkColors.tintaCastanha),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(ctxAviso).pop(); 
                                            Navigator.of(context).pop();  
                                          },
                                          child: Text('Entendido', style: GoogleFonts.cinzel(color: NnkColors.verdeErva, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Agendamento criado com sucesso!'),
                                      backgroundColor: NnkColors.verdeErva,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              _mostrarErro(context, e);
                            } finally {
                              if (context.mounted && !(avisoAgendamento != null && avisoAgendamento.trim().isNotEmpty)) {
                                setDialogState(() => isSaving = false);
                              }
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: NnkColors.ouroAntigo),
                        )
                      : Text('Salvar', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void _mostrarErro(BuildContext context, Object e) {
    if (!context.mounted) return;
    
    String mensagemErro = e.toString();

    if (mensagemErro.contains("400")) {
      final RegExp regex = RegExp(r'"message":"(.*?)"');
      final match = regex.firstMatch(mensagemErro);

      if (match != null) {
        mensagemErro = match.group(1) ?? "Horário indisponível.";
      } else {
        mensagemErro = "Conflito de horário. Tente outro período.";
      }
    } else {
      mensagemErro = mensagemErro.replaceAll(RegExp(r'Exception:?\s*'), '');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagemErro, style: GoogleFonts.alegreya(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: NnkColors.vermelhoLacre,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: NnkColors.ouroAntigo)),
      ),
    );
  }
}