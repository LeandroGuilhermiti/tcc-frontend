import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

// Modelos e Providers
import '../../models/agendamento_model.dart';
import '../../models/bloqueio_model.dart';
import '../../models/periodo_model.dart';
import '../../models/user_model.dart';
import '../../models/agenda_model.dart';
import '../../providers/agendamento_provider.dart';
import '../../providers/bloqueio_provider.dart';
import '../../providers/periodo_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_controller.dart';

// Serviços e Widgets
import '../../services/dialogo_agendamento_cliente.dart';
import '../../theme/app_colors.dart';
import '../../widgets/menu_lateral_cliente.dart'; // <-- 1. IMPORTA O NOVO WIDGET


class HomePageCliente extends StatefulWidget {
  final Agenda agenda;
  const HomePageCliente({super.key, required this.agenda});

  @override
  State<HomePageCliente> createState() => _HomePageClienteState();
}

class _HomePageClienteState extends State<HomePageCliente> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isMonthView = true;

  late final String _idAgenda;
  late final int _duracaoDaAgenda;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _idAgenda = widget.agenda.id!;
    _duracaoDaAgenda = widget.agenda.duracao;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _carregarDadosIniciais(),
    );
  }

  void _carregarDadosIniciais() {
    Provider.of<PeriodoProvider>(
      context,
      listen: false,
    ).carregarPeriodos(_idAgenda);
    Provider.of<AgendamentoProvider>(
      context,
      listen: false,
    ).carregarAgendamentos(idAgenda: _idAgenda);
    Provider.of<BloqueioProvider>(
      context,
      listen: false,
    ).carregarBloqueios(_idAgenda);
    Provider.of<UsuarioProvider>(context, listen: false).buscarUsuarios();
  }

  // ---
  // --- O WIDGET _buildDrawer FOI REMOVIDO DAQUI ---
  // ---

  @override
  Widget build(BuildContext context) {
    // ... (nenhuma alteração nos providers) ...
    final periodoProvider = context.watch<PeriodoProvider>();
    final agendamentoProvider = context.watch<AgendamentoProvider>();
    final bloqueioProvider = context.watch<BloqueioProvider>();
    final usuarioProvider = context.watch<UsuarioProvider>();
    final authProvider = context.watch<AuthController>();
    final String? currentUserId = authProvider.usuario?.id;
    final bool isLoading = periodoProvider.isLoading ||
        agendamentoProvider.isLoading ||
        bloqueioProvider.isLoading ||
        usuarioProvider.isLoading;
    final List<UserModel> usuarios = usuarioProvider.usuarios;
    final dataSource = _getDataSourceCombinado(
      agendamentoProvider.agendamentos,
      bloqueioProvider.bloqueios,
      usuarios,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.agenda.nome),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDadosIniciais,
          ),
        ],
      ),
      // --- 2. CHAMA O NOVO WIDGET ---
      // Passamos `null` porque esta *não* é a página "Agendas"
      drawer: const AppDrawerCliente(currentPage: null),
      // --- FIM DA ALTERAÇÃO ---
      body: Column(
        children: [
          _buildViewToggler(),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isMonthView
                    ? _buildMonthView(dataSource, currentUserId)
                    : _buildWeekView(
                        periodoProvider.periodos,
                        dataSource,
                        currentUserId,
                      ),
          ),
        ],
      ),
    );
  }

  // ... (O resto do arquivo _buildViewToggler, _buildMonthView, etc., não mudou) ...
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

  Widget _buildMonthView(MeetingDataSource dataSource, String? currentUserId) {
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
                            DialogoAgendamentoCliente.mostrarDialogoCliente(
                              context: context,
                              appointment: appointment,
                              currentUserId: currentUserId,
                              duracaoDaAgenda: _duracaoDaAgenda,
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
                          DialogoAgendamentoCliente
                              .mostrarDialogoApenasHoraCliente(
                            context: context,
                            diaSelecionado: _selectedDay!,
                            idAgenda: _idAgenda,
                            duracaoDaAgenda: _duracaoDaAgenda,
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
    String? currentUserId,
  ) {
    return SfCalendar(
      view: CalendarView.week,
      dataSource: dataSource,
      firstDayOfWeek: 1, // Segunda-feira
      timeSlotViewSettings: const TimeSlotViewSettings(
        startHour: 7,
        endHour: 22,
        timeInterval: Duration(
            minutes: 15),
        timeFormat: 'HH:mm',
      ),
      onTap: (details) {
        if (details.targetElement == CalendarElement.appointment &&
            details.appointments!.isNotEmpty) {
          DialogoAgendamentoCliente.mostrarDialogoCliente(
            context: context,
            appointment: details.appointments!.first,
            currentUserId: currentUserId,
            duracaoDaAgenda: _duracaoDaAgenda,
          );
        } else if (details.targetElement == CalendarElement.calendarCell) {
          DialogoAgendamentoCliente.mostrarDialogoNovoAgendamentoCliente(
            context: context,
            dataInicial: details.date!,
            idAgenda: _idAgenda,
            duracaoDaAgenda: _duracaoDaAgenda,
          );
        }
      },
    );
  }

  MeetingDataSource _getDataSourceCombinado(
    List<Agendamento> agendamentos,
    List<Bloqueio> bloqueios,
    List<UserModel> usuarios,
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
            Duration(minutes: agendamento.duracao * _duracaoDaAgenda),
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

