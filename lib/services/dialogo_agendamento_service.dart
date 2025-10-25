import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/agendamento_model.dart';
import '../models/user_model.dart'; 
import '../providers/agendamento_provider.dart';
import '../providers/user_provider.dart'; 
import 'package:syncfusion_flutter_calendar/calendar.dart';

class DialogoAgendamentoService {
  // ... (Funções 'mostrarDialogoNovoAgendamento' e 'mostrarDialogoApenasHora' ficam IGUAIS) ...

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
    
    // 3. Variável para guardar o ID do usuário selecionado
    String? idUsuarioSelecionado;
    
    // 4. Buscar a lista de usuários do provider (fora do builder)
    final usuariosDisponiveis = Provider.of<UsuarioProvider>(context, listen: false).usuarios;

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
                      // ... (seletor de data e hora - FICA IGUAL) ...
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Horário:', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () async {
                            TimeOfDay? novaHora;
                            DateTime? novaData = dataHoraAgendamento;
                            
                            if(context.mounted) {
                               novaHora = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(dataHoraAgendamento),
                              );
                            }

                            if (novaHora != null) {
                              setDialogState(() {
                                dataHoraAgendamento = DateTime(
                                  novaData?.year ?? dataHoraAgendamento.year,
                                  novaData?.month ?? dataHoraAgendamento.month,
                                  novaData?.day ?? dataHoraAgendamento.day,
                                  novaHora!.hour,
                                  novaHora.minute,
                                );
                              });
                            }
                          },
                          child: Text(DateFormat('dd/MM/yyyy HH:mm').format(dataHoraAgendamento)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 5. SUBSTITUIÇÃO: 'TextFormField' por 'Autocomplete'
                    Autocomplete<UserModel>(
                      // Opções de display: o que mostrar na lista
                      displayStringForOption: (UserModel option) => option.primeiroNome,
                      // Lógica de filtragem: como encontrar usuários
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<UserModel>.empty();
                        }
                        return usuariosDisponiveis.where((UserModel UserModel) {
                          return UserModel.primeiroNome
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      
                      // Ação ao selecionar: guardar o ID
                      onSelected: (UserModel selection) {
                        idUsuarioSelecionado = selection.id;
                      },

                      // Construtor do campo de texto
                      fieldViewBuilder: (BuildContext context, 
                                          TextEditingController fieldController, 
                                          FocusNode fieldFocusNode, 
                                          VoidCallback onFieldSubmitted) {
                        
                        // Limpa o ID selecionado se o usuário apagar o texto
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
                            // Validação crucial:
                            if (idUsuarioSelecionado == null) {
                              return 'Selecione um paciente válido da lista.';
                            }
                            return null;
                          },
                        );
                      },
                      
                      // Construtor da lista de opções
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200), // Limita altura da lista
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
                                      title: Text(option.primeiroNome),
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
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() => isSaving = true);

                            // 6. Criar agendamento com o ID selecionado
                            final novoAgendamento = Agendamento(
                              idAgenda: idAgenda,
                              idUsuario: idUsuarioSelecionado!, // Agora temos o ID real
                              dataHora: dataHoraAgendamento,
                              duracao: duracaoDaAgenda,
                            );

                            try {
                              await Provider.of<AgendamentoProvider>(context, listen: false)
                                  .adicionarAgendamento(novoAgendamento);

                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Erro ao salvar: ${e.toString()}"),
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
                  child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ... (Função 'mostrarDialogoEdicaoAgendamento' FICA IGUAL) ...
  /// Diálogo de Edição/Exclusão (a lógica de exclusão já está aqui)
  static void mostrarDialogoEdicaoAgendamento({
    required BuildContext context,
    required Appointment appointment,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) { // Renomeado para evitar conflito
        return AlertDialog(
          title: const Text('Detalhes do Agendamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appointment.subject),
              const SizedBox(height: 8),
              Text('Horário: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.startTime)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final agendamentoId = appointment.notes; // Este é o ID (ex: UUID)
                if (agendamentoId == null) return;

                // --- CORREÇÃO AQUI ---
                // 1. Obter o AgendamentoProvider (sem 'listen: false' ainda)
                final provider = Provider.of<AgendamentoProvider>(context, listen: false);

                // 2. Encontrar o objeto Agendamento completo na lista do provider
                //    usando o ID que temos.
                Agendamento? agendamentoParaRemover;
                try {
                   agendamentoParaRemover = provider.agendamentos.firstWhere(
                    (a) => a.id == agendamentoId
                  );
                } catch (e) {
                  // Não encontrou o agendamento na lista, tratar erro
                  if (dialogContext.mounted) {
                     ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text("Erro: Agendamento não encontrado localmente."), backgroundColor: Colors.orange),
                     );
                  }
                  return; // Sai da função
                }
                
                // 3. Agora chamar o provider com o objeto Agendamento completo
                try {
                  await provider.removerAgendamento(agendamentoParaRemover);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (e) {
                  if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text("Erro ao excluir: ${e.toString()}"), backgroundColor: Colors.red),
                      );
                  }
                }
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Fechar')),
          ],
        );
      },
    );
  }
}
