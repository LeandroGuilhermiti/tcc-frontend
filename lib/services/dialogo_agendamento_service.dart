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
  /// --- ALTERAÇÃO ---
  /// Lógica principal e partilhada para o formulário de diálogo.
  /// Agora aceita um [agendamentoExistente] opcional.
  static void _mostrarDialogo({
    required BuildContext context,
    required String titulo,
    required DateTime dataInicial,
    required String idAgenda,
    required int duracaoDaAgenda, // Ex: 15, 20, ou 30 (para travar o seletor)
    Agendamento? agendamentoExistente, // <-- ADICIONADO
  }) {
    final formKey = GlobalKey<FormState>();

    // --- ALTERAÇÃO --- Define se estamos editando ou criando
    final bool isEditing = agendamentoExistente != null;
    final String tituloFinal = isEditing ? 'Editar Agendamento' : titulo;

    // --- ALTERAÇÃO --- Pré-preenche os dados se estiver editando
    DateTime dataHoraAgendamento =
    agendamentoExistente?.dataHora ?? dataInicial;
    String? idUsuarioSelecionado = agendamentoExistente?.idUsuario;

    // ALERTA: Se a lista estiver vazia, o Autocomplete não funciona
    final usuariosDisponiveis = Provider.of<UsuarioProvider>(
      context,
      listen: false,
    ).usuarios;
    if (usuariosDisponiveis.isEmpty) {
      debugPrint(
        "ALERTA: O DialogoAgendamentoService foi aberto, mas a lista 'usuariosDisponiveis' está vazia.",
      );
    }

    // --- ALTERAÇÃO --- Busca o nome do paciente para pré-preencher o campo
    String nomeInicialPaciente = '';
    if (isEditing && idUsuarioSelecionado != null) {
      try {
        final usuario = usuariosDisponiveis.firstWhere(
          (u) => u.id == idUsuarioSelecionado,
        );
        // Assumindo que seu UserModel tem 'primeiroNome' e 'sobrenome'
        nomeInicialPaciente =
            '${usuario.primeiroNome} ${usuario.sobrenome ?? ''}';
      } catch (e) {
        debugPrint(
          "Não foi possível encontrar o nome do usuário para pré-preencher: $e",
        );
        // Se não encontrar (ex: usuário deletado), limpa o ID
        idUsuarioSelecionado = null; 
      }
    }

    // --- ALTERAÇÃO --- Cria o controller FORA do builder para pré-preencher
    final fieldController = TextEditingController(text: nomeInicialPaciente);

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(tituloFinal), // <-- ALTERAÇÃO
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
                              // --- TRAVA DE MINUTOS ---
                              int duracao = duracaoDaAgenda;
                              if (duracao <= 0) duracao = 30; // Segurança

                              int novoMinutoCorrigido =
                                  (novaHora.minute / duracao).floor() * duracao;

                              final horaCorrigida = TimeOfDay(
                                hour: novaHora.hour,
                                minute: novoMinutoCorrigido,
                              );
                              // --- FIM DA TRAVA ---

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
                    // ... (Autocomplete e outros campos) ...
                    Autocomplete<UserModel>(
                      displayStringForOption: (UserModel option) =>
                          '${option.primeiroNome} ${option.sobrenome ?? ''}',
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<UserModel>.empty();
                        }
                        final query = textEditingValue.text.toLowerCase();
                        return usuariosDisponiveis.where((UserModel option) {
                          final nomeCompleto =
                              '${option.primeiroNome} ${option.sobrenome ?? ''}'
                                  .toLowerCase();
                          return nomeCompleto.contains(query);
                        });
                      },
                      onSelected: (UserModel selection) {
                        idUsuarioSelecionado = selection.id;
                        debugPrint(
                          'Usuário selecionado ID: $idUsuarioSelecionado',
                        );
                      },
                      // --- ALTERAÇÃO NO FIELD VIEW BUILDER ---
                      fieldViewBuilder: (
                        BuildContext context,
                        // O controller interno não é mais usado diretamente
                        TextEditingController internalController, 
                        FocusNode fieldFocusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        // Ouve o controller externo para limpar o ID se o texto for apagado
                        fieldController.addListener(() {
                          if (fieldController.text.isEmpty) {
                            idUsuarioSelecionado = null;
                          }
                        });

                        return TextFormField(
                          controller: fieldController, // <-- USA O CONTROLLER EXTERNO
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
                      // --- FIM DA ALTERAÇÃO ---
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
                                  final UserModel option = options.elementAt(
                                    index,
                                  );
                                  return InkWell(
                                    onTap: () {
                                      onSelected(option);
                                    },
                                    child: ListTile(
                                      title: Text(
                                        '${option.primeiroNome} ${option.sobrenome ?? ''}',
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
                              // --- ALTERAÇÃO PRINCIPAL (LÓGICA DE SALVAR) ---
                              final provider = Provider.of<AgendamentoProvider>(
                                context,
                                listen: false,
                              );

                              if (isEditing) {
                                // MODO DE ATUALIZAÇÃO
                                // Recriamos o objeto mantendo o ID original
                                final agendamentoAtualizado = Agendamento(
                                  id: agendamentoExistente!.id, // Mantém o ID
                                  idAgenda: idAgenda,
                                  idUsuario: idUsuarioSelecionado!,
                                  dataHora: dataHoraAgendamento,
                                  duracao: 1, // Mantém a lógica de duração
                                );
                                
                                // Chama o provider de ATUALIZAÇÃO
                                await provider.atualizarAgendamento(agendamentoAtualizado);

                              } else {
                                // MODO DE CRIAÇÃO (Lógica original)
                                final novoAgendamento = Agendamento(
                                  idAgenda: idAgenda,
                                  idUsuario: idUsuarioSelecionado!,
                                  dataHora: dataHoraAgendamento,
                                  duracao: 1, 
                                );
                                // Chama o provider de ADIÇÃO
                                await provider.adicionarAgendamento(novoAgendamento);
                              }
                              // --- FIM DA ALTERAÇÃO ---

                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              // ... (SnackBar de erro) ...
                              final snackBar = SnackBar(
                                content: Text(
                                  "Erro ao salvar: ${e.toString().replaceFirst("Exception: ", "")}",
                                ),
                                backgroundColor: Colors.red,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(snackBar);
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

  /// Mostra o diálogo de Edição/Exclusão.
  static void mostrarDialogoEdicaoAgendamento({
    required BuildContext context,
    required Appointment appointment,
    required int duracaoDaAgenda, // <-- ADICIONADO
  }) {
    // Pega o objeto de dados de 'resourceIds'.
    final dynamic appointmentData = appointment.resourceIds?.first;

    // Verifica se é um Agendamento (e não um Bloqueio)
    if (appointmentData is! Agendamento) {
      // ... (lógica de bloqueio - sem alteração) ...
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

    // Se for um Agendamento, continua com a lógica
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
            ],
          ),
          // --- ALTERAÇÃO NOS BOTÕES ---
          actions: [
            // 1. Botão Excluir
            TextButton(
              onPressed: () async {
                // A lógica de exclusão agora usa o objeto 'agendamento' completo
                try {
                  await Provider.of<AgendamentoProvider>(
                    context,
                    listen: false,
                  ).removerAgendamento(agendamento); // Passa o objeto
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Erro ao excluir: ${e.toString().replaceFirst("Exception: ", "")}",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),

            // 2. NOVO BOTÃO EDITAR (O seu pedido!)
            TextButton(
              onPressed: () {
                // Fecha o diálogo de detalhes primeiro
                Navigator.pop(context);

                // Abre o diálogo de formulário em MODO DE EDIÇÃO
                _mostrarDialogo(
                  context: context,
                  titulo: 'Editar Agendamento', // Este título será usado
                  dataInicial: agendamento.dataHora, // Passa a data atual
                  idAgenda: agendamento.idAgenda,
                  duracaoDaAgenda: duracaoDaAgenda, // Passa a duração
                  agendamentoExistente: agendamento, // <-- PASSA O OBJETO
                );
              },
              child: const Text('Editar'), // O botão que você queria
            ),

            // 3. Botão Fechar
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
          // --- FIM DA ALTERAÇÃO ---
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
      agendamentoExistente: null, // <-- ALTERAÇÃO: Confirma que é nulo
    );
  }

  /// Mostra um diálogo para criar agendamento a partir da visão de mês.
  static void mostrarDialogoApenasHora({
    required BuildContext context,
    required DateTime diaSelecionado,
    required String idAgenda,
    required int duracaoDaAgenda,
  }) async {
    // Pega a hora atual, mas "trava" os minutos
    TimeOfDay horaAtual = TimeOfDay.now();
    int duracao = duracaoDaAgenda;
    if (duracao <= 0) duracao = 30; // Segurança
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
      agendamentoExistente: null, // <-- ALTERAÇÃO: Confirma que é nulo
    );
  }
}

