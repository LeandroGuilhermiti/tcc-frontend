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
    if (_idToken == null) return;

    try {
      if (kIsWeb) {
        final logoutUri = Uri.parse(
          '$_logoutEndpoint?client_id=$_clientId&logout_uri=$_webCallbackUrl',
        );
        await FlutterWebAuth2.authenticate(
          url: logoutUri.toString(),
          callbackUrlScheme: "http",
        );
      } else {
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
      print("Erro durante o logout (geralmente seguro ignorar): $e");
    } finally {
      _idToken = null;
      _refreshToken = null;
      _currentUser = null;
    }
  }

  // --- MÉTODOS PRIVADOS ESPECÍFICOS DE CADA PLATAFORMA ---

  // Lógica de login para Android e iOS usando flutter_appauth.
  Future<UserModel> _loginMobile() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _mobileCallbackUrl,
          discoveryUrl: _discoveryUrl,
          scopes: ['openid', 'email'],
        ),
      );

      if (result != null && result.idToken != null) {
        return await _processAndStoreTokens(
          result.idToken!,
          result.accessToken ?? '',
          result.refreshToken,
        );
      } else {
        throw Exception("Falha ao obter resposta de autorização.");
      }
    } catch (e) {
      print('Erro no login mobile: $e');
      throw Exception("Ocorreu um erro durante o login.");
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
      // Pegar detalhes do usuário com backend
      final Map<String, dynamic> backendUserDetails = await _fetchBackendUserDetails(userId, idToken);

      // O backend retorna os detalhes, e nós adicionamos o token que veio do Cognito
      final Map<String, dynamic> fullUserData = {
        ...backendUserDetails,
        'idToken': idToken,
        'access_token': accessToken,
        'refresh_token': refreshToken
      };

      // Criando usuário atual
      _currentUser = UserModel.fromJson(fullUserData);
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
