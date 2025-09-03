import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tcc_frontend/models/agenda_model.dart';
import 'package:tcc_frontend/models/periodo_model.dart';
import 'package:tcc_frontend/providers/agenda_provider.dart';

class AgendaEditorPage extends StatefulWidget {
  const AgendaEditorPage({super.key});

  @override
  State<AgendaEditorPage> createState() => _AgendaEditorPageState();
}

class _AgendaEditorPageState extends State<AgendaEditorPage> {
  // Chave para o formulário, usada para validação
  final _formKey = GlobalKey<FormState>(); 
  final TextEditingController _profissionalController = TextEditingController();
  final TextEditingController _describeController = TextEditingController();

  // Mapeia o nome do dia para o número correspondente (DateTime.monday = 1)
  final Map<String, int> diasSemanaMap = {
    'Seg': 1, 'Ter': 2, 'Qua': 3, 'Qui': 4, 'Sex': 5, 'Sáb': 6,
  };
  final List<String> diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
  final Map<String, bool> diasSelecionados = {
    'Seg': false, 'Ter': false, 'Qua': false, 'Qui': false, 'Sex': false, 'Sáb': false,
  };

  // Controle do Horário Fixo
  bool horarioFixo = false;
  TimeOfDay horaInicioFixo = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay horaFimFixo = const TimeOfDay(hour: 17, minute: 0);

  // Horários individuais para cada dia (se horarioFixo == false)
  final Map<String, TimeOfDay> inicioPorDia = {};
  final Map<String, TimeOfDay> fimPorDia = {};

  String duracaoConsulta = '30 min';
  final List<String> opcoesDuracao = ['15 min', '30 min', '45 min', '60 min'];

  bool _isSaving = false; // Estado para controlar o loading do botão salvar

  Future<void> _selecionarHora(BuildContext context, bool isInicio, {String? dia}) async {
    TimeOfDay initialTime;
    if (horarioFixo) {
      initialTime = isInicio ? horaInicioFixo : horaFimFixo;
    } else {
      if (dia == null) return;
      initialTime = isInicio ? (inicioPorDia[dia] ?? const TimeOfDay(hour: 8, minute: 0)) : (fimPorDia[dia] ?? const TimeOfDay(hour: 17, minute: 0));
    }

    final TimeOfDay? horaSelecionada = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (horaSelecionada != null) {
      setState(() {
        if (horarioFixo) {
          if (isInicio) {
            horaInicioFixo = horaSelecionada;
          } else {
            horaFimFixo = horaSelecionada;
          }
        } else {
          if (dia == null) return;
          if (isInicio) {
            inicioPorDia[dia] = horaSelecionada;
          } else {
            fimPorDia[dia] = horaSelecionada;
          }
        }
      });
    }
  }

  Future<void> _salvarAgenda() async {
    // 1. Valida o formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isSaving = true; });

    // 2. Prepara os objetos Agenda e Periodo com base nos dados da tela
    final agenda = Agenda(
      nome: _profissionalController.text.trim(),
      descricao: _describeController.text.trim(),
      duracao: duracaoConsulta.replaceAll(' min', ''), // Salva apenas o número
      // aviso: "Nenhum aviso", // possivel adição
    );

    final periodos = diasSelecionados.entries
        .where((e) => e.value) // Pega apenas os dias selecionados
        .map((e) {
      final diaKey = e.key;
      final diaNumero = diasSemanaMap[diaKey]!; // Converte 'Seg' para 1, 'Ter' para 2, etc.
      
      TimeOfDay inicio = horarioFixo ? horaInicioFixo : (inicioPorDia[diaKey] ?? const TimeOfDay(hour: 8, minute: 0));
      TimeOfDay fim = horarioFixo ? horaFimFixo : (fimPorDia[diaKey] ?? const TimeOfDay(hour: 17, minute: 0));

      // Cria o objeto Periodo usando o construtor correto do seu modelo
      return Periodo(
        idAgenda: '', // O backend deve associar este período à agenda que está sendo criada
        diaDaSemana: diaNumero,
        inicio: inicio,
        fim: fim,
      );
    }).toList();
    
    // 3. Chama o Provider para fazer o trabalho pesado
    try {
      final agendaProvider = Provider.of<AgendaProvider>(context, listen: false);
      // Supondo que você tenha um método para salvar ambos no provider
      await agendaProvider.adicionarAgendaCompleta(agenda, periodos); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agenda salva com sucesso!')),
        );
        Navigator.of(context).pop(); // Volta para a tela anterior após o sucesso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar agenda: ${e.toString()}')),
        );
      }
    } finally {
      // Garante que o estado de loading seja desativado, mesmo que dê erro
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editor de Agenda')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form( // Adicionado um Form para validação
          key: _formKey,
          child: ListView(
            children: [
              TextFormField( // Trocado para TextFormField para validação
                controller: _profissionalController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Profissional',
                  hintText: 'Ex.: Dr. João Silva',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o nome.';
                  }
                  return null;
                },
              ),
              TextFormField( // Também trocado para TextFormField
                controller: _describeController,
                decoration: const InputDecoration(
                  labelText: 'Descrição breve',
                  hintText: 'Ex.: Insira uma Descrição',
                ),
                // Pode adicionar um validator aqui também se for obrigatório
              ),
              const SizedBox(height: 20),
              const Text('Dias de Atendimento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Wrap(
                children: diasSemana.map((dia) {
                  return CheckboxListTile(
                    title: Text(dia),
                    value: diasSelecionados[dia],
                    onChanged: (bool? valor) {
                      setState(() {
                        diasSelecionados[dia] = valor ?? false;
                        if (!horarioFixo && valor == true) {
                          inicioPorDia.putIfAbsent(dia, () => const TimeOfDay(hour: 8, minute: 0));
                          fimPorDia.putIfAbsent(dia, () => const TimeOfDay(hour: 17, minute: 0));
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Horário Fixo para todos os dias'),
                value: horarioFixo,
                onChanged: (bool value) {
                  // ... sua lógica de onChanged do Switch permanece a mesma ...
                },
              ),
              const SizedBox(height: 10),
              // O resto da sua UI para selecionar os horários permanece o mesmo
              // ... if (horarioFixo) ... [ ... ] else ... [ ... ]
              const SizedBox(height: 20),
              const Text('Duração da Consulta',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: duracaoConsulta,
                isExpanded: true,
                items: opcoesDuracao.map((String valor) {
                  return DropdownMenuItem<String>(
                    value: valor,
                    child: Text(valor),
                  );
                }).toList(),
                onChanged: (String? novoValor) {
                  setState(() {
                    duracaoConsulta = novoValor!;
                  });
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                // Desabilita o botão enquanto está salvando e mostra o loading
                onPressed: _isSaving ? null : _salvarAgenda, 
                child: _isSaving
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text('Salvar Agenda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}