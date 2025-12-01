import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/agenda_model.dart';
import '../../models/periodo_model.dart';
import '../../providers/agenda_provider.dart';
import '../../theme/app_theme.dart'; // Importa NnkColors

class TimeRange {
  String? id;
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
    'Seg': 1, 'Ter': 2, 'Qua': 3, 'Qui': 4, 'Sex': 5, 'Sáb': 6, 'Dom': 7,
  };
  final Map<int, String> diasSemanaMapInverso = {
    1: 'Seg', 2: 'Ter', 3: 'Qua', 4: 'Qui', 5: 'Sex', 6: 'Sáb', 7: 'Dom',
  };
  final List<String> diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  final Map<String, bool> diasSelecionados = {};
  final Map<String, List<TimeRange>> periodosPorDia = {};

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
    _avisoController = TextEditingController(text: widget.agenda.avisoAgendamento ?? '');
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
      final periodosExistentes = await provider.buscarPeriodosDaAgenda(widget.agenda.id!);

      final Map<String, List<TimeRange>> periodosNovos = {};
      final Map<String, bool> diasNovos = {
        for (var dia in diasSemana) dia: false,
      };

      for (var periodo in periodosExistentes) {
        final diaString = diasSemanaMapInverso[periodo.diaDaSemana];

        if (diaString != null) {
          diasNovos[diaString] = true;
          final timeRange = TimeRange(
            id: periodo.id,
            inicio: periodo.inicio,
            fim: periodo.fim,
          );
          periodosNovos.putIfAbsent(diaString, () => []).add(timeRange);
        }
      }

      periodosNovos.forEach((dia, ranges) {
        ranges.sort((a, b) => _timeOfDayToDouble(a.inicio).compareTo(_timeOfDayToDouble(b.inicio)));
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
          SnackBar(content: Text('Erro ao carregar: $e'), backgroundColor: NnkColors.vermelhoLacre),
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

  void _validateDia(String dia) {
    setState(() {
      final periodos = periodosPorDia[dia] ?? [];
      if (periodos.isEmpty) {
        _errosDeHorario[dia] = null;
        return;
      }
      periodos.sort((a, b) => _timeOfDayToDouble(a.inicio).compareTo(_timeOfDayToDouble(b.inicio)));
      for (int i = 0; i < periodos.length; i++) {
        final atual = periodos[i];
        if (_timeOfDayToDouble(atual.fim) <= _timeOfDayToDouble(atual.inicio)) {
          _errosDeHorario[dia] = "Fim deve ser maior que o início.";
          return;
        }
        if (i < periodos.length - 1) {
          final proximo = periodos[i + 1];
          if (_timeOfDayToDouble(proximo.inicio) < _timeOfDayToDouble(atual.fim)) {
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

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!diasSelecionados.values.any((s) => s)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um dia.'), backgroundColor: NnkColors.vermelhoLacre),
      );
      return;
    }

    if (!_validateTodosOsHorarios()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrija os erros nos horários.'), backgroundColor: NnkColors.vermelhoLacre),
      );
      return;
    }

    await _executarAtualizacao();
  }

  Future<void> _executarAtualizacao() async {
    setState(() => _isSaving = true);

    final agendaEditada = Agenda(
      id: widget.agenda.id,
      nome: _profissionalController.text.trim(),
      descricao: _describeController.text.trim(),
      duracao: int.parse(duracaoConsulta!.replaceAll(' min', '')),
      avisoAgendamento: _avisoController.text.trim(),
    );

    final List<Map<String, dynamic>> listaAdicionar = [];
    final List<Map<String, dynamic>> listaEditar = [];
    final List<Map<String, dynamic>> listaExcluir = [];

    for (var idRemovido in _idsParaExcluir) {
      listaExcluir.add({"id": int.parse(idRemovido)});
    }

    for (var diaEntry in periodosPorDia.entries) {
      if (diasSelecionados[diaEntry.key] == true) {
        final diaNumero = diasSemanaMap[diaEntry.key]!;

        for (var timeRange in diaEntry.value) {
          if (timeRange.id == null) {
            listaAdicionar.add({
              "diaDaSemana": diaNumero.toString(),
              "inicio": _formatTime(timeRange.inicio),
              "fim": _formatTime(timeRange.fim),
            });
          } else {
            listaEditar.add({
              "id": int.parse(timeRange.id!),
              "diaDaSemana": diaNumero.toString(),
              "inicio": _formatTime(timeRange.inicio),
              "fim": _formatTime(timeRange.fim),
            });
          }
        }
      } else {
        for (var timeRange in diaEntry.value) {
          if (timeRange.id != null && !_idsParaExcluir.contains(timeRange.id)) {
            listaExcluir.add({"id": int.parse(timeRange.id!)});
          }
        }
      }
    }

    try {
      final agendaProvider = Provider.of<AgendaProvider>(context, listen: false);

      await agendaProvider.salvarEdicaoInteligente(
        agenda: agendaEditada,
        adicionar: listaAdicionar,
        editar: listaEditar,
        excluir: listaExcluir,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grimório atualizado!'), backgroundColor: NnkColors.verdeErva),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro mágico: $e'), backgroundColor: NnkColors.vermelhoLacre),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _adicionarPeriodo(String dia) {
    setState(() {
      final periodosDoDia = periodosPorDia.putIfAbsent(dia, () => []);
      if (periodosDoDia.length < 4) {
        if (periodosDoDia.isEmpty) {
          periodosDoDia.add(
            TimeRange(
              id: null,
              inicio: const TimeOfDay(hour: 8, minute: 0),
              fim: const TimeOfDay(hour: 12, minute: 0),
            ),
          );
        } else {
          periodosDoDia.sort((a, b) => _timeOfDayToDouble(a.inicio).compareTo(_timeOfDayToDouble(b.inicio)));
          final ultimoFim = periodosDoDia.last.fim;
          final novoInicio = ultimoFim;
          final novoFim = TimeOfDay(hour: novoInicio.hour + 1, minute: novoInicio.minute);
          periodosDoDia.add(TimeRange(id: null, inicio: novoInicio, fim: novoFim));
        }
        _validateDia(dia);
      }
    });
  }

  void _removerPeriodo(String dia, int index) {
    setState(() {
      final periodoRemovido = periodosPorDia[dia]![index];

      if (periodoRemovido.id != null) {
        _idsParaExcluir.add(periodoRemovido.id!);
      }

      periodosPorDia[dia]!.removeAt(index);
      _validateDia(dia);
    });
  }

  Future<void> _selecionarHora(BuildContext context, String dia, int index, bool isInicio) async {
    final periodosDoDia = periodosPorDia[dia]!;
    final initialTime = isInicio ? periodosDoDia[index].inicio : periodosDoDia[index].fim;

    final TimeOfDay? horaSelecionada = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: NnkColors.papelAntigo,
              hourMinuteShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                side: BorderSide(color: NnkColors.ouroAntigo, width: 2),
              ),
              hourMinuteColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.selected) 
                      ? NnkColors.tintaCastanha 
                      : NnkColors.ouroClaro.withOpacity(0.3)),
              hourMinuteTextColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.selected) 
                      ? NnkColors.ouroAntigo 
                      : NnkColors.tintaCastanha),
              dayPeriodBorderSide: const BorderSide(color: NnkColors.ouroAntigo),
              dayPeriodColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.selected) ? NnkColors.tintaCastanha : Colors.transparent),
              dayPeriodTextColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.selected) ? NnkColors.papelAntigo : NnkColors.tintaCastanha),
              dialBackgroundColor: NnkColors.ouroClaro.withOpacity(0.5),
              dialHandColor: NnkColors.tintaCastanha,
              dialTextColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.selected) ? NnkColors.ouroAntigo : NnkColors.tintaCastanha),
              entryModeIconColor: NnkColors.ouroAntigo,
              helpTextStyle: const TextStyle(fontFamily: 'Cinzel', color: NnkColors.tintaCastanha, fontWeight: FontWeight.bold),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: NnkColors.tintaCastanha,
                textStyle: const TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child!,
        );
      },
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
    return Scaffold(
      backgroundColor: NnkColors.papelAntigo,
      appBar: AppBar(
        title: Text(
          'Editar: ${widget.agenda.nome}',
          style: const TextStyle(
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
            color: NnkColors.tintaCastanha
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: NnkColors.ouroAntigo.withOpacity(0.5),
            height: 1.0,
          ),
        ),
      ),
      body: _isLoadingPeriods
          ? const Center(child: CircularProgressIndicator(color: NnkColors.ouroAntigo))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // --- NOME E DESCRIÇÃO ---
                    TextFormField(
                      controller: _profissionalController,
                      style: const TextStyle(fontFamily: 'Alegreya', fontSize: 18),
                      decoration: const InputDecoration(labelText: 'Nome do Profissional'),
                      validator: (v) => v!.isEmpty ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _describeController,
                      style: const TextStyle(fontFamily: 'Alegreya', fontSize: 18),
                      decoration: const InputDecoration(labelText: 'Descrição da Agenda'),
                      validator: (v) => v!.isEmpty ? 'Informe a descrição' : null,
                    ),
                    const SizedBox(height: 24),

                    // --- DIAS DE ATENDIMENTO ---
                    const Text(
                      'Dias de Atendimento',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        fontFamily: 'Cinzel',
                        color: NnkColors.tintaCastanha
                      )
                    ),
                    const SizedBox(height: 10),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: diasSemana.map((dia) {
                        final isSelected = diasSelecionados[dia]!;
                        return ChoiceChip(
                          label: Text(
                            dia,
                            style: TextStyle(
                              color: isSelected ? Colors.white : NnkColors.tintaCastanha,
                              fontFamily: 'Alegreya',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: NnkColors.ouroAntigo,
                          backgroundColor: NnkColors.papelAntigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: NnkColors.ouroAntigo),
                          ),
                          onSelected: (selecionado) {
                            setState(() {
                              diasSelecionados[dia] = selecionado;
                              if (selecionado) {
                                if (periodosPorDia[dia] == null || periodosPorDia[dia]!.isEmpty) {
                                  periodosPorDia.putIfAbsent(
                                    dia,
                                    () => [TimeRange(id: null, inicio: const TimeOfDay(hour: 8, minute: 0), fim: const TimeOfDay(hour: 12, minute: 0))],
                                  );
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // --- PERIODOS ---
                    Column(
                      children: diasSelecionados.entries.where((e) => e.value).map((entry) {
                            final dia = entry.key;
                            final periodos = periodosPorDia[dia] ?? [];
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: NnkColors.ouroClaro.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: NnkColors.ouroAntigo.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // --- CABEÇALHO DO DIA ---
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: NnkColors.tintaCastanha,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          dia,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: NnkColors.ouroAntigo, fontFamily: 'Cinzel'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      
                                      // Botão Adicionar Período (+)
                                      if (periodos.length < 4)
                                        IconButton(
                                          icon: const Icon(Icons.add_circle, color: NnkColors.verdeErva),
                                          onPressed: () => _adicionarPeriodo(dia),
                                          tooltip: "Adicionar Períodos",
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // --- LISTA DE HORÁRIOS (WRAP) ---
                                  Wrap(
                                    spacing: 8.0, 
                                    runSpacing: 8.0, 
                                    children: periodos.asMap().entries.map((pEntry) {
                                      int idx = pEntry.key;
                                      TimeRange rng = pEntry.value;
                                      
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: NnkColors.papelAntigo,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: NnkColors.ouroAntigo.withOpacity(0.5)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ActionChip(
                                              avatar: const Icon(Icons.access_time, size: 14, color: NnkColors.tintaCastanha),
                                              label: Text(rng.inicio.format(context), style: const TextStyle(fontFamily: 'Alegreya', fontWeight: FontWeight.bold)),
                                              backgroundColor: NnkColors.papelAntigo,
                                              side: BorderSide.none, 
                                              onPressed: () => _selecionarHora(context, dia, idx, true),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 2.0),
                                              child: Icon(Icons.arrow_right_alt, size: 16, color: NnkColors.tintaCastanha),
                                            ),
                                            ActionChip(
                                              avatar: const Icon(Icons.access_time, size: 14, color: NnkColors.tintaCastanha),
                                              label: Text(rng.fim.format(context), style: const TextStyle(fontFamily: 'Alegreya', fontWeight: FontWeight.bold)),
                                              backgroundColor: NnkColors.papelAntigo,
                                              side: BorderSide.none,
                                              onPressed: () => _selecionarHora(context, dia, idx, false),
                                            ),
                                            const SizedBox(width: 4),
                                            InkWell(
                                              onTap: () => _removerPeriodo(dia, idx),
                                              child: const Icon(Icons.remove_circle_outline, color: NnkColors.vermelhoLacre, size: 20),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  
                                  if (_errosDeHorario[dia] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        _errosDeHorario[dia]!, 
                                        style: const TextStyle(color: NnkColors.vermelhoLacre, fontSize: 14, fontWeight: FontWeight.bold)
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),

                    const SizedBox(height: 24),
                    
                    // --- DURAÇÃO E AVISO ---
                    DropdownButtonFormField<String>(
                      value: duracaoConsulta,
                      onChanged: null, // Desabilitado
                      decoration: InputDecoration(
                        labelText: 'Duração Padrão (Imutável)',
                        filled: true,
                        fillColor: NnkColors.cinzaSuave.withOpacity(0.3), // Visual desabilitado
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: NnkColors.cinzaSuave.withOpacity(0.5))),
                      ),
                      items: opcoesDuracao
                          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: NnkColors.cinzaSuave))))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _avisoController,
                      style: const TextStyle(fontFamily: 'Alegreya', fontSize: 18),
                      decoration: const InputDecoration(
                        labelText: 'Aviso Agendamento (Opcional)', 
                        prefixIcon: Icon(Icons.info_outline)
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // --- BOTÃO SALVAR (Estilizado) ---
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NnkColors.tintaCastanha,
                          foregroundColor: NnkColors.ouroAntigo,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: NnkColors.ouroAntigo, width: 1.5),
                          ),
                        ),
                        onPressed: _isSaving ? null : _handleSave,
                        child: _isSaving
                            ? const SizedBox(
                                height: 24, 
                                width: 24, 
                                child: CircularProgressIndicator(color: NnkColors.ouroAntigo)
                              )
                            : const Text(
                                'SALVAR ALTERAÇÕES',
                                style: TextStyle(
                                  fontFamily: 'Cinzel', 
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
    );
  }
}