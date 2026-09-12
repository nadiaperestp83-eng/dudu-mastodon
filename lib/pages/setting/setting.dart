import 'package:dudu/api/accounts_api.dart';
import 'package:dudu/constant/api.dart';
import 'package:dudu/constant/fb_colors.dart';
import 'package:dudu/constant/icon_font.dart';
import 'package:dudu/l10n/l10n.dart';
import 'package:dudu/models/json_serializable/media_attachment.dart';
import 'package:dudu/models/logined_user.dart';
import 'package:dudu/models/provider/result_list_provider.dart';
import 'package:dudu/models/provider/settings_provider.dart';
import 'package:dudu/pages/media/photo_gallery.dart';
import 'package:dudu/pages/setting/account_setting.dart';
import 'package:dudu/pages/setting/general_setting.dart';
import 'package:dudu/pages/setting/lists/lists_page.dart';
import 'package:dudu/pages/status/scheduled_statuses_list.dart';
import 'package:dudu/public.dart';
import 'package:dudu/utils/account_util.dart';
import 'package:dudu/utils/cache_manager.dart';
import 'package:dudu/utils/i18n_util.dart';
import 'package:dudu/utils/view/list_view_util.dart';
import 'package:dudu/widget/common/colored_tab_bar.dart';
import 'package:dudu/widget/listview/provider_easyrefresh_listview.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart'
    as extend;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nav_router/nav_router.dart';
import 'package:provider/provider.dart';

import '../../widget/setting/setting_cell.dart';
import 'setting_head.dart';

/// Tela de perfil próprio ("Me"), no mesmo padrão visual/estrutural usado
/// no perfil público (UserProfile): capa + avatar sobreposto, botões de
/// ação em pílula, e o conteúdo organizado em abas horizontais em vez da
/// antiga lista vertical de configurações com setinhas genéricas.
class Setting extends StatefulWidget {
  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  TabController _tabController;
  List<ResultListProvider> _providers = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _providers.addAll([
      // Publicações
      ResultListProvider(
        requestUrl: AccountsApi.statusUrl(
            account: LoginedUser().account, param: 'exclude_replies=true'),
        buildRow: ListViewUtil.statusRowFunction(),
        dataHandler: ListViewUtil.dataHandlerPrefixIdFunction('me_status_'),
      ),
      // Mídia
      ResultListProvider(
        requestUrl: AccountsApi.statusUrl(
            account: LoginedUser().account, param: 'only_media=true'),
        buildRow: _buildGridItem,
        firstRefresh: false,
        dataHandler: (data) {
          var handledData = [];
          for (var row in data) {
            row['media_attachments'].forEach((element) {
              element['id'] = 'me_media_' + element['id'];
            });
            handledData.addAll(row['media_attachments']);
          }
          return handledData;
        },
      ),
      // Favoritos
      ResultListProvider(
        requestUrl: Api.Favourites,
        buildRow: ListViewUtil.statusRowFunction(),
        headerLinkPagination: true,
        firstRefresh: false,
        dataHandler: ListViewUtil.dataHandlerPrefixIdFunction('me_fav_'),
      ),
      // Salvos
      ResultListProvider(
        requestUrl: Api.bookmarks,
        buildRow: ListViewUtil.statusRowFunction(),
        headerLinkPagination: true,
        firstRefresh: false,
        dataHandler: ListViewUtil.dataHandlerPrefixIdFunction('me_bookmark_'),
      ),
    ]);
    SettingsProvider().setSettingRefreshCallback(_onRefreshPage);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  _buildGridItem(int idx, List data, ResultListProvider provider) {
    MediaAttachment media = MediaAttachment.fromJson(data[idx]);
    return InkWell(
      onTap: () => AppNavigate.push(
          PhotoGallery(
            initialIndex: idx,
            galleryItems:
                provider.list.map((e) => MediaAttachment.fromJson(e)).toList(),
          ),
          routeType: RouterType.fade),
      child: Hero(
        tag: media.id,
        flightShuttleBuilder: (flightContext, animation, flightDirection,
            fromHeroContext, toHeroContext) {
          final Hero hero = flightDirection == HeroFlightDirection.push
              ? fromHeroContext.widget
              : toHeroContext.widget;
          return hero.child;
        },
        child: CachedNetworkImage(
            progressIndicatorBuilder: (context, widget, chunk) {
              return Container(color: FbColors.divider);
            },
            fit: BoxFit.cover,
            imageUrl: media.previewUrl,
            cacheManager: CustomCacheManager()),
      ),
    );
  }

