import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // Para min/max

import 'package:tcc_frontend/theme/app_theme.dart';
import '../../widgets/menu_letral_admin.dart';
import 'package:tcc_frontend/models/agendamento_model.dart';
import 'package:tcc_frontend/models/bloqueio_model.dart';
import 'package:tcc_frontend/models/periodo_model.dart';
import 'package:tcc_frontend/models/user_model.dart';

import 'package:tcc_frontend/providers/agendamento_provider.dart';
import 'package:tcc_frontend/providers/bloqueio_provider.dart';
import 'package:tcc_frontend/providers/periodo_provider.dart';
import 'package:tcc_frontend/providers/user_provider.dart';

import 'package:tcc_frontend/services/dialogo_agendamento_service.dart';


// A página "exige" saber qual é o ID da agenda e a sua duração.
class HomePageAdmin extends StatefulWidget {
  final String idAgenda;
  final int duracaoAgenda;

  const HomePageAdmin({
    super.key,
    required this.idAgenda,
    required this.duracaoAgenda,
  });

  @override
  State<HomePageAdmin> createState() => _HomePageAdminState();
}

class _HomePageAdminState extends State<HomePageAdmin> {
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
    debugPrint(
      "[HomePageAdmin] Iniciando carregamento de dados para Agenda ID: ${widget.idAgenda}",
    );
    Provider.of<BloqueioProvider>(
      context,
      listen: false,
    ).carregarBloqueios(widget.idAgenda);
    Provider.of<PeriodoProvider>(
      context,
      listen: false,
    ).carregarPeriodos(widget.idAgenda);
    Provider.of<AgendamentoProvider>(
      context,
      listen: false,
    ).carregarAgendamentos(idAgenda: widget.idAgenda);
    Provider.of<UsuarioProvider>(context, listen: false).buscarUsuarios();
  }

  // --- FUNÇÃO AUXILIAR 1: DIAS DE ATENDIMENTO ---
  Set<int> _getDiasDeAtendimento(List<Periodo> periodos) {
    return periodos.map((p) => p.diaDaSemana).toSet();
  }

  // --- FUNÇÃO AUXILIAR 2: HORÁRIOS DE ATENDIMENTO ---
  ({double startHour, double endHour}) _getHorariosDeAtendimento(
    List<Periodo> periodos,
  ) {
    if (periodos.isEmpty) {
      return (startHour: 8, endHour: 18);
    }
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

  @override
  Widget build(BuildContext context) {
    final periodoProvider = context.watch<PeriodoProvider>();
    final agendamentoProvider = context.watch<AgendamentoProvider>();
    final bloqueioProvider = context.watch<BloqueioProvider>();
    final usuarioProvider = context.watch<UsuarioProvider>();

    final bool isLoading =
        periodoProvider.isLoading ||
        agendamentoProvider.isLoading ||
        bloqueioProvider.isLoading ||
        usuarioProvider.isLoading;

    final int duracaoSegura = (widget.duracaoAgenda > 0)
        ? widget.duracaoAgenda
        : 30;

    final List<Periodo> periodos = periodoProvider.periodos;
    final List<Bloqueio> bloqueios = bloqueioProvider.bloqueios;

    debugPrint(
      "[HomePageAdmin Build] Periodos: ${periodos.length}, Bloqueios: ${bloqueios.length}",
    );

    final Set<int> diasDeAtendimento = _getDiasDeAtendimento(periodos);
    final horarios = _getHorariosDeAtendimento(periodos);

    final Set<String> datasBloqueadas = {};
    for (final bloqueio in bloqueios) {
      if (bloqueio.duracao >= 8) {
        datasBloqueadas.add(DateFormat('yyyy-MM-dd').format(bloqueio.dataHora));
      }
    }

    final List<UserModel> usuarios = usuarioProvider.usuarios;
    final dataSource = _getDataSourceCombinado(
      agendamentoProvider.agendamentos,
      bloqueios,
      usuarios,
      duracaoSegura,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda do Profissional'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDadosIniciais,
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
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
                  ),
          ),
        ],
      ),
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
          lastDay: DateTime.utc(2035),
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

          enabledDayPredicate: (day) {
            final bool isDiaDeAtendimento = diasDeAtendimento.contains(
              day.weekday,
            );
            if (!isDiaDeAtendimento) {
              return false;
            }
            final String dataFormatada = DateFormat('yyyy-MM-dd').format(day);
            final bool isDataBloqueada = datasBloqueadas.contains(
              dataFormatada,
            );
            if (isDataBloqueada) {
              return false;
            }
            return true;
          },

          calendarBuilders: CalendarBuilders(
            disabledBuilder: (context, day, focusedDay) {
              return Center(
                child: Text(
                  day.day.toString(),
                  style: TextStyle(
                    color: NnkColors.cinzaSuave.withOpacity(0.5),
                  ),
                ),
              );
            },
            outsideBuilder: (context, day, focusedDay) {
              return Center(
                child: Text(
                  day.day.toString(),
                  style: TextStyle(
                    color: NnkColors.cinzaSuave.withOpacity(0.5),
                  ),
                ),
              );
            },
          ),

          onDaySelected: (selectedDay, focusedDay) {
            final String dataFormatada = DateFormat(
              'yyyy-MM-dd',
            ).format(selectedDay);
            if (!diasDeAtendimento.contains(selectedDay.weekday) ||
                datasBloqueadas.contains(dataFormatada)) {
              return;
            }

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
                            DateFormat('HH:mm').format(appointment.startTime),
                          ),
                          onTap: () {
                            DialogoAgendamentoService.mostrarDialogoEdicaoAgendamento(
                              context: context,
                              appointment: appointment,
                              duracaoDaAgenda: duracaoDaAgenda,
                            );
                          },
                        );
                      },
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        onPressed: () {
                          DialogoAgendamentoService.mostrarDialogoApenasHora(
                            context: context,
                            diaSelecionado: _selectedDay!,
                            idAgenda: widget.idAgenda,
                            duracaoDaAgenda: duracaoDaAgenda,
                          );
                        },
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

  Widget _buildWeekView(
    MeetingDataSource dataSource,
    int duracaoDaAgenda,
    Set<int> diasDeAtendimento,
    Set<String> datasBloqueadas,
    ({double startHour, double endHour}) horarios,
  ) {
    final List<int> diasDeDescanso = [];
    for (int i = 1; i <= 7; i++) {
      if (!diasDeAtendimento.contains(i)) {
        diasDeDescanso.add(i);
      }
    }

    return SfCalendar(
      view: CalendarView.week,
      dataSource: dataSource,
      firstDayOfWeek: 1,
      timeSlotViewSettings: TimeSlotViewSettings(
        startHour: horarios.startHour,
        endHour: horarios.endHour,
        nonWorkingDays: diasDeDescanso,
        timeInterval: Duration(minutes: duracaoDaAgenda),
        timeFormat: 'HH:mm',
      ),
      onTap: (details) {
        if (details.date != null) {
          final String dataFormatada = DateFormat(
            'yyyy-MM-dd',
          ).format(details.date!);
          if (!diasDeAtendimento.contains(details.date!.weekday) ||
              datasBloqueadas.contains(dataFormatada)) {
            return;
          }
        }

        if (details.targetElement == CalendarElement.appointment &&
            details.appointments!.isNotEmpty) {
          DialogoAgendamentoService.mostrarDialogoEdicaoAgendamento(
            context: context,
            appointment: details.appointments!.first,
            duracaoDaAgenda: duracaoDaAgenda,
          );
        } else if (details.targetElement == CalendarElement.calendarCell) {
          DialogoAgendamentoService.mostrarDialogoNovoAgendamento(
            context: context,
            dataInicial: details.date!,
            idAgenda: widget.idAgenda,
            duracaoDaAgenda: duracaoDaAgenda,
          );
        }
      },
    );
  }

  MeetingDataSource _getDataSourceCombinado(
    List<Agendamento> agendamentos,
    List<Bloqueio> bloqueios,
    List<UserModel> usuarios,
    int duracaoDaAgenda,
  ) {
    final List<Appointment> appointments = [];
    final mapaUsuarios = {for (var u in usuarios) u.id: u.primeiroNome};

    for (final agendamento in agendamentos) {
      final nomePaciente =
          mapaUsuarios[agendamento.idUsuario] ?? 'ID: ${agendamento.idUsuario}';
      appointments.add(
        Appointment(
          startTime: agendamento.dataHora,
          endTime: agendamento.dataHora.add(
            Duration(minutes: agendamento.duracao * duracaoDaAgenda),
          ),
          subject: 'Agendado: $nomePaciente',
          color: Theme.of(context).primaryColor,
          resourceIds: [agendamento],
        ),
      );
    }
    for (final bloqueio in bloqueios) {
      final Duration duracaoBloqueio = Duration(hours: bloqueio.duracao);

      appointments.add(
        Appointment(
          startTime: bloqueio.dataHora,
          endTime: bloqueio.dataHora.add(duracaoBloqueio),
          subject: bloqueio.descricao,
          color: NnkColors.cinzaSuave,
          resourceIds: [bloqueio],
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
