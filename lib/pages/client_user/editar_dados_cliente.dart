import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import das fontes

// Imports de Modelos e Serviços
import '../../models/user_model.dart';
import '../../models/endereco_model.dart'; 
import '../../providers/auth_controller.dart';
import '../../providers/user_provider.dart';
import '../../services/user_service.dart';
import '../../services/cep_service.dart'; 

import '../../widgets/menu_lateral_cliente.dart'; 
import '../../theme/app_theme.dart'; // Import do tema

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

  // Lista de UFs
  final Map<String, String> listaUFs = {
    'AC': 'Acre', 'AL': 'Alagoas', 'AP': 'Amapá', 'AM': 'Amazonas', 'BA': 'Bahia',
    'CE': 'Ceará', 'DF': 'Distrito Federal', 'ES': 'Espírito Santo', 'GO': 'Goiás',
    'MA': 'Maranhão', 'MT': 'Mato Grosso', 'MS': 'Mato Grosso do Sul', 'MG': 'Minas Gerais',
    'PA': 'Pará', 'PB': 'Paraíba', 'PR': 'Paraná', 'PE': 'Pernambuco', 'PI': 'Piauí',
    'RJ': 'Rio de Janeiro', 'RN': 'Rio Grande do Norte', 'RS': 'Rio Grande do Sul',
    'RO': 'Rondônia', 'RR': 'Roraima', 'SC': 'Santa Catarina', 'SP': 'São Paulo',
    'SE': 'Sergipe', 'TO': 'Tocantins',
  };

  late TextEditingController _givenNameController;
  late TextEditingController _familyNameController;
  late TextEditingController _emailController;
  late TextEditingController _cpfController;
  late TextEditingController _telefoneController;
  late TextEditingController _cepController;

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

  // --- Lógica de CEP ---
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
          backgroundColor: NnkColors.ouroAntigo,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao buscar CEP: $e'),
          backgroundColor: NnkColors.vermelhoLacre,
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
        backgroundColor: NnkColors.ouroAntigo,
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
          backgroundColor: NnkColors.ouroAntigo,
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
          backgroundColor: NnkColors.papelAntigo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: NnkColors.ouroAntigo, width: 2),
          ),
          title: Text(
            'Selecione o CEP Correto',
            style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: NnkColors.tintaCastanha),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: resultados.length,
              itemBuilder: (context, index) {
                final endereco = resultados[index];
                return ListTile(
                  title: Text(endereco.cep, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${endereco.logradouro}, ${endereco.bairro}'),
                  textColor: NnkColors.tintaCastanha,
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
              child: const Text('Cancelar', style: TextStyle(color: NnkColors.vermelhoLacre)),
            ),
          ],
        );
      },
    );
  }

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

      final Map<String, dynamic> dadosEndereco = {
        'logradouro': _ruaController.text,
        'numero': _numeroController.text,
        'bairro': _bairroController.text,
        'cidade': _cidadeController.text,
        'uf': _ufSelecionada,
      };

      if (widget.isNovoCadastro) {
        final Map<String, dynamic> dadosNovoUsuario = {
          'id': authController.usuario!.id,
          'givenName': _givenNameController.text.trim(),
          'familyName': _familyNameController.text.trim(),
          'email': _emailController.text.trim(),
          'cpf': cpfSemMascara,
          'cep': cepSemMascara,
          'telefone': telefoneSemMascara,
          'tipo': 0,
          ...dadosEndereco
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

      } else {
        final Map<String, dynamic> dadosAtualizados = {
          'telefone': telefoneSemMascara,
          'cep': cepSemMascara,
          ...dadosEndereco
        };
        sucesso = await userProvider.atualizarUsuario(dadosAtualizados);
      }

      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dados salvos com sucesso!'),
          backgroundColor: NnkColors.verdeErva,
        ));
        Navigator.of(context).pushReplacementNamed('/selecao_cliente'); 
      } 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: NnkColors.vermelhoLacre,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- Helper: Estilo dos Campos de Input ---
  InputDecoration _buildInputDecoration(String label, IconData? icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.alegreya(color: NnkColors.tintaCastanha.withOpacity(0.7)),
      prefixIcon: icon != null ? Icon(icon, color: NnkColors.ouroAntigo) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: NnkColors.ouroAntigo),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: NnkColors.ouroAntigo),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: NnkColors.tintaCastanha, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: NnkColors.vermelhoLacre),
      ),
      // Ajustes para campos desabilitados
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: NnkColors.cinzaSuave.withOpacity(0.5)),
      ),
    );
  }

  // --- Helper: Estilo de Texto Interno ---
  TextStyle _inputTextStyle() {
    return GoogleFonts.alegreya(fontSize: 18, color: NnkColors.tintaCastanha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NnkColors.papelAntigo,
      appBar: AppBar(
        backgroundColor: NnkColors.papelAntigo,
        iconTheme: const IconThemeData(color: NnkColors.tintaCastanha),
        title: Text(
          widget.isNovoCadastro ? 'Finalizar Cadastro' : 'Editar Meus Dados',
          style: GoogleFonts.cinzel(
            color: NnkColors.tintaCastanha,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: NnkColors.ouroAntigo.withOpacity(0.5), height: 1.0),
        ),
        automaticallyImplyLeading: !widget.isNovoCadastro, 
      ),
      drawer: widget.isNovoCadastro ? null : const AppDrawerCliente(currentPage: AppDrawerPage.perfil),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (widget.isNovoCadastro)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  "Olá! Vimos que é seu primeiro acesso. Por favor, confirme seus dados para continuar.",
                  style: GoogleFonts.alegreya(fontSize: 18, color: NnkColors.tintaCastanha.withOpacity(0.8)),
                ),
              ),

            // --- Card de Informações Pessoais ---
            Card(
              color: Colors.white,
              elevation: 3,
              shadowColor: NnkColors.tintaCastanha.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: NnkColors.ouroAntigo.withOpacity(0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Dados Pessoais", 
                      style: GoogleFonts.cinzel(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: NnkColors.tintaCastanha
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _givenNameController,
                            readOnly: true,
                            style: _inputTextStyle().copyWith(color: NnkColors.cinzaSuave), // Visual de leitura
                            decoration: _buildInputDecoration('Nome', Icons.person_outline).copyWith(
                              fillColor: NnkColors.cinzaSuave.withOpacity(0.2), // Fundo mais escuro
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _familyNameController,
                            readOnly: true,
                            style: _inputTextStyle().copyWith(color: NnkColors.cinzaSuave),
                            decoration: _buildInputDecoration('Sobrenome', null).copyWith(
                              fillColor: NnkColors.cinzaSuave.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _cpfController,
                      readOnly: !widget.isNovoCadastro, 
                      inputFormatters: [_cpfFormatter],
                      style: _inputTextStyle().copyWith(
                        color: !widget.isNovoCadastro ? NnkColors.cinzaSuave : NnkColors.tintaCastanha
                      ),
                      decoration: _buildInputDecoration('CPF', Icons.badge_outlined).copyWith(
                        filled: true,
                        fillColor: !widget.isNovoCadastro ? NnkColors.cinzaSuave.withOpacity(0.2) : Colors.white.withOpacity(0.5),
                        helperText: widget.isNovoCadastro ? 'Obrigatório para agendamentos' : null,
                        helperStyle: GoogleFonts.alegreya(color: NnkColors.ouroAntigo),
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

            // --- Card de Contato e Endereço ---
            Card(
              color: Colors.white,
              elevation: 3,
              shadowColor: NnkColors.tintaCastanha.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: NnkColors.ouroAntigo.withOpacity(0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Contato e Endereço", 
                      style: GoogleFonts.cinzel(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: NnkColors.tintaCastanha
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Email ReadOnly
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      style: _inputTextStyle().copyWith(color: NnkColors.cinzaSuave),
                      decoration: _buildInputDecoration('Email', Icons.email_outlined).copyWith(
                        fillColor: NnkColors.cinzaSuave.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _telefoneController,
                      style: _inputTextStyle(),
                      decoration: _buildInputDecoration('Telefone', Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_telefoneFormatter],
                      validator: (v) => v!.length < 14 ? 'Telefone inválido' : null,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // --- ÁREA DE ENDEREÇO ---
                    TextFormField(
                      controller: _cepController,
                      style: _inputTextStyle(),
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
                      decoration: _buildInputDecoration(
                        'CEP', 
                        Icons.location_on_outlined,
                        suffix: _isSearchingCep
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.0, color: NnkColors.ouroAntigo)),
                              )
                            : Tooltip(
                                message: 'Buscar CEP pelo endereço',
                                child: IconButton(
                                  icon: const Icon(Icons.search, color: NnkColors.tintaCastanha),
                                  onPressed: _buscarCepPorEndereco,
                                ),
                              ),
                      ).copyWith(hintText: '00000-000', hintStyle: GoogleFonts.alegreya(color: NnkColors.cinzaSuave)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ruaController,
                      style: _inputTextStyle(),
                      decoration: _buildInputDecoration('Rua / Logradouro', null),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _bairroController,
                            style: _inputTextStyle(),
                            decoration: _buildInputDecoration('Bairro', null),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _numeroController,
                            style: _inputTextStyle(),
                            decoration: _buildInputDecoration('Nº', null),
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
                            style: _inputTextStyle(),
                            decoration: _buildInputDecoration('Cidade', null),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _ufSelecionada,
                            isExpanded: true,
                            style: _inputTextStyle(),
                            dropdownColor: NnkColors.papelAntigo,
                            decoration: _buildInputDecoration('UF', null).copyWith(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0)
                            ),
                            items: listaUFs.keys.map((String sigla) {
                              return DropdownMenuItem<String>(
                                value: sigla, 
                                child: Text(sigla, style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha))
                              );
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

            // Botão Salvar Estilizado
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: NnkColors.tintaCastanha,
                  foregroundColor: NnkColors.ouroAntigo,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: NnkColors.ouroAntigo, width: 1.5),
                  ),
                ),
                onPressed: _isSaving ? null : _salvarPerfil,
                child: _isSaving
                    ? const SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(color: NnkColors.ouroAntigo, strokeWidth: 3)
                      )
                    : Text(
                        widget.isNovoCadastro ? 'FINALIZAR CADASTRO' : 'SALVAR ALTERAÇÕES',
                        style: GoogleFonts.cinzel(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}