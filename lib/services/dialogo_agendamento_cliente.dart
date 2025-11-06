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
// Precisamos do serviço de diálogo do Admin para REUTILIZAR o formulário
// de criação/edição que já está pronto.
import 'dialogo_agendamento_service.dart';

///
/// Este novo serviço aplica a sua regra de negócio:
/// "O cliente só pode editar ou excluir os seus próprios agendamentos."
///
class DialogoAgendamentoCliente {
  ///
  /// Ponto de entrada principal.
  /// Este método decide qual diálogo mostrar (o de dono ou o de visitante).
  ///
  static void mostrarDialogoCliente({
    required BuildContext context,
    required Appointment appointment,
    required String? currentUserId, // O ID do usuário logado
    required int duracaoDaAgenda,
  }) {
    final dynamic appointmentData = appointment.resourceIds?.first;

    // Caso 1: É um Bloqueio (ex: Férias do profissional)
    if (appointmentData is Bloqueio) {
      _mostrarDialogoSimples(
        context: context,
        titulo: 'Horário Indisponível',
        motivo: appointment.subject, // Ex: "Férias"
      );
      return;
    }

    // Caso 2: É um Agendamento
    if (appointmentData is Agendamento) {
      final Agendamento agendamento = appointmentData;

      // --- ESTA É A SUA REGRA DE NEGÓCIO ---
      final bool isOwner = (agendamento.idUsuario == currentUserId);
      // -------------------------------------

      if (isOwner) {
        // O usuário logado é o dono do agendamento.
        // Mostra o diálogo completo com opções de Editar/Excluir.
        _mostrarDialogoDoDono(
          context: context,
          appointment: appointment,
          agendamento: agendamento,
          duracaoDaAgenda: duracaoDaAgenda,
        );
      } else {
        // Não é o dono. Mostra um diálogo simples, apenas informativo.
        _mostrarDialogoSimples(
          context: context,
          titulo: 'Horário Ocupado',
          motivo: 'Reservado por outro cliente.',
        );
      }
      return;
    }

    // Caso 3: Clicou em algo desconhecido (segurança)
    _mostrarDialogoSimples(
      context: context,
      titulo: 'Erro',
      motivo: 'Não foi possível identificar este horário.',
    );
  }

  ///
  /// Diálogo para agendamentos que NÃO pertencem ao usuário logado,
  /// ou para horários bloqueados.
  ///
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

  ///
  /// Diálogo para agendamentos que PERTENCEM ao usuário logado.
  /// Este é muito parecido com o `mostrarDialogoEdicaoAgendamento` do Admin.
  ///
  static void _mostrarDialogoDoDono({
    required BuildContext context,
    required Appointment appointment,
    required Agendamento agendamento,
    required int duracaoDaAgenda,
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
            // 1. Botão Excluir
            TextButton(
              onPressed: () async {
                try {
                  await Provider.of<AgendamentoProvider>(
                    context,
                    listen: false,
                  ).removerAgendamento(agendamento); // Passa o objeto
                  if (context.mounted) Navigator.pop(context); // Fecha diálogo
                } catch (e) {
                  _mostrarErro(context, "Erro ao excluir: $e");
                }
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),

            // 2. Botão Editar
            TextButton(
              onPressed: () {
                // Fecha o diálogo de detalhes primeiro
                Navigator.pop(context);

                // --- REUTILIZAÇÃO DE CÓDIGO ---
                // Chama o formulário que o Admin usa, passando os dados
                // deste agendamento para pré-preencher.
                DialogoAgendamentoService.mostrarDialogoEdicaoAgendamento(
                  context: context,
                  appointment: appointment,
                  duracaoDaAgenda: duracaoDaAgenda,
                );
                // --- FIM DA REUTILIZAÇÃO ---
              },
              child: const Text('Editar'),
            ),

            // 3. Botão Fechar
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

   /// Mostra um diálogo para criar agendamento (usado pela visão de semana).
  static void mostrarDialogoNovoAgendamentoCliente({
    required BuildContext context,
    required DateTime dataInicial,
    required String idAgenda,
    required int duracaoDaAgenda,
  }) {
    _mostrarDialogoNovoCliente(
      context: context,
      dataInicial: dataInicial,
      idAgenda: idAgenda,
      duracaoDaAgenda: duracaoDaAgenda,
    );
  }

  /// Mostra um diálogo para criar agendamento (usado pela visão de mês).
  static void mostrarDialogoApenasHoraCliente({
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

    _mostrarDialogoNovoCliente(
      context: context,
      dataInicial: dataHoraInicial,
      idAgenda: idAgenda,
      duracaoDaAgenda: duracaoDaAgenda,
    );
  }

  ///
  /// Lógica principal (privada) para o formulário de NOVO agendamento do CLIENTE.
  ///
  static void _mostrarDialogoNovoCliente({
    required BuildContext context,
    required DateTime dataInicial,
    required String idAgenda,
    required int duracaoDaAgenda,
  }) {
    // --- PASSO 1: Obter o usuário logado ---
    final auth = Provider.of<AuthController>(context, listen: false);
    final UserModel? usuarioLogado = auth.usuario;

    // Se, por algum motivo, não houver usuário logado, não abre o diálogo.
    if (usuarioLogado == null) {
      _mostrarErro(context, "Erro: Usuário não encontrado. Faça login novamente.");
      return;
    }

    // Pré-define o nome e o ID do usuário.
    final String idUsuarioSelecionado = usuarioLogado.id;
    final String nomeUsuario =
        '${usuarioLogado.primeiroNome} ${usuarioLogado.sobrenome ?? ''}';

    final formKey = GlobalKey<FormState>();
    DateTime dataHoraAgendamento = dataInicial;
    int duracaoSelecionada = 1; // Padrão de 1 período

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
                    // --- CAMPO 1: Horário ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Horário:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () async {
                            // ... (lógica de seleção de hora, copiada do admin) ...
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

                    // --- CAMPO 2: Nome do Paciente (TRAVADO) ---
                    TextFormField(
                      // Define o nome do usuário logado
                      initialValue: nomeUsuario,
                      readOnly: true, // Torna o campo apenas de leitura
                      decoration: const InputDecoration(
                        labelText: 'Nome do Paciente',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color.fromARGB(255, 238, 238, 238),
                      ),
                      // Não precisa de validador, pois já está pré-validado
                    ),
                    // --- FIM DA ALTERAÇÃO (Autocomplete removido) ---

                    const SizedBox(height: 16),

                    // --- CAMPO 3: Duração ---
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
                              final provider =
                                  Provider.of<AgendamentoProvider>(
                                context,
                                listen: false,
                              );

                              final agendamentoParaSalvar = Agendamento(
                                id: null, // Novo agendamento
                                idAgenda: idAgenda,
                                idUsuario: idUsuarioSelecionado, // <-- ID TRAVADO
                                dataHora: dataHoraAgendamento,
                                duracao: duracaoSelecionada,
                              );

                              await provider
                                  .adicionarAgendamento(agendamentoParaSalvar);

                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              _mostrarErro(context, "Erro ao salvar: $e");
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

  // Helper para mostrar erros
  static void _mostrarErro(BuildContext context, String mensagem) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem.replaceAll("Exception: ", "")),
        backgroundColor: Colors.red,
      ),
    );
  }
}
