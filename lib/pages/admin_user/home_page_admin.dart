import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'package:tcc_frontend/theme/app_colors.dart';

import 'package:tcc_frontend/models/agendamento_model.dart';
import 'package:tcc_frontend/models/bloqueio_model.dart';
import 'package:tcc_frontend/models/periodo_model.dart';
import 'package:tcc_frontend/models/user_model.dart'; 

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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _carregarDadosIniciais(),
    );
  }

  /// ALTERAÇÃO 4: A função de carregamento agora é simples e direta.
  void _carregarDadosIniciais() {
    // Carrega todos os dados necessários de uma vez
    Provider.of<PeriodoProvider>(
      context,
      listen: false,
    ).carregarPeriodos(idAgenda);
    Provider.of<AgendamentoProvider>(
      context,
      listen: false,
    ).carregarAgendamentos(idAgenda: idAgenda);
    Provider.of<BloqueioProvider>(
      context,
      listen: false,
    ).carregarBloqueios(idAgenda);
    Provider.of<UsuarioProvider>(context, listen: false).buscarUsuarios();
  }

  @override
  Widget build(BuildContext context) {
    // Observa todos os providers necessários
    final periodoProvider = context.watch<PeriodoProvider>();
    final agendamentoProvider = context.watch<AgendamentoProvider>();
    final bloqueioProvider = context.watch<BloqueioProvider>();
    // Precisamos do provider de usuários para buscar os nomes
    final usuarioProvider = context.watch<UsuarioProvider>();

    final bool isLoading =
        periodoProvider.isLoading ||
        agendamentoProvider.isLoading ||
        bloqueioProvider.isLoading ||
        usuarioProvider.isLoading;

    // Criamos a lista de usuários aqui para passar para os métodos de build
    final List<UserModel> usuarios = usuarioProvider.usuarios;
    // Criamos o data source combinado aqui
    final dataSource = _getDataSourceCombinado(
      agendamentoProvider.agendamentos,
      bloqueioProvider.bloqueios,
      usuarios, // Passa a lista de usuários
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildViewToggler(),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isMonthView
                ? _buildMonthView(dataSource) // Passa o dataSource
                : _buildWeekView(
                    periodoProvider.periodos,
                    dataSource,
                  ), // Passa o dataSource
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
          const Text(
            'Menu',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.edit_calendar),
            title: const Text('Criar agenda'),
            onTap: () => Navigator.pushNamed(context, '/create'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_calendar),
            title: const Text('Editar agenda'),
            onTap: () => Navigator.pushNamed(context, '/agendas'),
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

  Widget _buildMonthView(MeetingDataSource dataSource) {
    return Column(
      children: [
        TableCalendar(
          locale: 'pt_BR',
          focusedDay: _focusedDay,
          firstDay: DateTime.utc(2022),
          lastDay: DateTime.utc(2035),
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          // --- ALTERAÇÃO AQUI ---
          // O clique no dia agora apenas atualiza o estado,
          // não chama mais o _mostrarOpcoesDoDia
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          // --- FIM DA ALTERAÇÃO ---
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
        // --- ALTERAÇÃO AQUI: Lista de agendamentos e botão flutuante ---
        Expanded(
          child: _selectedDay == null
              ? const Center(
                  child: Text("Selecione um dia para ver os detalhes."),
                )
              : Stack(
                  // Usamos um Stack para sobrepor o botão à lista
                  children: [
                    // A Lista de Agendamentos
                    ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: 80.0,
                      ), // Garante espaço para o botão não sobrepor o último item
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
                          title: Text(appointment.subject), // Mostra o nome
                          subtitle: Text(
                            DateFormat('HH:mm').format(appointment.startTime),
                          ),
                          onTap: () {
                            // --- ALTERAÇÃO AQUI ---
                            // Permite editar/excluir ao clicar no item da lista
                            DialogoAgendamentoService.mostrarDialogoEdicaoAgendamento(
                              context: context,
                              appointment: appointment,
                              duracaoDaAgenda: duracaoPadraoParaTeste, // <-- ADICIONADO
                            );
                            // --- FIM DA ALTERAÇÃO ---
                          },
                        );
                      },
                    ),

                    // O Botão Flutuante
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        onPressed: () {
                          // Chama a criação de agendamento para o dia selecionado
                          DialogoAgendamentoService.mostrarDialogoApenasHora(
                            context: context,
                            diaSelecionado: _selectedDay!,
                            idAgenda: idAgenda, // Usa o ID fixo
                            duracaoDaAgenda:
                                duracaoPadraoParaTeste, // duração fixa
                          );
                        },
                        tooltip: 'Novo Agendamento',
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
        ),
        // --- FIM DA ALTERAÇÃO ---
      ],
    );
  }

  Widget _buildWeekView(List<Periodo> periodos, MeetingDataSource dataSource) {
    // final horarios = _getHorariosParaDia(_focusedDay, periodos);

    return SfCalendar(
      view: CalendarView.week,
      dataSource: dataSource,
      firstDayOfWeek: 1, // Segunda-feira
      timeSlotViewSettings: const TimeSlotViewSettings(
        startHour: 7, // Exemplo, pode ser dinâmico
        endHour: 22,
        timeInterval: Duration(
          minutes: 15,
        ), // Exemplo para 15 min, pode ser dinâmico
        timeFormat: 'HH:mm',
      ),
      onTap: (details) {
        if (details.targetElement == CalendarElement.appointment &&
            details.appointments!.isNotEmpty) {
          // --- ALTERAÇÃO AQUI ---
          DialogoAgendamentoService.mostrarDialogoEdicaoAgendamento(
            context: context,
            appointment: details.appointments!.first,
            duracaoDaAgenda: duracaoPadraoParaTeste, // <-- ADICIONADO
          );
          // --- FIM DA ALTERAÇÃO ---
        } else if (details.targetElement == CalendarElement.calendarCell) {
          DialogoAgendamentoService.mostrarDialogoNovoAgendamento(
            context: context,
            dataInicial: details.date!,
            idAgenda: idAgenda, // Usa o ID fixo
            duracaoDaAgenda: duracaoPadraoParaTeste, // duração fixa
          );
        }
      },
    );
  }

  MeetingDataSource _getDataSourceCombinado(
    List<Agendamento> agendamentos,
    List<Bloqueio> bloqueios,
    List<UserModel> usuarios, // Recebe a lista de usuários
  ) {
    final List<Appointment> appointments = [];

    // Mapeia IDs de usuário para nomes para consulta rápida
    final mapaUsuarios = {for (var u in usuarios) u.id: u.primeiroNome};

    for (final agendamento in agendamentos) {
      // Procura o nome do usuário. Se não encontrar, usa o ID.
      final nomePaciente =
          mapaUsuarios[agendamento.idUsuario] ?? 'ID: ${agendamento.idUsuario}';

      appointments.add(
        Appointment(
          startTime: agendamento.dataHora,
          endTime: agendamento.dataHora.add(
            Duration(minutes: agendamento.duracao * duracaoPadraoParaTeste),
          ), // Ajuste na duracao
          subject: 'Agendado: $nomePaciente', // Mostra o nome do paciente
          color: AppColors.primary,
          // Armazena o objeto Agendamento COMPLETO para facilitar a exclusão
          resourceIds: [agendamento], //armazena o objeto Agendamento
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
          resourceIds: [bloqueio], // Armazena o objeto Bloqueio
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
    // 1. Filtra os eventos para o dia selecionado
    final eventsToday =
        appointments
            ?.where((appt) => isSameDay(appt.startTime, day))
            .toList()
            .cast<Appointment>() ??
        [];

    // 2. ORGANIZA (SORT) a lista pela hora de início
    eventsToday.sort((a, b) => a.startTime.compareTo(b.startTime));

    // 3. Retorna a lista organizada
    return eventsToday;
  }
}
