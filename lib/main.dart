import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_controller.dart';

import 'models/user_model.dart';
import 'pages/login_page.dart';
import 'pages/client_user/home_page_client.dart';
import 'pages/admin_user/home_page_admin.dart';
import 'pages/admin_user/agenda_editor_page.dart';
import 'pages/admin_user/register_page_admin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 🔹 Garante que o Flutter iniciou
  // await dotenv.load(fileName: ".env"); // 🔹 Carrega o .env

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        // ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App de Agendamento',
      theme: ThemeData.light(),
      initialRoute: '/',
      routes: {
        '/': (_) {
          if (auth.isLogado) {
            if (auth.tipoUsuario == UserRole.admin) {
              return const HomePageAdmin();
            } else {
              return const HomePageClient();
            }
          } else {
            return const LoginPage(); // 🔹 const para otimizar
          }
        },
        '/login': (_) => const LoginPage(),
        '/admin': (_) => const HomePageAdmin(),
        '/cliente': (_) => const HomePageClient(),
        '/editor': (_) => const AgendaEditorPage(),
        '/cadastro': (_) => const RegisterPageAdmin(),
      },
    );
  }
}
