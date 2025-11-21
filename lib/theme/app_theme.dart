import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =======================================================
//  PALETA DE CORES
// =======================================================
class NnkColors {
  // Azul profundo (UI, botões primários)
  static const Color azulProfundo = Color(0xFF3D5A80);
  // Dourado mágico (destaques, ícones)
  static const Color dourado = Color(0xFFEEA823);
  // Creme/Pergaminho (fundo de telas e cards)
  static const Color pergaminho = Color(0xFFFBF3E4);
  // Marrom escuro (texto principal, bordas)
  static const Color marromEscuro = Color(0xFF4E342E);
  // Verde Ghibli (ações secundárias, sucesso)
  static const Color verde = Color(0xFF73A580);
  // Vermelho (erros, 'cancelar')
  static const Color vermelho = Color(0xFFC0392B);
  // Cinza Suave (bordas de campos de texto, desabilitado)
  static const Color cinzaSuave = Color(0xFFBDBDBD);
}

// =======================================================
// Esta função cria o ThemeData que será usado no MaterialApp.
// =======================================================
ThemeData getNnkTheme() {
  // Define as fontes base
  // Nunito: suave e legível, para textos do dia-a-dia
  final textThemeBase = GoogleFonts.nunitoTextTheme();
  // Merriweather: serifada, estilo "livro de histórias", para títulos
  final headlineThemeBase = GoogleFonts.merriweatherTextTheme();

  return ThemeData(
    // --- CORES PRINCIPAIS ---
    primaryColor: NnkColors.azulProfundo,
    scaffoldBackgroundColor: NnkColors.pergaminho,
    colorScheme: ColorScheme.light(
      primary: NnkColors.azulProfundo,
      onPrimary: Colors.white,
      secondary: NnkColors.verde,
      onSecondary: Colors.white,
      background: NnkColors.pergaminho,
      onBackground: NnkColors.marromEscuro,
      surface: NnkColors.pergaminho, // Cor de Cards, Menus
      onSurface: NnkColors.marromEscuro, // Cor do texto em Cards
      error: NnkColors.vermelho,
      onError: Colors.white,
      brightness: Brightness.light,
    ),

    // --- FONTES (TEXT THEME) ---
    // Aplica o marrom escuro como cor padrão de texto
    textTheme: textThemeBase
        .apply(
          bodyColor: NnkColors.marromEscuro,
          displayColor: NnkColors.marromEscuro,
        )
        .copyWith(
          // Sobrescreve títulos (usados nos Cards) com a fonte serifada
          headlineSmall: headlineThemeBase.headlineSmall?.copyWith(
            color: NnkColors.azulProfundo,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: headlineThemeBase.titleLarge?.copyWith(
            color: NnkColors.azulProfundo,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: textThemeBase.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

    // --- ESTILO DA APPBAR ---
    appBarTheme: AppBarTheme(
      backgroundColor: NnkColors.azulProfundo,
      foregroundColor: Colors.white,
      elevation: 2.0,
      titleTextStyle: GoogleFonts.merriweather(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // --- ESTILO DE FORMULÁRIOS (TextFormField, DropdownButtonFormField) ---
    // (Usado em register_page_admin.dart, agenda_create_page.dart, etc.)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(
        0.5,
      ), // Fundo branco semi-transparente
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: NnkColors.cinzaSuave),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: NnkColors.cinzaSuave.withOpacity(0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: NnkColors.azulProfundo, width: 2.0),
      ),
      labelStyle: TextStyle(color: NnkColors.marromEscuro.withOpacity(0.8)),
    ),

    // --- ESTILO DE BOTÕES (ElevatedButton) ---
    // (Usado em register_page_admin.dart, list_user_page.dart, etc.)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NnkColors.azulProfundo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),

    // --- ESTILO DO FloatingActionButton ---
    // (Usado em home_page_admin.dart, agenda_list_page.dart)
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: NnkColors.verde, // Cor secundária
      foregroundColor: Colors.white,
    ),

    // --- ESTILO DE CARDS ---
    // (Usado em register_page_admin.dart, list_user_page.dart)
    cardTheme: CardThemeData(
      color: NnkColors.pergaminho, // Fundo do card
      elevation: 1.0, // Sombra sutil
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        // Bordas estilo "desenhado", sutil
        side: BorderSide(
          color: NnkColors.marromEscuro.withOpacity(0.2),
          width: 1.0,
        ),
      ),
    ),

    // --- ESTILO DO ToggleButtons ---
    // (Usado em home_page_admin.dart, home_page_cliente.dart)
    toggleButtonsTheme: ToggleButtonsThemeData(
      fillColor: NnkColors.azulProfundo.withOpacity(0.8),
      selectedColor: Colors.white,
      color: NnkColors.azulProfundo,
      borderRadius: BorderRadius.circular(8.0),
      borderColor: NnkColors.azulProfundo.withOpacity(0.5),
      selectedBorderColor: NnkColors.azulProfundo,
    ),

    // --- ESTILO DOS CHIPS (ChoiceChip, ActionChip) ---
    // (Usado em agenda_create_page.dart, agenda_edit_page.dart)
    chipTheme: ChipThemeData(
      backgroundColor: NnkColors.pergaminho,
      disabledColor: NnkColors.cinzaSuave.withOpacity(0.5),
      selectedColor: NnkColors.azulProfundo,
      secondarySelectedColor: NnkColors.azulProfundo,
      padding: const EdgeInsets.all(8.0),
      labelStyle: GoogleFonts.nunito(color: NnkColors.marromEscuro),
      secondaryLabelStyle: GoogleFonts.nunito(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: NnkColors.azulProfundo.withOpacity(0.5)),
      ),
    ),

    // --- ESTILO DO ExpansionTile ---
    // (Usado em list_user_page.dart)
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: NnkColors.azulProfundo,
      textColor: NnkColors.azulProfundo,
      collapsedIconColor: NnkColors.marromEscuro.withOpacity(0.7),
      collapsedTextColor: NnkColors.marromEscuro,
    ),
  );
}
