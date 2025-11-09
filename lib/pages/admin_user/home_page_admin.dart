import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'package:tcc_frontend/theme/app_colors.dart';
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
    // Adiciona este log para sabermos que a função foi chamada
    debugPrint(
      "[HomePageAdmin] Iniciando carregamento de dados para Agenda ID: ${widget.idAgenda}",
    );

    // Chama todos os teus providers.
    // O teu BloqueioProvider está perfeito e vai funcionar bem aqui.
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

  @override
  Widget build(BuildContext context) {
    final periodoProvider = context.watch<PeriodoProvider>();
    final agendamentoProvider = context.watch<AgendamentoProvider>();
    final bloqueioProvider = context.watch<BloqueioProvider>();
    final usuarioProvider = context.watch<UsuarioProvider>();

    // --- LÓGICA DE LOADING CORRETA ---
    // (O teu teste "Forçando isLoading = false" foi removido)
    // O teu BloqueioProvider vai gerir o seu estado aqui corretamente.
    final bool isLoading = periodoProvider.isLoading ||
        agendamentoProvider.isLoading ||
        bloqueioProvider.isLoading ||
        usuarioProvider.isLoading;

    // --- A CORREÇÃO CRÍTICA (PROGRAMAÇÃO DEFENSIVA) ---
    // Mesmo que 'widget.duracaoAgenda' venha da API como 0,
    // 'duracaoSegura' será 30, prevenindo o "crash" do calendário.
    final int duracaoSegura =
        (widget.duracaoAgenda > 0) ? widget.duracaoAgenda : 30;
    // --- FIM DA CORREÇÃO ---

    // Log de debug para vermos o que está a acontecer
    print(
      "[HomePageAdmin Build] ID: ${widget.idAgenda}, Duração Original: ${widget.duracaoAgenda}, Duração Segura: $duracaoSegura, isLoading: $isLoading",
    );

    final List<UserModel> usuarios = usuarioProvider.usuarios;
    final dataSource = _getDataSourceCombinado(
      agendamentoProvider.agendamentos,
      bloqueioProvider.bloqueios,
      usuarios,
      duracaoSegura, // <-- Passa a duração segura
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Agenda do Profissional'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDadosIniciais,
          ),
        ],
      ),
      drawer: const AdminDrawer(), // Usar o Menu reutilizável
      body: Column(
        children: [
          _buildViewToggler(), // O teu Toggler
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                // Se estiver carregando, mostra o indicador
                ? const Center(child: CircularProgressIndicator())
                // Se não, mostra a visualização (mês ou semana)
                : _isMonthView
                    ? _buildMonthView(dataSource, duracaoSegura)
                    : _buildWeekView(
                        periodoProvider.periodos,
                        dataSource,
                        duracaoSegura, // <-- Passa a duração segura
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
      color: AppColors.details,
      selectedColor: Colors.white,
      fillColor: AppColors.details,
      borderColor: Colors.blueGrey,
      selectedBorderColor: AppColors.details,
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

  Widget _buildMonthView(MeetingDataSource dataSource, int duracaoDaAgenda) {
    return Column(
      children: [
        TableCalendar(
          locale: 'pt_BR',
          focusedDay: _focusedDay,
          firstDay: DateTime.utc(2022),
          lastDay: DateTime.utc(2035),
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) => dataSource.getEventsForDay(day),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.blue.shade200,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
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
                      padding: const EdgeInsets.only(
                        bottom: 80.0,
                      ),
                    itemCount:
                        dataSource.getEventsForDay(_selectedDay!).length,
                    itemBuilder: (context, index) {
                      final appointment =
                          dataSource.getEventsForDay(_selectedDay!)[index];
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
                          DialogoAgendamentoService
                              .mostrarDialogoEdicaoAgendamento(
                            context: context,
                            appointment: appointment,
                            duracaoDaAgenda: duracaoDaAgenda, // <-- Usa a segura
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
                            duracaoDaAgenda: duracaoDaAgenda, // <-- Usa a segura
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
    List<Periodo> periodos,
    MeetingDataSource dataSource,
    int duracaoDaAgenda, // <-- Recebe a segura
  ) {
    // final horarios = _getHorariosParaDia(_focusedDay, periodos);

    return SfCalendar(
      view: CalendarView.week,
      dataSource: dataSource,
      firstDayOfWeek: 1, // Segunda-feira
      timeSlotViewSettings: TimeSlotViewSettings(
        startHour: 7,
        endHour: 22,
        // --- USA A DURAÇÃO SEGURA AQUI ---
        timeInterval: Duration(
          minutes: duracaoDaAgenda,
        ),
        timeFormat: 'HH:mm',
      ),
      onTap: (details) {
        if (details.targetElement == CalendarElement.appointment &&
            details.appointments!.isNotEmpty) {
          DialogoAgendamentoService.mostrarDialogoEdicaoAgendamento(
            context: context,
            appointment: details.appointments!.first,
            duracaoDaAgenda: duracaoDaAgenda, // <-- Usa a segura
          );
        } else if (details.targetElement == CalendarElement.calendarCell) {
          DialogoAgendamentoService.mostrarDialogoNovoAgendamento(
            context: context,
            dataInicial: details.date!,
            idAgenda: widget.idAgenda,
            duracaoDaAgenda: duracaoDaAgenda, // <-- Usa a segura
          );
        }
      },
    );
  }

  MeetingDataSource _getDataSourceCombinado(
    List<Agendamento> agendamentos,
    List<Bloqueio> bloqueios,
    List<UserModel> usuarios,
    int duracaoDaAgenda, // <-- Recebe a segura
  ) {
    final List<Appointment> appointments = [];
    final mapaUsuarios = {for (var u in usuarios) u.id: u.primeiroNome};

    for (final agendamento in agendamentos) {
      final nomePaciente =
          mapaUsuarios[agendamento.idUsuario] ?? 'ID: ${agendamento.idUsuario}';

      appointments.add(
        Appointment(
          startTime: agendamento.dataHora,
          // --- USA A DURAÇÃO SEGURA AQUI ---
          endTime: agendamento.dataHora.add(
            Duration(minutes: agendamento.duracao * duracaoDaAgenda),
          ),
          subject: 'Agendado: $nomePaciente',
          color: AppColors.primary,
          resourceIds: [agendamento],
        ),
      );
    }
    for (final bloqueio in bloqueios) {
      appointments.add(
        Appointment(
          startTime: bloqueio.dataHora,
          endTime: bloqueio.dataHora.add(Duration(minutes: bloqueio.duracao)),
          subject: bloqueio.descricao,
          color: Colors.grey.shade400,
          resourceIds: [bloqueio],
        ),
      );
    }
    return MeetingDataSource(appointments);
  }

  ({double startHour, double endHour}) _getHorariosParaDia(
    DateTime dia,
    List<Periodo> periodos,
  ) {
    final diaDaSemanaCorrigido = dia.weekday % 7;
    final periodosDoDia = periodos
        .where((p) => p.diaDaSemana == diaDaSemanaCorrigido)
        .toList();

    if (periodosDoDia.isEmpty) return (startHour: 9, endHour: 18);

    final inicio = periodosDoDia
        .map((p) => p.inicio)
        .reduce(
          (a, b) => (a.hour * 60 + a.minute) < (b.hour * 60 + b.minute) ? a : b,
        );
    final fim = periodosDoDia
        .map((p) => p.fim)
        .reduce(
          (a, b) => (a.hour * 60 + a.minute) > (b.hour * 60 + b.minute) ? a : b,
        );

    return (
      startHour: inicio.hour + inicio.minute / 60.0,
      endHour: fim.hour + fim.minute / 60.0,
    );
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
  List<Appointment> getEventsForDay(DateTime day) {
    final eventsToday = appointments
            ?.where((appt) => isSameDay(appt.startTime, day))
            .toList()
            .cast<Appointment>() ??
        [];
    eventsToday.sort((a, b) => a.startTime.compareTo(b.startTime));
    return eventsToday;
  }
}