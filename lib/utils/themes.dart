import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dudu/constant/fb_colors.dart';

class ThemeUtil {
  // Design system "Facebook": tipografia Roboto (google_fonts) + paleta
  // azul #1877F2 / fundo cinza-gelo #F0F2F5 / texto grafite #050505.
  static ThemeData lightTheme() {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);
    return ThemeData(
      fontFamily: GoogleFonts.inter().fontFamily,
      primaryColor: FbColors.cardBackground, // fundo branco dos "cards"
      toggleableActiveColor: FbColors.primaryBlue,
      // Ícones sem cor explícita (ex: lista de Configurações) ficam azuis
      // por padrão, estilo Facebook.
      iconTheme: IconThemeData(color: FbColors.primaryBlue),
      appBarTheme: AppBarTheme(
        elevation: 0.5,
        color: FbColors.cardBackground,
        brightness: Brightness.light,
        iconTheme: IconThemeData(color: FbColors.textPrimary),
        textTheme: TextTheme(
            headline6: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: FbColors.primaryBlue)),
      ),
      dialogTheme: DialogTheme(),
      popupMenuTheme:
          PopupMenuThemeData(color: FbColors.cardBackground),
      inputDecorationTheme:
          InputDecorationTheme(fillColor: FbColors.background),
      backgroundColor: FbColors.background,
      buttonColor: FbColors.primaryBlue,
      textTheme: baseTextTheme.copyWith(
        headline5: GoogleFonts.inter(color: FbColors.textSecondary),
        bodyText1: GoogleFonts.inter(color: FbColors.textPrimary),
        bodyText2: GoogleFonts.inter(color: FbColors.textSecondary),
        subtitle1: GoogleFonts.inter(color: FbColors.textSecondary),
      ),
      bottomSheetTheme:
          BottomSheetThemeData(backgroundColor: FbColors.cardBackground),
      splashColor: Colors.transparent,
      accentColor: FbColors.textSecondary,
      bottomAppBarColor: FbColors.cardBackground,
      scaffoldBackgroundColor: FbColors.background,
      cardColor: FbColors.cardBackground,
      dividerColor: FbColors.divider,
      buttonTheme: ButtonThemeData(
        buttonColor: FbColors.primaryBlue,
        textTheme: ButtonTextTheme.primary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: FbColors.primaryBlue,
      ),
    );
  }

  static ThemeData darkTheme() {
    // Tema "escuro" abandonado: aponta pro mesmo Light Mode do Facebook,
    // pra garantir que ninguém fique preso na paleta escura antiga (mesmo
    // que já tenha essa opção salva nas configurações do celular).
    return lightTheme();
  }

  static ThemeData lightDartTheme() {
    // Idem acima: era a paleta "escuro intermediário", agora também usa
    // o Light Mode do Facebook.
    return lightTheme();
  }

  static get themes {
    return [lightTheme(),lightDartTheme(),darkTheme()];
  }
}
