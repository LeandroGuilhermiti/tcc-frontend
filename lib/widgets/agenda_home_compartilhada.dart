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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _carregarDadosIniciais(),
    );
  }

  void _carregarDadosIniciais() {
    final idAgenda = widget.agenda.id!;
    Provider.of<BloqueioProvider>(
      context,
      listen: false,
    ).carregarBloqueios(idAgenda);
    Provider.of<PeriodoProvider>(
      context,
      listen: false,
    ).carregarPeriodos(idAgenda);
    Provider.of<AgendamentoProvider>(
      context,
      listen: false,
    ).carregarAgendamentos(idAgenda: idAgenda);
    Provider.of<UsuarioProvider>(context, listen: false).buscarUsuarios();
  }

  Set<int> _getDiasDeAtendimento(List<Periodo> periodos) {
    return periodos.map((p) => p.diaDaSemana).toSet();
  }

  ({double startHour, double endHour}) _getHorariosDeAtendimento(
    List<Periodo> periodos,
  ) {
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

  // --- ALTERAÇÃO: Lógica refatorada para preencher dias vazios e buracos com "Sem Atendimentos" ---
  List<TimeRegion> _getRegionsDeBloqueio(
    List<Periodo> periodos,
    List<Bloqueio> bloqueios,
    double globalStart,
    double globalEnd,
  ) {
    final List<TimeRegion> regions = [];

    // Cores ajustadas para simular o rascunho
    final Color corSemAtendimento = const Color(0xFFF5F5F5);
    final Color corBloqueio = const Color(0xFFE0E0E0);

    final Map<int, String> weekDayMap = {
      1: 'MO',
      2: 'TU',
      3: 'WE',
      4: 'TH',
      5: 'FR',
      6: 'SA',
      7: 'SU',
    };

    double timeToDouble(TimeOfDay t) => t.hour + t.minute / 60.0;

    // 1. Preenchimento de Horários Vazios (Intervalos e Dias sem expediente)
    // Percorre de Segunda (1) a Domingo (7)
    for (int dia = 1; dia <= 7; dia++) {
      final periodosDoDia = periodos
          .where((p) => p.diaDaSemana == dia)
          .toList();

      // Helper para criar a região cinza
      void addRegion(double start, double end, String label) {
        if (start >= end) return;

        // Data base para calcular a recorrência correta (2024-01-01 foi Segunda-feira)
        final DateTime baseDate = DateTime(
          2024,
          1,
          1,
        ).add(Duration(days: dia - 1));

        regions.add(
          TimeRegion(
            startTime: DateTime(
              baseDate.year,
              baseDate.month,
              baseDate.day,
              start.floor(),
              ((start % 1) * 60).round(),
            ),
            endTime: DateTime(
              baseDate.year,
              baseDate.month,
              baseDate.day,
              end.floor(),
              ((end % 1) * 60).round(),
            ),
            recurrenceRule: 'FREQ=WEEKLY;BYDAY=${weekDayMap[dia]}',
            color: corSemAtendimento,
            text: label,
            // Estilo avermelhado para destacar "Sem Atendimentos" conforme rascunho
            textStyle: const TextStyle(
              color: Color(0xFFD32F2F),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            enablePointerInteraction: false,
          ),
        );
      }

      // Se não há períodos no dia (ex: Sexta, Sábado, Domingo), bloqueia o dia todo
      if (periodosDoDia.isEmpty) {
        addRegion(globalStart, globalEnd, "Sem Atendimentos");
      } else {
        // Se há períodos, preenche os espaços vazios
        periodosDoDia.sort(
          (a, b) => timeToDouble(a.inicio).compareTo(timeToDouble(b.inicio)),
        );

        double currentCursor = globalStart;

        // Espaço antes do primeiro atendimento
        double primeiroInicio = timeToDouble(periodosDoDia.first.inicio);
        if (primeiroInicio > currentCursor) {
          addRegion(currentCursor, primeiroInicio, "Sem Atendimentos");
        }

        // Espaços entre atendimentos (Almoço/Intervalos)
        for (var p in periodosDoDia) {
          double pInicio = timeToDouble(p.inicio);
          double pFim = timeToDouble(p.fim);

          if (pInicio > currentCursor && currentCursor >= globalStart) {
            addRegion(currentCursor, pInicio, "Intervalo");
          }
          currentCursor = max(currentCursor, pFim);
        }

        // Espaço após o último atendimento até o fim do dia
        if (currentCursor < globalEnd) {
          addRegion(currentCursor, globalEnd, "Sem Atendimentos");
        }
      }
    }

    // 2. Bloqueios Cadastrados (Feriados, etc) - Lógica original mantida
    for (var bloqueio in bloqueios) {
      DateTime raw = bloqueio.dataHora;
      DateTime startTime = DateTime(
        raw.year,
        raw.month,
        raw.day,
        raw.hour,
        raw.minute,
      );
      DateTime endTime = startTime.add(Duration(hours: bloqueio.duracao));

      if (bloqueio.duracao >= 24) {
        startTime = DateTime(
          startTime.year,
          startTime.month,
          startTime.day,
          0,
          0,
        );
        endTime = startTime.add(const Duration(days: 1));
      }

      regions.add(
        TimeRegion(
          startTime: startTime,
          endTime: endTime,
          color: corBloqueio,
          text: bloqueio.descricao,
          textStyle: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          enablePointerInteraction: false,
        ),
      );
    }
    return regions;
  }
  // --- FIM DA ALTERAÇÃO ---

  @override
  Widget build(BuildContext context) {
    final periodoProvider = context.watch<PeriodoProvider>();
    final agendamentoProvider = context.watch<AgendamentoProvider>();
    final bloqueioProvider = context.watch<BloqueioProvider>();
    final usuarioProvider = context.watch<UsuarioProvider>();
    final auth = context.watch<AuthController>();

    final bool isLoading =
        periodoProvider.isLoading ||
        agendamentoProvider.isLoading ||
        bloqueioProvider.isLoading ||
        usuarioProvider.isLoading;

    final int duracaoSegura = (widget.agenda.duracao > 0)
        ? widget.agenda.duracao
        : 30;

    final List<Periodo> periodos = periodoProvider.periodos;
    final List<Bloqueio> bloqueios = bloqueioProvider.bloqueios;
    final Set<int> diasDeAtendimento = _getDiasDeAtendimento(periodos);
    final horarios = _getHorariosDeAtendimento(periodos);

    final Set<String> datasBloqueadas = {};
    for (final bloqueio in bloqueios) {
      if (bloqueio.duracao >= 24) {
        DateTime raw = bloqueio.dataHora;
        DateTime dataLocal = DateTime(raw.year, raw.month, raw.day);
        datasBloqueadas.add(DateFormat('yyyy-MM-dd').format(dataLocal));
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
              ? _buildMonthView(
                  dataSource,
                  duracaoSegura,
                  diasDeAtendimento,
                  datasBloqueadas,
                )
              : _buildWeekView(
                  dataSource,
                  duracaoSegura,
                  diasDeAtendimento,
                  datasBloqueadas,
                  horarios,
                  specialRegions,
                ),
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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Mês'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Semana'),
        ),
      ],
    );
  }

  Widget _buildMonthView(
    MeetingDataSource dataSource,
    int duracaoDaAgenda,
    Set<int> diasDeAtendimento,
    Set<String> datasBloqueadas,
  ) {
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
            final bool isDiaDeAtendimento = diasDeAtendimento.contains(
              day.weekday,
            );
            if (!isDiaDeAtendimento) return false;
            final String dataFormatada = DateFormat('yyyy-MM-dd').format(day);
            if (datasBloqueadas.contains(dataFormatada)) return false;
            return true;
          },
          calendarBuilders: CalendarBuilders(
            disabledBuilder: (context, day, focusedDay) => Center(
              child: Text(
                day.day.toString(),
                style: TextStyle(color: NnkColors.cinzaSuave.withOpacity(0.5)),
              ),
            ),
            outsideBuilder: (context, day, focusedDay) => Center(
              child: Text(
                day.day.toString(),
                style: TextStyle(color: NnkColors.cinzaSuave.withOpacity(0.5)),
              ),
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            final String dataFormatada = DateFormat(
              'yyyy-MM-dd',
            ).format(selectedDay);
            if (!diasDeAtendimento.contains(selectedDay.weekday) ||
                datasBloqueadas.contains(dataFormatada))
              return;
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) => dataSource.getEventsForDay(day),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            disabledTextStyle: TextStyle(
              color: NnkColors.cinzaSuave.withOpacity(0.5),
            ),
          ),
          calendarFormat: CalendarFormat.month,
          availableGestures: AvailableGestures.horizontalSwipe,
        ),
        const Divider(),
        Expanded(
          child: _selectedDay == null
              ? const Center(
                  child: Text("Selecione um dia para ver os detalhes."),
                )
              : Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80.0),
                      itemCount: dataSource
                          .getEventsForDay(_selectedDay!)
                          .length,
                      itemBuilder: (context, index) {
                        final appointment = dataSource.getEventsForDay(
                          _selectedDay!,
                        )[index];
                        return ListTile(
                          leading: Icon(
                            Icons.circle,
                            color: appointment.color,
                            size: 12,
                          ),
                          title: Text(appointment.subject),
                          subtitle: Text(
                            '${DateFormat('HH:mm').format(appointment.startTime)} - ${DateFormat('HH:mm').format(appointment.endTime)}',
                          ),
                          onTap: () =>
                              widget.onAppointmentTap(appointment, context),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        onPressed: () =>
                            widget.onSlotTap(_selectedDay!, context),
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

  // --- ALTERAÇÃO: Removido nonWorkingDays para permitir que as regiões cinzas "Sem Atendimento" apareçam ---
  Widget _buildWeekView(
    MeetingDataSource dataSource,
    int duracaoDaAgenda,
    Set<int> diasDeAtendimento,
    Set<String> datasBloqueadas,
    ({double startHour, double endHour}) horarios,
    List<TimeRegion> specialRegions,
  ) {
    // A lista 'diasDeDescanso' foi removida pois agora controlamos isso via specialRegions.

    return SfCalendar(
      view: CalendarView.week,
      dataSource: dataSource,
      firstDayOfWeek: 1,
      specialRegions: specialRegions,
      timeSlotViewSettings: TimeSlotViewSettings(
        startHour: horarios.startHour,
        endHour: horarios.endHour,
        // nonWorkingDays REMOVIDO: Isso permite que o sábado/domingo seja renderizado e coberto pela nossa região cinza
        timeInterval: Duration(minutes: duracaoDaAgenda),
        timeFormat: 'HH:mm',
      ),
      onTap: (details) {
        if (details.date != null) {
          final String dataFormatada = DateFormat(
            'yyyy-MM-dd',
          ).format(details.date!);
          // A lógica de clique continua igual (bloqueia se não for dia de atendimento)
          if (!diasDeAtendimento.contains(details.date!.weekday) ||
              datasBloqueadas.contains(dataFormatada))
            return;
        }

        if (details.targetElement == CalendarElement.appointment &&
            details.appointments!.isNotEmpty) {
          widget.onAppointmentTap(details.appointments!.first, context);
        } else if (details.targetElement == CalendarElement.calendarCell) {
          widget.onSlotTap(details.date!, context);
        }
      },
    );
  }
  // --- FIM DA ALTERAÇÃO ---

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
        final nomePaciente =
            mapaUsuarios[agendamento.idUsuario] ??
            'ID: ${agendamento.idUsuario}';
        subjectTexto = 'Agendado: $nomePaciente';
        corEvento = Theme.of(context).primaryColor;
      }

      appointments.add(
        Appointment(
          startTime: agendamento.dataHora,
          endTime: agendamento.dataHora.add(
            Duration(minutes: agendamento.duracao * duracaoDaAgenda),
          ),
          subject: subjectTexto,
          color: corEvento,
          resourceIds: [agendamento],
        ),
      );
    }

    return MeetingDataSource(appointments);
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
  List<Appointment> getEventsForDay(DateTime day) {
    final eventsToday =
        appointments
            ?.where((appt) => isSameDay(appt.startTime, day))
            .toList()
            .cast<Appointment>() ??
        [];
    eventsToday.sort((a, b) => a.startTime.compareTo(b.startTime));
    return eventsToday;
  }
}
