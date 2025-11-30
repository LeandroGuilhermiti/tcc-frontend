import 'package:tcc_frontend/models/user_model.dart';
import 'package:tcc_frontend/config/app_config.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar a plataforma
import 'package:flutter/material.dart';

// Pacotes de autenticação específicos para cada plataforma
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';


class AuthService {
  // Instâncias dos pacotes
  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  // Configurações obtidas do AppConfig
  final String _clientId = AppConfig.awsClientId;
  final String _cognitoDomain = AppConfig.cognitoDomain;
  final String _userPoolId = AppConfig.awsUserPoolId;
  final String _region = 'sa-east-1';

  // URLs de callback para cada plataforma
  final String _mobileCallbackUrl = 'meuapptcc://callback';
  final String _webCallbackUrl = AppConfig.clientBaseUrL;

  // Endpoints do Cognito
  String get _discoveryUrl =>
      'https://cognito-idp.$_region.amazonaws.com/$_userPoolId/.well-known/openid-configuration';
  String get _tokenEndpoint => 'https://$_cognitoDomain/oauth2/token';
  String get _authEndpoint => 'https://$_cognitoDomain/oauth2/authorize';
  String get _logoutEndpoint => 'https://$_cognitoDomain/logout';

  // Estado do serviço
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  String? _idToken;
  String? _refreshToken;

  /// Inicia o fluxo de login, escolhendo o método correto baseado na plataforma.
  Future<void> login() async {
    if (kIsWeb) {
      return _loginWithRedirect();
    } else {
    //   return _loginMobile();
    return;
    }
  }

  // Faz o logout, escolhendo o método correto baseado na plataforma.
Future<void> logout() async {
    try {
      if (kIsWeb) {
        // 1. Remove a barra '/' do final se ela existir, para garantir que bate com a AWS
        String logoutUrlCallback = _webCallbackUrl;
        if (logoutUrlCallback.endsWith('/')) {
          logoutUrlCallback = logoutUrlCallback.substring(0, logoutUrlCallback.length - 1);
        }
        // 2. Extrair apenas o domínio do Cognito (sem https://)
        // O Uri.https precisa apenas do host, ex: "tcc-agendamento.auth..."
        final cognitoHost = _cognitoDomain; 

        // 3. Construção Segura da URL
        // Usamos Uri.https para ele codificar os parâmetros corretamente (? & =)
        final logoutUri = Uri.https(
          cognitoHost,
          '/logout',
          {
            'client_id': _clientId,
            'logout_uri': logoutUrlCallback, // URL limpa sem barra no final
          },
        );

        debugPrint('--- LOGOUT DEBUG ---');
        debugPrint('URL Gerada: $logoutUri');
        
        // 4. Redirecionamento da Janela (Obrigatório '_self')
        await launchUrl(
          logoutUri,
          webOnlyWindowName: '_self', 
        );
        
      } else {
        // Lógica Mobile
        if (_idToken == null) return;
        await _appAuth.endSession(
          EndSessionRequest(
            idTokenHint: _idToken,
            postLogoutRedirectUrl: _mobileCallbackUrl,
            serviceConfiguration: AuthorizationServiceConfiguration(
              authorizationEndpoint: _authEndpoint,
              tokenEndpoint: _tokenEndpoint,
              endSessionEndpoint: _logoutEndpoint,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro durante o logout: $e");
    } finally {
      // Limpeza local
      _idToken = null;
      _refreshToken = null;
      _currentUser = null;
      // Nota: Não chama notifyListeners aqui porque o redirecionamento web vai recarregar a página
    }
  }

  // Lógica de login para Web usando redirecionamento.
  Future<void> _loginWithRedirect() async {
    final authUrl = Uri.parse(
        '$_authEndpoint?response_type=code&client_id=$_clientId&redirect_uri=$_webCallbackUrl&scope=email+openid',
      );

    if (!await launchUrl(
      authUrl,
      webOnlyWindowName: '_self', // Garante que abrirá na mesma aba
    )) {
      throw Exception('Não foi possível abrir a URL de autenticação.');
    }
  }

  // Nova função para ser chamada na inicialização do app
  Future<UserModel?> exchangeCodeForToken(String code) async {
    try {
      final tokenResponse = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': _clientId,
          'code': code,
          'redirect_uri': _webCallbackUrl,
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokens = jsonDecode(tokenResponse.body);
        return _processAndStoreTokens(tokens['id_token'], tokens['access_token'], tokens['refresh_token']);
      } else {
        throw Exception('Falha ao trocar código por token: ${tokenResponse.body}');
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Método unificado para processar os tokens após a autenticação.
  Future<UserModel> _processAndStoreTokens(String idToken, String accessToken, String? refreshToken) async {
    _idToken = idToken;
    _refreshToken = refreshToken;
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(_idToken!);
    final String userId = decodedToken['sub']!;

    try {
      // 1. Busca o JSON cru do backend (status 200)
    final Map<String, dynamic> backendResponse = await _fetchBackendUserDetails(userId, idToken);

    // Variável que vai guardar os dados finais para criar o Model
    Map<String, dynamic> dadosParaOModel;

    // 2. VERIFICAÇÃO EXPLÍCITA DA RESPOSTA DO BACKEND
    if (backendResponse.containsKey('id') && backendResponse['id'] != null) {
      // CENÁRIO A: O usuário JÁ EXISTE no banco.
      // O backend mandou o ID, então usamos tudo que veio de lá.
      
      dadosParaOModel = {
        ...backendResponse, // Usa o JSON do backend
        'cadastroPendente': false, // Cadastro está completo
      };
      
    } else {
      // CENÁRIO B: O usuário NÃO EXISTE no banco (JSON sem ID).
      // Precisamos "fabricar" o objeto para o Flutter não quebrar.
      // Injetamos o ID do Cognito e avisamos que é pendente.
      
      dadosParaOModel = {
        ...backendResponse, // Pega email/nome que vieram
        'id': userId, // IMPORTANTE: Usamos o ID do Cognito aqui para preencher o required this.id
        'cadastroPendente': true, // AVISO: Cadastro incompleto!
      };
    }

    // 3. Injeta os tokens que sempre são necessários
    dadosParaOModel.addAll({
      'idToken': idToken,
      'access_token': accessToken,
      'refresh_token': refreshToken,
    });

    // 4. Cria o usuário com o mapa preparado corretamente
    _currentUser = UserModel.fromJson(dadosParaOModel);
    
    debugPrint(jsonEncode(_currentUser!.toJson()));

    return _currentUser!;

    } catch (e) {
      debugPrint("ERRO: Falha ao buscar detalhes do usuário no backend. $e");
      // Aqui você pode decidir o que fazer em caso de falha:
      // - Deslogar o usuário?
      // - Tentar criar um UserModel com dados parciais?
      // Por enquanto, vamos lançar uma exceção para que o AuthController saiba que o login falhou.
      throw Exception("Não foi possível carregar seu perfil. Tente novamente.");
    }
  }

  Future<Map<String, dynamic>> _fetchBackendUserDetails(String userId, String idToken) async {
    
    final baseUrl = Uri.parse(AppConfig.apiBaseUrl);
    final url = Uri.parse('$baseUrl/usuario/$userId/buscar');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Código de erro do backend: ${response.statusCode}');
    }
  }

}