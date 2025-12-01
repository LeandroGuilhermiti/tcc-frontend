import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

// Imports de Modelos e Serviços
import '../../models/user_model.dart';
import '../../models/endereco_model.dart'; // Necessário para a busca de CEP
import '../../providers/auth_controller.dart';
import '../../providers/user_provider.dart';
import '../../services/user_service.dart';
import '../../services/cep_service.dart'; // Necessário para a busca de CEP

import '../../widgets/menu_lateral_cliente.dart'; 
// import '/pages/client_user/selecao_agenda_page.dart'; // Descomente se necessário

class EditarDadosCliente extends StatefulWidget {
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
  bool _isSearchingCep = false;

  // Lista de UFs (Igual ao Admin)
  final Map<String, String> listaUFs = {
    'AC': 'Acre', 'AL': 'Alagoas', 'AP': 'Amapá', 'AM': 'Amazonas', 'BA': 'Bahia',
    'CE': 'Ceará', 'DF': 'Distrito Federal', 'ES': 'Espírito Santo', 'GO': 'Goiás',
    'MA': 'Maranhão', 'MT': 'Mato Grosso', 'MS': 'Mato Grosso do Sul', 'MG': 'Minas Gerais',
    'PA': 'Pará', 'PB': 'Paraíba', 'PR': 'Paraná', 'PE': 'Pernambuco', 'PI': 'Piauí',
    'RJ': 'Rio de Janeiro', 'RN': 'Rio Grande do Norte', 'RS': 'Rio Grande do Sul',
    'RO': 'Rondônia', 'RR': 'Roraima', 'SC': 'Santa Catarina', 'SP': 'São Paulo',
    'SE': 'Sergipe', 'TO': 'Tocantins',
  };

  // Controladores (Nomes atualizados para bater com Admin)
  late TextEditingController _givenNameController;
  late TextEditingController _familyNameController;
  late TextEditingController _emailController;
  late TextEditingController _cpfController;
  late TextEditingController _telefoneController;
  late TextEditingController _cepController;

  // Novos Controladores de Endereço (Vindos do Admin)
  late TextEditingController _ruaController;
  late TextEditingController _numeroController;
  late TextEditingController _bairroController;
  late TextEditingController _cidadeController;
  
  String? _ufSelecionada;

