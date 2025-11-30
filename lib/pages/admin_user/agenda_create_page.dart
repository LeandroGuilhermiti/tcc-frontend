import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/agenda_model.dart';
import '../../models/periodo_model.dart';
import '../../providers/agenda_provider.dart';

class TimeRange {
  TimeOfDay inicio;
  TimeOfDay fim;
  TimeRange({required this.inicio, required this.fim});
}

class AgendaCreatePage extends StatefulWidget {
  const AgendaCreatePage({super.key});

  @override
  State<AgendaCreatePage> createState() => _AgendaCreatePageState();
}

class _AgendaCreatePageState extends State<AgendaCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _profissionalController = TextEditingController();
  final TextEditingController _describeController = TextEditingController();
  final TextEditingController _avisoController = TextEditingController();

  final Map<String, int> diasSemanaMap = {
    'Seg': 1, 'Ter': 2, 'Qua': 3, 'Qui': 4, 'Sex': 5, 'Sáb': 6, 'Dom': 7,
  };
  final List<String> diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  final Map<String, bool> diasSelecionados = {
    'Seg': false, 'Ter': false, 'Qua': false, 'Qui': false, 'Sex': false, 'Sáb': false, 'Dom': false,
  };

  final Map<String, List<TimeRange>> periodosPorDia = {};
  final Map<String, String?> _errosDeHorario = {};

  String? duracaoConsulta = '30 min';
  final List<String> opcoesDuracao = ['15 min', '30 min', '45 min', '60 min'];
  bool _isSaving = false;

  double _timeOfDayToDouble(TimeOfDay time) => time.hour + time.minute / 60.0;

  void _validateDia(String dia) {
    setState(() {
      final periodos = periodosPorDia[dia] ?? [];
      if (periodos.isEmpty) {
        _errosDeHorario[dia] = null;
        return;
      }

      periodos.sort(
        (a, b) => _timeOfDayToDouble(a.inicio).compareTo(_timeOfDayToDouble(b.inicio)),
      );

      for (int i = 0; i < periodos.length; i++) {
        final atual = periodos[i];
        if (_timeOfDayToDouble(atual.fim) <= _timeOfDayToDouble(atual.inicio)) {
          _errosDeHorario[dia] = "Período ${i + 1} é inválido (fim ≤ início).";
          return; 
        }
        if (i < periodos.length - 1) {
          final proximo = periodos[i + 1];
          if (_timeOfDayToDouble(proximo.inicio) < _timeOfDayToDouble(atual.fim)) {
            _errosDeHorario[dia] = "Período ${i + 2} está sobreposto ao anterior.";
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
        if (_errosDeHorario[dia] != null) {
          hasError = true;
        }
      }
    }
    return !hasError;
  }

  Future<void> _handleSave() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    final isAnyDaySelected = diasSelecionados.values.any((selecionado) => selecionado);
    final areHorariosValid = _validateTodosOsHorarios();

    if (!isFormValid || !isAnyDaySelected || !areHorariosValid) {
      if (!isAnyDaySelected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione pelo menos um dia de atendimento.'), backgroundColor: Colors.red),
        );
      } else if (!areHorariosValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Existem erros nos horários. Por favor, corrija-os.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    await _executarSalvamento();
  }

  Future<void> _executarSalvamento() async {
    setState(() {
      _isSaving = true;
    });

    final agenda = Agenda(
      nome: _profissionalController.text.trim(),
      descricao: _describeController.text.trim(),
      duracao: int.parse(duracaoConsulta!.replaceAll(' min', '')),
      avisoAgendamento: _avisoController.text.trim(),
    );

    final List<Periodo> periodosParaSalvar = [];
    for (var diaEntry in periodosPorDia.entries) {
      if (diasSelecionados[diaEntry.key] ?? false) {
        final diaKey = diaEntry.key;
        final diaNumero = diasSemanaMap[diaKey]!;
        for (var timeRange in diaEntry.value) {
          periodosParaSalvar.add(
            Periodo(
              idAgenda: '',
              diaDaSemana: diaNumero,
              inicio: timeRange.inicio,
              fim: timeRange.fim,
            ),
          );
        }
      }
    }

    try {
      final agendaProvider = Provider.of<AgendaProvider>(context, listen: false);
      
      final Agenda agendaCriada = await agendaProvider.adicionarAgendaCompleta(agenda, periodosParaSalvar);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Agenda Salva!'),
            content: const Text(
              'A agenda foi criada com sucesso.\n\nDeseja adicionar bloqueios (férias, ausências) para esta agenda agora?'
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Não, concluir'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacementNamed(
                    '/bloqueios/create',
                    arguments: agendaCriada, 
                  );
                },
                child: const Text('Sim, adicionar bloqueios'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar agenda: ${e.toString()}')),
        );
        setState(() => _isSaving = false); 
      }
    }
  }

  void _adicionarPeriodo(String dia) {
    setState(() {
      final periodosDoDia = periodosPorDia[dia]!;
      if (periodosDoDia.length < 4) {
        if (periodosDoDia.isEmpty) {
          periodosDoDia.add(TimeRange(inicio: const TimeOfDay(hour: 8, minute: 0), fim: const TimeOfDay(hour: 9, minute: 0)));
        } else {
          periodosDoDia.sort((a, b) => _timeOfDayToDouble(a.inicio).compareTo(_timeOfDayToDouble(b.inicio)));
          final ultimoFim = periodosDoDia.last.fim;
          final novoInicio = ultimoFim;
          final novoFim = TimeOfDay(hour: novoInicio.hour + 1, minute: novoInicio.minute);
          periodosDoDia.add(TimeRange(inicio: novoInicio, fim: novoFim));
        }
        _validateDia(dia);
      }
    });
  }

  void _removerPeriodo(String dia, int index) {
    setState(() {
      periodosPorDia[dia]!.removeAt(index);
      _validateDia(dia);
    });
  }

  Future<void> _selecionarHora(BuildContext context, String dia, int index, bool isInicio) async {
    final periodosDoDia = periodosPorDia[dia]!;
    final initialTime = isInicio ? periodosDoDia[index].inicio : periodosDoDia[index].fim;

    final TimeOfDay? horaSelecionada = await showTimePicker(context: context, initialTime: initialTime);

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
      appBar: AppBar(title: const Text('Criar Nova Agenda')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _profissionalController,
                decoration: const InputDecoration(labelText: 'Nome do Profissional ou da Agenda', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Por favor, informe o nome.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _describeController,
                decoration: const InputDecoration(labelText: 'Descrição breve', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Por favor, informe a descrição.' : null,
              ),
              const SizedBox(height: 20),
              const Text('Dias de Atendimento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: diasSemana.map((dia) {
                  return ChoiceChip(
                    label: Text(dia),
                    selected: diasSelecionados[dia]!,
                    onSelected: (bool selecionado) {
                      setState(() {
                        diasSelecionados[dia] = selecionado;
                        if (selecionado) {
                          periodosPorDia.putIfAbsent(dia, () => [TimeRange(inicio: const TimeOfDay(hour: 8, minute: 0), fim: const TimeOfDay(hour: 9, minute: 0))]);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Column(
                children: diasSelecionados.entries.where((e) => e.value).map((entry) {
                  final dia = entry.key;
                  final periodos = periodosPorDia[dia] ?? [];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 40, child: Text(dia, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent))),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Wrap(
                                spacing: 6.0,
                                runSpacing: 8.0,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ...periodos.asMap().entries.map((periodoEntry) {
                                    int index = periodoEntry.key;
                                    TimeRange range = periodoEntry.value;
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ActionChip(avatar: const Icon(Icons.access_time, size: 16), label: Text(range.inicio.format(context)), onPressed: () => _selecionarHora(context, dia, index, true)),
                                        const Padding(padding: EdgeInsets.symmetric(horizontal: 2.0), child: Text('-')),
                                        ActionChip(avatar: const Icon(Icons.access_time, size: 16), label: Text(range.fim.format(context)), onPressed: () => _selecionarHora(context, dia, index, false)),
                                        if (periodos.length > 1)
                                          IconButton(padding: const EdgeInsets.only(left: 4), constraints: const BoxConstraints(), icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20), onPressed: () => _removerPeriodo(dia, index)),
                                      ],
                                    );
                                  }),
                                  if (periodos.length < 4)
                                    IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => _adicionarPeriodo(dia), tooltip: 'Adicionar período'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_errosDeHorario[dia] != null)
                          Padding(padding: const EdgeInsets.only(top: 8.0, left: 50), child: Text(_errosDeHorario[dia]!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: duracaoConsulta,
                decoration: const InputDecoration(labelText: 'Duração Padrão da Consulta', border: OutlineInputBorder()),
                items: opcoesDuracao.map((String valor) {
                  return DropdownMenuItem<String>(value: valor, child: Text(valor));
                }).toList(),
                onChanged: (String? novoValor) { setState(() { duracaoConsulta = novoValor; }); },
                validator: (value) => value == null ? 'Por favor, selecione a duração.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _avisoController,
                decoration: const InputDecoration(labelText: 'Aviso do Agendamento (opcional)', hintText: 'Ex: "Trazer exames anteriores"', border: OutlineInputBorder(), prefixIcon: Icon(Icons.info_outline)),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 18)),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Salvar Agenda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}