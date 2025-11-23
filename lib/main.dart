import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html; // Necessário para web
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

//controllers, providers, models
import 'providers/auth_controller.dart';
import 'providers/periodo_provider.dart';
import 'providers/agendamento_provider.dart';
import 'providers/bloqueio_provider.dart';
import 'providers/agenda_provider.dart';
import 'providers/user_provider.dart'; 
import 'providers/feriado_provider.dart';
import 'models/user_model.dart';

//telas
import 'pages/login_page.dart';
import 'pages/admin_user/agenda_list_page.dart';
import 'pages/admin_user/agenda_create_page.dart';
import 'pages/admin_user/register_page_admin.dart';
import 'pages/admin_user/list_user_page.dart';

import 'pages/client_user/selecao_agenda_page.dart';
import 'pages/client_user/editar_dados_cliente.dart';


// Service
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('pt_BR', null);

  UserModel? initialUser;
  final authService = AuthService();

  if (kIsWeb) {
    final uri = Uri.parse(html.window.location.href);
    if (uri.queryParameters.containsKey('code')) {
      final code = uri.queryParameters['code']!;
      initialUser = await authService.exchangeCodeForToken(code);
      final cleanUri = uri.removeFragment().replace(queryParameters: {});
      html.window.history.replaceState(null, 'home', cleanUri.toString());
    }
  }

  runApp(MyApp(initialUser: initialUser));
}

class MyApp extends StatelessWidget {
  final UserModel? initialUser;
  const MyApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController(initialUser)),
        ChangeNotifierProxyProvider<AuthController, PeriodoProvider>(
          create: (_) => PeriodoProvider(null),
          update: (_, auth, previousProvider) =>
              previousProvider!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthController, AgendaProvider>(
          create: (_) => AgendaProvider(null),
          update: (_, auth, previousProvider) =>
              previousProvider!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthController, AgendamentoProvider>(
          create: (_) => AgendamentoProvider(null),
          update: (_, auth, previousProvider) =>
              previousProvider!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthController, BloqueioProvider>(
          create: (_) => BloqueioProvider(null),
          update: (_, auth, previousProvider) =>
              previousProvider!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthController, UsuarioProvider>(
          create: (_) => UsuarioProvider(null), 
          update: (_, auth, previousProvider) => UsuarioProvider(auth),
        ),
        ChangeNotifierProvider(create: (_) => FeriadoProvider()),
      ],
      
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'App de Agendamento',
        theme: ThemeData.light(),
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'),
          Locale('en', 'US'),
        ],
        home: Consumer<AuthController>(
          builder: (context, auth, child) {
            if (auth.isLogado) {
              return auth.tipoUsuario == UserRole.admin
                  ? const AgendaListPage()
                  : const SelecaoAgendaPage();
            } else {
              return const LoginPage();
            }
          },
        ),
        routes: {
          '/login': (_) => const LoginPage(),
          '/create': (_) => const AgendaCreatePage(),
          '/cadastro': (_) => const RegisterPageAdmin(),
          '/agendas': (_) => const AgendaListPage(), 
          '/selecao_cliente': (_) => const SelecaoAgendaPage(),
          '/editar_dados_cliente': (_) => const EditarDadosCliente(),
          '/pacientes': (_) => const PacientesListPage(),
        },
      ),
    );
  }
}