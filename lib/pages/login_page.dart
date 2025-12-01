import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'dart:math' as math; // Para rodar os arabescos
import '../providers/auth_controller.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart'; // Importa NnkColors

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);

    // Cor de fundo mais branca como pedido, mas mantendo o tom quente
    final Color fundoBrancoMagico = const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: fundoBrancoMagico,
      body: Stack(
        children: [
          // --- 0. TEXTURA DE FUNDO SUBTIL (Opcional, para não ficar branco chapado) ---
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage("https://www.transparenttextures.com/patterns/aged-paper.png"), 
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  // --- 1. LOGÓTIPO ESTILO NI NO KUNI ---
                  const NiNoKuniLogo(),

                  const SizedBox(height: 60),

                  // --- 2. CARTÃO DE LOGIN ---
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      // Borda dourada muito fina e elegante
                      border: Border.all(color: NnkColors.ouroAntigo.withOpacity(0.4), width: 1),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white, // Fundo branco puro no cartão
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: NnkColors.tintaCastanha.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Bem-vindo",
                            style: GoogleFonts.cinzel(
                              fontSize: 16,
                              color: NnkColors.tintaCastanha.withOpacity(0.7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Botão Temático
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: NnkColors.tintaCastanha,
                                foregroundColor: NnkColors.ouroAntigo,
                                elevation: 5,
                                shadowColor: NnkColors.ouroAntigo.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  // Borda dourada no botão
                                  side: const BorderSide(color: NnkColors.ouroAntigo, width: 1.5),
                                ),
                              ),
                              onPressed: auth.isLoading
                                  ? null
                                  : () async {
                                      await auth.loginComHostedUI();
                                      if (auth.isLogado && context.mounted) {
                                        if (auth.tipoUsuario == UserRole.admin) {
                                          Navigator.pushReplacementNamed(context, '/agendas');
                                        } else {
                                          Navigator.pushReplacementNamed(context, '/cliente');
                                        }
                                      }
                                    },
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 24, 
                                      width: 24, 
                                      child: CircularProgressIndicator(color: NnkColors.ouroAntigo)
                                    )
                                  : Text(
                                      'Cadastrar / Entrar', 
                                      style: GoogleFonts.cinzel(
                                        fontSize: 18, 
                                        fontWeight: FontWeight.w900, // Extra Bold
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          if (auth.erro != null)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: NnkColors.vermelhoLacre.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: NnkColors.vermelhoLacre.withOpacity(0.2))
                              ),
                              child: Text(
                                auth.erro!,
                                style: GoogleFonts.alegreya(
                                  color: NnkColors.vermelhoLacre, 
                                  fontSize: 14, 
                                  fontWeight: FontWeight.bold
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                  
                  // --- 3. RODAPÉ ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 30, height: 1, color: NnkColors.ouroAntigo.withOpacity(0.5)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Nnk foundation © 2025',
                          style: GoogleFonts.cinzel(
                            fontSize: 12,
                            color: NnkColors.tintaCastanha.withOpacity(0.4),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(width: 30, height: 1, color: NnkColors.ouroAntigo.withOpacity(0.5)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// WIDGET DO LOGÓTIPO PERSONALIZADO (Estilo Ni No Kuni)
// =======================================================
class NiNoKuniLogo extends StatelessWidget {
  const NiNoKuniLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // CAMADA 1: ARABESCOS DE FUNDO (Simulando o desenho a lápis)
          // Usamos Ícones transformados para criar os redemoinhos de fundo
          Positioned(
            top: 20,
            left: 20,
            child: Transform.rotate(
              angle: -0.5,
              child: Icon(Icons.spa_outlined, size: 140, color: Colors.grey.withOpacity(0.15)),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Transform.rotate(
              angle: 2.5,
              child: Icon(Icons.yard_outlined, size: 140, color: Colors.grey.withOpacity(0.15)),
            ),
          ),
           Positioned(
            top: -10,
            right: 40,
            child: Transform.rotate(
              angle: 0.5,
              child: Icon(Icons.wind_power, size: 100, color: Colors.grey.withOpacity(0.1)),
            ),
          ),

          // CAMADA 2: TEXTO PRINCIPAL "AGENDA" (Com Borda/Sombra Escura)
          // Isso cria o "outline" escuro atrás do dourado
          Positioned(
            top: 62, // Ajuste fino para alinhar
            child: Text(
              'AGENDA',
              style: GoogleFonts.cinzel(
                fontSize: 60,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0, // Espaçamento largo típico
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 6
                  ..color = const Color(0xFF3E2723), // Castanho muito escuro para o contorno
              ),
            ),
          ),

          // CAMADA 3: TEXTO PRINCIPAL "AGENDA" (Dourado Metálico)
          // O gradiente simula o brilho do ouro
          Positioned(
            top: 62,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [
                    Color(0xFFB8860B), // Ouro Escuro
                    Color(0xFFFFD700), // Ouro Brilhante
                    Color(0xFFFFFacd), // Ouro Claro (Brilho)
                    Color(0xFFB8860B), // Ouro Escuro
                  ],
                  stops: [0.0, 0.4, 0.6, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds);
              },
              child: Text(
                'AGENDA',
                style: GoogleFonts.cinzel(
                  fontSize: 60,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                  color: Colors.white, // Necessário para o ShaderMask funcionar
                ),
              ),
            ),
          ),
          
          // CAMADA 4: ÍCONE/ELEMENTO SUPERIOR (O Livro Mágico)
          Positioned(
             top: 15,
             child: ShaderMask(
               shaderCallback: (bounds) => const LinearGradient(
                 colors: [Color(0xFFB8860B), Color(0xFFFFD700)],
                 begin: Alignment.topLeft,
                 end: Alignment.bottomRight
               ).createShader(bounds),
               child: const Icon(Icons.auto_stories, size: 45, color: Colors.white),
             ),
          ),

          // CAMADA 5: SUBTÍTULO / TRAÇO INFERIOR
          Positioned(
            bottom: 45,
            child: Column(
              children: [
                // Linha fina dourada
                Container(
                  height: 2,
                  width: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        NnkColors.ouroAntigo,
                        Colors.transparent
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "WRATH OF THE SCHEDULE", // Referência divertida ao jogo
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5D4037), // Castanho terra
                    letterSpacing: 3.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}