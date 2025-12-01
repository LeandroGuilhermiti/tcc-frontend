import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../models/agenda_model.dart';
import '../../models/bloqueio_model.dart';
import '../../providers/bloqueio_provider.dart';
import '../../theme/app_theme.dart'; // Importa NnkColors

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
        WidgetsBinding.instance.addPostFrameCallback((_) {
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
        backgroundColor: NnkColors.papelAntigo,
        title: const Text(
          'Excluir Bloqueio?',
          style: TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.bold, color: NnkColors.vermelhoLacre),
        ),
        content: Text(
          'Deseja remover o bloqueio de ${DateFormat('dd/MM HH:mm').format(bloqueio.dataHora)}?',
          style: const TextStyle(fontFamily: 'Alegreya', fontSize: 18, color: NnkColors.tintaCastanha),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: NnkColors.tintaCastanha)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: NnkColors.vermelhoLacre, fontWeight: FontWeight.bold)),
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

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bloqueio removido.'), backgroundColor: NnkColors.verdeErva),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: NnkColors.vermelhoLacre),
          );
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
                const SnackBar(content: Text('Duração atualizada com sucesso!'), backgroundColor: NnkColors.verdeErva),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: NnkColors.vermelhoLacre),
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
        backgroundColor: NnkColors.papelAntigo,
        appBar: AppBar(title: const Text('Bloqueios')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: NnkColors.ouroAntigo),
              SizedBox(height: 16),
              Text('Redirecionando...', style: TextStyle(fontFamily: 'Alegreya', color: NnkColors.tintaCastanha)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: NnkColors.papelAntigo,
      appBar: AppBar(
        title: Text(
          'Bloqueios: ${_agenda!.nome}',
          style: const TextStyle(
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
            color: NnkColors.tintaCastanha
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: NnkColors.ouroAntigo.withOpacity(0.5),
            height: 1.0,
          ),
        ),
      ),

      body: Consumer<BloqueioProvider>(
        builder: (ctx, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator(color: NnkColors.ouroAntigo));
          if (provider.bloqueios.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum bloqueio cadastrado.',
                style: TextStyle(fontFamily: 'Alegreya', fontSize: 18, color: NnkColors.tintaCastanha),
              )
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.bloqueios.length,
            itemBuilder: (ctx, i) {
              final bloqueio = provider.bloqueios[i];
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: NnkColors.ouroAntigo.withOpacity(0.3))
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: NnkColors.vermelhoLacre.withOpacity(0.1),
                    child: const Icon(Icons.block, color: NnkColors.vermelhoLacre),
                  ),
                  title: Text(
                    bloqueio.descricao, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cinzel', color: NnkColors.tintaCastanha)
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${DateFormat('dd/MM/yyyy - HH:mm').format(bloqueio.dataHora)}\n'
                      'Duração: ${bloqueio.duracao} h',
                      style: const TextStyle(fontFamily: 'Alegreya', fontSize: 15, color: Colors.black87),
                    ),
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: NnkColors.tintaCastanha), 
                        onPressed: () => _editarBloqueio(bloqueio)
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: NnkColors.vermelhoLacre), 
                        onPressed: () => _deletarBloqueio(bloqueio)
                      ),
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
      backgroundColor: NnkColors.papelAntigo,
      title: const Text(
        'Editar Duração', 
        style: TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.bold, color: NnkColors.tintaCastanha)
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: widget.bloqueio.descricao,
              enabled: false,
              style: const TextStyle(fontFamily: 'Alegreya', fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Descrição',
                labelStyle: TextStyle(color: NnkColors.tintaCastanha.withOpacity(0.7)),
                border: const OutlineInputBorder(),
                filled: true, 
                fillColor: NnkColors.cinzaSuave.withOpacity(0.2) // Cor suave para desabilitado
              ),
            ),
            const SizedBox(height: 16),

            const Text('Data e Início (Não editável)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: NnkColors.tintaCastanha, fontFamily: 'Cinzel')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NnkColors.ouroClaro.withOpacity(0.3), 
                      borderRadius: BorderRadius.circular(8), 
                      border: Border.all(color: NnkColors.ouroAntigo.withOpacity(0.5))
                    ),
                    child: Text(dataFormatada, style: const TextStyle(color: NnkColors.tintaCastanha, fontFamily: 'Alegreya', fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NnkColors.ouroClaro.withOpacity(0.3), 
                      borderRadius: BorderRadius.circular(8), 
                      border: Border.all(color: NnkColors.ouroAntigo.withOpacity(0.5))
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(horaFormatada, style: const TextStyle(color: NnkColors.tintaCastanha, fontFamily: 'Alegreya', fontSize: 16)),
                        const Icon(Icons.lock, size: 16, color: NnkColors.cinzaSuave),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text('Duração (em horas)', style: TextStyle(fontWeight: FontWeight.bold, color: NnkColors.tintaCastanha, fontFamily: 'Cinzel')),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: NnkColors.ouroAntigo),
                borderRadius: BorderRadius.circular(8),
                color: NnkColors.papelAntigo,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: NnkColors.vermelhoLacre),
                    onPressed: _decrementar,
                  ),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: _duracaoController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: NnkColors.tintaCastanha, fontFamily: 'Cinzel'),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        suffixText: " h"
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: NnkColors.verdeErva),
                    onPressed: _incrementar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('Cancelar', style: TextStyle(color: NnkColors.tintaCastanha))
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: NnkColors.tintaCastanha,
            foregroundColor: NnkColors.ouroAntigo,
          ),
          onPressed: _isLoading ? null : _salvar,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: NnkColors.ouroAntigo, strokeWidth: 2)) : const Text('Salvar'),
        ),
      ],
    );
  }
}