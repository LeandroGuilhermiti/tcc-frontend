import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/agendamento_model.dart';
import '../models/user_model.dart';
import '../providers/agendamento_provider.dart';
import '../providers/user_provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class DialogoAgendamentoService {
  /// Lógica principal e partilhada para o formulário de diálogo.
  static void _mostrarDialogo({
    required BuildContext context,
    required String titulo,
    required DateTime dataInicial,
    required String idAgenda,
    required int duracaoDaAgenda,
  }) {
    final formKey = GlobalKey<FormState>();
    DateTime dataHoraAgendamento = dataInicial;

    String? idUsuarioSelecionado;

    // Busca a lista de usuários do provider (fora do builder)
    // Esta lista agora deve vir preenchida com os nomes do Cognito
    final usuariosDisponiveis = Provider.of<UsuarioProvider>(
      context,
      listen: false,
    ).usuarios;

    // --- DEBUG ---
    // Vamos verificar se a lista de usuários está a chegar corretamente
    if (usuariosDisponiveis.isEmpty) {
      print(
        "ALERTA: O DialogoAgendamentoService foi aberto, mas a lista 'usuariosDisponiveis' está vazia.",
      );
    } else {
      print(
        "DialogoAgendamentoService: Lista de usuários carregada com ${usuariosDisponiveis.length} usuários.",
      );
      // print("Primeiro usuário: ${usuariosDisponiveis.first.primeiroNome}");
    }
    // --- FIM DEBUG ---

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(titulo),
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

                            if (context.mounted) {
                              novaHora = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                  dataHoraAgendamento,
                                ),
                              );
                            }

                            if (novaHora != null) {
                              final TimeOfDay horaSelecionada = novaHora!;
                              setDialogState(() {
                                dataHoraAgendamento = DateTime(
                                  novaData?.year ?? dataHoraAgendamento.year,
                                  novaData?.month ?? dataHoraAgendamento.month,
                                  novaData?.day ?? dataHoraAgendamento.day,
                                  horaSelecionada.hour,
                                  horaSelecionada.minute,
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

                    // --- CORREÇÃO E MELHORIA NO AUTOCOMPLETE ---
                    Autocomplete<UserModel>(
                      // O que mostrar na lista
                      displayStringForOption: (UserModel option) =>
                          '${option.primeiroNome} ${option.sobrenome ?? ''}'
                              .trim(),

                      // Lógica de filtragem (optionsBuilder)
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          // Não mostra nada se o campo estiver vazio
                          return const Iterable<UserModel>.empty();
                        }

                        // Filtra a lista 'usuariosDisponiveis'
                        return usuariosDisponiveis.where((UserModel option) {
                          // Combina nome e sobrenome para uma busca melhor
                          final nomeCompleto =
                              '${option.primeiroNome} ${option.sobrenome ?? ''}'
                                  .toLowerCase()
                                  .trim();

                          final input = textEditingValue.text.toLowerCase();

                          // Retorna true se o nome completo contiver o texto digitado
                          return nomeCompleto.contains(input);
                        });
                      },

                      // Ação ao selecionar: guardar o ID
                      onSelected: (UserModel selection) {
                        idUsuarioSelecionado = selection.id;
                      },

                      // Construtor do campo de texto
                      fieldViewBuilder:
                          (
                            BuildContext context,
                            TextEditingController fieldController,
                            FocusNode fieldFocusNode,
                            VoidCallback onFieldSubmitted,
                          ) {
                            fieldController.addListener(() {
                              if (fieldController.text.isEmpty) {
                                idUsuarioSelecionado = null;
                              }
                            });

                            return TextFormField(
                              controller: fieldController,
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

                      // Construtor da lista de opções (como ela se parece)
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                              ), // Limita altura
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final UserModel option = options.elementAt(
                                    index,
                                  );
                                  return InkWell(
                                    onTap: () {
                                      onSelected(option);
                                    },
                                    child: ListTile(
                                      // Mostra nome e sobrenome na lista
                                      title: Text(
                                        '${option.primeiroNome} ${option.sobrenome ?? ''}'
                                            .trim(),
                                      ),
                                      // Mostra o email (se existir) como subtítulo
                                      subtitle: option.email != null
                                          ? Text(option.email!)
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
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

                            final novoAgendamento = Agendamento(
                              idAgenda: idAgenda,
                              idUsuario: idUsuarioSelecionado!,
                              dataHora: dataHoraAgendamento,
                              duracao: 2, // usar o int 2 conforme solicitado
                            );							

                            try {
                              await Provider.of<AgendamentoProvider>(
                                context,
                                listen: false,
                              ).adicionarAgendamento(novoAgendamento);

                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Erro ao salvar: ${e.toString()}",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted) {
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

  /// Mostra um diálogo completo para criar um novo agendamento (usado pela visão de semana).
  static void mostrarDialogoNovoAgendamento({
    required BuildContext context,
    required DateTime dataInicial,
    required String idAgenda,
    required int duracaoDaAgenda,
  }) {
    _mostrarDialogo(
      context: context,
      titulo: 'Novo Agendamento',
      dataInicial: dataInicial,
      idAgenda: idAgenda,
      duracaoDaAgenda: duracaoDaAgenda,
    );
  }

  /// Mostra um diálogo para criar agendamento a partir da visão de mês.
  static void mostrarDialogoApenasHora({
    required BuildContext context,
    required DateTime diaSelecionado,
    required String idAgenda,
    required int duracaoDaAgenda,
  }) async {
    final dataHoraInicial = DateTime(
      diaSelecionado.year,
      diaSelecionado.month,
      diaSelecionado.day,
      TimeOfDay.now().hour,
      TimeOfDay.now().minute,
    );

    _mostrarDialogo(
      context: context,
      titulo: 'Novo Agendamento',
      dataInicial: dataHoraInicial,
      idAgenda: idAgenda,
      duracaoDaAgenda: duracaoDaAgenda,
    );
  }

  /// Diálogo de Edição/Exclusão
  static void mostrarDialogoEdicaoAgendamento({
    required BuildContext context,
    required Appointment appointment,
  }) {
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // ESTA LÓGICA DE APAGAR PRECISA SER AJUSTADA
                // COMO DISCUTIMOS ANTERIORMENTE.
                final agendamentoId = appointment.notes; // Isto é só o ID
                if (agendamentoId == null) return;

                // Para apagar, precisamos do objeto Agendamento completo.
                // Esta lógica precisa ser implementada:
                // 1. Buscar o agendamento completo pelo ID (appointment.notes)
                // 2. Chamar o provider.removerAgendamento(agendamentoCompleto)

                print(
                  "LÓGICA DE APAGAR AINDA NÃO IMPLEMENTADA CORRETAMENTE - PRECISA DO OBJETO AGENDAMENTO COMPLETO",
                );

                // --- Solução Temporária (Se o seu provider foi ajustado) ---
                // Se o seu provider.removerAgendamento(String id) ainda funciona,
                // este código pode funcionar. Se ele espera um Agendamento, vai falhar.
                try {
                  // O provider espera um Agendamento; constrói-se um objeto com todos os campos requeridos.
                  // TODO: Substituir por uma busca do Agendamento completo pelo ID (ex: provider.buscarAgendamentoPorId)
                  // antes de remover, para não precisar usar placeholders.
                  final agendamentoTemp = Agendamento(
                    id: agendamentoId,
                    idAgenda: '', // TODO: preencher com idAgenda correto
                    idUsuario: '', // TODO: preencher com idUsuario correto
                    dataHora: DateTime.now(), // TODO: usar a dataHora do agendamento real
                    duracao: 0, // TODO: usar a duracao do agendamento real
                  );

                  await Provider.of<AgendamentoProvider>(
                    context,
                    listen: false,
                  ).removerAgendamento(agendamentoTemp);

                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Erro ao excluir: ${e.toString()}"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
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
}
