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

  // Controladores
  late TextEditingController _nomeController;
  late TextEditingController _sobrenomeController; // Caso queira separar ou juntar
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

    // Concatena nome se necessário ou usa campos separados se tiver no model
    String nomeCompleto = p.primeiroNome ?? '';
    if (p.sobrenome != null && p.sobrenome!.isNotEmpty) {
      nomeCompleto += ' ${p.sobrenome}';
    }

    _nomeController = TextEditingController(text: nomeCompleto);
    _emailController = TextEditingController(text: p.email ?? '');
    
    // Aplica a máscara nos dados vindos do banco
    _cpfController = TextEditingController(text: _cpfFormatter.maskText(p.cpf ?? ''));
    _cepController = TextEditingController(text: _cepFormatter.maskText(p.cep ?? ''));
    _telefoneController = TextEditingController(text: _telefoneFormatter.maskText(p.telefone ?? ''));

    // Inicializa endereço (Caso o UserModel não tenha esses campos, iniciam vazios)
    // Se você tiver adicionado rua/bairro no UserModel, mapeie aqui: p.rua, p.bairro...
    _ruaController = TextEditingController(text: ''); 
    _numeroController = TextEditingController(text: '');
    _bairroController = TextEditingController(text: '');
    _cidadeController = TextEditingController(text: '');
    _ufSelecionada = null; // ou p.uf

    // Define o tipo inicial baseado no Role do usuário
    _tipoSelecionado = p.role == UserRole.admin ? 'admin' : 'cliente';
  }

  @override
  void dispose() {
    _nomeController.dispose();
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

  // --- Lógica de CEP (Idêntica ao Cadastro) ---
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

    // Separando Nome e Sobrenome (lógica simples baseada no primeiro espaço)
    final nomeCompleto = _nomeController.text.trim();
    String nome = nomeCompleto;
    String sobrenome = '';
    
    if (nomeCompleto.contains(' ')) {
      final partes = nomeCompleto.split(' ');
      nome = partes[0];
      sobrenome = partes.sublist(1).join(' ');
    }

    // Monta o JSON de Atualização (PATCH)
    final Map<String, dynamic> dadosAtualizados = {
      'nome': nome,
      'sobrenome': sobrenome,
      'email': _emailController.text.trim(),
      'cpf': _cpfFormatter.getUnmaskedText(),
      'cep': _cepFormatter.getUnmaskedText(),
      'telefone': _telefoneFormatter.getUnmaskedText(),
      // Converte a string 'admin'/'cliente' para Inteiro (1 ou 0)
      'tipo': _tipoSelecionado == 'admin' ? 1 : 0,
      
      // Adicione os campos de endereço se seu backend suportar no PATCH
      'logradouro': _ruaController.text,
      'numero': _numeroController.text,
      'bairro': _bairroController.text,
      'cidade': _cidadeController.text,
      'uf': _ufSelecionada,
    };

    try {
      // Chama o método de ATUALIZAR, passando o ID do usuário
      final sucesso = await Provider.of<UsuarioProvider>(context, listen: false)
          .atualizarUsuario(dadosAtualizados, idUsuarioAlvo: widget.paciente.id); 
          // Nota: Certifique-se que seu UsuarioProvider tem um método como 'atualizarUsuarioNaLista'
          // que recebe (id, map) e faz o PATCH na API.

      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dados atualizados com sucesso!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context); // Volta para a lista
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
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null,
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

            // --- Card de Contato e Acesso ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Contato e Permissões", style: Theme.of(context).textTheme.titleLarge),
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
                    // DROPDOWN DE TIPO (ROLE)
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
                    const SizedBox(height: 16),
                    
                    // --- ÁREA DE ENDEREÇO (Igual ao Cadastro) ---
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