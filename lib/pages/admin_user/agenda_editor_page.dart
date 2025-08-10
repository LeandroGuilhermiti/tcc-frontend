import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tcc_frontend/models/agenda_model.dart';  
import 'package:tcc_frontend/models/periodo_model.dart';

class AgendaEditorPage extends StatefulWidget {
  const AgendaEditorPage({super.key});

  @override
  State<AgendaEditorPage> createState() => _AgendaEditorPageState();
}

class _AgendaEditorPageState extends State<AgendaEditorPage> {
  final TextEditingController _profissionalController = TextEditingController();
  final TextEditingController _describeController = TextEditingController();

  final List<String> diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
  final Map<String, bool> diasSelecionados = {
    'Seg': false,
    'Ter': false,
    'Qua': false,
    'Qui': false,
    'Sex': false,
    'Sáb': false,
  };

  // Controle do Horário Fixo
  bool horarioFixo = false;
  TimeOfDay horaInicioFixo = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay horaFimFixo = const TimeOfDay(hour: 17, minute: 0);

  // Horários individuais para cada dia (se horarioFixo == false)
  final Map<String, TimeOfDay> inicioPorDia = {};
  final Map<String, TimeOfDay> fimPorDia = {};

  String duracaoConsulta = '30 min';
  final List<String> opcoesDuracao = ['15 min', '30 min', '45 min', '60 min'];

  Future<void> _selecionarHora(BuildContext context, bool isInicio, {String? dia}) async {
    TimeOfDay initialTime;
    if (horarioFixo) {
      initialTime = isInicio ? horaInicioFixo : horaFimFixo;
    } else {
      if (dia == null) return;
      initialTime = isInicio ? (inicioPorDia[dia] ?? const TimeOfDay(hour: 8, minute: 0)) : (fimPorDia[dia] ?? const TimeOfDay(hour: 17, minute: 0));
    }

    final TimeOfDay? horaSelecionada = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (horaSelecionada != null) {
      setState(() {
        if (horarioFixo) {
          if (isInicio) {
            horaInicioFixo = horaSelecionada;
          } else {
            horaFimFixo = horaSelecionada;
          }
        } else {
          if (dia == null) return;
          if (isInicio) {
            inicioPorDia[dia] = horaSelecionada;
          } else {
            fimPorDia[dia] = horaSelecionada;
          }
        }
      });
    }
  }

Future<void> _salvarAgenda() async {
  if (_profissionalController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informe o nome do profissional')),
    );
    return;
  }

  final agenda = Agenda(
    nome: _profissionalController.text.trim(),
    descricao: _describeController.text.trim(),
    duracao: duracaoConsulta,
    aviso: "Nenhum aviso",
  );

  final periodos = diasSelecionados.entries
      .where((e) => e.value)
      .map((e) {
        if (horarioFixo) {
          return Periodo(
            diaDaSemana: e.key,
            inicio: "${horaInicioFixo.hour}:${horaInicioFixo.minute.toString().padLeft(2, '0')}",
            fim: "${horaFimFixo.hour}:${horaFimFixo.minute.toString().padLeft(2, '0')}",
          );
        } else {
          return Periodo(
            diaDaSemana: e.key,
            inicio: "${(inicioPorDia[e.key] ?? const TimeOfDay(hour: 8, minute: 0)).hour}:${(inicioPorDia[e.key] ?? const TimeOfDay(hour: 8, minute: 0)).minute.toString().padLeft(2, '0')}",
            fim: "${(fimPorDia[e.key] ?? const TimeOfDay(hour: 17, minute: 0)).hour}:${(fimPorDia[e.key] ?? const TimeOfDay(hour: 17, minute: 0)).minute.toString().padLeft(2, '0')}",
          );
        }
      })
      .toList();

  final payload = {
    "agenda": agenda.toJson(),
    "periodos": periodos.map((p) => p.toJson()).toList()
  };
  
