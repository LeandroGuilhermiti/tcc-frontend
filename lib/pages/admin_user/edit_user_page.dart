import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import das fontes

// Imports do seu projeto
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/cep_service.dart';
import '../../models/endereco_model.dart';
import '../../theme/app_theme.dart'; // Import do tema

class PacienteEditPage extends StatefulWidget {
  final UserModel paciente;

  const PacienteEditPage({super.key, required this.paciente});

  @override
  State<PacienteEditPage> createState() => _PacienteEditPageState();
}

class _PacienteEditPageState extends State<PacienteEditPage> {
  final _formKey = GlobalKey<FormState>();

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
  
  late TextEditingController _cpfController;
  late TextEditingController _cepController;
  late TextEditingController _telefoneController;
  late TextEditingController _emailController;
  
  // Endereço
  late TextEditingController _ruaController;
  late TextEditingController _numeroController;
  late TextEditingController _bairroController;
  late TextEditingController _cidadeController;
  
  String? _ufSelecionada;
  String? _tipoSelecionado;
  
  bool _isSaving = false;
  bool _isSearchingCep = false;

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
    final p = widget.paciente;

    _givenNameController = TextEditingController(text: p.primeiroNome ?? '');
    _familyNameController = TextEditingController(text: p.sobrenome ?? '');
    
    _emailController = TextEditingController(text: p.email ?? '');
    
    _cpfController = TextEditingController(text: _cpfFormatter.maskText(p.cpf ?? ''));
    _cepController = TextEditingController(text: _cepFormatter.maskText(p.cep ?? ''));
    _telefoneController = TextEditingController(text: _telefoneFormatter.maskText(p.telefone ?? ''));

    _ruaController = TextEditingController(text: ''); 
    _numeroController = TextEditingController(text: '');
    _bairroController = TextEditingController(text: '');
    _cidadeController = TextEditingController(text: '');
    _ufSelecionada = null; 

    _tipoSelecionado = p.role == UserRole.admin ? 'admin' : 'cliente';
  }

  @override
  void dispose() {
    _givenNameController.dispose();
    _familyNameController.dispose();
    
    _cpfController.dispose();
    _cepController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
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
          backgroundColor: NnkColors.vermelhoLacre, // Estilizado
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao buscar CEP: $e'),
          backgroundColor: NnkColors.vermelhoLacre, // Estilizado
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
        backgroundColor: Colors.orange, // Mantido para warnings simples
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

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final Map<String, dynamic> dadosAtualizados = {
      'givenName': _givenNameController.text.trim(),
      'familyName': _familyNameController.text.trim(),
      
      'email': _emailController.text.trim(),
      'cpf': _cpfFormatter.getUnmaskedText(),
      'cep': _cepFormatter.getUnmaskedText(),
      'telefone': _telefoneFormatter.getUnmaskedText(),
      
      'tipo': _tipoSelecionado == 'admin' ? 1 : 0,
      
      'logradouro': _ruaController.text,
      'numero': _numeroController.text,
      'bairro': _bairroController.text,
      'cidade': _cidadeController.text,
      'uf': _ufSelecionada,
    };

    try {
      final sucesso = await Provider.of<UsuarioProvider>(context, listen: false)
          .atualizarUsuario(dadosAtualizados, idUsuarioAlvo: widget.paciente.id); 

      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dados atualizados com sucesso!'),
          backgroundColor: NnkColors.verdeErva, // Estilizado
        ));
        Navigator.pop(context);
      } else if (mounted) {
        final erro = Provider.of<UsuarioProvider>(context, listen: false).error;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Falha ao atualizar: $erro"),
          backgroundColor: NnkColors.vermelhoLacre, // Estilizado
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Erro inesperado: $e"),
          backgroundColor: NnkColors.vermelhoLacre, // Estilizado
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
          'Editar: ${widget.paciente.primeiroNome}',
          style: GoogleFonts.cinzel(
            color: NnkColors.tintaCastanha,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: NnkColors.ouroAntigo.withOpacity(0.5), height: 1.0),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
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
                      "Informações Pessoais", 
                      style: GoogleFonts.cinzel(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: NnkColors.tintaCastanha
                      )
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _givenNameController,
                            style: _inputTextStyle(),
                            decoration: _buildInputDecoration('Nome', Icons.person_outline),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _familyNameController,
                            style: _inputTextStyle(),
                            decoration: _buildInputDecoration('Sobrenome', null),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _cpfController,
                      style: _inputTextStyle(),
                      decoration: _buildInputDecoration('CPF', Icons.badge_outlined),
                      keyboardType: TextInputType.number,
                      inputFormatters: [_cpfFormatter],
                      validator: (v) => v == null || v.length < 14 ? 'CPF inválido' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Card de Contato ---
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
                      )
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      style: _inputTextStyle(),
                      decoration: _buildInputDecoration('Email', Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@') ? 'Email inválido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telefoneController,
                      style: _inputTextStyle(),
                      decoration: _buildInputDecoration('Telefone', Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_telefoneFormatter],
                      validator: (v) => v == null || v.length < 15 ? 'Telefone inválido' : null,
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
            const SizedBox(height: 20),

            // --- Permissões ---
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
                      "Configurações do Sistema", 
                      style: GoogleFonts.cinzel(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: NnkColors.tintaCastanha
                      )
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      style: _inputTextStyle(),
                      dropdownColor: NnkColors.papelAntigo,
                      decoration: _buildInputDecoration('Tipo de Usuário', Icons.security_outlined),
                      value: _tipoSelecionado,
                      items: ['cliente', 'admin'].map((tipo) => DropdownMenuItem(
                        value: tipo,
                        child: Text(
                          tipo[0].toUpperCase() + tipo.substring(1),
                          style: GoogleFonts.alegreya(color: NnkColors.tintaCastanha)
                        ),
                      )).toList(),
                      onChanged: (value) => setState(() => _tipoSelecionado = value),
                      validator: (value) => value == null ? 'Selecione o tipo' : null,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),

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
                onPressed: _isSaving ? null : _salvarAlteracoes,
                child: _isSaving
                    ? const SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(color: NnkColors.ouroAntigo, strokeWidth: 3)
                      )
                    : Text(
                        'SALVAR ALTERAÇÕES',
                        style: GoogleFonts.cinzel(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}