  // Máscaras
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
    _inicializarDados();
  }

  void _inicializarDados() {
    final auth = Provider.of<AuthController>(context, listen: false);
    final UserModel? usuario = auth.usuario;

    // 1. Dados Pessoais (Que existem no banco/Cognito)
    _givenNameController = TextEditingController(text: usuario?.primeiroNome ?? '');
    _familyNameController = TextEditingController(text: usuario?.sobrenome ?? '');
    _emailController = TextEditingController(text: usuario?.email ?? '');

    // 2. Preparar dados para Máscaras
    final cpfDB = usuario?.cpf ?? '';
    final celDB = usuario?.telefone ?? '';
    final cepDB = usuario?.cep ?? '';

    // Inicializa os controllers aplicando a máscara visualmente
    _cpfController = TextEditingController(text: _cpfFormatter.maskText(cpfDB));
    _telefoneController = TextEditingController(text: _telefoneFormatter.maskText(celDB));
    _cepController = TextEditingController(text: _cepFormatter.maskText(cepDB));

    // ATENÇÃO: Atualiza o estado interno da máscara para o validador não achar que está vazio
    // Isso resolve o problema de "ter que digitar de novo"
    if (cpfDB.isNotEmpty) {
      _cpfFormatter.updateMask(mask: '###.###.###-##', newValue: TextEditingValue(text: _cpfController.text));
    }
    if (celDB.isNotEmpty) {
      _telefoneFormatter.updateMask(mask: '(##) #####-####', newValue: TextEditingValue(text: _telefoneController.text));
    }
    if (cepDB.isNotEmpty) {
      _cepFormatter.updateMask(mask: '#####-###', newValue: TextEditingValue(text: _cepController.text));
    }

    // 3. Inicializar Endereço VAZIO (Pois não tem no banco)
    _ruaController = TextEditingController(text: '');
    _numeroController = TextEditingController(text: '');
    _bairroController = TextEditingController(text: '');
    _cidadeController = TextEditingController(text: '');
    
    // IMPORTANTE: Começar com null evita o erro "Assertion failed" no Dropdown
    _ufSelecionada = null; 

    // 4. AUTOMAÇÃO: Se tiver CEP, busca o endereço sozinho
    if (cepDB.isNotEmpty && cepDB.length >= 8) {
      // Usamos o addPostFrameCallback para garantir que a tela já foi construída
      // antes de chamar o setState dentro do _buscarCep
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _buscarCep(); 
      });
    }
  }

  @override
  void dispose() {
    _givenNameController.dispose();
    _familyNameController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    super.dispose();
  }

  // --- Lógica de CEP (Copiada do Admin para consistência) ---
  Future<void> _buscarCep() async {
    final cep = _cepFormatter.getUnmaskedText();
    if (cep.length != 8) return;

    setState(() => _isSearchingCep = true);

    try {
      final cepService = CepService();
      final endereco = await cepService.buscarEndereco(cep);

      if (mounted && endereco != null) {
        _ruaController.text = endereco.logradouro;
        _bairroController.text = endereco.bairro;
        _cidadeController.text = endereco.localidade;
        setState(() {
          _ufSelecionada = endereco.uf;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('CEP não encontrado.'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao buscar CEP: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSearchingCep = false);
    }
  }

  void _limparCamposEndereco() {
    _ruaController.clear();
    _bairroController.clear();
    _cidadeController.clear();
    _numeroController.clear();
    setState(() => _ufSelecionada = null);
  }

  Future<void> _buscarCepPorEndereco() async {
    final uf = _ufSelecionada;
    final cidade = _cidadeController.text;
    final rua = _ruaController.text;

    if (uf == null || cidade.isEmpty || rua.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Preencha UF, Cidade e Rua para buscar o CEP.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isSearchingCep = true);

    try {
      final cepService = CepService();
      final resultados = await cepService.buscarCepPorEndereco(uf: uf, cidade: cidade, rua: rua);

      if (mounted && resultados.isNotEmpty) {
        _mostrarDialogoSelecaoCep(resultados);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nenhum CEP encontrado.'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSearchingCep = false);
    }
  }

  void _mostrarDialogoSelecaoCep(List<Endereco> resultados) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecione o CEP Correto'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: resultados.length,
              itemBuilder: (context, index) {
                final endereco = resultados[index];
                return ListTile(
                  title: Text(endereco.cep),
                  subtitle: Text('${endereco.logradouro}, ${endereco.bairro}'),
                  onTap: () {
                    final unmaskedCep = endereco.cep.replaceAll(RegExp(r'[^0-9]'), '');
                    _cepController.value = _cepFormatter.formatEditUpdate(
                      TextEditingValue.empty,
                      TextEditingValue(text: unmaskedCep),
                    );
                    if (_cepFormatter.getUnmaskedText().length < 8) {
                      _limparCamposEndereco();
                    }
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
  // --- Fim Lógica CEP ---

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return; 

    setState(() => _isSaving = true);

    final authController = Provider.of<AuthController>(context, listen: false);
    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final userService = UsuarioService();

    final String telefoneSemMascara = _telefoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final String cepSemMascara = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final String cpfSemMascara = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');

    try {
      bool sucesso = false;

      // Dados comuns de endereço para enviar (se o backend aceitar)
      final Map<String, dynamic> dadosEndereco = {
        'logradouro': _ruaController.text,
        'numero': _numeroController.text,
        'bairro': _bairroController.text,
        'cidade': _cidadeController.text,
        'uf': _ufSelecionada,
      };

      // --- CENÁRIO 1: NOVO CADASTRO (POST) ---
      if (widget.isNovoCadastro) {
        final Map<String, dynamic> dadosNovoUsuario = {
          'id': authController.usuario!.id,
          'givenName': _givenNameController.text.trim(), // Usando padrão givenName
          'familyName': _familyNameController.text.trim(),
          'email': _emailController.text.trim(),
          'cpf': cpfSemMascara,
          'cep': cepSemMascara,
          'telefone': telefoneSemMascara,
          'tipo': 0, // Cliente fixo
          ...dadosEndereco // Espalha os dados de endereço
        };

        await userService.cadastrarUsuarioBancoDados(
          dadosNovoUsuario, 
          authController.usuario!.idToken!
        );
        
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
          ...dadosEndereco // Atualiza endereço também na edição
        };
        sucesso = await userProvider.atualizarUsuario(dadosAtualizados);
      }

      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dados salvos com sucesso!'),
          backgroundColor: Colors.green,
        ));
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNovoCadastro ? 'Finalizar Cadastro' : 'Editar Meus Dados'),
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

            // --- Card de Informações Pessoais (Visual do Admin) ---
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
                    
                    // Linha com Nome e Sobrenome separados
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _givenNameController,
                            readOnly: true, // Usuário não edita nome que vem do Cognito
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                              filled: true, // Cinza para indicar ReadOnly
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _familyNameController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Sobrenome',
                              border: OutlineInputBorder(),
                              filled: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _cpfController,
                      // Só pode editar CPF se for NOVO cadastro
                      readOnly: !widget.isNovoCadastro, 
                      inputFormatters: [_cpfFormatter],
                      decoration: InputDecoration(
                        labelText: 'CPF',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: const OutlineInputBorder(),
                        // Cinza se bloqueado
                        filled: !widget.isNovoCadastro,
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

            // --- Card de Contato e Endereço (Visual do Admin Completo) ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Contato e Endereço", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    
                    // Email ReadOnly
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email', 
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _telefoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefone', 
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_telefoneFormatter],
                      validator: (v) => v!.length < 14 ? 'Telefone inválido' : null,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // --- ÁREA DE ENDEREÇO COMPLETA (Do Admin) ---
                    TextFormField(
                      controller: _cepController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_cepFormatter],
                      validator: (value) {
                        if (_cepFormatter.getUnmaskedText().isEmpty) return 'Informe o CEP';
                        if (_cepFormatter.getUnmaskedText().length < 8) return 'CEP inválido';
                        return null;
                      },
                      onChanged: (value) {
                        if (_cepFormatter.getUnmaskedText().length == 8) {
                          _buscarCep();
                        } else {
                          _limparCamposEndereco();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'CEP',
                        hintText: '00000-000',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: _isSearchingCep
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.0)),
                              )
                            : Tooltip(
                                message: 'Buscar CEP pelo endereço',
                                child: IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: _buscarCepPorEndereco,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ruaController,
                      decoration: const InputDecoration(labelText: 'Rua / Logradouro', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _bairroController,
                            decoration: const InputDecoration(labelText: 'Bairro', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _numeroController,
                            decoration: const InputDecoration(labelText: 'Nº', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _cidadeController,
                            decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _ufSelecionada,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'UF', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12.0)),
                            items: listaUFs.keys.map((String sigla) {
                              return DropdownMenuItem<String>(value: sigla, child: Text(sigla));
                            }).toList(),
                            onChanged: (String? novoValor) => setState(() => _ufSelecionada = novoValor),
                            validator: (value) => value == null ? 'UF?' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Botão Salvar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: widget.isNovoCadastro ? Colors.blueAccent : null,
                ),
                onPressed: _isSaving ? null : _salvarPerfil,
                child: _isSaving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text(widget.isNovoCadastro ? 'FINALIZAR CADASTRO' : 'SALVAR ALTERAÇÕES'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}