import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_controller.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart'; // Importe para usar no cadastro
import '../../services/user_service.dart'; // Importe o serviço diretamente para o POST

import '../../widgets/menu_lateral_cliente.dart'; 
import '/pages/client_user/selecao_agenda_page.dart';

class EditarDadosCliente extends StatefulWidget {
  // Adicionamos esta flag para distinguir os modos
  final bool isNovoCadastro;

  const EditarDadosCliente({
    super.key, 
    this.isNovoCadastro = false,
  });

  @override
  State<EditarDadosCliente> createState() => _EditarDadosClienteState();
}

class _EditarDadosClienteState extends State<EditarDadosCliente> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late TextEditingController _nomeController;
  late TextEditingController _sobrenomeController;
  late TextEditingController _emailController;
  late TextEditingController _cpfController;
  late TextEditingController _telefoneController;
  late TextEditingController _cepController;

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _cepFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  void _carregarDadosUsuario() {
    final auth = Provider.of<AuthController>(context, listen: false);
    final UserModel? usuario = auth.usuario; // Aqui usamos o usuario "temporário" criado no login

    _nomeController = TextEditingController(text: usuario?.primeiroNome ?? '');
    _sobrenomeController = TextEditingController(text: usuario?.sobrenome ?? '');
    _emailController = TextEditingController(text: usuario?.email ?? '');
    
    // Se for novo cadastro, o CPF provavelmente virá vazio do Cognito, então deixamos vazio.
    _cpfController = TextEditingController(text: _cpfFormatter.maskText(usuario?.cpf ?? ''));
    
    _telefoneController = TextEditingController(text: _telefoneFormatter.maskText(usuario?.telefone ?? ''));
    _cepController = TextEditingController(text: _cepFormatter.maskText(usuario?.cep ?? ''));
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    setState(() => _isSaving = true);

    final authController = Provider.of<AuthController>(context, listen: false);
    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final userService = UsuarioService(); // Instancia o serviço diretamente para o POST

    // Limpeza das máscaras
    final String telefoneSemMascara = _telefoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final String cepSemMascara = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final String cpfSemMascara = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');

    try {
      bool sucesso = false;

      // --- CENÁRIO 1: NOVO CADASTRO (POST) ---
      if (widget.isNovoCadastro) {
        
        // Montamos o objeto completo para o banco de dados
        final Map<String, dynamic> dadosNovoUsuario = {
          'id': authController.usuario!.id, // ID QUE VEIO DO COGNITO (Injetado no Login)
          'nome': _nomeController.text.trim(), // Ajuste conforme seu backend espera (nome ou givenName?)
          'sobrenome': _sobrenomeController.text.trim(),
          'email': _emailController.text.trim(),
          'cpf': cpfSemMascara,
          'cep': cepSemMascara,
          'telefone': telefoneSemMascara,
          'tipo': 0, // 0 = Cliente Comum
        };

        // Fazemos o POST
        await userService.cadastrarUsuario(
          dadosNovoUsuario, 
          authController.usuario!.idToken!
        );
        
        // Se não deu Exception, foi sucesso.
        // PRECISAS ADICIONAR UM MÉTODO NO AUTHCONTROLLER PARA ATUALIZAR O ESTADO
        // Exemplo: authController.concluirCadastro();
        // Por enquanto, vamos forçar uma atualização manual no model local:
        authController.atualizarUsuarioLocalmente(
             cadastroPendente: false,
             cpf: cpfSemMascara,
             telefone: telefoneSemMascara,
             cep: cepSemMascara
        );
        
        sucesso = true;

      } 
      // --- CENÁRIO 2: EDIÇÃO (PATCH) ---
      else {
        final Map<String, dynamic> dadosAtualizados = {
          'telefone': telefoneSemMascara,
          'cep': cepSemMascara,
        };
        sucesso = await userProvider.atualizarUsuario(dadosAtualizados);
      }

      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dados salvos com sucesso!'),
          backgroundColor: Colors.green,
        ));

        // Redireciona para a home (o main.dart vai reconstruir e ver que cadastroPendente agora é false)
        Navigator.of(context).pushReplacementNamed('/selecao_cliente'); 
      } 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se for novo cadastro, não mostra menu lateral (drawer), pois ele ainda não "entrou" no sistema
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNovoCadastro ? 'Finalizar Cadastro' : 'Editar Meus Dados'),
        // Remove botão de voltar se for novo cadastro para obrigar o preenchimento
        automaticallyImplyLeading: !widget.isNovoCadastro, 
      ),
      drawer: widget.isNovoCadastro ? null : const AppDrawerCliente(currentPage: AppDrawerPage.perfil),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (widget.isNovoCadastro)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  "Olá! Vimos que é seu primeiro acesso. Por favor, confirme seus dados para continuar.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),

            // --- Card de Informações Pessoais ---
            Card(
              elevation: 2, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dados Pessoais", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    
                    // NOME E SOBRENOME (Geralmente vem do Cognito, ReadOnly)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nomeController,
                            readOnly: true, // Cognito manda, não edita
                            decoration: const InputDecoration(labelText: 'Nome', filled: true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _sobrenomeController,
                            readOnly: true,
                            decoration: const InputDecoration(labelText: 'Sobrenome', filled: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // EMAIL (ReadOnly)
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), filled: true),
                    ),
                    const SizedBox(height: 16),
                    
                    // CPF - LÓGICA DE BLOQUEIO
                    // Se é novo cadastro, permite editar. Se é edição, bloqueia.
                    TextFormField(
                      controller: _cpfController,
                      // Só pode editar se for NOVO cadastro
                      readOnly: !widget.isNovoCadastro, 
                      inputFormatters: [_cpfFormatter],
                      decoration: InputDecoration(
                        labelText: 'CPF',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        filled: !widget.isNovoCadastro, // Cinza se bloqueado
                        // Helper text para avisar
                        helperText: widget.isNovoCadastro ? 'Obrigatório para agendamentos' : null,
                      ),
                      validator: (value) {
                         if (widget.isNovoCadastro) {
                            if (value == null || value.isEmpty) return 'Obrigatório';
                            if (_cpfFormatter.getUnmaskedText().length != 11) return 'CPF incompleto';
                         }
                         return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Card de Contato ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _telefoneController,
                      decoration: const InputDecoration(labelText: 'Telefone', prefixIcon: Icon(Icons.phone_outlined)),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_telefoneFormatter],
                      validator: (v) => v!.length < 14 ? 'Inválido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cepController,
                      decoration: const InputDecoration(labelText: 'CEP', prefixIcon: Icon(Icons.location_on_outlined)),
                      keyboardType: TextInputType.number,
                      inputFormatters: [_cepFormatter],
                      validator: (v) => _cepFormatter.getUnmaskedText().length < 8 ? 'Inválido' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _salvarPerfil,
                style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   backgroundColor: widget.isNovoCadastro ? Colors.blueAccent : null, // Destaque se for novo
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.isNovoCadastro ? 'FINALIZAR CADASTRO' : 'SALVAR ALTERAÇÕES'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}