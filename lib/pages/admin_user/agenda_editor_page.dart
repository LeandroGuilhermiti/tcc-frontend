import 'package:flutter/material.dart';

class AgendaEditorPage extends StatefulWidget {
  const AgendaEditorPage({super.key});

  @override
  State<AgendaEditorPage> createState() => _AgendaEditorPageState();
}

class _AgendaEditorPageState extends State<AgendaEditorPage> {
  final List<String> diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
  final Map<String, bool> diasSelecionados = {
    'Seg': false,
    'Ter': false,
    'Qua': false,
    'Qui': false,
    'Sex': false,
    'Sáb': false,
  };

  TimeOfDay horaInicio = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay horaFim = const TimeOfDay(hour: 17, minute: 0);

  String duracaoConsulta = '30 min';

  final List<String> opcoesDuracao = ['15 min', '30 min', '45 min', '60 min'];

  Future<void> _selecionarHora(BuildContext context, bool isInicio) async {
    final TimeOfDay? horaSelecionada = await showTimePicker(
      context: context,
      initialTime: isInicio ? horaInicio : horaFim,
    );
    if (horaSelecionada != null) {
      setState(() {
        if (isInicio) {
          horaInicio = horaSelecionada;
        } else {
          horaFim = horaSelecionada;
        }
      });
    }
  }

  void _salvarAgenda() {
    final dias = diasSelecionados.entries.where((e) => e.value).map((e) => e.key).toList();
    final agenda = {
      'diasAtendimento': dias,
      'horaInicio': '${horaInicio.hour}:${horaInicio.minute.toString().padLeft(2, '0')}',
      'horaFim': '${horaFim.hour}:${horaFim.minute.toString().padLeft(2, '0')}',
      'duracaoConsulta': duracaoConsulta,
    };
    // Aqui você pode fazer um POST ou salvar no Firestore/DynamoDB
    debugPrint('Agenda salva: $agenda');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Agenda salva com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editor de Agenda')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Dias de Atendimento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Wrap(
              children: diasSemana.map((dia) {
                return CheckboxListTile(
                  title: Text(dia),
                  value: diasSelecionados[dia],
                  onChanged: (bool? valor) {
                    setState(() {
                      diasSelecionados[dia] = valor ?? false;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Horários', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              title: Text('Início: ${horaInicio.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selecionarHora(context, true),
            ),
            ListTile(
              title: Text('Fim: ${horaFim.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selecionarHora(context, false),
            ),
            const SizedBox(height: 20),
            const Text('Duração da Consulta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
