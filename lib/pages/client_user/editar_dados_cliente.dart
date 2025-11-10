import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_controller.dart';
import '../../providers/user_provider.dart';
import '../../widgets/menu_lateral_cliente.dart'; // Importa o menu lateral

class EditarDadosCliente extends StatefulWidget {
  const EditarDadosCliente({super.key});

  @override
  State<EditarDadosCliente> createState() => _EditarDadosClienteState();
}

class _EditarDadosClienteState extends State<EditarDadosCliente> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Controladores de texto
  late TextEditingController _nomeController;
  late TextEditingController _sobrenomeController;
  late TextEditingController _emailController;
  late TextEditingController _cpfController;
  late TextEditingController _telefoneController;
  late TextEditingController _cepController;

  // Máscaras de formatação
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
    // Carrega os dados do usuário logado assim que a página inicia
    _carregarDadosUsuario();
  }

  void _carregarDadosUsuario() {
    // Pega o AuthController sem 'ouvir' (listen: false)
    final auth = Provider.of<AuthController>(context, listen: false);
    final UserModel? usuario = auth.usuario;

    // Inicializa os controladores com os dados do usuário
    _nomeController =
        TextEditingController(text: usuario?.primeiroNome ?? '');
    _sobrenomeController =
        TextEditingController(text: usuario?.sobrenome ?? '');
    _emailController = TextEditingController(text: usuario?.email ?? '');
    _cpfController = TextEditingController(
        text: _cpfFormatter.maskText(usuario?.cpf ?? ''));
    _telefoneController = TextEditingController(
        text: _telefoneFormatter.maskText(usuario?.telefone ?? ''));
    _cepController = TextEditingController(
        text: _cepFormatter.maskText(usuario?.cep ?? ''));
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) {
      return; // Se o formulário for inválido, não faz nada
    }

    setState(() {
      _isSaving = true;
    });
    //pegando o texto mascarado de dentro dos controllers
    final String telefoneMascarado = _telefoneController.text;
    final String cepMascarado = _cepController.text;

    //Remove manualmente as máscaras, sempre que editar ou não
    final String telefoneSemMascara =
        telefoneMascarado.replaceAll(RegExp(r'[^0-9]'), '');
    final String cepSemMascara =
        cepMascarado.replaceAll(RegExp(r'[^0-9]'), '');

    // Monta o mapa SÓ com os dados que podem ser alterados
    final Map<String, dynamic> dadosAtualizados = {
      // 'primeiroNome': _nomeController.text.trim(),
      // 'sobrenome': _sobrenomeController.text.trim(),
      'telefone': telefoneSemMascara,
      'cep': cepSemMascara,
      // Nota: Não enviamos email ou cpf, pois são imutáveis
    };

    try {
      // Chama o provider para salvar os dados
      final sucesso = await Provider.of<UsuarioProvider>(context, listen: false)
          .atualizarUsuario(dadosAtualizados);

      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        // Se der erro, o provider terá a mensagem
        final erro = Provider.of<UsuarioProvider>(context, listen: false).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $erro'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocorreu um erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Meus Dados'),
      ),
      // Adiciona o menu lateral, marcando 'perfil' como página atual
      drawer: const AppDrawerCliente(currentPage: AppDrawerPage.perfil),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Card de Informações Pessoais ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Meus Dados",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    // Nome e Sobrenome (só leitura)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nomeController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Obrigatório'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _sobrenomeController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Sobrenome',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // E-mail (Não Editável)
                    TextFormField(
                      controller: _emailController,
                      readOnly: true, // Bloqueado
                      decoration: const InputDecoration(
                        labelText: 'Email (não pode ser alterado)',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color.fromARGB(255, 235, 235, 235),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // CPF (Não Editável)
                    TextFormField(
                      controller: _cpfController,
                      readOnly: true, // Bloqueado
                      inputFormatters: [_cpfFormatter],
                      decoration: const InputDecoration(
                        labelText: 'CPF (não pode ser alterado)',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color.fromARGB(255, 235, 235, 235),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Card de Contato (Editável) ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Contato",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _telefoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefone',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_telefoneFormatter],
                      validator: (value) => value == null || value.length < 15
                          ? 'Telefone inválido'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cepController,
                      decoration: const InputDecoration(
                        labelText: 'CEP',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [_cepFormatter],
                      validator: (value) =>
                          _cepFormatter.getUnmaskedText().isNotEmpty &&
                                  _cepFormatter.getUnmaskedText().length < 8
                              ? 'CEP inválido'
                              : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botão de Ação Principal
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _salvarPerfil,
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text('Salvar Alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}