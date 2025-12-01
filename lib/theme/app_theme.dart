import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =======================================================
//  PALETA DE CORES "NI NO KUNI" / RPG
// =======================================================
class NnkColors {
  // Fundo Creme/Papel Antigo (A cor principal que pediste)
  static const Color papelAntigo = Color(0xFFFDFBF7); 
  
  // Castanho Tinta (Para textos e ícones principais)
  static const Color tintaCastanha = Color(0xFF4A3B32);
  
  // Dourado Envelhecido (Para bordas, destaques e botões)
  static const Color ouroAntigo = Color(0xFFC5A059);
  
  // Dourado Claro (Para fundos de destaque subtis)
  static const Color ouroClaro = Color(0xFFEDE6D6);

  // Vermelho Lacre (Para erros ou ações destrutivas)
  static const Color vermelhoLacre = Color(0xFFA83232);
  
  // Verde Erva (Para sucesso ou confirmações)
  static const Color verdeErva = Color(0xFF5D8A66);

  // Cinza Suave (Para itens desabilitados, placeholders ou bordas neutras)
  static const Color cinzaSuave = Color(0xFFBDBDBD);
  
  // Azul Calmo (Para widgets, detalhes pequenos)
  static const Color azulSuave = Color(0xFF358C9F);

  static List<Color> coresVivas = [
    Colors.pink.shade300,
    Colors.purple.shade300,
    Colors.orange.shade300,
    Colors.teal.shade300,
    Colors.blue.shade300,
    Colors.red.shade300,
    Colors.indigo.shade300,
    Colors.green.shade300,
  ];
}


ThemeData getNnkTheme() {
  // Tipografia Épica
  final TextTheme textThemeBase = GoogleFonts.alegreyaTextTheme(); // Corpo do texto (Livro)
  final TextTheme titleThemeBase = GoogleFonts.cinzelTextTheme();  // Títulos (Épico)

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: NnkColors.papelAntigo,
    primaryColor: NnkColors.ouroAntigo,
    
    // Definição de Cores do Material 3
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: NnkColors.tintaCastanha,
      onPrimary: Colors.white,
      secondary: NnkColors.ouroAntigo,
      onSecondary: NnkColors.tintaCastanha,
      error: NnkColors.vermelhoLacre,
      onError: Colors.white,
      surface: NnkColors.papelAntigo, // Fundo
      onSurface: NnkColors.tintaCastanha, // Texto no fundo
    ),

    // --- TIPOGRAFIA ---
    textTheme: textThemeBase.copyWith(
      // Títulos Épicos
      displayLarge: titleThemeBase.displayLarge?.copyWith(color: NnkColors.tintaCastanha),
      headlineMedium: titleThemeBase.headlineMedium?.copyWith(
        color: NnkColors.tintaCastanha, 
        fontWeight: FontWeight.bold
      ),
      headlineSmall: titleThemeBase.headlineSmall?.copyWith(
        color: NnkColors.tintaCastanha,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: titleThemeBase.titleLarge?.copyWith(
        color: NnkColors.tintaCastanha,
        fontWeight: FontWeight.w600,
      ),
      // Corpo do texto estilo livro
      bodyLarge: textThemeBase.bodyLarge?.copyWith(color: NnkColors.tintaCastanha, fontSize: 18),
      bodyMedium: textThemeBase.bodyMedium?.copyWith(color: NnkColors.tintaCastanha, fontSize: 16),
      // Pequenos textos ou legendas
      bodySmall: textThemeBase.bodySmall?.copyWith(color: NnkColors.tintaCastanha.withOpacity(0.7)),
    ),

    // --- APP BAR (Cabeçalho do Livro) ---
    appBarTheme: AppBarTheme(
      backgroundColor: NnkColors.papelAntigo,
      foregroundColor: NnkColors.tintaCastanha,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.cinzel(
        color: NnkColors.tintaCastanha,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5, // Espaçamento elegante
      ),
      iconTheme: const IconThemeData(color: NnkColors.ouroAntigo),
    ),

    // --- BOTÕES (Selo de Cera / Placa Dourada) ---
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NnkColors.tintaCastanha, // Fundo escuro
        foregroundColor: NnkColors.ouroAntigo,    // Texto dourado
        disabledBackgroundColor: NnkColors.cinzaSuave.withOpacity(0.3), // Fundo desabilitado
        disabledForegroundColor: NnkColors.cinzaSuave, // Texto desabilitado
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: NnkColors.ouroAntigo, width: 2), // Borda dourada
        ),
        textStyle: GoogleFonts.cinzel(
          fontSize: 16, 
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    ),

    // --- INPUTS (Campos de Escrita) ---
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.6), // Levemente transparente
      contentPadding: const EdgeInsets.all(16),
      // Borda normal (Traço de pena fino)
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: NnkColors.ouroAntigo, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: NnkColors.ouroAntigo, width: 1),
      ),
      // Borda focada (Dourado mais forte)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: NnkColors.tintaCastanha, width: 2),
      ),
      // Borda de erro
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: NnkColors.vermelhoLacre, width: 1),
      ),
      labelStyle: GoogleFonts.alegreya(color: NnkColors.tintaCastanha.withOpacity(0.7)),
      hintStyle: GoogleFonts.alegreya(color: NnkColors.cinzaSuave), // Hint com a cor cinza suave
      prefixIconColor: NnkColors.ouroAntigo,
    ),

    // --- CARDS (Páginas Soltas / Cartas) ---
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: NnkColors.tintaCastanha.withOpacity(0.2),
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: NnkColors.ouroAntigo.withOpacity(0.3), width: 1),
      ),
    ),

    // --- CHIPS (Etiquetas) ---
    chipTheme: ChipThemeData(
      backgroundColor: NnkColors.papelAntigo,
      disabledColor: NnkColors.cinzaSuave.withOpacity(0.2),
      selectedColor: NnkColors.ouroAntigo,
      secondarySelectedColor: NnkColors.ouroAntigo,
      padding: const EdgeInsets.all(8.0),
      labelStyle: GoogleFonts.alegreya(color: NnkColors.tintaCastanha),
      secondaryLabelStyle: GoogleFonts.alegreya(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: NnkColors.ouroAntigo.withOpacity(0.5)),
      ),
    ),
  );
}