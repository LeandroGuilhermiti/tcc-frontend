import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/agenda_model.dart';
import '../../models/bloqueio_model.dart';
import '../../providers/agenda_provider.dart';
import '../../providers/bloqueio_provider.dart';

class BloqueioCreatePage extends StatefulWidget {
  const BloqueioCreatePage({super.key});

  @override
  State<BloqueioCreatePage> createState() => _BloqueioCreatePageState();
}

class _BloqueioCreatePageState extends State<BloqueioCreatePage> {
  final _formKey = GlobalKey<FormState>();
  
  Agenda? _selectedAgenda;
  DateTime _dataSelecionada = DateTime.now();
  TimeOfDay _horaInicio = const TimeOfDay(hour: 8, minute: 0);
  
  // --- ALTERAÇÃO 1: Variável inteira para controlar as horas ---
  int _horasSelecionadas = 1; 
  
  final _descricaoController = TextEditingController();
  
  bool _isLoading = false;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Agenda) {
        setState(() {
          _selectedAgenda = args;
        });
      }
      Provider.of<AgendaProvider>(context, listen: false).buscarTodasAgendas();
      _isInit = false;
    }
  }

  Future<void> _selecionarData(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
      });
    }
  }

  Future<void> _selecionarHora(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaInicio,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _horaInicio = picked;
      });
    }
  }

  Future<void> _salvarBloqueio() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAgenda == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma agenda')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dataHoraInicio = DateTime(
        _dataSelecionada.year,
        _dataSelecionada.month,
        _dataSelecionada.day,
        _horaInicio.hour,
        _horaInicio.minute,
      );

      // --- ALTERAÇÃO 2: Cálculo simples (Horas Inteiras * 60) ---
      final int duracaoEmMinutos = _horasSelecionadas * 60;

      final novoBloqueio = Bloqueio(
        id: null,
        idAgenda: _selectedAgenda!.id!,
        dataHora: dataHoraInicio,
        duracao: duracaoEmMinutos,
        descricao: _descricaoController.text,
      );

      await Provider.of<BloqueioProvider>(context, listen: false)
          .cadastrarBloqueio(novoBloqueio);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bloqueio criado com sucesso!')),
      );

      Navigator.of(context).pop(); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar bloqueio: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Métodos auxiliares para incrementar/decrementar
  void _incrementarHoras() {
    setState(() {
      _horasSelecionadas++;
    });
  }

  void _decrementarHoras() {
    if (_horasSelecionadas > 1) {
      setState(() {
        _horasSelecionadas--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final agendaProvider = Provider.of<AgendaProvider>(context);
    
    List<Agenda> listaAgendas = [...agendaProvider.agendas];
    
    if (_selectedAgenda != null && _selectedAgenda!.id != null) {
      final existe = listaAgendas.any((a) => a.id == _selectedAgenda!.id);
      if (!existe) {
        listaAgendas.add(_selectedAgenda!);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Novo Bloqueio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Agenda',
                  border: OutlineInputBorder(),
                ),
                value: _selectedAgenda?.id,
                items: listaAgendas.map((agenda) {
                  return DropdownMenuItem(
                    value: agenda.id,
                    child: Text(agenda.nome), 
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    _selectedAgenda = listaAgendas.firstWhere((a) => a.id == valor);
                  });
                },
                validator: (value) => value == null ? 'Selecione a agenda' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selecionarData(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_dataSelecionada)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selecionarHora(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Início',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(_horaInicio.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- ALTERAÇÃO 3: Seletor Intuitivo de Horas (+/-) ---
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Duração (horas inteiras)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botão Menos
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 28),
                      color: Colors.red[400],
                      onPressed: _horasSelecionadas > 1 ? _decrementarHoras : null,
                      tooltip: 'Diminuir horas',
                    ),
                    
                    // Texto Central
                    Text(
                      '$_horasSelecionadas h',
                      style: const TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold,
                        color: Colors.black87
                      ),
                    ),
                    
                    // Botão Mais
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 28),
                      color: Theme.of(context).primaryColor,
                      onPressed: _incrementarHoras,
                      tooltip: 'Aumentar horas',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo do Bloqueio',
                  hintText: 'Ex: Férias, Médico, Ausência',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Informe o motivo' : null,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _salvarBloqueio,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Criar Bloqueio',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}