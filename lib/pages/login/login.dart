import 'package:dudu/l10n/l10n.dart';
import 'dart:convert';

import 'package:dudu/api/accounts_api.dart';
import 'package:dudu/models/json_serializable/owner_account.dart';
import 'package:dudu/models/local_account.dart';
import 'package:dudu/models/logined_user.dart';
import 'package:dudu/models/provider/settings_provider.dart';
import 'package:dudu/pages/home_page.dart';
import 'package:dudu/pages/webview/inner_browser.dart';
import 'package:dudu/public.dart';
import 'package:dudu/utils/account_util.dart';
import 'package:dudu/utils/dialog_util.dart';
import 'package:dudu/widget/common/custom_app_bar.dart';
import 'package:dudu/widget/common/loading_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nav_router/nav_router.dart';
import 'package:http/http.dart' as http;

import 'model/app_credential.dart';
import 'model/token.dart';

class Login extends StatefulWidget {
  final bool showBackButton;

  Login({this.showBackButton = false});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _clickButton = false;

  bool isLoading = false; // 是否登录成功获取token中

  // Servidor fixo: sempre mastodon.social, sem tela de escolha.
  final String _hostUrl = AppConfig.fixedHost;

  @override
  void initState() {
    super.initState();
  }

  // Monta o AppCredential com as chaves fixas (não registra mais via API)
  // e abre direto a tela de autorização do Mastodon.
  Future<void> _startLogin() async {
    if (AppConfig.fixedClientId.isEmpty || AppConfig.fixedClientSecret.isEmpty) {
      DialogUtils.showSimpleAlertDialog(
        context: navGK.currentState.overlay.context,
        text: 'Client ID/Secret não configurados no build.',
        onlyInfo: true,
      );
      return;
    }

    setState(() {
      _clickButton = true;
    });

    AppCredential model = AppCredential(
      '0',
      AppConfig.ClientName,
      AppConfig.fixedRedirectUri,
      AppConfig.fixedClientId,
      AppConfig.fixedClientSecret,
      null,
    );

    setState(() {
      _clickButton = false;
    });

    final result = await AppNavigate.push(
      InnerBrowser(_hostUrl, appCredential: model),
    );

    if (result == null) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    await _getToken(result, model, _hostUrl);
  }

// 获取token，此后的每次请求都需带上此token
  Future<void> _getToken(
      String code, AppCredential serverItem, String hostUrl) async {
    Map<String, dynamic> paramsMap = Map();
    paramsMap['client_id'] = serverItem.clientId;
    paramsMap['client_secret'] = serverItem.clientSecret;
    paramsMap['grant_type'] = 'authorization_code';
    paramsMap['code'] = code;
    paramsMap['redirect_uri'] = serverItem.redirectUri;
    try {
      await http.post('$hostUrl' + Api.Token, body: paramsMap).then((data) async{
        Token getToken = Token.fromJson(json.decode(data.body));
        String token = '${getToken.tokenType} ${getToken.accessToken}';

        Request.closeHttpClient();

        LoginedUser user = new LoginedUser();
        user.token = token;
        user.host = hostUrl;
        OwnerAccount account = await AccountsApi.getMyAccount();
        if (account == null) {
          DialogUtils.toastErrorInfo(S.of(context).something_went_wrong);
          setState(() {
            isLoading = false;
          });
        }

        LocalAccount localAccount = LocalAccount(hostUrl: hostUrl,token: token,active: true,account: account);
        await LocalStorageAccount.addLocalAccount(localAccount);


        user = new LoginedUser();
        user.loadFromLocalAccount(localAccount);

        await SettingsProvider().load(); // load new settings

        AccountUtil.cacheEmoji();
        AccountUtil.requestPreference();

        pushAndRemoveUntil(HomePage());

        // eventBus.emit(EventBusKey.HidePresentWidegt);
      });
    } catch (e) {
      print(e);
      debugPrint(e.toString());
      DialogUtils.toastErrorInfo(S.of(context).something_went_wrong);
      setState(() {
        isLoading = false;
      });
      debugPrint(e);
    }
  }

  Widget _showButtonLoading(BuildContext context) {
    if (_clickButton) {
      return SpinKitThreeBounce(
        color: Theme.of(context).buttonColor,
        size: 23,
      );
    }
    return Text(S.of(context).log_in_to_mastodon_account,
        style: TextStyle(fontSize: 16, color: Color.fromRGBO(80, 125, 175, 1)));
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  width: 50,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    color: Colors.grey[300],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                      'Mastodon（长毛象）是由多个不同的营运者独立运作的服务器（实例）彼此链接组成的分布式微博客社交网络。网友可自主访问目标实例并注册成为该实例的用户。请注意，每个实例的用户协议和交流风格是该实例的所有者（站长）所自行定义的，注册的时候应仔细了解该实例的用户协议以免误入。Mastodon实例可以由Web浏览器输入域名直接访问，或者通过第三方客户端来访问。这些客户端包括但不限于本客户端以及tusky、Twidere、Amaroq、Tootdon。另外，Mastodon.social，Mastodon.online是Mastodon官方运营的实例。'),
                )
              ],
            ),
          );
        });
  }

  Widget loadView() {

      return Scaffold(
        body: LoadingView(text: S.of(context).loading,),
      );
  }

  @override
  Widget build(BuildContext context) {
    return  isLoading ? loadView():
    Scaffold(
      appBar: CustomAppBar(
        automaticallyImplyLeading: widget.showBackButton,
          backgroundColor: Colors.transparent,
        elevation: 0,
        leading: null,
      ),
        extendBodyBehindAppBar:true,
            resizeToAvoidBottomPadding: false,
        backgroundColor: Color.fromRGBO(0, 71, 122, 1),
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                FocusScope.of(context).requestFocus(FocusNode());
              },
              child: Container(
                child: Column(
                  children: <Widget>[
                    Container(
                        height: 60,
                        child: Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Center(
                            child: Text('Mastodon',
                                style: TextStyle(
                                    fontSize: 20, )),
                          ),
                        )),
                    Image.asset('assets/images/wallpaper.png'),
                    Card(
                      margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(2))),
                      elevation: 5,
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(_hostUrl.replaceAll('https://', ''), style: TextStyle(fontSize: 16))
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: RaisedButton(
                              onPressed: () {
                                _startLogin();
                              },
                              child: Padding(
                                padding: EdgeInsets.all(10),
                                child: _showButtonLoading(context),
                              ),
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              _showAboutSheet(context);
                            },
                            child: Container(
                              child: Center(
                                child: Text(S.of(context).about_mastodon,
                                    style:
                                        TextStyle(color: Theme.of(context).primaryColor)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ));
  }
}
