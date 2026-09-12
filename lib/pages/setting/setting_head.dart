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

/// Cabeçalho de perfil no estilo Facebook: capa + avatar circular
/// sobreposto, nome/handle, contadores discretos e os botões de ação em
/// formato de pílula ("Editar perfil" + atalho "mais opções").
class SettingHead extends StatelessWidget {
  SettingHead({Key key, this.onMoreTap}) : super(key: key);

  /// Chamado ao tocar no botão circular "⋯" (mais opções: Listas,
  /// Postagens agendadas, Configurações da conta e Configurações gerais).
  final VoidCallback onMoreTap;

  Widget userStatistics(BuildContext context, OwnerAccount account) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        NoSplashInkWell(
          child: headerSection(account.statusesCount, S.of(context).toots),
          onTap: () => AppNavigate.push(UserProfile(account)),
        ),
        _statDot(),
        NoSplashInkWell(
          child:
              headerSection(account.followingCount, S.of(context).attention),
          onTap: () => AppNavigate.push(UserFollowing(account.id)),
        ),
        _statDot(),
        NoSplashInkWell(
          child: headerSection(account.followersCount, S.of(context).fans),
          onTap: () => AppNavigate.push(UserFollowers(account.id)),
        ),
      ],
    );
  }

  // Um pontinho discreto no lugar da antiga linha divisória pesada entre
  // os contadores.
  Widget _statDot() {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: FbColors.textSecondary.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget headerSection(int number, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$number  ',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: FbColors.textPrimary),
            ),
            TextSpan(
              text: title,
              style:
                  TextStyle(fontSize: 14, color: FbColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // Botão principal (pílula azul cheia) + botão secundário circular
  // ("⋯"), lado a lado, no estilo dos botões de ação do Facebook.
  Widget _actionButtons(BuildContext context, OwnerAccount account) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: FbColors.primaryBlue,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => AppNavigate.push(EditUserProfile(account)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        S.of(context).edit_profile,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onMoreTap != null) ...[
            SizedBox(width: 8),
            Material(
              color: FbColors.iconChipBackground,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onMoreTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 9, horizontal: 14),
                  child: Icon(Icons.more_horiz,
                      size: 20, color: FbColors.textPrimary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    OwnerAccount account =
        Provider.of<SettingsProvider>(context)?.currentUser?.account;

    if (account == null) return Container(height: 260);

    return Container(
      color: FbColors.cardBackground,
      child: Column(
        children: [
          // Capa + avatar circular centralizado sobreposto, estilo Facebook.
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
          SizedBox(height: 6),
          userStatistics(context, account),
          SizedBox(height: 4),
          _actionButtons(context, account),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
