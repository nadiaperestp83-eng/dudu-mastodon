import 'package:dudu/l10n/l10n.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dudu/constant/fb_colors.dart';
import 'package:dudu/models/json_serializable/owner_account.dart';
import 'package:dudu/models/provider/settings_provider.dart';
import 'package:dudu/pages/setting/edit_user_profile.dart';
import 'package:dudu/pages/user_profile/user_follewers.dart';
import 'package:dudu/pages/user_profile/user_follewing.dart';
import 'package:dudu/pages/user_profile/user_profile.dart';
import 'package:dudu/public.dart';
import 'package:dudu/utils/cache_manager.dart';
import 'package:dudu/widget/common/no_splash_ink_well.dart';
import 'package:dudu/widget/other/avatar.dart';
import 'package:flutter/material.dart';
import 'package:nav_router/nav_router.dart';
import 'package:provider/provider.dart';

class SettingHead extends StatelessWidget {
  SettingHead({Key key}) : super(key: key);

  Widget userStatistics(BuildContext context,OwnerAccount account) {
    if (account == null) {
      return Container();
    }
    return Ink(
      color: FbColors.cardBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          NoSplashInkWell(
            child: headerSection(account.statusesCount, S.of(context).toots),
            onTap: () => AppNavigate.push(UserProfile(account,)),
          ),
          NoSplashInkWell(
            child: headerSection(account.followingCount, S.of(context).attention),
            onTap: () => AppNavigate.push(UserFollowing(account.id)),
          ),
          NoSplashInkWell(
            child: headerSection(account.followersCount, S.of(context).fans),
            onTap: () => AppNavigate.push(UserFollowers(account.id)),
          ),
        ],
      ),
    );
  }

  Widget headerSection(int number, String title) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: <Widget>[
          Text('$number',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: FbColors.textPrimary)),
          Text(title,
              style: TextStyle(fontSize: 13, color: FbColors.textSecondary))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    OwnerAccount account = Provider.of<SettingsProvider>(context)?.currentUser?.account;

    if (account == null) return Container(height: 220);

    return Column(
      children: [
        // Capa + avatar circular centralizado sobreposto, estilo Facebook
        // (mesmo tratamento visual do perfil público).
        Stack(
          overflow: Overflow.visible,
          children: [
            Container(
              height: 150,
              width: ScreenUtil.width(context),
              color: FbColors.divider,
              child: account.header != null
                  ? CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: account.header,
                      cacheManager: CustomCacheManager(),
                      width: double.infinity,
                      height: 150,
                    )
                  : null,
            ),
            Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: Center(
                child: NoSplashInkWell(
                  onTap: () => AppNavigate.push(EditUserProfile(account)),
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(width: 4, color: Colors.white),
                    ),
                    child: Avatar(
                      account: account,
                      width: 80,
                      height: 80,
                      navigateToDetail: false,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 46),
        Text(
          StringUtil.displayName(account),
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: FbColors.textPrimary),
        ),
        SizedBox(height: 2),
        Text(
          StringUtil.accountFullAddress(account),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: FbColors.textSecondary),
        ),
        SizedBox(height: 8),
        userStatistics(context,account),
        Container(height: 8, color: FbColors.background),
      ],
    );
  }
}
