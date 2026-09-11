import 'package:dudu/api/timeline_api.dart';
import 'package:dudu/constant/icon_font.dart';
import 'package:dudu/constant/fb_colors.dart';
import 'package:dudu/l10n/l10n.dart';
import 'package:dudu/models/logined_user.dart';
import 'package:dudu/models/provider/settings_provider.dart';
import 'package:dudu/models/task/check_role_task.dart';
import 'package:dudu/models/task/get_emoji_task.dart';
import 'package:dudu/models/task/notification_task.dart';
import 'package:dudu/models/task/register_help_task.dart';
import 'package:dudu/models/task/update_task.dart';
import 'package:dudu/pages/timeline/local_timeline.dart';
import 'package:dudu/pages/timeline/notification_timeline.dart';
import 'package:dudu/pages/timeline/public_timeline.dart';
import 'package:dudu/public.dart';
import 'package:dudu/utils/account_util.dart';
import 'package:dudu/utils/dialog_util.dart';
import 'package:dudu/utils/filter_util.dart';
import 'package:dudu/widget/other/app_retain_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'setting/setting.dart';
import 'status/new_status.dart';

class HomePage extends StatefulWidget {
  final bool logined;
  const HomePage({Key key, this.logined = true}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      UpdateTask.checkUpdateIfNeed(context);
      RegisterHelpTask.start();
      if (LoginedUser().account != null) {
        CheckRoleTask.checkUserRole();
        GetEmojiTask.get();
        removeState();
      }
    } else if (state == AppLifecycleState.paused) {
      saveState();
    }
  }

  saveState() {
    AccountUtil.saveState();
  }

  removeState() {
    AccountUtil.restoreState();
  }

  @override
  void initState() {
    super.initState();
    UpdateTask.checkUpdateIfNeed(context);

    if (LoginedUser().account != null) {
      CheckRoleTask.checkUserRole();
      FilterUtil.getFiltersAndApply();

      NotificationTask.enable();
      GetEmojiTask.get();

      WidgetsBinding.instance.addObserver(this);
    }
    RegisterHelpTask.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    eventBus.off(EventBusKey.ShowLoginWidget);
    super.dispose();
  }

  // Aba "Discover" (instâncias) removida da navegação.
  // Ícones estilo Facebook: contorno quando inativo, preenchido e azul
  // quando ativo (Material Icons, para ter as duas variantes prontas).
  List<IconData> _tabIconsOutline = [
    Icons.home_outlined,
    Icons.people_outline,
    Icons.notifications_outlined,
    Icons.person_outline,
  ];

  List<IconData> _tabIconsFilled = [
    Icons.home,
    Icons.people,
    Icons.notifications,
    Icons.person,
  ];

  List<String> get _tabTitles {
    return [
      S.of(context).home,
      S.of(context).square,
      S.of(context).news,
      S.of(context).me
    ];
  }

  Icon getTabIcon(int index, Color activeColor, bool logined) {
    if (index == SettingsProvider().homeTabIndex) {
      return Icon(
        _tabIconsFilled[index],
        color: activeColor,
        size: 26,
      ); //_tabSelectedImages[index];
    } else {
      return Icon(
        _tabIconsOutline[index],
        color: logined ? FbColors.textPrimary : Colors.grey,
        size: 26,
      ); //_tabImages[index];
    }
  }

  void showNewArtical() {
    AppNavigate.push(NewStatus());
    // eventBus.emit(EventBusKey.ShowNewArticalWidget);
  }

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<SettingsProvider>(context);
    var homeTabIndex = provider.homeTabIndex;
    return AppRetainWidget(
      child: Scaffold(
          body: Column(
            children: [
              if (widget.logined) _topMenu(homeTabIndex, widget.logined),
              Expanded(
                child: IndexedStack(
                  children: <Widget>[
                    widget.logined ? HomeTimeline() : Container(),
                    widget.logined
                        ? PublicTimeline(
                            enableFederated: !LoginedUser()
                                .host
                                .startsWith('https://help.dudu.today'),
                          )
                        : Container(),
                    widget.logined ? NotificationTimeline() : Container(),
                    widget.logined ? Setting() : Container()
                  ],
                  index: homeTabIndex,
                ),
              ),
            ],
          )),
    );
  }

  // Barra de navegação estilo Facebook: fica no TOPO (não embaixo), só com
  // ícones (sem legenda) e uma barrinha azul embaixo do ícone ativo.
  Widget _topMenu(int _tabIndex, bool logined) {
    SettingsProvider provider = Provider.of<SettingsProvider>(context);
    Color activeColor = Theme.of(context).toggleableActiveColor;
    var showBadge = provider.get('red_dot_notfication');
    return SafeArea(
      bottom: false,
      child: Container(
        color: FbColors.cardBackground,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _topNavItem(
                  index: 0,
                  tabIndex: _tabIndex,
                  activeColor: activeColor,
                  logined: logined,
                  showBadge: showBadge &&
                      logined &&
                      provider.unread[TimelineApi.home] != 0,
                  onTap: logined
                      ? () {
                          if (_tabIndex == 0) {
                            provider.homeProvider.refreshController
                                .requestRefresh(
                                    duration: Duration(milliseconds: 100));
                          } else {
                            setState(() {
                              SettingsProvider().setHomeTabIndex(0);
                            });
                          }
                        }
                      : () => DialogUtils.showInfoDialog(
                          context, S.of(context).need_login_before_operate),
                ),
                _topNavItem(
                  index: 1,
                  tabIndex: _tabIndex,
                  activeColor: activeColor,
                  logined: logined,
                  showBadge: showBadge &&
                      logined &&
                      provider.unread[TimelineApi.local] != 0,
                  onTap: logined
                      ? () {
                          if (_tabIndex == 1) {
                            if (SettingsProvider().publicTabIndex == 0) {
                              provider.localProvider.refreshController
                                  .requestRefresh(
                                      duration: Duration(milliseconds: 100));
                            } else {
                              provider.federatedProvider.refreshController
                                  .requestRefresh(
                                      duration: Duration(milliseconds: 100));
                            }
                          } else {
                            SettingsProvider().setHomeTabIndex(1);
                          }
                        }
                      : () => DialogUtils.showInfoDialog(
                          context, S.of(context).need_login_before_operate),
                ),
                _topNavItem(
                  index: 2,
                  tabIndex: _tabIndex,
                  activeColor: activeColor,
                  logined: logined,
                  showBadge: showBadge &&
                      logined &&
                      (provider.unread[TimelineApi.conversations] != 0 ||
                          provider.unread[TimelineApi.followRquest] != 0 ||
                          provider.unread[TimelineApi.follow] != 0 ||
                          provider.unread[TimelineApi.mention] != 0 ||
                          provider.unread[TimelineApi.reblogNotification] !=
                              0 ||
                          provider.unread[TimelineApi.favoriteNotification] !=
                              0 ||
                          provider.unread[TimelineApi.pollNotification] != 0),
                  onTap: logined
                      ? () {
                          if (_tabIndex == 2) {
                            provider.notificationProvider.refreshController
                                .requestRefresh(
                                    duration: Duration(milliseconds: 100));
                          } else {
                            SettingsProvider().setHomeTabIndex(2);
                          }
                        }
                      : () => DialogUtils.showInfoDialog(
                          context, S.of(context).need_login_before_operate),
                ),
                _topNavItem(
                  index: 3,
                  tabIndex: _tabIndex,
                  activeColor: activeColor,
                  logined: logined,
                  showBadge: false,
                  onTap: logined
                      ? () {
                          if (_tabIndex == 3) {
                            SettingsProvider()
                                .settingController
                                .requestRefresh(
                                    duration: Duration(milliseconds: 100));
                          } else {
                            SettingsProvider().setHomeTabIndex(3);
                          }
                        }
                      : () => DialogUtils.showInfoDialog(
                          context, S.of(context).need_login_before_operate),
                ),
              ],
            ),
            Divider(height: 0.5, thickness: 0.5),
          ],
        ),
      ),
    );
  }

  Widget _topNavItem(
      {int index,
      int tabIndex,
      Color activeColor,
      bool logined,
      bool showBadge,
      VoidCallback onTap}) {
    bool active = index == tabIndex;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              overflow: Overflow.visible,
              children: [
                getTabIcon(index, activeColor, logined),
                if (showBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                    ),
                  )
              ],
            ),
            SizedBox(height: 4),
            Container(
              height: 2,
              width: 26,
              decoration: BoxDecoration(
                  color: active ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ],
        ),
      ),
    );
  }
}
