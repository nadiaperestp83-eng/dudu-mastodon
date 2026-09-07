import 'dart:convert';

import 'package:dudu/constant/app_config.dart';
import 'package:dudu/l10n/l10n.dart';
import 'package:dudu/pages/login/login.dart';
import 'package:dudu/public.dart';
import 'package:dudu/utils/dialog_util.dart';
import 'package:dudu/widget/common/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;

class SignUp extends StatefulWidget {
  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _agree = false;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState.validate()) return;
    if (!_agree) {
      DialogUtils.toastErrorInfo('Você precisa aceitar os termos do servidor.');
      return;
    }

    setState(() => _loading = true);

    try {
      // 1) Token de aplicativo (client_credentials) — não é o token do usuário,
      // só autoriza a própria criação da conta.
      final tokenResponse = await http.post(
        '${AppConfig.fixedHost}/oauth/token',
        body: {
          'client_id': AppConfig.fixedClientId,
          'client_secret': AppConfig.fixedClientSecret,
          'grant_type': 'client_credentials',
          'scope': 'read write follow',
        },
      );

      if (tokenResponse.statusCode != 200) {
        _showApiError(tokenResponse.body, fallback: 'Não foi possível conectar ao servidor.');
        setState(() => _loading = false);
        return;
      }

      final appToken = json.decode(tokenResponse.body)['access_token'];

      // 2) Cria a conta de verdade.
      final signupResponse = await http.post(
        '${AppConfig.fixedHost}/api/v1/accounts',
        headers: {'Authorization': 'Bearer $appToken'},
        body: {
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'agreement': 'true',
          'locale': 'pt',
        },
      );

      setState(() => _loading = false);

      if (signupResponse.statusCode == 200 || signupResponse.statusCode == 201) {
        _showSuccessDialog();
      } else {
        _showApiError(signupResponse.body, fallback: 'Não foi possível criar a conta.');
      }
    } catch (e) {
      setState(() => _loading = false);
      DialogUtils.toastErrorInfo('Falha de conexão. Tente novamente.');
    }
  }

  void _showApiError(String body, {String fallback}) {
    String message = fallback;
    try {
      final data = json.decode(body);
      if (data['error'] != null) {
        message = data['error'].toString();
      }
      if (data['details'] != null) {
        final details = data['details'] as Map<String, dynamic>;
        final parts = <String>[];
        details.forEach((field, issues) {
          if (issues is List && issues.isNotEmpty) {
            final reason = issues[0]['error'] ?? '';
            parts.add('$field: $reason');
          }
        });
        if (parts.isNotEmpty) {
          message = parts.join('\n');
        }
      }
    } catch (_) {}
    DialogUtils.toastErrorInfo(message);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Conta criada!'),
        content: Text(
            'Enviamos um e-mail de confirmação. Confirme seu e-mail e depois toque em Entrar para fazer login.'),
        actions: [
          FlatButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              AppNavigate.pop();
              AppNavigate.push(Login(showBackButton: true));
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final host = AppConfig.fixedHost.replaceAll('https://', '');

    return Scaffold(
      appBar: CustomAppBar(
        title: Text('Criar conta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Sua conta será criada em',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  host,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 24),
                TextFormField(
                  controller: _usernameController,
                  decoration: _decoration('Nome de usuário'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe um nome de usuário';
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                      return 'Use só letras, números e _';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoration('E-mail'),
                  validator: (v) {
                    if (v == null || !v.contains('@')) return 'Informe um e-mail válido';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _decoration('Senha').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 8) return 'Mínimo de 8 caracteres';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscurePassword,
                  decoration: _decoration('Confirmar senha'),
                  validator: (v) {
                    if (v != _passwordController.text) return 'As senhas não coincidem';
                    return null;
                  },
                ),
                SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _agree,
                  onChanged: (v) => setState(() => _agree = v),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'Concordo com os termos de uso do servidor $host',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: RaisedButton(
                    color: Theme.of(context).primaryColor,
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? SpinKitThreeBounce(color: Colors.white, size: 20)
                        : Text('Cadastrar', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
