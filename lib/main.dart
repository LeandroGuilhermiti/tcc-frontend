import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. Importar o dotenv

// Importe os seus controllers, providers e telas
import 'providers/auth_controller.dart';
import 'providers/periodo_provider.dart';
import 'providers/agendamento_provider.dart';
import 'providers/bloqueio_provider.dart';

import 'models/user_model.dart';
import 'pages/login_page.dart';
import 'pages/client_user/home_page_client.dart';
import 'pages/admin_user/home_page_admin.dart';
import 'pages/admin_user/agenda_editor_page.dart';
import 'pages/admin_user/register_page_admin.dart';

Future<void> main() async {
  // 2. Garantir que o Flutter está pronto e carregar as variáveis de ambiente
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProxyProvider<AuthController, PeriodoProvider>(
          create: (_) => PeriodoProvider(null),
          update: (_, auth, previousProvider) => previousProvider!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthController, AgendamentoProvider>(
          create: (_) => AgendamentoProvider(null),
          update: (_, auth, previousProvider) => previousProvider!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthController, BloqueioProvider>(
          create: (_) => BloqueioProvider(null),
          update: (_, auth, previousProvider) => previousProvider!..updateAuth(auth),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'App de Agendamento',
        theme: ThemeData.light(),
        home: Consumer<AuthController>(
          builder: (context, auth, child) {
            if (auth.isLogado) {
              return auth.tipoUsuario == UserRole.admin
                  ? const HomePageAdmin()
                  : const HomePageClient();
            } else {
              return const LoginPage();
            }
          },
        ),
        routes: {
          '/login': (_) => const LoginPage(),
          '/admin': (_) => const HomePageAdmin(),
          '/cliente': (_) => const HomePageClient(),
          '/editor': (_) => const AgendaEditorPage(),
          '/cadastro': (_) => const RegisterPageAdmin(),
        },
      ),
    );
  }
}