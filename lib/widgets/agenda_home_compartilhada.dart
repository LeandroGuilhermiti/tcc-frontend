import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../theme/app_theme.dart'; 
import '../models/agendamento_model.dart';
import '../models/bloqueio_model.dart';
import '../models/periodo_model.dart';
import '../models/user_model.dart';
import '../models/agenda_model.dart';

import '../providers/agendamento_provider.dart';
import '../providers/bloqueio_provider.dart';
import '../providers/periodo_provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_controller.dart';

class SharedAgendaCalendar extends StatefulWidget {
  final Agenda agenda;
  
  // Callbacks para definir o comportamento ao clicar
  final Function(Appointment, BuildContext) onAppointmentTap;
  final Function(DateTime, BuildContext) onSlotTap;

  const SharedAgendaCalendar({
    super.key,
    required this.agenda,
    required this.onAppointmentTap,
    required this.onSlotTap,
  });

  @override
  State<SharedAgendaCalendar> createState() => _SharedAgendaCalendarState();
}

class _SharedAgendaCalendarState extends State<SharedAgendaCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isMonthView = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarDadosIniciais());
  }

  void _carregarDadosIniciais() {
    final idAgenda = widget.agenda.id!;
    debugPrint("[SharedCalendar] Carregando dados para Agenda ID: $idAgenda");
    
    Provider.of<BloqueioProvider>(context, listen: false).carregarBloqueios(idAgenda);
    Provider.of<PeriodoProvider>(context, listen: false).carregarPeriodos(idAgenda);
    Provider.of<AgendamentoProvider>(context, listen: false).carregarAgendamentos(idAgenda: idAgenda);
    Provider.of<UsuarioProvider>(context, listen: false).buscarUsuarios();
  }

  // --- LÓGICA DE NEGÓCIO ---

  Set<int> _getDiasDeAtendimento(List<Periodo> periodos) {
    return periodos.map((p) => p.diaDaSemana).toSet();
  }

  ({double startHour, double endHour}) _getHorariosDeAtendimento(List<Periodo> periodos) {
    if (periodos.isEmpty) return (startHour: 8, endHour: 18);
    
    double timeToDouble(TimeOfDay time) => time.hour + time.minute / 60.0;
    
    final double minStartHour = periodos
        .map((p) => timeToDouble(p.inicio))
        .reduce((a, b) => min(a, b));
    final double maxEndHour = periodos
        .map((p) => timeToDouble(p.fim))
        .reduce((a, b) => max(a, b));
        
    return (
      startHour: (minStartHour).floorToDouble(),
      endHour: (maxEndHour).ceilToDouble(),
    );
  }

  List<TimeRegion> _getRegionsDeBloqueio(
    List<Periodo> periodos,
    List<Bloqueio> bloqueios,
    double globalStart,
    double globalEnd,
  ) {
    final List<TimeRegion> regions = [];
    final Color corIntervalo = NnkColors.cinzaSuave.withOpacity(0.3);
    final Color corFeriado = const Color(0xFFEEEEEE); 

    // 1. Intervalos (Gaps)
    if (periodos.isNotEmpty) {
      final Map<int, String> weekDayMap = {
        1: 'MO', 2: 'TU', 3: 'WE', 4: 'TH', 5: 'FR', 6: 'SA', 7: 'SU'
      };
      final Map<int, List<Periodo>> periodosPorDia = {};
      for (var p in periodos) {
        periodosPorDia.putIfAbsent(p.diaDaSemana, () => []).add(p);
      }
      double toDouble(TimeOfDay t) => t.hour + t.minute / 60.0;

      periodosPorDia.forEach((dia, lista) {
        if (lista.isEmpty) return;
        lista.sort((a, b) => toDouble(a.inicio).compareTo(toDouble(b.inicio)));

        void addGapRegion(double start, double end, String label) {
          if (start >= end) return;
          final int dayOffset = dia - 1; 
          final DateTime baseDate = DateTime(2024, 1, 1).add(Duration(days: dayOffset));
          
          regions.add(TimeRegion(
            startTime: DateTime(baseDate.year, baseDate.month, baseDate.day, start.floor(), ((start % 1) * 60).round()),
            endTime: DateTime(baseDate.year, baseDate.month, baseDate.day, end.floor(), ((end % 1) * 60).round()),
            recurrenceRule: 'FREQ=WEEKLY;BYDAY=${weekDayMap[dia]}',
            color: corIntervalo,
            text: label,
            textStyle: const TextStyle(color: Colors.black54, fontSize: 10),
            enablePointerInteraction: false,
          ));
        }

        for (int i = 0; i < lista.length - 1; i++) {
          double currentEnd = toDouble(lista[i].fim);
          double nextStart = toDouble(lista[i+1].inicio);
          if (nextStart > currentEnd) {
            addGapRegion(currentEnd, nextStart, "Intervalo");
          }
        }
      });
    }

    // 2. Feriados
    for (var bloqueio in bloqueios) {
      if (bloqueio.duracao >= 8) {
        regions.add(TimeRegion(
          startTime: bloqueio.dataHora,
          endTime: bloqueio.dataHora.add(const Duration(hours: 24)),
          color: corFeriado,
          text: bloqueio.descricao,
          textStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
          enablePointerInteraction: false,
        ));
      }
    }
    return regions;
  }

  @override
  Widget build(BuildContext context) {
    final periodoProvider = context.watch<PeriodoProvider>();
    final agendamentoProvider = context.watch<AgendamentoProvider>();
    final bloqueioProvider = context.watch<BloqueioProvider>();
    final usuarioProvider = context.watch<UsuarioProvider>();
    
    // --- NOVO: OBTER DADOS DE AUTENTICAÇÃO ---
    final auth = context.watch<AuthController>();
    // -----------------------------------------

    final bool isLoading = periodoProvider.isLoading ||
        agendamentoProvider.isLoading ||
        bloqueioProvider.isLoading ||
        usuarioProvider.isLoading;

    final int duracaoSegura = (widget.agenda.duracao > 0) ? widget.agenda.duracao : 30;

    final List<Periodo> periodos = periodoProvider.periodos;
    final List<Bloqueio> bloqueios = bloqueioProvider.bloqueios;
    final Set<int> diasDeAtendimento = _getDiasDeAtendimento(periodos);
    final horarios = _getHorariosDeAtendimento(periodos);

    final Set<String> datasBloqueadas = {};
    for (final bloqueio in bloqueios) {
      if (bloqueio.duracao >= 8) {
        datasBloqueadas.add(DateFormat('yyyy-MM-dd').format(bloqueio.dataHora));
      }
    }

    final List<TimeRegion> specialRegions = _getRegionsDeBloqueio(
      periodos,
      bloqueios,
      horarios.startHour,
      horarios.endHour,
    );

    final dataSource = _getDataSourceCombinado(
      agendamentoProvider.agendamentos,
      bloqueios,
      usuarioProvider.usuarios,
      duracaoSegura,
      auth, // <-- Passamos o auth para a função de dados
    );

    return Column(
      children: [
        _buildViewToggler(),
        const SizedBox(height: 8),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isMonthView
                  ? _buildMonthView(dataSource, duracaoSegura, diasDeAtendimento, datasBloqueadas)
                  : _buildWeekView(dataSource, duracaoSegura, diasDeAtendimento, datasBloqueadas, horarios, specialRegions),
        ),
      ],
    );
  }

  Widget _buildViewToggler() {
    return ToggleButtons(
      isSelected: [_isMonthView, !_isMonthView],
      onPressed: (index) => setState(() => _isMonthView = index == 0),
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      children: const [
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Mês')),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Semana')),
      ],
    );
  }

  Widget _buildMonthView(MeetingDataSource dataSource, int duracaoDaAgenda, Set<int> diasDeAtendimento, Set<String> datasBloqueadas) {
    return Column(
      children: [
        TableCalendar(
          locale: 'pt_BR',
          focusedDay: _focusedDay,
          firstDay: DateTime.utc(2022),
          lastDay: DateTime.utc(2050),
          daysOfWeekHeight: 40.0,  //espaçamento para cabeçalho dos dias da semana no modo mês
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false, // <-- ESCONDE O BOTÃO 2 weeks
            titleCentered: true, //Centraliza "novembro de 2025"
            headerMargin: EdgeInsets.only(bottom: 8.0),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: NnkColors.marromEscuro),
            weekendStyle: TextStyle(color: NnkColors.vermelho.withOpacity(0.6)),
          ),
          enabledDayPredicate: (day) {
            final bool isDiaDeAtendimento = diasDeAtendimento.contains(day.weekday);
            if (!isDiaDeAtendimento) return false;
            final String dataFormatada = DateFormat('yyyy-MM-dd').format(day);
            return !datasBloqueadas.contains(dataFormatada);
          },
          calendarBuilders: CalendarBuilders(
            disabledBuilder: (context, day, focusedDay) => Center(child: Text(day.day.toString(), style: TextStyle(color: NnkColors.cinzaSuave.withOpacity(0.5)))),
            outsideBuilder: (context, day, focusedDay) => Center(child: Text(day.day.toString(), style: TextStyle(color: NnkColors.cinzaSuave.withOpacity(0.5)))),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            final String dataFormatada = DateFormat('yyyy-MM-dd').format(selectedDay);
            if (!diasDeAtendimento.contains(selectedDay.weekday) || datasBloqueadas.contains(dataFormatada)) return;
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) => dataSource.getEventsForDay(day),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withOpacity(0.5), shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
            disabledTextStyle: TextStyle(color: NnkColors.cinzaSuave.withOpacity(0.5)),
          ),
          calendarFormat: CalendarFormat.month,
          availableGestures: AvailableGestures.horizontalSwipe,
        ),
        const Divider(),
        Expanded(
          child: _selectedDay == null
              ? const Center(child: Text("Selecione um dia para ver os detalhes."))
              : Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80.0),
                      itemCount: dataSource.getEventsForDay(_selectedDay!).length,
                      itemBuilder: (context, index) {
                        final appointment = dataSource.getEventsForDay(_selectedDay!)[index];
                        return ListTile(
                          leading: Icon(Icons.circle, color: appointment.color, size: 12),
                          title: Text(appointment.subject),
                          // Mostra o intervalo de tempo no subtítulo (ex: 08:00 - 08:30)
                          subtitle: Text(
                            '${DateFormat('HH:mm').format(appointment.startTime)} - ${DateFormat('HH:mm').format(appointment.endTime)}'
                          ),
                          onTap: () => widget.onAppointmentTap(appointment, context),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        onPressed: () => widget.onSlotTap(_selectedDay!, context),
                        tooltip: 'Novo Agendamento',
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildWeekView(MeetingDataSource dataSource, int duracaoDaAgenda, Set<int> diasDeAtendimento, Set<String> datasBloqueadas, ({double startHour, double endHour}) horarios, List<TimeRegion> specialRegions) {
    final List<int> diasDeDescanso = [];
    for (int i = 1; i <= 7; i++) {
      if (!diasDeAtendimento.contains(i)) diasDeDescanso.add(i);
    }

    return Stack(
      children: [
        SfCalendar(
          view: CalendarView.week,
          dataSource: dataSource,
          firstDayOfWeek: 1,
          specialRegions: specialRegions,
          timeSlotViewSettings: TimeSlotViewSettings(
            startHour: horarios.startHour,
            endHour: horarios.endHour, 
            nonWorkingDays: diasDeDescanso,
            timeInterval: Duration(minutes: duracaoDaAgenda),
            timeFormat: 'HH:mm',
          ),
      onTap: (details) {
        if (details.date != null) {
          final String dataFormatada = DateFormat('yyyy-MM-dd').format(details.date!);
          if (!diasDeAtendimento.contains(details.date!.weekday) || datasBloqueadas.contains(dataFormatada)) return;
        }

        if (details.targetElement == CalendarElement.appointment && details.appointments!.isNotEmpty) {
          widget.onAppointmentTap(details.appointments!.first, context); 
        } else if (details.targetElement == CalendarElement.calendarCell) {
          widget.onSlotTap(details.date!, context); 
        }
      },

        ),
        // Positioned(
        //   left: 0,
        //   right: 0,
        //   bottom: 0,
        //   height: 60,               // ajustar
        //   child: Container(
        //     color: Colors.white,    // cor da margem
        //   ),
        // ),
      ],
    );
  }

  // --- LÓGICA DE PRIVACIDADE INCLUÍDA AQUI ---
  MeetingDataSource _getDataSourceCombinado(
    List<Agendamento> agendamentos, 
    List<Bloqueio> bloqueios, 
    List<UserModel> usuarios, 
    int duracaoDaAgenda,
    AuthController auth, // <-- Recebe o AuthController
  ) {
    final List<Appointment> appointments = [];
    final mapaUsuarios = {for (var u in usuarios) u.id: u.primeiroNome};

    // Verifica quem está vendo a agenda
    final bool isClient = auth.tipoUsuario == UserRole.cliente;
    final String? currentUserId = auth.usuario?.id;

    for (final agendamento in agendamentos) {
      // Determina se o agendamento é do próprio usuário
      final bool isMe = agendamento.idUsuario == currentUserId;
      
      String subjectTexto;
      Color corEvento;

      if (isClient && !isMe) {
        // CASO 1: Sou cliente e o agendamento NÃO é meu -> Oculta dados
        subjectTexto = 'Agendado';
        corEvento = Colors.grey.withOpacity(0.7); // Cor de "Ocupado"
      } else {
        // CASO 2: Sou Admin OU Sou cliente e o agendamento é meu -> Mostra dados
        final nomePaciente = mapaUsuarios[agendamento.idUsuario] ?? 'ID: ${agendamento.idUsuario}';
        subjectTexto = 'Agendado: $nomePaciente';
        corEvento = Theme.of(context).primaryColor;
      }

      appointments.add(Appointment(
        startTime: agendamento.dataHora,
        endTime: agendamento.dataHora.add(Duration(minutes: agendamento.duracao * duracaoDaAgenda)),
        subject: subjectTexto,
        color: corEvento,
        resourceIds: [agendamento],
      ));
    }
    
    for (final bloqueio in bloqueios) {
      appointments.add(Appointment(
        startTime: bloqueio.dataHora,
        endTime: bloqueio.dataHora.add(Duration(hours: bloqueio.duracao)),
        subject: bloqueio.descricao,
        color: NnkColors.cinzaSuave,
        resourceIds: [bloqueio],
      ));
    }
    return MeetingDataSource(appointments);
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) { appointments = source; }
  List<Appointment> getEventsForDay(DateTime day) {
    final eventsToday = appointments?.where((appt) => isSameDay(appt.startTime, day)).toList().cast<Appointment>() ?? [];
    eventsToday.sort((a, b) => a.startTime.compareTo(b.startTime));
    return eventsToday;
  }
}