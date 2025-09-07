import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:tcc_frontend/providers/user_provider.dart';
import 'package:tcc_frontend/services/cep_service.dart';
import 'package:tcc_frontend/models/endereco_model.dart';

class RegisterPageAdmin extends StatefulWidget {
  const RegisterPageAdmin({super.key});

  @override
  _RegisterPageAdminState createState() => _RegisterPageAdminState();
}

class _RegisterPageAdminState extends State<RegisterPageAdmin> {
  final _formKey = GlobalKey<FormState>();

  // Lista de UFs para o Dropdown
  final Map<String, String> listaUFs = {
    'AC': 'Acre',
    'AL': 'Alagoas',
    'AP': 'Amapá',
    'AM': 'Amazonas',
    'BA': 'Bahia',
    'CE': 'Ceará',
    'DF': 'Distrito Federal',
    'ES': 'Espírito Santo',
    'GO': 'Goiás',
    'MA': 'Maranhão',
    'MT': 'Mato Grosso',
    'MS': 'Mato Grosso do Sul',
    'MG': 'Minas Gerais',
    'PA': 'Pará',
    'PB': 'Paraíba',
    'PR': 'Paraná',
    'PE': 'Pernambuco',
    'PI': 'Piauí',
    'RJ': 'Rio de Janeiro',
    'RN': 'Rio Grande do Norte',
    'RS': 'Rio Grande do Sul',
    'RO': 'Rondônia',
    'RR': 'Roraima',
    'SC': 'Santa Catarina',
    'SP': 'São Paulo',
    'SE': 'Sergipe',
    'TO': 'Tocantins',
  };

  // Controladores de texto
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cepController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController(); 
  final _senhaController = TextEditingController();

  // Controladores para os campos de endereço
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  String? _ufSelecionada; // Variável para armazenar a UF selecionada

  // Variáveis de estado da UI
  String? _tipoSelecionado;
  bool _isSaving = false;
  bool _isPasswordVisible = false;
  bool _isSearchingCep = false;

  // Máscaras de formatação para UX aprimorada
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
  void dispose() {
    // Limpeza dos controladores para evitar vazamento de memória
    _nomeController.dispose();
    _cpfController.dispose();
    _cepController.dispose();
    _telefoneController.dispose();
    _emailController.dispose(); 
    _senhaController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    super.dispose();
  }

