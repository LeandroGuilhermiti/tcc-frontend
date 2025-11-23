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
import '../models/feriado_model.dart'; 
import '../providers/feriado_provider.dart';

import '../providers/agendamento_provider.dart';
import '../providers/bloqueio_provider.dart';
import '../providers/periodo_provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_controller.dart';

class SharedAgendaCalendar extends StatefulWidget {
  final Agenda agenda;
  
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
    Provider.of<BloqueioProvider>(context, listen: false).carregarBloqueios(idAgenda);
    Provider.of<PeriodoProvider>(context, listen: false).carregarPeriodos(idAgenda);
    Provider.of<AgendamentoProvider>(context, listen: false).carregarAgendamentos(idAgenda: idAgenda);
    Provider.of<UsuarioProvider>(context, listen: false).buscarUsuarios();
    
    final feriadoProvider = Provider.of<FeriadoProvider>(context, listen: false);
    final anoAtual = DateTime.now().year;
    feriadoProvider.carregarFeriados(anoAtual);
    feriadoProvider.carregarFeriados(anoAtual + 1);
  }

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
    List<FeriadoModel> feriados,
    double globalStart,
    double globalEnd,
  ) {
    final List<TimeRegion> regions = [];
    
    final Color corSemAtendimento = const Color(0xFFF5F5F5); 
    final Color corBloqueio = const Color(0xFFE0E0E0); 
    final Color corFeriado = const Color(0xFFFFF3E0); 

    final Map<int, String> weekDayMap = {
      1: 'MO', 2: 'TU', 3: 'WE', 4: 'TH', 5: 'FR', 6: 'SA', 7: 'SU'
    };

    double timeToDouble(TimeOfDay t) => t.hour + t.minute / 60.0;

    for (int dia = 1; dia <= 7; dia++) {
      final periodosDoDia = periodos.where((p) => p.diaDaSemana == dia).toList();
      
      void addRegion(double start, double end, String label) {
        if (start >= end) return;
        
        final DateTime baseDate = DateTime(2024, 1, 1).add(Duration(days: dia - 1));
        
        regions.add(TimeRegion(
          startTime: DateTime(baseDate.year, baseDate.month, baseDate.day, start.floor(), ((start % 1) * 60).round()),
          endTime: DateTime(baseDate.year, baseDate.month, baseDate.day, end.floor(), ((end % 1) * 60).round()),
          recurrenceRule: 'FREQ=WEEKLY;BYDAY=${weekDayMap[dia]}',
          color: corSemAtendimento,
          text: label,
          textStyle: const TextStyle(
            color: Color(0xFFD32F2F), 
            fontSize: 12,
            fontStyle: FontStyle.italic
          ),
          enablePointerInteraction: false,
        ));
      }

      if (periodosDoDia.isEmpty) {
        addRegion(globalStart, globalEnd, "Sem Atendimentos");
      } else {
        periodosDoDia.sort((a, b) => timeToDouble(a.inicio).compareTo(timeToDouble(b.inicio)));
        
        double currentCursor = globalStart;

        double primeiroInicio = timeToDouble(periodosDoDia.first.inicio);
        
        if (primeiroInicio > currentCursor) {
          addRegion(currentCursor, primeiroInicio, "Sem Atendimentos");
          currentCursor = primeiroInicio; 
        }
        
        for (var p in periodosDoDia) {
          double pInicio = timeToDouble(p.inicio);
          double pFim = timeToDouble(p.fim);

          if (pInicio > currentCursor && currentCursor >= globalStart) {
             addRegion(currentCursor, pInicio, "Intervalo");
          }
          currentCursor = max(currentCursor, pFim);
        }

        if (currentCursor < globalEnd) {
          addRegion(currentCursor, globalEnd, "Sem Atendimentos");
        }
      }
    }

    for (var bloqueio in bloqueios) {
      DateTime raw = bloqueio.dataHora;
      DateTime startTime = DateTime(raw.year, raw.month, raw.day, raw.hour, raw.minute);
      DateTime endTime = startTime.add(Duration(hours: bloqueio.duracao));

      if (bloqueio.duracao >= 24) {
        startTime = DateTime(startTime.year, startTime.month, startTime.day, 0, 0);
        endTime = startTime.add(const Duration(days: 1));
      }

      regions.add(TimeRegion(
        startTime: startTime,
        endTime: endTime,
        color: corBloqueio,
        text: bloqueio.descricao,
        textStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        enablePointerInteraction: false, 
      ));
    }

    for (var feriado in feriados) {
      final start = DateTime(feriado.date.year, feriado.date.month, feriado.date.day, 0, 0);
      final end = start.add(const Duration(days: 1));

      regions.add(TimeRegion(
        startTime: start,
        endTime: end,
        color: corFeriado,
        text: feriado.name,
        textStyle: const TextStyle(
          color: Colors.deepOrange, 
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        enablePointerInteraction: false,
      ));
    }

    return regions;
  }

  @override
  Widget build(BuildContext context) {
    final periodoProvider = context.watch<PeriodoProvider>();
    final agendamentoProvider = context.watch<AgendamentoProvider>();
    final bloqueioProvider = context.watch<BloqueioProvider>();
    final usuarioProvider = context.watch<UsuarioProvider>();
    final feriadoProvider = context.watch<FeriadoProvider>();
    final auth = context.watch<AuthController>();

    final bool isLoading = periodoProvider.isLoading ||
        agendamentoProvider.isLoading ||
        bloqueioProvider.isLoading ||
        usuarioProvider.isLoading ||
        feriadoProvider.isLoading;

    final int duracaoSegura = (widget.agenda.duracao > 0) ? widget.agenda.duracao : 30;

    final List<Periodo> periodos = periodoProvider.periodos;
    final List<Bloqueio> bloqueios = bloqueioProvider.bloqueios;
    final List<FeriadoModel> feriados = feriadoProvider.feriados;

    final Set<int> diasDeAtendimento = _getDiasDeAtendimento(periodos);
    final horarios = _getHorariosDeAtendimento(periodos);

    //Mapa para saber o motivo do bloqueio (nome do feriado ou descrição do bloqueio)
    final Map<String, String> detalhesBloqueios = {};

    // Adiciona Bloqueios Manuais
    for (final bloqueio in bloqueios) {
      if (bloqueio.duracao >= 24) {
        DateTime raw = bloqueio.dataHora;
        DateTime dataLocal = DateTime(raw.year, raw.month, raw.day);
        String key = DateFormat('yyyy-MM-dd').format(dataLocal);
        detalhesBloqueios[key] = bloqueio.descricao;
      }
    }
    
    // Adiciona Feriados (Sobrescreve se cair no mesmo dia, ou poderia concatenar)
    for (final feriado in feriados) {
       String key = DateFormat('yyyy-MM-dd').format(feriado.date);
       detalhesBloqueios[key] = feriado.name;
    }

    // A lista antiga de 'datasBloqueadas' ainda é útil para a visão semanal
    final Set<String> datasBloqueadas = detalhesBloqueios.keys.toSet();

    final List<TimeRegion> specialRegions = _getRegionsDeBloqueio(
      periodos,
      bloqueios,
      feriados,
      horarios.startHour,
      horarios.endHour,
    );

    final dataSource = _getDataSourceCombinado(
      agendamentoProvider.agendamentos,
      usuarioProvider.usuarios,
      duracaoSegura,
      auth,
    );

    return Column(
      children: [
        _buildViewToggler(),
        const SizedBox(height: 8),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isMonthView
                  // o novo mapa 'detalhesBloqueios'
                  ? _buildMonthView(dataSource, duracaoSegura, diasDeAtendimento, detalhesBloqueios)
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

  // --- ALTERAÇÃO: Recebe Map<String, String> em vez de Set<String> ---
  Widget _buildMonthView(MeetingDataSource dataSource, int duracaoDaAgenda, Set<int> diasDeAtendimento, Map<String, String> detalhesBloqueios) {
    return Column(
      children: [
        TableCalendar(
          locale: 'pt_BR',
          focusedDay: _focusedDay,
          firstDay: DateTime.utc(2022),
          lastDay: DateTime.utc(2050),
          daysOfWeekHeight: 40.0,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            headerMargin: EdgeInsets.only(bottom: 8.0),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: NnkColors.marromEscuro),
            weekendStyle: TextStyle(color: NnkColors.vermelho.withOpacity(0.6)),
          ),
          enabledDayPredicate: (day) {
            final String dataFormatada = DateFormat('yyyy-MM-dd').format(day);
            
            // --- ALTERAÇÃO: Habilita o clique se for feriado/bloqueio ---
            if (detalhesBloqueios.containsKey(dataFormatada)) return true;

            // Se não for feriado, aplica regra normal (dia de trabalho)
            final bool isDiaDeAtendimento = diasDeAtendimento.contains(day.weekday);
            return isDiaDeAtendimento;
          },
          calendarBuilders: CalendarBuilders(
            disabledBuilder: (context, day, focusedDay) => Center(child: Text(day.day.toString(), style: TextStyle(color: NnkColors.cinzaSuave.withOpacity(0.5)))),
            outsideBuilder: (context, day, focusedDay) => Center(child: Text(day.day.toString(), style: TextStyle(color: NnkColors.cinzaSuave.withOpacity(0.5)))),
            
            // --- ALTERAÇÃO: Builder Personalizado para Feriados ---
            defaultBuilder: (context, day, focusedDay) {
               final String dataFormatada = DateFormat('yyyy-MM-dd').format(day);
               if (detalhesBloqueios.containsKey(dataFormatada)) {
                 // Estilo do dia de feriado (Laranja claro com borda)
                 return Center(
                   child: Container(
                     margin: const EdgeInsets.all(6.0),
                     decoration: BoxDecoration(
                       color: Colors.deepOrange.withOpacity(0.1), 
                       shape: BoxShape.circle,
                       border: Border.all(color: Colors.deepOrange.withOpacity(0.5)),
                     ),
                     alignment: Alignment.center,
                     child: Text(
                       '${day.day}',
                       style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                     ),
                   ),
                 );
               }
               return null; // Retorna nulo para usar o estilo padrão nos outros dias
            },
          ),
          onDaySelected: (selectedDay, focusedDay) {
            final String dataFormatada = DateFormat('yyyy-MM-dd').format(selectedDay);
            
            // --- ALTERAÇÃO: Intercepta o clique se for Feriado ---
            if (detalhesBloqueios.containsKey(dataFormatada)) {
               showDialog(
                 context: context,
                 builder: (context) => AlertDialog(
                   title: const Text("Dia Indisponível"),
                   content: Text(detalhesBloqueios[dataFormatada]!), // Exibe o nome do feriado
                   actions: [
                     TextButton(
                       onPressed: () => Navigator.pop(context), 
                       child: const Text("OK")
                     )
                   ]
                 )
               );
               return; // Não seleciona o dia, apenas avisa
            }

            // Lógica normal de seleção
            if (!diasDeAtendimento.contains(selectedDay.weekday)) return;
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
    return SfCalendar(
      view: CalendarView.week,
      dataSource: dataSource,
      firstDayOfWeek: 1,
      specialRegions: specialRegions,
      timeSlotViewSettings: TimeSlotViewSettings(
        startHour: horarios.startHour,
        endHour: horarios.endHour,
        timeInterval: Duration(minutes: duracaoDaAgenda),
        timeFormat: 'HH:mm',
      ),
      onTap: (details) {
        if (details.date != null) {
          final String dataFormatada = DateFormat('yyyy-MM-dd').format(details.date!);
          if (!diasDeAtendimento.contains(details.date!.weekday) ||
              datasBloqueadas.contains(dataFormatada)) return;
        }

        if (details.targetElement == CalendarElement.appointment && details.appointments!.isNotEmpty) {
          widget.onAppointmentTap(details.appointments!.first, context); 
        } else if (details.targetElement == CalendarElement.calendarCell) {
          widget.onSlotTap(details.date!, context); 
        }
      },
    );
  }

  MeetingDataSource _getDataSourceCombinado(
    List<Agendamento> agendamentos, 
    List<UserModel> usuarios, 
    int duracaoDaAgenda,
    AuthController auth,
  ) {
    final List<Appointment> appointments = [];
    final mapaUsuarios = {for (var u in usuarios) u.id: u.primeiroNome};

    final bool isClient = auth.tipoUsuario == UserRole.cliente;
    final String? currentUserId = auth.usuario?.id;

    for (final agendamento in agendamentos) {
      final bool isMe = agendamento.idUsuario == currentUserId;
      
      String subjectTexto;
      Color corEvento;

      if (isClient && !isMe) {
        subjectTexto = 'Agendado';
        corEvento = Colors.grey.withOpacity(0.7);
      } else {
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