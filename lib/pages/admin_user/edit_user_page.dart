import 'package:flutter/material.dart';

// Importa o modelo que vamos receber
import '../../models/user_model.dart';

class PacienteEditPage extends StatefulWidget {
  final UserModel paciente;

  const PacienteEditPage({super.key, required this.paciente});

  @override
  State<PacienteEditPage> createState() => _PacienteEditPageState();
}

class _PacienteEditPageState extends State<PacienteEditPage> {
  // Podes usar controllers para os campos do formulário
  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.paciente.primeiroNome);
    _emailController = TextEditingController(text: widget.paciente.email);
    _telefoneController = TextEditingController(text: widget.paciente.telefone);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  void _salvarAlteracoes() {
    // TODO: Adicionar a lógica para salvar
    // 1. Chamar o UsuarioProvider (ex: provider.atualizarUsuario(...))
    // 2. Mostrar um SnackBar de sucesso
    // 3. Voltar para a tela anterior

    print('Salvando dados...');
    Navigator.pop(context); // Volta para a lista
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar: ${widget.paciente.primeiroNome}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          // Podes adicionar uma GlobalKey<FormState> para validação
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _salvarAlteracoes,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('Salvar Alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
