import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'package:tcc_frontend/theme/app_colors.dart';

import 'package:tcc_frontend/models/agendamento_model.dart';
import 'package:tcc_frontend/models/bloqueio_model.dart';
import 'package:tcc_frontend/models/periodo_model.dart';

import 'package:tcc_frontend/providers/agendamento_provider.dart';
import 'package:tcc_frontend/providers/bloqueio_provider.dart';
import 'package:tcc_frontend/providers/periodo_provider.dart';
import 'package:tcc_frontend/providers/user_provider.dart'; 

import 'package:tcc_frontend/services/dialogo_agendamento_service.dart';

class HomePageAdmin extends StatefulWidget {
  const HomePageAdmin({super.key});

  @override
  State<HomePageAdmin> createState() => _HomePageAdminState();
}

class _HomePageAdminState extends State<HomePageAdmin> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isMonthView = true;

  // ALTERAÇÃO 1: ID e duração fixa para testes
  final String idAgenda = "6";
  final int duracaoPadraoParaTeste = 30; 

  // ALTERAÇÃO 2: Remoção das variáveis de estado complexas (_agendaSelecionada, _isAgendaLoading)

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // ALTERAÇÃO 3: Voltamos a chamar a função de carregamento simples diretamente.
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarDadosIniciais());
  }

  /// ALTERAÇÃO 4: A função de carregamento agora é simples e direta.
  void _carregarDadosIniciais() {
    Provider.of<PeriodoProvider>(context, listen: false).carregarPeriodos(idAgenda);
    Provider.of<AgendamentoProvider>(context, listen: false).carregarAgendamentos(idAgenda: idAgenda);
    Provider.of<BloqueioProvider>(context, listen: false).carregarBloqueios(idAgenda);
	Provider.of<UsuarioProvider>(context, listen: false).buscarUsuarios();
  }

  /// Mostra as opções de "Ver" ou "Criar" agendamento para um dia específico.
  void _mostrarOpcoesDoDia(DateTime diaSelecionado) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Ver Agendamentos do Dia'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedDay = diaSelecionado;
                  _focusedDay = diaSelecionado;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Novo Agendamento para este Dia'),
              onTap: () {
                Navigator.pop(context);
                DialogoAgendamentoService.mostrarDialogoApenasHora(
                  context: context,
                  diaSelecionado: diaSelecionado,
                  idAgenda: idAgenda, // Usa o ID fixo
                  duracaoDaAgenda: duracaoPadraoParaTeste, // duração fixa para teste
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final periodoProvider = context.watch<PeriodoProvider>();
    final agendamentoProvider = context.watch<AgendamentoProvider>();
    final bloqueioProvider = context.watch<BloqueioProvider>();
    final bool isLoading = periodoProvider.isLoading || agendamentoProvider.isLoading || bloqueioProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        // ALTERAÇÃO 5: O título volta a ser estático.
        title: const Text('Agenda do Profissional'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarDadosIniciais),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacementNamed(context, '/login')),
        ],
      ),
      drawer: _buildDrawer(),
      // ALTERAÇÃO 6: O corpo da tela é simplificado, sem as verificações de agenda.
      body: Column(
        children: [
          _buildViewToggler(),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isMonthView
                    ? _buildMonthView(_getDataSourceCombinado(agendamentoProvider.agendamentos, bloqueioProvider.bloqueios))
                    : _buildWeekView(periodoProvider.periodos, _getDataSourceCombinado(agendamentoProvider.agendamentos, bloqueioProvider.bloqueios)),
          ),
        ],
      ),
    );
  }

  // O resto dos widgets de construção (_buildDrawer, _buildViewToggler, etc.)
  // permanecem os mesmos, mas agora usarão o `idAgenda` fixo quando necessário.

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
        children: [
          const Text('Menu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ListTile(leading: const Icon(Icons.home), title: const Text('Home'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.edit_calendar), title: const Text('Criar agenda'), onTap: () => Navigator.pushNamed(context, '/create')),
          ListTile(leading: const Icon(Icons.edit_calendar), title: const Text('Editar agenda'), onTap: () => Navigator.pushNamed(context, '/agendas')),
          ListTile(leading: const Icon(Icons.schedule), title: const Text('Cadastrar usuários'), onTap: () => Navigator.pushNamed(context, '/cadastro')),
          ListTile(leading: const Icon(Icons.people), title: const Text('Consultar pacientes'), onTap: () => Navigator.pushNamed(context, '/pacientes')),
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
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Mês')),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Semana')),
      ],
    );
  }

  Widget _buildMonthView(MeetingDataSource dataSource) {
    return Column(
      children: [
        TableCalendar(
          locale: 'pt_BR',
          focusedDay: _focusedDay,
          firstDay: DateTime.utc(2022),
          lastDay: DateTime.utc(2035),
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            _mostrarOpcoesDoDia(selectedDay);
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) => dataSource.getEventsForDay(day),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: Colors.blue.shade200, shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
          calendarFormat: CalendarFormat.month,
          availableGestures: AvailableGestures.horizontalSwipe,
        ),
        const Divider(),
        Expanded(
          child: _selectedDay == null
              ? const Center(child: Text("Selecione um dia para ver os detalhes."))
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: dataSource.getEventsForDay(_selectedDay!).length,
                  itemBuilder: (context, index) {
                    final appointment = dataSource.getEventsForDay(_selectedDay!)[index];
                    return ListTile(
                      leading: Icon(Icons.circle, color: appointment.color, size: 12),
                      title: Text(appointment.subject),
                      subtitle: Text(DateFormat('HH:mm').format(appointment.startTime)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWeekView(List<Periodo> periodos, MeetingDataSource dataSource) {
    final horarios = _getHorariosParaDia(_focusedDay, periodos);

    return SfCalendar(
      view: CalendarView.week,
      dataSource: dataSource,
      firstDayOfWeek: 1, // Segunda-feira
        timeSlotViewSettings: const TimeSlotViewSettings(
        startHour: 7, // Exemplo, pode ser dinâmico
        endHour: 22,
        timeInterval: Duration(minutes: 15), // Exemplo para 15 min, pode ser dinâmico
        timeFormat: 'HH:mm',
      ),
      onTap: (details) {
        if (details.targetElement == CalendarElement.appointment && details.appointments!.isNotEmpty) {
          DialogoAgendamentoService.mostrarDialogoEdicaoAgendamento(
            context: context,
            appointment: details.appointments!.first,
          );
        } else if (details.targetElement == CalendarElement.calendarCell) {
          DialogoAgendamentoService.mostrarDialogoNovoAgendamento(
            context: context,
            dataInicial: details.date!,
            idAgenda: idAgenda, // Usa o ID fixo
            duracaoDaAgenda: duracaoPadraoParaTeste, // duração fixa para teste
          );
        }
      },
    );
  }

  MeetingDataSource _getDataSourceCombinado(List<Agendamento> agendamentos, List<Bloqueio> bloqueios) {
    final List<Appointment> appointments = [];
    for (final agendamento in agendamentos) {
      appointments.add(Appointment(
        startTime: agendamento.dataHora,
        endTime: agendamento.dataHora.add(Duration(minutes: agendamento.duracao)),
        subject: 'Agendado para ${agendamento.idUsuario}',
        color: AppColors.primary,
        notes: agendamento.id,
      ));
    }
    for (final bloqueio in bloqueios) {
      appointments.add(Appointment(
        startTime: bloqueio.dataHora,
        endTime: bloqueio.dataHora.add(Duration(minutes: bloqueio.duracao)),
        subject: bloqueio.descricao,
        color: Colors.grey.shade400,
        notes: bloqueio.id,
      ));
    }
    return MeetingDataSource(appointments);
  }

  ({double startHour, double endHour}) _getHorariosParaDia(DateTime dia, List<Periodo> periodos) {
    final diaDaSemanaCorrigido = dia.weekday % 7;
    final periodosDoDia = periodos.where((p) => p.diaDaSemana == diaDaSemanaCorrigido).toList();

    if (periodosDoDia.isEmpty) return (startHour: 9, endHour: 18);

    final inicio = periodosDoDia.map((p) => p.inicio).reduce((a, b) => (a.hour * 60 + a.minute) < (b.hour * 60 + b.minute) ? a : b);
    final fim = periodosDoDia.map((p) => p.fim).reduce((a, b) => (a.hour * 60 + a.minute) > (b.hour * 60 + b.minute) ? a : b);

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
    return appointments?.where((appt) => isSameDay(appt.startTime, day)).toList().cast<Appointment>() ?? [];
  }
}

