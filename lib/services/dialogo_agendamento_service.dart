import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/agendamento_model.dart';
import '../models/bloqueio_model.dart';
import '../models/user_model.dart';
import '../providers/agendamento_provider.dart';
import '../providers/user_provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

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

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(tituloFinal),
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

                            final TimeOfDay initialTime = TimeOfDay.fromDateTime(dataHoraAgendamento);

                            if (context.mounted) {
                              novaHora = await showTimePicker(
                                context: context,
                                initialTime: initialTime,
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
                          child: Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(dataHoraAgendamento),
                          ),
                        ),
                      ],
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
                          decoration: const InputDecoration(
                            labelText: 'Nome do Paciente',
                            hintText: 'Digite para procurar...',
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
                                      title: Text('${option.primeiroNome} ${option.sobrenome ?? ''}'),
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
                      validator: (value) => value == null ? 'Selecione a duração' : null,
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
                                  if (!isEditing) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Agendamento criado com sucesso!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Atualizado com sucesso!')),
                                    );
                                  }
                                }
                              }
                            } catch (e) {
                              // --- ALTERAÇÃO AQUI: Chama a função de tratamento de erro ---
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

  // --- NOVA FUNÇÃO PARA TRATAR O ERRO 400 ---
  static void _tratarErro(BuildContext context, Object e) {
    if (!context.mounted) return;

    String mensagemErro = e.toString();
    
    // Verifica se é o erro 400 (conflito de horário)
    if (mensagemErro.contains("400")) {
      mensagemErro = "O horário solicitado já está ocupado pelo agendamento de outra pessoa ou o usuário atual possui agendamentos no mesmo horário, mas em outra agenda";
    } else {
      // Limpa "Exception: " caso seja outro erro
      mensagemErro = mensagemErro.replaceAll("Exception: ", "");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagemErro),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5), // Mais tempo para ler
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
          title: const Text('Detalhes do Bloqueio'),
          content: Text(appointment.subject),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
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
          title: const Text('Detalhes do Agendamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appointment.subject),
              const SizedBox(height: 8),
              Text(
                'Horário: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.startTime)}',
              ),
              Text(
                'Duração: ${agendamento.duracao} período${agendamento.duracao > 1 ? 's' : ''}',
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
                   // --- ALTERAÇÃO AQUI: Chama a função de tratamento de erro ---
                   if (context.mounted) _tratarErro(context, e);
                }
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
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