  // Método para ser chamado quando o CEP for preenchido
  Future<void> _buscarCep() async {
    final cep = _cepFormatter.getUnmaskedText();
    if (cep.length != 8) return; // Só busca se o CEP estiver completo

    setState(() {
      _isSearchingCep = true; // Ativa o loading
    });

    try {
      final cepService = CepService();
      final endereco = await cepService.buscarEndereco(cep);

      if (mounted && endereco != null) {
        // Se encontrou, preenche os campos
        _ruaController.text = endereco.logradouro;
        _bairroController.text = endereco.bairro;
        _cidadeController.text = endereco.localidade;
        setState(() {
          _ufSelecionada = endereco.uf;
        });
      } else if (mounted) {
        // Se não encontrou, mostra um aviso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CEP não encontrado.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar CEP: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingCep = false; // Desativa o loading
        });
      }
    }
  }  

  // Método para limpar os campos de endereço
  void _limparCamposEndereco() {
    _ruaController.clear();
    _bairroController.clear();
    _cidadeController.clear();
    setState(() {
    _ufSelecionada = null;
    });
    _numeroController.clear(); 
  }

  // Método que é chamado pelo botão "Buscar CEP"
  Future<void> _buscarCepPorEndereco() async {
    // Pega os dados dos campos
    final uf = _ufSelecionada;
    final cidade = _cidadeController.text;
    final rua = _ruaController.text;

    // Valida se os campos necessários estão preenchidos
    if (uf == null || cidade.isEmpty || rua.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha UF, Cidade e Rua para buscar o CEP.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSearchingCep = true; // Reutilizamos a variável de loading
    });

    try {
      final cepService = CepService();
      final resultados = await cepService.buscarCepPorEndereco(
        uf: uf,
        cidade: cidade,
        rua: rua,
      );

      if (mounted && resultados.isNotEmpty) {
        // Se encontrou resultados, mostra o diálogo de seleção
        _mostrarDialogoSelecaoCep(resultados);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum CEP encontrado para este endereço.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na busca: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingCep = false;
        });
      }
    }
  }

  // Diálogo para o usuário selecionar o CEP correto
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

                    // --- ALTERAÇÃO AQUI ---
                    onTap: () {
                      // Pega o texto do CEP (ex: "12345-678") e remove a formatação,
                      // deixando apenas os números ("12345678").
                      final unmaskedCep = endereco.cep.replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );

                      // Agora, usamos o NOSSO formatador para aplicar a máscara.
                      // Isso garante que o estado do controlador e do formatador fiquem sincronizados.
                      _cepController.value = _cepFormatter.formatEditUpdate(
                        TextEditingValue.empty, // Estado antigo (não importa)
                        TextEditingValue(
                          text: unmaskedCep,
                        ), // Novo texto a ser formatado
                      );

                      // Opcional, mas bom para garantir: dispara a lógica de limpeza/busca
                      // caso o usuário interaja mais com o campo depois.
                      if (_cepFormatter.getUnmaskedText().length < 8) {
                        _limparCamposEndereco();
                      }

                      // Fecha o diálogo
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

  Future<void> _salvarUsuario() async {
    // Valida o formulário antes de prosseguir
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Monta o Map de dados para enviar ao provider
    final dadosNovoUsuario = {
      'nome': _nomeController.text.trim(),
      'email': _emailController.text.trim(), // Re-adicionado
      'senha': _senhaController.text.trim(),
      // Pega os valores sem a máscara de formatação
      'cpf': _cpfFormatter.getUnmaskedText(),
      'cep': _cepFormatter.getUnmaskedText(),
      'telefone': _telefoneFormatter.getUnmaskedText(),
      'role': _tipoSelecionado == 'admin' ? 1 : 0,
    };

    try {
      // Chama o provider de forma assíncrona
      final sucesso = await Provider.of<UsuarioProvider>(
        context,
        listen: false,
      ).adicionarUsuario(dadosNovoUsuario);

      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        final erro = Provider.of<UsuarioProvider>(context, listen: false).erro;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Falha ao cadastrar: $erro"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ocorreu um erro inesperado: ${e.toString()}"),
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
      appBar: AppBar(title: const Text('Cadastrar Novo Usuário')),
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
                      "Informações Pessoais",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Informe o nome'
                          : null,
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
                      validator: (value) => value == null || value.length < 14
                          ? 'CPF inválido'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Card de Contato e Acesso ---
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
                      "Contato e Acesso",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    // CAMPO DE E-MAIL RE-ADICIONADO AQUI
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Email inválido'
                          : null,
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
                      validator: (value) => value == null || value.length < 15
                          ? 'Telefone inválido'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      // Propriedades de controle e formatação do input
                      controller: _cepController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_cepFormatter],

                      // Lógica de validação do campo
                      validator: (value) {
                        // É mais seguro validar pelo texto sem máscara
                        if (_cepFormatter.getUnmaskedText().isEmpty) {
                          return 'Informe o CEP';
                        }
                        if (_cepFormatter.getUnmaskedText().length < 8) {
                          return 'CEP inválido';
                        }
                        return null;
                      },

                      // Lógica de interação em tempo real
                      onChanged: (value) {
                        // Busca automática quando o CEP está completo
                        if (_cepFormatter.getUnmaskedText().length == 8) {
                          _buscarCep();
                        }
                        // Limpa os campos de endereço se o CEP for apagado
                        else {
                          _limparCamposEndereco();
                        }
                      },

                      // Configurações visuais do campo (layout)
                      decoration: InputDecoration(
                        labelText: 'CEP',
                        hintText: '00000-000',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: const OutlineInputBorder(),

                        // Ícone de sufixo dinâmico: mostra loading ou o botão de busca
                        suffixIcon: _isSearchingCep
                            // Se estiver buscando, mostra o indicador de progresso
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.0),
                                ),
                              )
                            // Se não, mostra o botão de busca com um Tooltip
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
                    // --- NOVOS CAMPOS DE ENDEREÇO ---
                    TextFormField(
                      controller: _ruaController,
                      decoration: const InputDecoration(
                        labelText: 'Rua / Logradouro',
                        prefixIcon: Icon(Icons.signpost_outlined),
                        border: OutlineInputBorder(),
                      ),
                      // O usuário pode editar, mas o preenchimento inicial é automático
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _bairroController,
                            decoration: const InputDecoration(
                              labelText: 'Bairro',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _numeroController,
                            decoration: const InputDecoration(
                              labelText: 'Nº',
                              border: OutlineInputBorder(),
                            ),
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
                            decoration: const InputDecoration(
                              labelText: 'Cidade',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          //dropdown de UF
                          child: DropdownButtonFormField<String>(
                            value: _ufSelecionada,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'UF',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.0), // Ajuste de padding
                            ),
                            // Mapeia nossa lista de UFs para os itens do dropdown
                            items: listaUFs.keys.map((String sigla) {
                              return DropdownMenuItem<String>(
                                value: sigla,
                                child: Text(sigla),
                              );
                            }).toList(),
                            // Atualiza o estado quando o usuário seleciona uma UF
                            onChanged: (String? novoValor) {
                              setState(() {
                                _ufSelecionada = novoValor;
                              });
                            },
                            validator: (value) => value == null ? 'UF?' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Usuário',
                        prefixIcon: Icon(Icons.security_outlined),
                        border: OutlineInputBorder(),
                      ),
                      value: _tipoSelecionado,
                      items: ['cliente', 'admin']
                          .map(
                            (tipo) => DropdownMenuItem(
                              value: tipo,
                              child: Text(
                                tipo[0].toUpperCase() + tipo.substring(1),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _tipoSelecionado = value),
                      validator: (value) =>
                          value == null ? 'Selecione o tipo' : null,
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
                onPressed: _isSaving ? null : _salvarUsuario,
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text('Salvar Usuário'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
