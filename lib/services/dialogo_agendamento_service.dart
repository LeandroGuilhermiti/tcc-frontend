import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Fonts
import 'dart:convert';

// Models e Providers
import '../models/agendamento_model.dart';
import '../models/bloqueio_model.dart';
import '../models/user_model.dart';
import '../providers/agendamento_provider.dart';
import '../providers/user_provider.dart';

// Tema
import '../theme/app_theme.dart';

class DialogoAgendamentoService {
  
  static void _mostrarDialogo({
    required BuildContext context,
    required String titulo,
    required DateTime dataInicial,
    required String idAgenda,
    required int duracaoDaAgenda,
    Agendamento? agendamentoExistente,
    String? avisoAgendamento,
  }) {
    final formKey = GlobalKey<FormState>();

    final bool isEditing = agendamentoExistente != null;
    final String tituloFinal = isEditing ? 'Editar Agendamento' : titulo;

    DateTime dataHoraAgendamento = agendamentoExistente?.dataHora ?? dataInicial;
    String? idUsuarioSelecionado = agendamentoExistente?.idUsuario;
    int duracaoSelecionada = agendamentoExistente?.duracao ?? 1;

    final usuariosDisponiveis = Provider.of<UsuarioProvider>(context, listen: false).usuarios;
    if (usuariosDisponiveis.isEmpty) {
      debugPrint("ALERTA: O DialogoAgendamentoService foi aberto, mas a lista 'usuariosDisponiveis' está vazia.");
    }

    String nomeInicialPaciente = '';
    if (isEditing && idUsuarioSelecionado != null) {
      try {
        final usuario = usuariosDisponiveis.firstWhere((u) => u.id == idUsuarioSelecionado);
        nomeInicialPaciente = '${usuario.primeiroNome} ${usuario.sobrenome ?? ''}';
      } catch (e) {
        debugPrint("Não foi possível encontrar o nome do usuário para pré-preencher: $e");
        idUsuarioSelecionado = null; 
      }
    }

    // Helper de estilo para inputs
    InputDecoration _inputDeco(String label, IconData? icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.alegreya(color: NnkColors.tintaCastanha.withOpacity(0.7)),
        prefixIcon: icon != null ? Icon(icon, color: NnkColors.ouroAntigo) : null,
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
                tituloFinal,
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

                              final TimeOfDay initialTime = TimeOfDay.fromDateTime(dataHoraAgendamento);

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

                                int novoMinutoCorrigido = (novaHora.minute / duracao).floor() * duracao;

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
                    Autocomplete<UserModel>(
                      initialValue: TextEditingValue(text: nomeInicialPaciente),
                      displayStringForOption: (UserModel option) => '${option.primeiroNome} ${option.sobrenome ?? ''}',
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<UserModel>.empty();
                        }
                        final query = textEditingValue.text.toLowerCase();
                        return usuariosDisponiveis.where((UserModel option) {
                          final nomeCompleto = '${option.primeiroNome} ${option.sobrenome ?? ''}'.toLowerCase();
                          return nomeCompleto.contains(query);
                        });
                      },
                      onSelected: (UserModel selection) {
                        idUsuarioSelecionado = selection.id;
                      },
                      fieldViewBuilder: (
                        BuildContext context,
                        TextEditingController internalController, 
                        FocusNode fieldFocusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        internalController.addListener(() {
                          if (internalController.text.isEmpty) {
                            idUsuarioSelecionado = null;
                          }
                        });

                        return TextFormField(
                          controller: internalController,
                          focusNode: fieldFocusNode,
                          style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha, fontSize: 16),
                          decoration: _inputDeco('Nome do Paciente', null).copyWith(
                            hintText: 'Digite para procurar...',
                            hintStyle: GoogleFonts.alegreya(color: NnkColors.cinzaSuave),
                            prefixIcon: const Icon(Icons.person_search, color: NnkColors.ouroAntigo),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o nome do paciente.';
                            }
                            if (idUsuarioSelecionado == null) {
                              return 'Selecione um paciente válido da lista.';
                            }
                            return null;
                          },
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            color: NnkColors.papelAntigo,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: NnkColors.ouroAntigo)),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final UserModel option = options.elementAt(index);
                                  return InkWell(
                                    onTap: () {
                                      onSelected(option);
                                    },
                                    child: ListTile(
                                      title: Text(
                                        '${option.primeiroNome} ${option.sobrenome ?? ''}',
                                        style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
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
                      validator: (value) => value == null ? 'Selecione a duração' : null,
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
                              final provider = Provider.of<AgendamentoProvider>(context, listen: false);

                              final agendamentoParaSalvar = Agendamento(
                                id: isEditing ? agendamentoExistente!.id : null,
                                idAgenda: idAgenda,
                                idUsuario: idUsuarioSelecionado!,
                                dataHora: dataHoraAgendamento,
                                duracao: duracaoSelecionada,
                              );
                              
                              if (isEditing) {
                                await provider.atualizarAgendamento(agendamentoParaSalvar);
                              } else {
                                await provider.adicionarAgendamento(agendamentoParaSalvar);
                              }

                              if (context.mounted) {
                                if (!isEditing && avisoAgendamento != null && avisoAgendamento.trim().isNotEmpty) {
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
                                        style: GoogleFonts.alegreya(fontSize: 16, color: NnkColors.tintaCastanha),
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
                                  if (!isEditing) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Agendamento criado com sucesso!'),
                                        backgroundColor: NnkColors.verdeErva,
                                      ),
                                    );
                                  } else {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Atualizado com sucesso!'), backgroundColor: NnkColors.verdeErva),
                                    );
                                  }
                                }
                              }
                            } catch (e) {
                              _tratarErro(context, e);
                            } finally {
                              if (context.mounted && !(!isEditing && avisoAgendamento != null && avisoAgendamento.trim().isNotEmpty)) {
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

  static void _tratarErro(BuildContext context, Object e) {
    if (!context.mounted) return;

    String mensagemErro = e.toString();

    // 1. Verifica se é erro 400
    if (mensagemErro.contains("400")) {
      final RegExp regex = RegExp(r'"message":"(.*?)"');
      final match = regex.firstMatch(mensagemErro);

      if (match != null) {
        mensagemErro = match.group(1) ?? "Horário indisponível.";
      } else {
        mensagemErro = "O horário solicitado não está disponível (Erro 400).";
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

  static void mostrarDialogoEdicaoAgendamento({
    required BuildContext context,
    required Appointment appointment,
    required int duracaoDaAgenda,
    String? avisoAgendamento,
  }) {
    final dynamic appointmentData = appointment.resourceIds?.first;

    if (appointmentData is! Agendamento) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: NnkColors.papelAntigo,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: NnkColors.ouroAntigo, width: 2)),
          title: Text('Detalhes do Bloqueio', style: GoogleFonts.cinzel(color: NnkColors.tintaCastanha, fontWeight: FontWeight.bold)),
          content: Text(appointment.subject, style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha, fontSize: 18)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Fechar', style: GoogleFonts.cinzel(color: NnkColors.tintaCastanha)),
            ),
          ],
        ),
      );
      return;
    }

    final Agendamento agendamento = appointmentData;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: NnkColors.papelAntigo,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: NnkColors.ouroAntigo, width: 2)),
          title: Text('Detalhes do Agendamento', style: GoogleFonts.cinzel(color: NnkColors.tintaCastanha, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appointment.subject, style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
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
                   if (context.mounted) _tratarErro(context, e);
                }
              },
              child: Text('Excluir', style: GoogleFonts.cinzel(color: NnkColors.vermelhoLacre, fontWeight: FontWeight.bold)),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _mostrarDialogo(
                  context: context,
                  titulo: 'Editar Agendamento',
                  dataInicial: agendamento.dataHora,
                  idAgenda: agendamento.idAgenda,
                  duracaoDaAgenda: duracaoDaAgenda,
                  agendamentoExistente: agendamento,
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

  static void mostrarDialogoNovoAgendamento({
    required BuildContext context,
    required DateTime dataInicial,
    required String idAgenda,
    required int duracaoDaAgenda,
    String? avisoAgendamento,
  }) {
    _mostrarDialogo(
      context: context,
      titulo: 'Novo Agendamento',
      dataInicial: dataInicial,
      idAgenda: idAgenda,
      duracaoDaAgenda: duracaoDaAgenda,
      agendamentoExistente: null,
      avisoAgendamento: avisoAgendamento,
    );
  }

  static void mostrarDialogoApenasHora({
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

    _mostrarDialogo(
      context: context,
      titulo: 'Novo Agendamento',
      dataInicial: dataHoraInicial,
      idAgenda: idAgenda,
      duracaoDaAgenda: duracaoDaAgenda,
      agendamentoExistente: null,
      avisoAgendamento: avisoAgendamento,
    );
  }
}