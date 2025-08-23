import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tcc_frontend/theme/app_colors.dart';

import 'package:tcc_frontend/models/agendamento_model.dart';
import 'package:tcc_frontend/models/bloqueio_model.dart';
import 'package:tcc_frontend/models/periodo_model.dart';

import 'package:tcc_frontend/providers/agendamento_provider.dart';
import 'package:tcc_frontend/providers/bloqueio_provider.dart';
import 'package:tcc_frontend/providers/periodo_provider.dart';

class HomePageAdmin extends StatefulWidget {
  const HomePageAdmin({super.key});

  @override
  State<HomePageAdmin> createState() => _HomePageAdminState();
}

class _HomePageAdminState extends State<HomePageAdmin> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _mostrarTabela = true;
  final String idAgenda = "0"; // Exemplo: Pegue o ID do profissional logado

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Dispara o carregamento de todos os dados necessários assim que a tela é construída
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDadosIniciais();
    });
  }

  void _carregarDadosIniciais() {
    // Usamos 'listen: false' dentro do initState para apenas disparar as ações
    final periodoProvider = Provider.of<PeriodoProvider>(
      context,
      listen: false,
    );
    final agendamentoProvider = Provider.of<AgendamentoProvider>(
      context,
      listen: false,
    );
    final bloqueioProvider = Provider.of<BloqueioProvider>(
      context,
      listen: false,
    );

    // Chama os métodos para carregar os dados de cada provider
    periodoProvider.carregarPeriodos(idAgenda);
    agendamentoProvider.carregarAgendamentos(idAgenda);
    bloqueioProvider.carregarBloqueios(idAgenda);
  }

  // Suas funções de diálogo para criar/editar agendamentos permanecem aqui
  // Lembre-se de chamar os métodos do provider para salvar as alterações
  void _abrirDialogoAgendamento(
    BuildContext context,
    DateTime dataSelecionada,
  ) {
    /* ... Sua lógica de diálogo aqui ... */
    // Ao salvar, você chamaria algo como:
    // Provider.of<AgendamentoProvider>(context, listen: false).adicionarAgendamento(novoAgendamento);
  }

  void _abrirDialogoEdicao(BuildContext context, Appointment appointment) {
    /* ... Sua lógica de diálogo aqui ... */
    // Ao salvar, você chamaria algo como:
    // Provider.of<AgendamentoProvider>(context, listen: false).atualizarAgendamento(agendamentoEditado);
  }

  @override
  Widget build(BuildContext context) {
    // "Ouve" os providers para reagir a mudanças de estado (como o fim do carregamento)
    final periodoProvider = context.watch<PeriodoProvider>();
    final agendamentoProvider = context.watch<AgendamentoProvider>();
    final bloqueioProvider = context.watch<BloqueioProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Admin Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _carregarDadosIniciais, // Adiciona um botão para recarregar os dados
          ),
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
              title: const Text('Editar agenda'),
              onTap: () => Navigator.pushNamed(context, '/editor'),
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
            color: AppColors.details, // texto quando não selecionado
            selectedColor: Colors.white, // texto quando selecionado
            fillColor: AppColors.details, // fundo quando selecionado
            borderColor: Colors.blueGrey, // borda quando não selecionado
            selectedBorderColor: AppColors.details, // borda quando selecionado
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
          ),
          const SizedBox(height: 8),
          Expanded(
            // Verifica se algum dos providers ainda está carregando os dados
            child:
                (periodoProvider.isLoading ||
                    agendamentoProvider.isLoading ||
                    bloqueioProvider.isLoading)
                ? const Center(
                    child: CircularProgressIndicator(),
                  ) // Mostra o loading
                : _buildCalendarContent(
                    // Constrói o conteúdo do calendário
                    periodoProvider,
                    agendamentoProvider,
                    bloqueioProvider,
                  ),
          ),
        ],
      ),
    );
  }

  /// Constrói o conteúdo principal do calendário (Mês ou Semana)
  Widget _buildCalendarContent(
    PeriodoProvider periodoProvider,
    AgendamentoProvider agendamentoProvider,
    BloqueioProvider bloqueioProvider,
  ) {
    // Combina agendamentos e bloqueios em uma única lista para os calendários
    final dataSource = _getDataSourceCombinado(
      agendamentoProvider.agendamentos,
      bloqueioProvider.bloqueios,
    );

    // Lógica para a visão de Mês (TableCalendar)
    if (_mostrarTabela) {
      return Column(
        children: [
          TableCalendar(
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
            // Usa o dataSource combinado para marcar os dias com eventos
            eventLoader: (day) {
              return dataSource.getEventsForDay(day);
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
            child: ListView.builder(
              itemCount: dataSource.getEventsForDay(_selectedDay!).length,
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
                );
              },
            ),
          ),
        ],
      );
    }
    // Lógica para a visão de Semana (SfCalendar)
    else {
      // Determina os horários de trabalho para o dia focado
      final horarios = _getHorariosParaDia(
        _focusedDay,
        periodoProvider.periodos,
      );

      return SfCalendar(
        view: CalendarView.week,
        dataSource: dataSource,
        firstDayOfWeek: 1, // Segunda-feira
        // Configura a estrutura do calendário com base nos períodos de trabalho
        timeSlotViewSettings: TimeSlotViewSettings(
          startHour: horarios.startHour,
          endHour: horarios.endHour,
          timeInterval: const Duration(
            minutes: 15,
          ), // Pode vir do seu model `Agenda`
          // ... resto das suas configurações ...
        ),
        headerStyle: CalendarHeaderStyle(
          backgroundColor: AppColors.backgroundLight,  
          textAlign: TextAlign.center,  
          textStyle: TextStyle(
          color: AppColors.textPrimary,     
          fontSize: 18,
          fontWeight: FontWeight.bold,
          ),
        ),
        onTap: (details) {
          if (details.targetElement == CalendarElement.appointment) {
            _abrirDialogoEdicao(context, details.appointments!.first);
          } else if (details.targetElement == CalendarElement.calendarCell) {
            _abrirDialogoAgendamento(context, details.date!);
          }
        },
        // ... resto do seu SfCalendar ...
      );
    }
  }

  /// Encontra os horários de início e fim para um dia específico da semana
  ({double startHour, double endHour}) _getHorariosParaDia(
    DateTime dia,
    List<Periodo> periodos,
  ) {
    // dia.weekday retorna 1 para Segunda, 7 para Domingo. Seu modelo usa 0-6? Ajuste se necessário.
    final periodosDoDia = periodos
        .where((p) => p.diaDaSemana == dia.weekday)
        .toList();

    if (periodosDoDia.isEmpty) {
      return (
        startHour: 9,
        endHour: 18,
      ); // Horário padrão se não houver período
    }

    // Encontra o horário mais cedo de início e o mais tarde de fim
    final inicio = periodosDoDia
        .map((p) => DateFormat('HH:mm').parse(p.inicio))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final fim = periodosDoDia
        .map((p) => DateFormat('HH:mm').parse(p.fim))
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return (
      startHour: inicio.hour + inicio.minute / 60.0,
      endHour: fim.hour + fim.minute / 60.0,
    );
  }

  /// Combina Agendamentos e Bloqueios em um único DataSource para os calendários
  MeetingDataSource _getDataSourceCombinado(
    List<Agendamento> agendamentos,
    List<Bloqueio> bloqueios,
  ) {
    final List<Appointment> appointments = [];

    // Adiciona os agendamentos (em azul)
    for (final agendamento in agendamentos) {
      appointments.add(
        Appointment(
          startTime: agendamento.dataHora,
          endTime: agendamento.dataHora.add(
            Duration(minutes: agendamento.duracao),
          ),
          subject: 'Agendado para ${agendamento.idUsuario}', // Exemplo
          color: AppColors.primary,
        ),
      );
    }

    // Adiciona os bloqueios (em cinza)
    for (final bloqueio in bloqueios) {
      appointments.add(
        Appointment(
          startTime: bloqueio.dataHora,
          endTime: bloqueio.dataHora.add(Duration(minutes: bloqueio.duracao)),
          subject: bloqueio.descricao,
          color: Colors.grey.shade400,
        ),
      );
    }

    return MeetingDataSource(appointments);
  }
}

/// Um DataSource customizado para funcionar com ambos os calendários
class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }

  List<Appointment> getEventsForDay(DateTime day) {
    return appointments?.where((appt) {
          return isSameDay(appt.startTime, day);
        }).toList() ??
        [];
  }
}
