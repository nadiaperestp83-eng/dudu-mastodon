import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dudu/constant/fb_colors.dart';

class ThemeUtil {
  // Design system "Facebook": tipografia Roboto (google_fonts) + paleta
  // azul #1877F2 / fundo cinza-gelo #F0F2F5 / texto grafite #050505.
  static ThemeData lightTheme() {
    final baseTextTheme = GoogleFonts.robotoTextTheme(ThemeData.light().textTheme);
    return ThemeData(
      fontFamily: GoogleFonts.roboto().fontFamily,
      primaryColor: FbColors.cardBackground, // fundo branco dos "cards"
      toggleableActiveColor: FbColors.primaryBlue,
      appBarTheme: AppBarTheme(
        elevation: 0.5,
        color: FbColors.cardBackground,
        brightness: Brightness.light,
        iconTheme: IconThemeData(color: FbColors.textPrimary),
        textTheme: TextTheme(
            headline6: GoogleFonts.roboto(
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
        headline5: GoogleFonts.roboto(color: FbColors.textSecondary),
        bodyText1: GoogleFonts.roboto(color: FbColors.textPrimary),
        bodyText2: GoogleFonts.roboto(color: FbColors.textSecondary),
        subtitle1: GoogleFonts.roboto(color: FbColors.textSecondary),
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
    return ThemeData.dark().copyWith(
        primaryColor: Color.fromRGBO(30, 30, 30, 1),
        accentColor: Colors.grey[600],
        textTheme: TextTheme(
            bodyText1: TextStyle(color: Color.fromRGBO(211, 211, 211, 1)),
            bodyText2: TextStyle(color: Color.fromRGBO(211, 211, 211, 1)),),
        toggleableActiveColor: Colors.blue,
        backgroundColor: Color.fromRGBO(21, 21, 21, 1),
        appBarTheme:
            AppBarTheme(color: Color.fromRGBO(30, 30, 30, 1), elevation: 1.0),
        splashColor: Colors.transparent,
        scaffoldBackgroundColor: Color.fromRGBO(21, 21, 21, 1),
        buttonColor: Colors.blue //Colors.grey[800],

        );
  }

  static ThemeData lightDartTheme() {
    return ThemeData.dark().copyWith(
        primaryColor: Color.fromRGBO(49,52,67, 1),
        accentColor: Color.fromRGBO(154, 174, 199, 1),
        textTheme: TextTheme(
          bodyText1: TextStyle(color: Color.fromRGBO(255, 255, 255, 1)),
          subtitle1: TextStyle(color: Color.fromRGBO(216, 225, 232, 1)),
          headline5: TextStyle(color: Color.fromRGBO(154, 174, 199, 1)), // 转嘟前面颜色
          bodyText2: TextStyle(color: Color.fromRGBO(226, 226, 226, 1)),),

        toggleableActiveColor: Colors.blue,
        backgroundColor: Color.fromRGBO(40, 44, 53, 1),
        appBarTheme:
        AppBarTheme(color: Color.fromRGBO(68, 75, 93, 1), elevation: 1.0),
        splashColor: Colors.transparent,
        scaffoldBackgroundColor: Color.fromRGBO(40,44,55, 1),
        buttonColor: Colors.blue, //Colors.grey[800],
        dialogTheme: DialogTheme(backgroundColor: Color.fromRGBO(49,52,67, 1)),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: Color.fromRGBO(49,52,67, 1)),
      cardColor: Color.fromRGBO(40,44,55, 1),
      dividerColor: Color.fromRGBO(40,44,55, 1)
    );
  }

  static get themes {
    return [lightTheme(),lightDartTheme(),darkTheme()];
  }
}
