import 'package:tcc_frontend/models/user_model.dart';
import 'package:tcc_frontend/config/app_config.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
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
  final String _webCallbackUrl = AppConfig.webCallbackUrl;
  final String _getTokenUrl = AppConfig.getTokenUrl;

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
  Future<Null> login() async {
    if (kIsWeb) {
      return _loginWeb();
    } else {
    //   return _loginMobile();
    return null;
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
//   Future<UserModel> _loginMobile() async {
//     try {
//       final result = await _appAuth.authorizeAndExchangeCode(
//         AuthorizationTokenRequest(
//           _clientId,
//           _mobileCallbackUrl,
//           discoveryUrl: _discoveryUrl,
//           scopes: ['openid', 'profile', 'email'],
//         ),
//       );

//       if (result != null && result.idToken != null) {
//         return _processAndStoreTokens(result.idToken!, result.refreshToken);
//       } else {
//         throw Exception("Falha ao obter resposta de autorização.");
//       }
//     } catch (e) {
//       print('Erro no login mobile: $e');
//       throw Exception("Ocorreu um erro durante o login.");
//     }
//   }

  // Lógica de login para Web usando flutter_web_auth_2 e http.
  Future<Null> _loginWeb() async {
    try {
      final authUrl = Uri.parse(
        '$_authEndpoint?response_type=code&client_id=$_clientId&redirect_uri=$_getTokenUrl&scope=email+openid',
      );
		debugPrint('authUrl: $authUrl');

      // 1. Abre o popup/aba de login e obtém o código de autorização
      final resultUrl = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme:
            "http", // ou "https", dependendo se usar http ou https no localhost
      );

      debugPrint('authUrlParseada: ${Uri.parse(resultUrl).toString()}');
      final authCode = Uri.parse(resultUrl).queryParameters['code'];
      if (authCode == null) {
        throw Exception('Não foi possível obter o código de autorização.');
      }

      // 2. Troca o código de autorização pelos tokens
      final tokenResponse = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': _clientId,
          'code': authCode,
          'redirect_uri': _webCallbackUrl,
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokens = jsonDecode(tokenResponse.body);
        final idToken = tokens['id_token'];
        final refreshToken = tokens['refresh_token'];
        // return _processAndStoreTokens(idToken, refreshToken);
    	debugPrint('idToken: $idToken, refreshToken: $refreshToken');

      } else {
        throw Exception(
          'Falha ao trocar código por token: ${tokenResponse.body}',
        );
      }
    } catch (e) {
      print('Erro no login web: $e');
      throw Exception("Ocorreu um erro durante o login.");
    }
  }
	
	

  // Método unificado para processar os tokens após a autenticação.
//   UserModel _processAndStoreTokens(String idToken, String? refreshToken) {
//     _idToken = idToken;
//     _refreshToken = refreshToken;
//     final Map<String, dynamic> decodedToken = JwtDecoder.decode(_idToken!);
//     _currentUser = _userModelFromTokenClaims(decodedToken, _idToken!);
//     return _currentUser!;
//   }

//   // Construtor auxiliar para criar um UserModel a partir das claims de um JWT.
//   UserModel _userModelFromTokenClaims(
//     Map<String, dynamic> claims,
//     String token,
//   ) {
//     final String? principal = claims['custom:principal'];
//     return UserModel(
//       id: claims['sub']!,
//       token: token,
//       nome: claims['name'] ?? claims['email'],
//       cpf: claims['custom:cpf'] ?? '',
//       cep: claims['custom:cep'] ?? '',
//       telefone: claims['phone_number'] ?? '',
//       role: principal == '1' ? UserRole.admin : UserRole.cliente,
//     );
//   }
}
