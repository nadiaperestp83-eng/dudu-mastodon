import 'package:dudu/constant/app_config.dart';
import 'package:dudu/pages/login/login.dart';
import 'package:dudu/pages/login/signup.dart';
import 'package:dudu/public.dart';
import 'package:flutter/material.dart';

// Tela fixa de entrada (instância única: organica.social), com a
// identidade visual do Vkton. Substitui a antiga tela de "descobrir
// instâncias" (Discovery/Add Instance).
class InstanceList extends StatelessWidget {
  static const Color _brand = Color(0xFF6C5CE7);
  static const Color _brandDark = Color(0xFF3B2F91);

  @override
  Widget build(BuildContext context) {
    final host = AppConfig.fixedHost.replaceAll('https://', '');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_brandDark, _brand],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: <Widget>[
                Spacer(flex: 3),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'V',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _brand,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Vkton',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  host,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
                Spacer(flex: 4),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: RaisedButton(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onPressed: () {
                      AppNavigate.push(Login(showBackButton: true));
                    },
                    child: Text(
                      'Entrar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _brand,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlineButton(
                    borderSide: BorderSide(color: Colors.white70, width: 1.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onPressed: () {
                      AppNavigate.push(SignUp());
                    },
                    child: Text(
                      'Criar conta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
