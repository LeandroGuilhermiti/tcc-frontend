import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:tcc_frontend/theme/app_colors.dart';

import 'package:tcc_frontend/models/agendamento_model.dart';
import 'package:tcc_frontend/models/bloqueio_model.dart';
import 'package:tcc_frontend/models/periodo_model.dart';

import 'package:tcc_frontend/providers/agendamento_provider.dart';
import 'package:tcc_frontend/providers/bloqueio_provider.dart';
import 'package:tcc_frontend/providers/periodo_provider.dart';

class HomePageAdmin extends StatefulWidget {
  const HomePageAdmin({super.key});

  @override
  State<HomePageAdmin> createState() => _HomePageAdminState();
}

class _HomePageAdminState extends State<HomePageAdmin> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _mostrarTabela = true; // true = TableCalendar, false = SfCalendar

  Map<DateTime, List<String>> _eventos = {};

  List<String> _getEventosDoDia(DateTime dia) {
    return _eventos[dia] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _eventos = {
      DateTime.utc(2025, 7, 7): ['Consulta com João', 'Retorno Maria'],
      DateTime.utc(2025, 7, 8): ['Avaliação inicial Carla'],
    };
  }

  void _abrirDialogoAgendamento(BuildContext context, DateTime dataSelecionada) async {
    final TextEditingController eventoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Novo Agendamento'),
          content: TextField(
            controller: eventoController,
            decoration: const InputDecoration(
              labelText: 'Descrição do evento',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final evento = eventoController.text.trim();
                if (evento.isNotEmpty) {
                  // Usa o horário exato do quadradinho clicado
                  final DateTime agendamento = dataSelecionada;

                  // Limita a 1 agendamento por horário
                  if (!_eventos.containsKey(agendamento)) {
                    setState(() {
                      _eventos[agendamento] = [evento];
                    });
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Já existe agendamento neste horário!')),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _abrirDialogoEdicao(BuildContext context, DateTime dataSelecionada, String descricaoAtual) {
    final TextEditingController eventoController = TextEditingController(text: descricaoAtual);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Agendamento'),
          content: TextField(
            controller: eventoController,
            decoration: const InputDecoration(
              labelText: 'Descrição do evento',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final eventoEditado = eventoController.text.trim();
                if (eventoEditado.isNotEmpty) {
                  setState(() {
                    _eventos[dataSelecionada] = [eventoEditado];
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Admin Home'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
          children: [
            const Text('Menu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar),
              title: const Text('Editar agenda'),
              onTap: () => Navigator.pushNamed(context, '/editor'),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Cadastrar usuários'),
              onTap: () => Navigator.pushNamed(context, '/cadastro'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Consultar pacientes'),
              onTap: () => Navigator.pushNamed(context, '/pacientes'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          ToggleButtons(
            isSelected: [_mostrarTabela, !_mostrarTabela],
            onPressed: (index) {
              setState(() {
                _mostrarTabela = index == 0;
              });
            },
            color:AppColors.details,            // texto quando não selecionado
            selectedColor: Colors.white,        // texto quando selecionado
            fillColor: AppColors.details,       // fundo quando selecionado
            borderColor: Colors.blueGrey,       // borda quando não selecionado
            selectedBorderColor: AppColors.details, // borda quando selecionado
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Mês')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Semana')),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _mostrarTabela
                ? Column(
                    children: [
                      TableCalendar<String>(
                        focusedDay: _focusedDay,
                        firstDay: DateTime.utc(2025),
                        lastDay: DateTime.utc(2035),
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Mês'
                        },
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        eventLoader: _getEventosDoDia,
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarStyle: const CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          children: _getEventosDoDia(_selectedDay!).map((evento) {
                            return ListTile(
                              title: Text(evento),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  )
                : SfCalendar(
                    view: CalendarView.week,
                    firstDayOfWeek: 1,
                    timeSlotViewSettings: const TimeSlotViewSettings(
                      startHour: 8,
                      endHour: 18,
                      timeInterval: Duration(minutes: 30),
                      timeIntervalHeight: 40,
                      timeRulerSize: 80,
                      timeFormat: 'h:mm a',
                    ),
                    dataSource: _getDataSource(),
                      headerStyle: CalendarHeaderStyle(
                        backgroundColor: AppColors.backgroundLight,  
                        textAlign: TextAlign.center,  
                        textStyle: TextStyle(
                        color: AppColors.textPrimary,     
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        ),
                      ),
                    onTap: (CalendarTapDetails details) {
                      if (details.targetElement == CalendarElement.appointment && details.appointments != null) {
                        final Appointment appt = details.appointments!.first;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(appt.subject),
                            content: Text('Horário: ${appt.startTime.hour}:${appt.startTime.minute.toString().padLeft(2, '0')}'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Fechar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Fecha o dialog de detalhes
                                  _abrirDialogoEdicao(context, appt.startTime, appt.subject);
                                },
                                child: const Text('Editar'),
                              ),
                            ],
                          ),
                        );
                      } else if (details.targetElement == CalendarElement.calendarCell && details.date != null) {
                        _abrirDialogoAgendamento(context, details.date!);
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  MeetingDataSource _getDataSource() {
    final List<Appointment> appointments = [];

    _eventos.forEach((date, eventos) {
      for (var evento in eventos) {
        appointments.add(
          Appointment(
            startTime: date,
            endTime: date.add(const Duration(minutes: 30)),
            subject: evento,
            color: Colors.blue,
          ),
        );
      }
    });

    return MeetingDataSource(appointments);
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
