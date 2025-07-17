import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'pages/login_page.dart';
import 'pages/client_user/home_page_client.dart';
import 'pages/admin_user/home_page_admin.dart';
import 'package:tcc_frontend/models/user_model.dart';       
import 'pages/admin_user/agenda_editor_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthController(),
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
            return LoginPage();
          }
        },
        '/login': (_) => LoginPage(),
        '/admin': (_) => const HomePageAdmin(),
        '/cliente': (_) => const HomePageClient(),
        '/editor': (context) => const AgendaEditorPage(),
      },
    );
  }
}
