import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home'),
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
              title: const Text('Editor agenda'),
              onTap: () => Navigator.pushNamed(context, '/editor'),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Consultar agendas'),
              onTap: () => Navigator.pushNamed(context, '/agendas'),
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
            startTime: date.add(const Duration(hours: 9)),
            endTime: date.add(const Duration(hours: 10)),
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
