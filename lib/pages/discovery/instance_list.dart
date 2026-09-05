import 'package:dudu/constant/app_config.dart';
import 'package:dudu/l10n/l10n.dart';
import 'package:dudu/pages/login/login.dart';
import 'package:dudu/public.dart';
import 'package:dudu/utils/url_util.dart';
import 'package:dudu/widget/common/custom_app_bar.dart';
import 'package:flutter/material.dart';

// Tela fixa de login/cadastro (instância única: mastodon.social).
// Substitui a antiga tela de "descobrir instâncias" (Discovery/Add Instance).
class InstanceList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final host = AppConfig.fixedHost.replaceAll('https://', '');

    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('Orkutodon'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset('assets/images/wallpaper.png', height: 120),
              SizedBox(height: 24),
              Text(
                host,
                style: TextStyle(fontSize: 16, color: Theme.of(context).buttonColor),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: RaisedButton(
                  color: Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  onPressed: () {
                    AppNavigate.push(Login(showBackButton: true));
                  },
                  child: Text(
                    S.of(context).log_in_to_mastodon_account,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlineButton(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  onPressed: () {
                    UrlUtil.openUrl('${AppConfig.fixedHost}/auth/sign_up');
                  },
                  child: Text(
                    S.of(context).registered,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
