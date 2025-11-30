import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../models/agenda_model.dart';
import '../../models/bloqueio_model.dart';
import '../../providers/bloqueio_provider.dart';

class BloqueioListPage extends StatefulWidget {
  const BloqueioListPage({super.key});

  @override
  State<BloqueioListPage> createState() => _BloqueioListPageState();
}

class _BloqueioListPageState extends State<BloqueioListPage> {
  bool _isInit = true;
  Agenda? _agenda;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      
      // 1. Verifica se recebemos a Agenda corretamente
      if (args is Agenda) {
        _agenda = args;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<BloqueioProvider>(context, listen: false)
              .carregarBloqueios(_agenda!.id!);
        });
      } else {
        // 2. CASO DE ERRO (F5 ou acesso direto): Redirecionar
        // Agendamos o redirecionamento para após a construção do widget
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Volta para a rota '/agendas' (ou a tua rota principal de admin)
          Navigator.of(context).pushReplacementNamed('/agendas');
        });
      }
      _isInit = false;
    }
  }

  Future<void> _deletarBloqueio(Bloqueio bloqueio) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Bloqueio?'),
        content: Text('Deseja remover o bloqueio de ${DateFormat('dd/MM HH:mm').format(bloqueio.dataHora)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted && _agenda != null && _agenda!.id != null) {
      try {
        final int agendaIdInt = int.parse(_agenda!.id!);
        
        await Provider.of<BloqueioProvider>(context, listen: false)
            .excluirBloqueio(agendaIdInt, bloqueio.dataHora);
        
        if (mounted) {
          await Provider.of<BloqueioProvider>(context, listen: false)
              .carregarBloqueios(_agenda!.id!);

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bloqueio removido.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
        }
      }
    }
  }

  void _editarBloqueio(Bloqueio bloqueio) {
    showDialog(
      context: context,
      builder: (ctx) => DialogEditarBloqueio(
        bloqueio: bloqueio,
        onSalvar: (bloqueioEditado) async {
          try {
            await Provider.of<BloqueioProvider>(context, listen: false)
                .atualizarBloqueio(bloqueioEditado);
            
            if (mounted) {
              Navigator.pop(ctx);
              await Provider.of<BloqueioProvider>(context, listen: false)
                  .carregarBloqueios(_agenda!.id!);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Duração atualizada com sucesso!')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao atualizar: $e')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 3. Interface de Loading enquanto redireciona
    if (_agenda == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bloqueios')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Redirecionando...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Bloqueios: ${_agenda!.nome}')),

      body: Consumer<BloqueioProvider>(
        builder: (ctx, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.bloqueios.isEmpty) return const Center(child: Text('Nenhum bloqueio cadastrado.'));

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.bloqueios.length,
            itemBuilder: (ctx, i) {
              final bloqueio = provider.bloqueios[i];
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.block, color: Colors.white),
                  ),
                  title: Text(bloqueio.descricao, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy - HH:mm').format(bloqueio.dataHora)}\n'
                    'Duração: ${bloqueio.duracao} h', 
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editarBloqueio(bloqueio)),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deletarBloqueio(bloqueio)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DialogEditarBloqueio extends StatefulWidget {
  final Bloqueio bloqueio;
  final Function(Bloqueio) onSalvar;

  const DialogEditarBloqueio({
    super.key,
    required this.bloqueio,
    required this.onSalvar,
  });

  @override
  State<DialogEditarBloqueio> createState() => _DialogEditarBloqueioState();
}

class _DialogEditarBloqueioState extends State<DialogEditarBloqueio> {
  late TextEditingController _duracaoController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _duracaoController = TextEditingController(text: widget.bloqueio.duracao.toString());
  }

  @override
  void dispose() {
    _duracaoController.dispose();
    super.dispose();
  }

  void _incrementar() {
    int valor = int.tryParse(_duracaoController.text) ?? 0;
    valor++;
    setState(() {
      _duracaoController.text = valor.toString();
    });
  }

  void _decrementar() {
    int valor = int.tryParse(_duracaoController.text) ?? 0;
    if (valor > 1) {
      valor--;
      setState(() {
        _duracaoController.text = valor.toString();
      });
    }
  }

  void _salvar() {
    if (_duracaoController.text.isEmpty) return;
    
    setState(() => _isLoading = true);

    final int novaDuracao = int.parse(_duracaoController.text);

    final bloqueioEditado = Bloqueio(
      id: widget.bloqueio.id,
      idAgenda: widget.bloqueio.idAgenda,
      descricao: widget.bloqueio.descricao,
      dataHora: widget.bloqueio.dataHora, 
      duracao: novaDuracao, 
    );

    widget.onSalvar(bloqueioEditado);
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yyyy').format(widget.bloqueio.dataHora);
    final horaFormatada = DateFormat('HH:mm').format(widget.bloqueio.dataHora);

    return AlertDialog(
      title: const Text('Editar Duração'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: widget.bloqueio.descricao,
              enabled: false,
              decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder(), filled: true, fillColor: Color(0xFFF5F5F5)),
            ),
            const SizedBox(height: 16),

            const Text('Data e Início (Não editável)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade400)),
                    child: Text(dataFormatada, style: const TextStyle(color: Colors.black54)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade400)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(horaFormatada, style: const TextStyle(color: Colors.black54)),
                        const Icon(Icons.lock, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text('Duração (em horas)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(4),
                color: Colors.blue.withOpacity(0.05),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: _decrementar,
                  ),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: _duracaoController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        suffixText: " h"
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                    onPressed: _incrementar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isLoading ? null : _salvar,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
        ),
      ],
    );
  }
}