import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

// Imports do seu projeto
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/cep_service.dart';
import '../../models/endereco_model.dart';

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

  // --- ALTERAÇÃO 1: Controladores separados para Nome e Sobrenome ---
  late TextEditingController _givenNameController; // Nome
  late TextEditingController _familyNameController; // Sobrenome
  
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

    // --- ALTERAÇÃO 2: Inicialização separada ---
    // Pega o dado do model, ou string vazia se for null
    _givenNameController = TextEditingController(text: p.primeiroNome ?? '');
    _familyNameController = TextEditingController(text: p.sobrenome ?? '');
    
    _emailController = TextEditingController(text: p.email ?? '');
    
    // Aplica a máscara nos dados vindos do banco
    _cpfController = TextEditingController(text: _cpfFormatter.maskText(p.cpf ?? ''));
    _cepController = TextEditingController(text: _cepFormatter.maskText(p.cep ?? ''));
    _telefoneController = TextEditingController(text: _telefoneFormatter.maskText(p.telefone ?? ''));

    // Inicializa endereço
    _ruaController = TextEditingController(text: ''); // Mapear p.rua se existir
    _numeroController = TextEditingController(text: '');
    _bairroController = TextEditingController(text: '');
    _cidadeController = TextEditingController(text: '');
    _ufSelecionada = null; 

    // Define o tipo inicial
    _tipoSelecionado = p.role == UserRole.admin ? 'admin' : 'cliente';
  }

  @override
  void dispose() {
    // --- ALTERAÇÃO 3: Dispose dos novos controllers ---
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

  // --- Lógica de CEP (Mantida igual) ---
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

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // --- ALTERAÇÃO 4: Montagem do JSON com as chaves corretas ---
    final Map<String, dynamic> dadosAtualizados = {
      // Usando as chaves que seu Backend Node espera
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
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      } else if (mounted) {
        final erro = Provider.of<UsuarioProvider>(context, listen: false).error;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Falha ao atualizar: $erro"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Erro inesperado: $e"),
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
      appBar: AppBar(title: Text('Editar: ${widget.paciente.primeiroNome}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Card de Informações Pessoais ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Informações Pessoais", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    
                    // --- ALTERAÇÃO 5: Linha com Nome e Sobrenome separados ---
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _givenNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome', // Label para UI
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _familyNameController,
                            decoration: const InputDecoration(
                              labelText: 'Sobrenome', // Label para UI
                              border: OutlineInputBorder(),
                            ),
                            // Sobrenome é opcional? Se for obrigatório, adicione validação
                            validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _cpfController,
                      decoration: const InputDecoration(
                        labelText: 'CPF',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
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
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Contato e Endereço", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@') ? 'Email inválido' : null,
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
                      validator: (v) => v == null || v.length < 15 ? 'Telefone inválido' : null,
                    ),

                    const SizedBox(height: 16),
                    
                    // --- ÁREA DE ENDEREÇO ---
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
            const SizedBox(height: 20),

            // --- ALTERAÇÃO 6: Card exclusivo para Permissões no final ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Configurações do Sistema", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Usuário',
                        prefixIcon: Icon(Icons.security_outlined),
                        border: OutlineInputBorder(),
                      ),
                      value: _tipoSelecionado,
                      items: ['cliente', 'admin'].map((tipo) => DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo[0].toUpperCase() + tipo.substring(1)),
                      )).toList(),
                      onChanged: (value) => setState(() => _tipoSelecionado = value),
                      validator: (value) => value == null ? 'Selecione o tipo' : null,
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
                ),
                onPressed: _isSaving ? null : _salvarAlteracoes,
                child: _isSaving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Salvar Alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}