  Future<void> _onRefreshPage() async {
    if (LoginedUser().account != null) {
      var newAccount = await AccountsApi.getAccount(LoginedUser().account);
      if (newAccount != null) {
        AccountUtil.updateAccount(newAccount);
      }
    }
    _providers[_tabController.index]?.refresh();
    if (mounted) setState(() {});
  }

  // Bottom sheet "mais opções", estilo Facebook, com os atalhos que antes
  // eram itens soltos na lista vertical (Listas, Postagens agendadas,
  // Configurações da conta e Configurações gerais). Mesma navegação de
  // sempre, só que reunida num único ponto de entrada compacto.
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FbColors.cardBackground,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: FbColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              SizedBox(height: 8),
              SettingCell(
                title: S.of(context).list,
                leftIcon: Icon(IconFont.list),
                onPress: () {
                  Navigator.pop(context);
                  AppNavigate.push(ListsPage());
                },
              ),
              SettingCell(
                title: S.of(context).timed_beep,
                leftIcon: Icon(IconFont.time, size: 22),
                onPress: () {
                  Navigator.pop(context);
                  AppNavigate.push(ScheduledStatusesList());
                },
              ),
              SettingCell(
                title: S.of(context).account_settings,
                leftIcon: Icon(IconFont.accountSetting),
                onPress: () {
                  Navigator.pop(context);
                  AppNavigate.push(AccountSetting());
                },
              ),
              SettingCell(
                title: S.of(context).universal,
                leftIcon: Icon(IconFont.settings),
                onPress: () {
                  Navigator.pop(context);
                  AppNavigate.push(GeneralSetting());
                },
              ),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _tab(String text) => Tab(text: text);

  Widget _contentView() {
    return TabBarView(
      controller: _tabController,
      children: <Widget>[
        extend.NestedScrollViewInnerScrollPositionKeyWidget(
            Key('me_tab0'),
            ChangeNotifierProvider<ResultListProvider>.value(
              value: _providers[0],
              child: ProviderEasyRefreshListView(),
            )),
        extend.NestedScrollViewInnerScrollPositionKeyWidget(
            Key('me_tab1'),
            ChangeNotifierProvider<ResultListProvider>.value(
              value: _providers[1],
              child: Container(
                key: PageStorageKey('me_tab1'),
                child: ProviderEasyRefreshListView(
                  usingGrid: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3),
                  firstRefresh: true,
                ),
              ),
            )),
        extend.NestedScrollViewInnerScrollPositionKeyWidget(
            Key('me_tab2'),
            ChangeNotifierProvider<ResultListProvider>.value(
              value: _providers[2],
              child: ProviderEasyRefreshListView(firstRefresh: true),
            )),
        extend.NestedScrollViewInnerScrollPositionKeyWidget(
            Key('me_tab3'),
            ChangeNotifierProvider<ResultListProvider>.value(
              value: _providers[3],
              child: ProviderEasyRefreshListView(firstRefresh: true),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    bool isZh = I18nUtil.isZh(context);
    String zanOrShoucang = context
        .select<SettingsProvider, String>((m) => m.get('zan_or_shoucang'));
    var favoritesTabText = isZh
        ? (zanOrShoucang == '0' ? '赞' : S.of(context).favorites)
        : S.of(context).favorites;

    return Scaffold(
      backgroundColor: FbColors.background,
      body: extend.NestedScrollViewRefreshIndicator(
        onRefresh: _onRefreshPage,
        child: extend.NestedScrollView(
          innerScrollPositionKeyBuilder: () {
            return Key('me_tab${_tabController.index}');
          },
          headerSliverBuilder: (context, boxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: SettingHead(
                  onMoreTap: () => _showMoreOptions(context),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  ColoredTabBar(
                    color: FbColors.cardBackground,
                    tabBar: TabBar(
                      labelColor: FbColors.primaryBlue,
                      unselectedLabelColor: FbColors.textSecondary,
                      labelStyle:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: TextStyle(fontSize: 15),
                      indicatorColor: FbColors.primaryBlue,
                      indicatorWeight: 3,
                      controller: _tabController,
                      tabs: [
                        _tab(S.of(context).toot),
                        _tab(S.of(context).media),
                        _tab(favoritesTabText),
                        _tab(S.of(context).bookmark),
                      ],
                      onTap: (_) => setState(() {}),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: _contentView(),
        ),
      ),
    );
  }
}

// Delegate simples para manter a TabBar fixa (pinned) logo abaixo do
// cabeçalho de perfil enquanto o usuário rola o conteúdo das abas.
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _TabBarDelegate(this.child);

  @override
  double get minExtent => 50;

  @override
  double get maxExtent => 50;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
