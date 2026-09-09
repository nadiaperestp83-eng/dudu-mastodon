import 'package:dudu/api/timeline_api.dart';
import 'package:dudu/constant/fb_colors.dart';
import 'package:dudu/l10n/l10n.dart';
import 'package:dudu/models/logined_user.dart';
import 'package:dudu/models/provider/settings_provider.dart';
import 'package:dudu/pages/search/search_page_delegate.dart';
import 'package:dudu/pages/status/new_status.dart';
import 'package:dudu/utils/app_navigate.dart';
import 'package:dudu/widget/common/app_bar_title.dart';
import 'package:dudu/widget/common/custom_app_bar.dart';
import 'package:dudu/widget/other/avatar.dart';
import 'package:dudu/widget/setting/account_list_header.dart';
import 'package:dudu/widget/timeline/timeline_content.dart';
import 'package:flutter/material.dart';
import 'package:mk_drop_down_menu/mk_drop_down_menu.dart';
import 'package:nav_router/nav_router.dart';

import '../../widget/other/search.dart' as customSearch;

class HomeTimeline extends StatefulWidget {
  @override
  _HomeTimelineState createState() => _HomeTimelineState();
}

class _HomeTimelineState extends State<HomeTimeline> {
  GlobalKey _headerKey;
  MKDropDownMenuController _downMenuController;

  @override
  void initState() {
    _headerKey = GlobalKey();
    _downMenuController = MKDropDownMenuController();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        key: _headerKey,
        // Logo do app em azul e negrito à esquerda, estilo Facebook.
        title: MKDropDownMenu(
          controller: _downMenuController,
          headerBuilder: (menuShowing) {
            return DropDownTitle(
              title: S.of(context).home,
              expand: menuShowing,
              showIcon: true,
              fontColor: FbColors.primaryBlue,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            );
          },
          headerKey: _headerKey,
          menuBuilder: () {
            return AccountListHeader(_downMenuController);
          },
        ),
        actions: [
          _FbIconChip(
            icon: Icons.search,
            onTap: () {
              OverlayUtil.hideAllOverlay();
              customSearch.showSearch(
                  context: context, delegate: SearchPageDelegate());
            },
          ),
          SizedBox(width: 8),
          _FbIconChip(
            icon: Icons.notifications_outlined,
            onTap: () {
              OverlayUtil.hideAllOverlay();
              SettingsProvider().setHomeTabIndex(2);
            },
          ),
          SizedBox(width: 8),
          _FbIconChip(
            icon: Icons.add,
            onTap: () {
              OverlayUtil.hideAllOverlay();
              AppNavigate.push(NewStatus(), routeType: RouterType.material);
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Barra "No que você está pensando?" no topo do feed, estilo Facebook.
          _ComposerBar(onTap: () {
            AppNavigate.push(NewStatus(), routeType: RouterType.material);
          }),
          Container(color: FbColors.background, height: 8),
          Expanded(
            child: TimelineContent(
              url: TimelineApi.home,
              tag: 'home',
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de composição no topo do feed ("No que você está pensando?"),
/// com o avatar do usuário logado - estilo Facebook. Ao tocar, abre a
/// tela de nova publicação (New Status) do Mastodon.
class _ComposerBar extends StatelessWidget {
  final VoidCallback onTap;

  const _ComposerBar({Key key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FbColors.cardBackground,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Avatar(
            width: 40,
            height: 40,
            navigateToDetail: false,
            account: LoginedUser().account,
          ),
          SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: FbColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  S.of(context).beep,
                  style: TextStyle(
                      color: FbColors.textSecondary, fontSize: 15),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          InkWell(
            onTap: onTap,
            child: Icon(Icons.photo_library, color: Colors.green[700], size: 24),
          ),
        ],
      ),
    );
  }
}

/// Botão de atalho circular com fundo cinza-claro, no estilo dos ícones
/// de "pesquisa" e "notificações" da AppBar do Facebook.
class _FbIconChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FbIconChip({Key key, this.icon, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: FbColors.iconChipBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: FbColors.textPrimary),
      ),
    );
  }
}
