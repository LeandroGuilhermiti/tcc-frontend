import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/agenda_model.dart';
import '../../models/periodo_model.dart';
import '../../providers/agenda_provider.dart';

// Classe auxiliar atualizada para rastrear IDs
class TimeRange {
  String? id; // ID do período (null se for novo)
  TimeOfDay inicio;
  TimeOfDay fim;
  TimeRange({this.id, required this.inicio, required this.fim});
}

class AgendaEditPage extends StatefulWidget {
  final Agenda agenda;
  const AgendaEditPage({super.key, required this.agenda});

  @override
  State<AgendaEditPage> createState() => _AgendaEditPageState();
}

class _AgendaEditPageState extends State<AgendaEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _profissionalController;
  late TextEditingController _describeController;
  late TextEditingController _avisoController;

  final Map<String, int> diasSemanaMap = {
    'Seg': 1,
    'Ter': 2,
    'Qua': 3,
    'Qui': 4,
    'Sex': 5,
    'Sáb': 6,
  };
  final Map<int, String> diasSemanaMapInverso = {
    1: 'Seg',
    2: 'Ter',
    3: 'Qua',
    4: 'Qui',
    5: 'Sex',
    6: 'Sáb',
  };
  final List<String> diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  final Map<String, bool> diasSelecionados = {};
  final Map<String, List<TimeRange>> periodosPorDia = {};

  // --- LISTA DE EXCLUSÃO ---
  // Guarda os IDs dos períodos que foram removidos da tela
  final List<String> _idsParaExcluir = [];

  final Map<String, String?> _errosDeHorario = {};

  String? duracaoConsulta;
  final List<String> opcoesDuracao = ['15 min', '30 min', '45 min', '60 min'];
  bool _isSaving = false;
  bool _isLoadingPeriods = true;

  @override
  void initState() {
    super.initState();
    _profissionalController = TextEditingController(text: widget.agenda.nome);
    _describeController = TextEditingController(text: widget.agenda.descricao);
    _avisoController = TextEditingController(
      text: widget.agenda.avisoAgendamento ?? '',
    );
    duracaoConsulta = '${widget.agenda.duracao} min';

    for (var dia in diasSemana) {
      diasSelecionados[dia] = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarPeriodos();
    });
  }

  Future<void> _carregarPeriodos() async {
    if (!_isLoadingPeriods) setState(() => _isLoadingPeriods = true);

    try {
      final provider = Provider.of<AgendaProvider>(context, listen: false);
      final periodosExistentes = await provider.buscarPeriodosDaAgenda(
        widget.agenda.id!,
      );

      final Map<String, List<TimeRange>> periodosNovos = {};
      final Map<String, bool> diasNovos = {
        for (var dia in diasSemana) dia: false,
      };

      for (var periodo in periodosExistentes) {
        final diaString = diasSemanaMapInverso[periodo.diaDaSemana];

        if (diaString != null) {
          diasNovos[diaString] = true;
          final timeRange = TimeRange(
            id: periodo.id, // <--- IMPORTANTE: Guardar o ID original
            inicio: periodo.inicio,
            fim: periodo.fim,
          );
          periodosNovos.putIfAbsent(diaString, () => []).add(timeRange);
        }
      }

      periodosNovos.forEach((dia, ranges) {
        ranges.sort(
          (a, b) => _timeOfDayToDouble(
            a.inicio,
          ).compareTo(_timeOfDayToDouble(b.inicio)),
        );
      });

      setState(() {
        periodosPorDia.clear();
        diasSelecionados.clear();
        periodosPorDia.addAll(periodosNovos);
        diasSelecionados.addAll(diasNovos);
        _isLoadingPeriods = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoadingPeriods = false);
      }
    }
  }

  double _timeOfDayToDouble(TimeOfDay time) => time.hour + time.minute / 60.0;

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m:00";
  }

  // --- LÓGICA DE VALIDAÇÃO
  void _validateDia(String dia) {
    setState(() {
      final periodos = periodosPorDia[dia] ?? [];
      if (periodos.isEmpty) {
        _errosDeHorario[dia] = null;
        return;
      }
      periodos.sort(
        (a, b) => _timeOfDayToDouble(
          a.inicio,
        ).compareTo(_timeOfDayToDouble(b.inicio)),
      );
      for (int i = 0; i < periodos.length; i++) {
        final atual = periodos[i];
        if (_timeOfDayToDouble(atual.fim) <= _timeOfDayToDouble(atual.inicio)) {
          _errosDeHorario[dia] = "Fim deve ser maior que o início.";
          return;
        }
        if (i < periodos.length - 1) {
          final proximo = periodos[i + 1];
          if (_timeOfDayToDouble(proximo.inicio) <
              _timeOfDayToDouble(atual.fim)) {
            _errosDeHorario[dia] = "Sobreposição de horários.";
            return;
          }
        }
      }
      _errosDeHorario[dia] = null;
    });
  }

  bool _validateTodosOsHorarios() {
    bool hasError = false;
    for (var dia in diasSelecionados.keys) {
      if (diasSelecionados[dia] == true) {
        _validateDia(dia);
        if (_errosDeHorario[dia] != null) hasError = true;
      }
    }
    return !hasError;
  }

  Future<void> _showConfirmDialog() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Verifica se tem algum dia selecionado
    if (!diasSelecionados.values.any((s) => s)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um dia.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_validateTodosOsHorarios()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corrija os erros nos horários.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Se a agenda já for principal, apenas salva. Se não, pergunta.
    if (widget.agenda.principal) {
      _executarAtualizacao(true);
      return;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Agenda Principal'),
          content: const Text('Definir esta como a agenda principal?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Não'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _executarAtualizacao(false);
              },
            ),
            ElevatedButton(
              child: const Text('Sim'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _executarAtualizacao(true);
              },
            ),
          ],
        );
      },
    );
  }

  // --- O CORAÇÃO DA NOVA LÓGICA DE SALVAMENTO ---
  Future<void> _executarAtualizacao(bool definirComoPrincipal) async {
    setState(() => _isSaving = true);

    // 1. Prepara a Agenda
    final agendaEditada = Agenda(
      id: widget.agenda.id,
      nome: _profissionalController.text.trim(),
      descricao: _describeController.text.trim(),
      duracao: int.parse(duracaoConsulta!.replaceAll(' min', '')),
      avisoAgendamento: _avisoController.text.trim(),
      principal: definirComoPrincipal,
    );

    // 2. Prepara as listas: Adicionar, Editar, Excluir
    final List<Map<String, dynamic>> listaAdicionar = [];
    final List<Map<String, dynamic>> listaEditar = [];
    final List<Map<String, dynamic>> listaExcluir = [];

    // A. Processa os Excluídos (que foram removidos via UI)
    for (var idRemovido in _idsParaExcluir) {
      listaExcluir.add({"id": int.parse(idRemovido)});
    }

    // B. Processa os Atuais (Adicionar ou Editar)
    for (var diaEntry in periodosPorDia.entries) {
      // Só processa se o dia estiver marcado como "Selecionado"
      if (diasSelecionados[diaEntry.key] == true) {
        final diaNumero = diasSemanaMap[diaEntry.key]!;

        for (var timeRange in diaEntry.value) {
          if (timeRange.id == null) {
            // SEM ID = NOVO (ADICIONAR)
            listaAdicionar.add({
              "diaDaSemana": diaNumero.toString(), // Back pede string? "3"
              "inicio": _formatTime(timeRange.inicio),
              "fim": _formatTime(timeRange.fim),
            });
          } else {
            // COM ID = EXISTENTE (EDITAR)
            // Nota: Mesmo que não tenha mudado, enviamos no editar para garantir consistência
            // ou pode adicionar lógica para verificar se mudou.
            // Pelo seu requisito, mandamos tudo o que sobrou como editar.
            listaEditar.add({
              "id": int.parse(timeRange.id!),
              "diaDaSemana": diaNumero.toString(),
              "inicio": _formatTime(timeRange.inicio),
              "fim": _formatTime(timeRange.fim),
            });
          }
        }
      } else {
        // Se o dia foi desmarcado, todos os seus períodos originais (que tinham ID) devem ser movidos para a lista de EXCLUIR, se ainda não estiverem lá.
        // Mas a lógica de _removerPeriodo já deve ter tratado disso se o usuário clicou no "-".
        // Caso o usuário apenas desmarcou o Checkbox do dia, precisa tratar aqui:
        for (var timeRange in diaEntry.value) {
          if (timeRange.id != null && !_idsParaExcluir.contains(timeRange.id)) {
            listaExcluir.add({"id": int.parse(timeRange.id!)});
          }
        }
      }
    }

    try {
      final agendaProvider = Provider.of<AgendaProvider>(
        context,
        listen: false,
      );

      await agendaProvider.salvarEdicaoInteligente(
        agenda: agendaEditada,
        adicionar: listaAdicionar,
        editar: listaEditar,
        excluir: listaExcluir,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- MANIPULAÇÃO DA UI ---
  void _adicionarPeriodo(String dia) {
    setState(() {
      final periodosDoDia = periodosPorDia.putIfAbsent(dia, () => []);
      if (periodosDoDia.length < 4) {
        if (periodosDoDia.isEmpty) {
          // Novo período sem ID
          periodosDoDia.add(
            TimeRange(
              id: null,
              inicio: const TimeOfDay(hour: 8, minute: 0),
              fim: const TimeOfDay(hour: 9, minute: 0),
            ),
          );
        } else {
          // Lógica para sugerir próximo horário
          periodosDoDia.sort(
            (a, b) => _timeOfDayToDouble(
              a.inicio,
            ).compareTo(_timeOfDayToDouble(b.inicio)),
          );
          final ultimoFim = periodosDoDia.last.fim;
          final novoInicio = ultimoFim;
          final novoFim = TimeOfDay(
            hour: novoInicio.hour + 1,
            minute: novoInicio.minute,
          );
          periodosDoDia.add(
            TimeRange(id: null, inicio: novoInicio, fim: novoFim),
          );
        }
        _validateDia(dia);
      }
    });
  }

  void _removerPeriodo(String dia, int index) {
    setState(() {
      final periodoRemovido = periodosPorDia[dia]![index];

      // Se tinha ID, vai para a lista de exclusão
      if (periodoRemovido.id != null) {
        _idsParaExcluir.add(periodoRemovido.id!);
      }

      periodosPorDia[dia]!.removeAt(index);
      _validateDia(dia);
    });
  }

  Future<void> _selecionarHora(
    BuildContext context,
    String dia,
    int index,
    bool isInicio,
  ) async {
    final periodosDoDia = periodosPorDia[dia]!;
    final initialTime = isInicio
        ? periodosDoDia[index].inicio
        : periodosDoDia[index].fim;

    final TimeOfDay? horaSelecionada = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (horaSelecionada != null) {
      setState(() {
        if (isInicio) {
          periodosDoDia[index].inicio = horaSelecionada;
        } else {
          periodosDoDia[index].fim = horaSelecionada;
        }
        _validateDia(dia);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // A UI permanece praticamente a mesma, apenas a lógica interna mudou
    return Scaffold(
      appBar: AppBar(title: Text('Editar: ${widget.agenda.nome}')),
      body: _isLoadingPeriods
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _profissionalController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _describeController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Informe a descrição' : null,
                    ),
                    const SizedBox(height: 20),

                    // Seletor de Dias (ChoiceChips)
                    const Text(
                      'Dias de Atendimento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: diasSemana.map((dia) {
                        return ChoiceChip(
                          label: Text(dia),
                          selected: diasSelecionados[dia]!,
                          onSelected: (selecionado) {
                            setState(() {
                              diasSelecionados[dia] = selecionado;
                              if (selecionado) {
                                if (periodosPorDia[dia] == null ||
                                    periodosPorDia[dia]!.isEmpty) {
                                  // Adiciona padrão se vazio
                                  periodosPorDia.putIfAbsent(
                                    dia,
                                    () => [
                                      TimeRange(
                                        id: null,
                                        inicio: const TimeOfDay(
                                          hour: 8,
                                          minute: 0,
                                        ),
                                        fim: const TimeOfDay(
                                          hour: 12,
                                          minute: 0,
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              } else {
                                // SE DESMARCAR O DIA, devemos considerar todos os períodos desse dia como removidos?
                                //manter os dados em 'periodosPorDia' caso ele remarque,
                                // mas na hora de salvar (_executarAtualizacao), nós verifica 'diasSelecionados'.
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Lista de horários por dia
                    Column(
                      children: diasSelecionados.entries
                          .where((e) => e.value)
                          .map((entry) {
                            final dia = entry.key;
                            final periodos = periodosPorDia[dia] ?? [];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          dia,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 8,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            ...periodos.asMap().entries.map((
                                              pEntry,
                                            ) {
                                              int idx = pEntry.key;
                                              TimeRange rng = pEntry.value;
                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ActionChip(
                                                    avatar: const Icon(
                                                      Icons.access_time,
                                                      size: 16,
                                                    ),
                                                    label: Text(
                                                      rng.inicio.format(
                                                        context,
                                                      ),
                                                    ),
                                                    onPressed: () =>
                                                        _selecionarHora(
                                                          context,
                                                          dia,
                                                          idx,
                                                          true,
                                                        ),
                                                  ),
                                                  const Text(' - '),
                                                  ActionChip(
                                                    avatar: const Icon(
                                                      Icons.access_time,
                                                      size: 16,
                                                    ),
                                                    label: Text(
                                                      rng.fim.format(context),
                                                    ),
                                                    onPressed: () =>
                                                        _selecionarHora(
                                                          context,
                                                          dia,
                                                          idx,
                                                          false,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.remove_circle,
                                                      color: Colors.red,
                                                      size: 20,
                                                    ),
                                                    onPressed: () =>
                                                        _removerPeriodo(
                                                          dia,
                                                          idx,
                                                        ),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                  ),
                                                ],
                                              );
                                            }),
                                            if (periodos.length < 4)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.add_circle,
                                                  color: Colors.green,
                                                ),
                                                onPressed: () =>
                                                    _adicionarPeriodo(dia),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_errosDeHorario[dia] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 50),
                                      child: Text(
                                        _errosDeHorario[dia]!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                    ),

                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: duracaoConsulta,
                      decoration: const InputDecoration(
                        labelText: 'Duração Padrão',
                      ),
                      items: opcoesDuracao
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => duracaoConsulta = v),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _avisoController,
                      decoration: const InputDecoration(
                        labelText: 'Aviso (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isSaving ? null : _showConfirmDialog,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Salvar Alterações'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