  // Print JSON legível no console
  debugPrint(const JsonEncoder.withIndent('  ').convert(payload));

  final baseUrl = dotenv.env['API_BASE_URL']!;
  final url = Uri.parse('$baseUrl/agenda');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode == 201) {
      debugPrint('Agenda salva no backend: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agenda salva com sucesso!')),
      );
    } else {
      debugPrint('Erro ao salvar agenda: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar agenda: ${response.statusCode}')),
      );
    }
  } catch (e) {
    debugPrint('Exceção ao salvar agenda: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro de conexão com o servidor')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editor de Agenda')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _profissionalController,
              decoration: const InputDecoration(
                labelText: 'Nome do Profissional',
                hintText: 'Ex.: Dr. João Silva',
              ),
            ),
            TextField(
              controller: _describeController,
              decoration: const InputDecoration(
                labelText: 'Descrição breve',
                hintText: 'Ex.: Insira uma Descrição',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Dias de Atendimento',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Wrap(
              children: diasSemana.map((dia) {
                return CheckboxListTile(
                  title: Text(dia),
                  value: diasSelecionados[dia],
                  onChanged: (bool? valor) {
                    setState(() {
                      diasSelecionados[dia] = valor ?? false;
                      // Inicializa horários individuais ao selecionar dias se horarioFixo == false
                      if (!horarioFixo && valor == true) {
                        inicioPorDia.putIfAbsent(dia, () => const TimeOfDay(hour: 8, minute: 0));
                        fimPorDia.putIfAbsent(dia, () => const TimeOfDay(hour: 17, minute: 0));
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            SwitchListTile(
              title: const Text('Horário Fixo para todos os dias'),
              value: horarioFixo,
              onChanged: (bool value) {
                setState(() {
                  horarioFixo = value;
                  // Se ativou horário fixo, limpa horários individuais (não usados)
                  if (horarioFixo) {
                    inicioPorDia.clear();
                    fimPorDia.clear();
                  } else {
                    // Se desativou horário fixo, inicializa horários individuais para dias selecionados
                    for (var dia in diasSelecionados.entries.where((e) => e.value).map((e) => e.key)) {
                      inicioPorDia.putIfAbsent(dia, () => const TimeOfDay(hour: 8, minute: 0));
                      fimPorDia.putIfAbsent(dia, () => const TimeOfDay(hour: 17, minute: 0));
                    }
                  }
                });
              },
            ),

            const SizedBox(height: 10),

            // Se horário fixo, mostra apenas um par de seleção de horários
            if (horarioFixo) ...[
              ListTile(
                title: Text('Início: ${horaInicioFixo.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selecionarHora(context, true),
              ),
              ListTile(
                title: Text('Fim: ${horaFimFixo.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selecionarHora(context, false),
              ),
            ] else ...[
              // Se não for fixo, mostra horário individual para cada dia selecionado
              Column(
                children: diasSelecionados.entries.where((e) => e.value).map((entry) {
                  final dia = entry.key;
                  return ListTile(
                    title: Text('$dia'),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text('Início: ${inicioPorDia[dia]?.format(context) ?? '08:00'}'),
                            trailing: const Icon(Icons.access_time),
                            onTap: () => _selecionarHora(context, true, dia: dia),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text('Fim: ${fimPorDia[dia]?.format(context) ?? '17:00'}'),
                            trailing: const Icon(Icons.access_time),
                            onTap: () => _selecionarHora(context, false, dia: dia),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),
            const Text('Duração da Consulta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: duracaoConsulta,
              isExpanded: true,
              items: opcoesDuracao.map((String valor) {
                return DropdownMenuItem<String>(
                  value: valor,
                  child: Text(valor),
                );
              }).toList(),
              onChanged: (String? novoValor) {
                setState(() {
                  duracaoConsulta = novoValor!;
                });
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _salvarAgenda,
              child: const Text('Salvar Agenda'),
            ),
          ],
        ),
      ),
    );
  }
}
