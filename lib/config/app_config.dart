import 'package:flutter_dotenv/flutter_dotenv.dart';

// Gerencia as variáveis de ambiente da aplicação.
// Prioriza as variáveis injetadas via --dart-define em produção e utiliza o arquivo .env como fallback para o desenvolvimento local.

class AppConfig {
  // Tenta ler o valor da variável injetada no build.
  // Se não foi injetada, o valor será uma string vazia.
  static const _userPoolIdFromDefine = String.fromEnvironment(
    'AWS_USER_POOL_ID');
  static const _clientIdFromDefine = String.fromEnvironment('AWS_CLIENT_ID');
  static const _cognitoDomainFromDefine = String.fromEnvironment('AWS_COGNITO_DOMAIN');
  static const _apiBaseUrlFromDefine = String.fromEnvironment('API_BASE_URL');
  static const _webCallbackUrlFromDefine = String.fromEnvironment('WEB_CALLBACK_URL');
  static const _getTokenUrlFromDefine = String.fromEnvironment('GET_TOKEN_URL');

  /// Retorna o ID do User Pool do Cognito.
  static String get awsUserPoolId {
    return _userPoolIdFromDefine.isNotEmpty
        ? _userPoolIdFromDefine
        : dotenv.env['AWS_USER_POOL_ID']!;
  }

  /// Retorna o Client ID da aplicação no Cognito.
  static String get awsClientId {
    return _clientIdFromDefine.isNotEmpty
        ? _clientIdFromDefine
        : dotenv.env['AWS_CLIENT_ID']!;
  }

  /// Retorna o domínio da Hosted UI do Cognito.
  static String get cognitoDomain {
    return _cognitoDomainFromDefine.isNotEmpty
        ? _cognitoDomainFromDefine
        : dotenv.env['AWS_COGNITO_DOMAIN']!;
  }

  /// Retorna a URL base da API Gateway.
  static String get apiBaseUrl {
    return _apiBaseUrlFromDefine.isNotEmpty
        ? _apiBaseUrlFromDefine
        : dotenv.env['API_BASE_URL']!;
  }

  static String get webCallbackUrl {
    return _webCallbackUrlFromDefine.isNotEmpty
        ? _webCallbackUrlFromDefine
        : dotenv.env['WEB_CALLBACK_URL']!;
  }

  /// Retorna a URL para obtenção do token.
  static String get getTokenUrl {
    return _getTokenUrlFromDefine.isNotEmpty
        ? _getTokenUrlFromDefine
        : dotenv.env['GET_TOKEN_URL']!;
  }
  
}
