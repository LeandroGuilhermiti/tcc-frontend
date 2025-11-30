import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

// Modelos
import '../models/agendamento_model.dart';
import '../models/bloqueio_model.dart';
import '../models/user_model.dart';

// Providers
import '../providers/agendamento_provider.dart';
import '../providers/auth_controller.dart';

// Serviços
import 'dialogo_agendamento_service.dart';

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
    );
  }

  static void _mostrarDialogoSimples({
    required BuildContext context,
    required String titulo,
    required String motivo,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(motivo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
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
          title: const Text('Meu Agendamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Horário: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.startTime)}'),
              Text(
                  'Duração: ${agendamento.duracao} período${agendamento.duracao > 1 ? 's' : ''}'),
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
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
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
              child: const Text('Editar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
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

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Novo Agendamento'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Horário:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () async {
                            TimeOfDay? novaHora;
                            DateTime? novaData = dataHoraAgendamento;
                            final TimeOfDay initialTime =
                                TimeOfDay.fromDateTime(dataHoraAgendamento);

                            if (context.mounted) {
                              novaHora = await showTimePicker(
                                context: context,
                                initialTime: initialTime,
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
                          child: Text(
                            DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(dataHoraAgendamento),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: nomeUsuario,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Paciente',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color.fromARGB(255, 238, 238, 238),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: duracaoSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Períodos (Duração)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.layers_outlined),
                      ),
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
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
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
                                      title: const Row(
                                        children: [
                                          Icon(Icons.info_outline, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Aviso da Agenda'),
                                        ],
                                      ),
                                      content: Text(
                                        avisoAgendamento,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(ctxAviso).pop(); 
                                            Navigator.of(context).pop();  
                                          },
                                          child: const Text('Entendido'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Agendamento criado com sucesso!'),
                                      backgroundColor: Colors.green,
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- ALTERAÇÃO: Atualizado para tratar erro 400 ---
  static void _mostrarErro(BuildContext context, Object e) {
    if (!context.mounted) return;
    
    String mensagemErro = e.toString();

    // Se conter "400", substitui pela mensagem personalizada
    if (mensagemErro.contains("400")) {
      mensagemErro = "O horário solicitado ou o usuário possui agendamento no mesmo horário em outra agenda";
    } else {
      mensagemErro = mensagemErro.replaceAll("Exception: ", "");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagemErro),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}