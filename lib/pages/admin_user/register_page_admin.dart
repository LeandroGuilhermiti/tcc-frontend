import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tcc_frontend/models/user_model.dart';
import 'package:tcc_frontend/providers/user_provider.dart';

class RegisterPageAdmin extends StatefulWidget {
  const RegisterPageAdmin({super.key});

  @override
  _RegisterPageAdminState createState() => _RegisterPageAdminState();
}

class _RegisterPageAdminState extends State<RegisterPageAdmin> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cepController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();

  String? _tipoSelecionado;

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _cepController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _salvarUsuario() {
    if (_formKey.currentState!.validate()) {
      final novoUsuario = UserModel(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        cpf: _cpfController.text.trim(),
        cep: _cepController.text.trim(),
        telefone: _telefoneController.text.trim(),
        role: _tipoSelecionado == 'admin' ? UserRole.admin : UserRole.cliente,
      );

      Provider.of<UsuarioProvider>(context, listen: false)
          .adicionarUsuario(novoUsuario);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário cadastrado com sucesso')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastrar Usuário'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(labelText: 'Nome'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o nome' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || !value.contains('@') ? 'Email inválido' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _cpfController,
                decoration: InputDecoration(labelText: 'CPF'),
                keyboardType: TextInputType.number,
                maxLength: 11,
                validator: (value) =>
                    value == null || value.length != 11 ? 'CPF inválido' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _cepController,
                decoration: InputDecoration(labelText: 'CEP'),
                keyboardType: TextInputType.number,
                maxLength: 8,
                validator: (value) =>
                    value == null || value.length != 8 ? 'CEP inválido' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _telefoneController,
                decoration: InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
                maxLength: 11,
                validator: (value) => value == null || value.length < 10
                    ? 'Telefone inválido'
                    : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Tipo'),
                value: _tipoSelecionado,
                items: ['cliente', 'admin']
                    .map((tipo) => DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo[0].toUpperCase() + tipo.substring(1)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _tipoSelecionado = value),
                validator: (value) =>
                    value == null ? 'Selecione o tipo' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarUsuario,
                child: Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
