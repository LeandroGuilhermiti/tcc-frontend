import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; // Import necessário
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

  Future<void> _carregarDadosIniciais() async {
    final idAgenda = widget.agenda.id!;
    
    Provider.of<BloqueioProvider>(context, listen: false).carregarBloqueios(idAgenda);
    Provider.of<PeriodoProvider>(context, listen: false).carregarPeriodos(idAgenda);
    Provider.of<AgendamentoProvider>(context, listen: false).carregarAgendamentos(idAgenda: idAgenda);
    Provider.of<UsuarioProvider>(context, listen: false).buscarUsuarios();
    
    final feriadoProvider = Provider.of<FeriadoProvider>(context, listen: false);
    final anoAtual = DateTime.now().year;
    
    try {
      await Future.wait([
        feriadoProvider.carregarFeriados(anoAtual),
        feriadoProvider.carregarFeriados(anoAtual + 1),
      ]);
    } catch (e) {
      debugPrint("Erro ao carregar feriados: $e");
    }
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
    
    final Color corSemAtendimento = NnkColors.cinzaSuave.withOpacity(0.3); 
    final Color corBloqueio = NnkColors.vermelhoLacre.withOpacity(0.15); 
    final Color corFeriado = NnkColors.ouroAntigo.withOpacity(0.2); 

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
          textStyle: GoogleFonts.alegreya(
            color: NnkColors.tintaCastanha.withOpacity(0.5), 
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
          enablePointerInteraction: false,
        ));
      }

      if (periodosDoDia.isEmpty) {
        addRegion(globalStart, globalEnd, "Fechado");
      } else {
        periodosDoDia.sort((a, b) => timeToDouble(a.inicio).compareTo(timeToDouble(b.inicio)));
        
        double currentCursor = globalStart;
        double primeiroInicio = timeToDouble(periodosDoDia.first.inicio);
        
        if (primeiroInicio > currentCursor) {
          addRegion(currentCursor, primeiroInicio, "Fechado");
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
          addRegion(currentCursor, globalEnd, "Fechado");
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
        textStyle: GoogleFonts.alegreya(color: NnkColors.tintaCastanha, fontWeight: FontWeight.bold),
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
        textStyle: GoogleFonts.alegreya(
          color: NnkColors.tintaCastanha, 
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

    final Map<String, String> detalhesBloqueios = {};

    for (final bloqueio in bloqueios) {
      if (bloqueio.duracao >= 24) {
        DateTime raw = bloqueio.dataHora;
        DateTime dataLocal = DateTime(raw.year, raw.month, raw.day);
        String key = DateFormat('yyyy-MM-dd').format(dataLocal);
        detalhesBloqueios[key] = bloqueio.descricao;
      }
    }
    
    for (final feriado in feriados) {
       String key = DateFormat('yyyy-MM-dd').format(feriado.date);
       detalhesBloqueios[key] = feriado.name;
    }

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
    
    String textoTitulo = _selectedDay != null 
        ? "Agendamentos de ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}" 
        : "Selecione uma data";

    return Container(
      color: NnkColors.papelAntigo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Center(
             child: Padding(
               padding: const EdgeInsets.symmetric(vertical: 8),
               child: _buildViewToggler(),
             ),
           ),
          
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: NnkColors.ouroAntigo))
                : _isMonthView
                    ? _buildMonthView(dataSource, duracaoSegura, diasDeAtendimento, detalhesBloqueios, textoTitulo)
                    : _buildWeekView(dataSource, duracaoSegura, diasDeAtendimento, datasBloqueadas, horarios, specialRegions),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggler() {
    return Container(
      decoration: BoxDecoration(
        color: NnkColors.ouroClaro.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NnkColors.ouroAntigo),
      ),
      child: ToggleButtons(
        isSelected: [_isMonthView, !_isMonthView],
        onPressed: (index) => setState(() => _isMonthView = index == 0),
        borderRadius: BorderRadius.circular(11),
        selectedColor: NnkColors.papelAntigo, 
        fillColor: NnkColors.tintaCastanha,   
        color: NnkColors.tintaCastanha,       
        renderBorder: false,
        textStyle: GoogleFonts.cinzel(fontWeight: FontWeight.bold), // Fonte do Toggle
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24), 
            child: Row(children: [Icon(Icons.calendar_month, size: 18), SizedBox(width: 8), Text('MÊS')]),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24), 
            child: Row(children: [Icon(Icons.view_week, size: 18), SizedBox(width: 8), Text('SEMANA')]),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView(MeetingDataSource dataSource, int duracaoDaAgenda, Set<int> diasDeAtendimento, Map<String, String> detalhesBloqueios, String textoTitulo) {
    
    final double screenHeight = MediaQuery.of(context).size.height;
    final double dynamicRowHeight = (screenHeight * 0.06).clamp(35.0, 65.0);
    final double dynamicDayLabelHeight = (screenHeight * 0.035).clamp(20.0, 35.0);
    final double dynamicFontSize = (dynamicRowHeight * 0.35).clamp(12.0, 16.0);
    final double circleSize = (dynamicRowHeight * 0.70).clamp(28.0, 42.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TableCalendar(
          locale: 'pt_BR',
          focusedDay: _focusedDay,
          firstDay: DateTime.utc(2022),
          lastDay: DateTime.utc(2050),
          
          rowHeight: dynamicRowHeight, 
          daysOfWeekHeight: dynamicDayLabelHeight,

          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            headerMargin: const EdgeInsets.only(bottom: 6.0),
            decoration: const BoxDecoration(color: NnkColors.papelAntigo),
            titleTextStyle: GoogleFonts.cinzel(
              color: NnkColors.tintaCastanha,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            leftChevronIcon: const Icon(Icons.chevron_left, color: NnkColors.ouroAntigo),
            rightChevronIcon: const Icon(Icons.chevron_right, color: NnkColors.ouroAntigo),
          ),

          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: GoogleFonts.alegreya(
              color: NnkColors.tintaCastanha, 
              fontSize: dynamicFontSize, 
              fontWeight: FontWeight.bold,
            ),
            weekendStyle: GoogleFonts.alegreya(
              color: NnkColors.vermelhoLacre.withOpacity(0.7), 
              fontSize: dynamicFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          enabledDayPredicate: (day) {
            final String dataFormatada = DateFormat('yyyy-MM-dd').format(day);
            if (detalhesBloqueios.containsKey(dataFormatada)) return true;
            final bool isDiaDeAtendimento = diasDeAtendimento.contains(day.weekday);
            return isDiaDeAtendimento;
          },

          calendarBuilders: CalendarBuilders(
            disabledBuilder: (context, day, focusedDay) => Center(
              child: Text(day.day.toString(), style: GoogleFonts.alegreya(color: NnkColors.cinzaSuave, fontSize: dynamicFontSize))
            ),
            outsideBuilder: (context, day, focusedDay) => Center(
              child: Text(day.day.toString(), style: GoogleFonts.alegreya(color: NnkColors.cinzaSuave.withOpacity(0.5), fontSize: dynamicFontSize))
            ),
            defaultBuilder: (context, day, focusedDay) {
               final String dataFormatada = DateFormat('yyyy-MM-dd').format(day);
               if (detalhesBloqueios.containsKey(dataFormatada)) {
                 return Center(
                   child: Container(
                     width: circleSize, 
                     height: circleSize,
                     decoration: BoxDecoration(
                       color: NnkColors.ouroClaro, 
                       shape: BoxShape.circle,
                       border: Border.all(color: NnkColors.ouroAntigo.withOpacity(0.5)),
                     ),
                     alignment: Alignment.center,
                     child: Text(
                       '${day.day}',
                       style: GoogleFonts.alegreya(
                         color: NnkColors.tintaCastanha.withOpacity(0.6), 
                         fontWeight: FontWeight.bold, 
                         fontSize: dynamicFontSize,
                         decoration: TextDecoration.lineThrough,
                       ),
                     ),
                   ),
                 );
               }
               return Center(child: Text('${day.day}', style: GoogleFonts.alegreya(fontSize: dynamicFontSize, color: NnkColors.tintaCastanha)));
            },
            selectedBuilder: (context, day, focusedDay) {
              return Center(
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: const BoxDecoration(
                    color: NnkColors.ouroAntigo, 
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))]
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: GoogleFonts.alegreya(color: NnkColors.papelAntigo, fontSize: dynamicFontSize, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
            todayBuilder: (context, day, focusedDay) {
              return Center(
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: NnkColors.tintaCastanha, width: 2),
                    shape: BoxShape.circle
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha, fontSize: dynamicFontSize, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
          onDaySelected: (selectedDay, focusedDay) {
            final String dataFormatada = DateFormat('yyyy-MM-dd').format(selectedDay);
            if (detalhesBloqueios.containsKey(dataFormatada)) {
               showDialog(
                 context: context,
                 builder: (context) => AlertDialog(
                   backgroundColor: NnkColors.papelAntigo,
                   title: Text("Data Indisponível", style: GoogleFonts.cinzel(color: NnkColors.vermelhoLacre)),
                   content: Text(detalhesBloqueios[dataFormatada]!, style: GoogleFonts.alegreya(fontSize: 18)),
                   actions: [
                     TextButton(
                       onPressed: () => Navigator.pop(context), 
                       child: Text("ENTENDIDO", style: GoogleFonts.cinzel(color: NnkColors.tintaCastanha, fontWeight: FontWeight.bold))
                     )
                   ]
                 )
               );
               return;
            }
            if (!diasDeAtendimento.contains(selectedDay.weekday)) return;
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) => dataSource.getEventsForDay(day),
          calendarFormat: CalendarFormat.month,
          availableGestures: AvailableGestures.horizontalSwipe,
        ),
        
        Divider(height: 1, color: NnkColors.ouroAntigo.withOpacity(0.5)), 

        Container(
          width: double.infinity,
          color: NnkColors.ouroClaro.withOpacity(0.3), 
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                textoTitulo,
                style: GoogleFonts.cinzel(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: NnkColors.tintaCastanha,
                ),
              ),
              IconButton(
                onPressed: () => widget.onSlotTap(_selectedDay!, context),
                icon: const Icon(Icons.add_circle),
                color: NnkColors.ouroAntigo,
                iconSize: 36,
                tooltip: 'Novo Agendamento',
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _selectedDay == null
              ? Center(child: Text("Selecione um dia para ver os detalhes.", style: GoogleFonts.alegreya(color: NnkColors.cinzaSuave, fontSize: 18)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8.0), 
                  itemCount: dataSource.getEventsForDay(_selectedDay!).length,
                  itemBuilder: (context, index) {
                    final appointment = dataSource.getEventsForDay(_selectedDay!)[index];
                    return ListTile(
                      leading: Icon(Icons.circle, color: appointment.color, size: 14),
                      title: Text(
                        appointment.subject, 
                        style: GoogleFonts.alegreya(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                      subtitle: Text(
                        '${DateFormat('HH:mm').format(appointment.startTime)} - ${DateFormat('HH:mm').format(appointment.endTime)}',
                        style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha.withOpacity(0.7)),
                      ),
                      onTap: () => widget.onAppointmentTap(appointment, context),
                      splashColor: NnkColors.ouroAntigo.withOpacity(0.1),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWeekView(MeetingDataSource dataSource, int duracaoDaAgenda, Set<int> diasDeAtendimento, Set<String> datasBloqueadas, ({double startHour, double endHour}) horarios, List<TimeRegion> specialRegions) {
    return Stack(
      children: [
        SfCalendar(
          view: CalendarView.week,
          dataSource: dataSource,
          firstDayOfWeek: 1,
          specialRegions: specialRegions,
          backgroundColor: NnkColors.papelAntigo,
          
          headerStyle: CalendarHeaderStyle(
            backgroundColor: NnkColors.papelAntigo,
            textStyle: GoogleFonts.cinzel(
              color: NnkColors.tintaCastanha, 
              fontSize: 20
            ),
          ),
          
          viewHeaderStyle: ViewHeaderStyle(
            backgroundColor: NnkColors.papelAntigo,
            dayTextStyle: GoogleFonts.cinzel(
              color: NnkColors.tintaCastanha, 
              fontWeight: FontWeight.bold
            ),
            dateTextStyle: GoogleFonts.alegreya(
              color: NnkColors.tintaCastanha, 
              fontSize: 18
            ),
          ),
          
          timeSlotViewSettings: TimeSlotViewSettings(
            startHour: horarios.startHour,
            endHour: horarios.endHour,
            timeInterval: Duration(minutes: duracaoDaAgenda),
            timeFormat: 'HH:mm',
            timeTextStyle: GoogleFonts.alegreya(color: NnkColors.tintaCastanha),
            timelineAppointmentHeight: -1, 
          ),
          
          todayHighlightColor: NnkColors.ouroAntigo,
          
          selectionDecoration: BoxDecoration(
            border: Border.all(color: NnkColors.tintaCastanha, width: 2),
            color: Colors.transparent,
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
        ),

        Positioned(
          left: 0,
          top: 28,
          height: 40, 
          width: 50,           
          child: IgnorePointer(
            child: Center(
              child: _SwipeIndicator(isRight: false),
            ),
          ),
        ),

        Positioned(
          right: 0,
          top: 28,
          height: 40, 
          width: 50,
          child: IgnorePointer(
            child: Center(
              child: _SwipeIndicator(isRight: true),
            ),
          ),
        ),
      ],
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
        subjectTexto = 'Ocupado';
        corEvento = NnkColors.cinzaSuave;
      } else {
        final nomePaciente = mapaUsuarios[agendamento.idUsuario] ?? 'ID: ${agendamento.idUsuario}';
        subjectTexto = '$nomePaciente';
        corEvento = isMe ? NnkColors.verdeErva : NnkColors.ouroAntigo;
      }

      appointments.add(Appointment(
        startTime: agendamento.dataHora,
        endTime: agendamento.dataHora.add(Duration(minutes: agendamento.duracao * duracaoDaAgenda)),
        subject: subjectTexto,
        color: corEvento,
        resourceIds: [agendamento],
        startTimeZone: '',
        endTimeZone: '',
      ));
    }
    
    return MeetingDataSource(appointments);
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) { appointments = source; }
  @override
  List<Appointment> getEventsForDay(DateTime day) {
    final eventsToday = appointments?.where((appt) => isSameDay(appt.startTime, day)).toList().cast<Appointment>() ?? [];
    eventsToday.sort((a, b) => a.startTime.compareTo(b.startTime));
    return eventsToday;
  }
}

class _SwipeIndicator extends StatefulWidget {
  final bool isRight;
  const _SwipeIndicator({required this.isRight});

  @override
  State<_SwipeIndicator> createState() => _SwipeIndicatorState();
}

class _SwipeIndicatorState extends State<_SwipeIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 10).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double offsetValue = widget.isRight ? _animation.value : -_animation.value;
        
        return Transform.translate(
          offset: Offset(offsetValue, 0),
          child: Opacity(
            opacity: 0.8,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Icon(
                widget.isRight ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left,
                size: 40,
                color: NnkColors.ouroAntigo,
                shadows: const [
                  Shadow(blurRadius: 4, color: Colors.white, offset: Offset(0,0))
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}