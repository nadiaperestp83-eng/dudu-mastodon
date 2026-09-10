import 'package:dudu/api/accounts_api.dart';
import 'package:dudu/constant/fb_colors.dart';
import 'package:dudu/l10n/l10n.dart';
import 'package:dudu/models/json_serializable/owner_account.dart';
import 'package:dudu/pages/user_profile/user_profile.dart';
import 'package:dudu/public.dart';
import 'package:dudu/utils/app_navigate.dart';
import 'package:dudu/widget/other/avatar.dart';
import 'package:dudu/widget/status/text_with_emoji.dart';
import 'package:flutter/material.dart';

/// Carrossel "Sugestões para você" no topo do feed, igual ao Facebook/
/// Instagram, mas puxando sugestões de contas (pessoas, páginas, fóruns)
/// direto da API do Mastodon (GET /api/v2/suggestions, com fallback pro v1).
class SuggestionsCarousel extends StatefulWidget {
  @override
  _SuggestionsCarouselState createState() => _SuggestionsCarouselState();
}

class _SuggestionsCarouselState extends State<SuggestionsCarousel> {
  List<OwnerAccount> _suggestions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var res = await AccountsApi.getSuggestions(limit: 10);
    if (!mounted) return;
    setState(() {
      _suggestions = res ?? [];
      _loading = false;
    });
  }

  void _dismiss(OwnerAccount account) {
    setState(() {
      _suggestions.removeWhere((a) => a.id == account.id);
    });
  }

  Future<void> _follow(OwnerAccount account) async {
    await AccountsApi.follow(account.id);
    if (!mounted) return;
    _dismiss(account);
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto carrega ou se não vier nenhuma sugestão (instância sem
    // suporte ao endpoint, ou usuário já segue todo mundo sugerido),
    // não ocupa espaço nenhum no feed.
    if (_loading || _suggestions.isEmpty) {
      return SizedBox.shrink();
    }
    return Container(
      color: FbColors.cardBackground,
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              S.of(context).suggestions_for_you,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: FbColors.textPrimary),
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return _SuggestionCard(
                  account: _suggestions[index],
                  onDismiss: () => _dismiss(_suggestions[index]),
                  onFollow: () => _follow(_suggestions[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final OwnerAccount account;
  final VoidCallback onDismiss;
  final VoidCallback onFollow;

  const _SuggestionCard({this.account, this.onDismiss, this.onFollow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: FbColors.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => AppNavigate.push(UserProfile(account)),
                    child: Avatar(
                      account: account,
                      width: 130,
                      height: 100,
                      navigateToDetail: false,
                    ),
                  ),
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: GestureDetector(
                    onTap: onDismiss,
                    child: Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: TextWithEmoji(
              text: StringUtil.displayName(account),
              emojis: account.emojis,
              maxLines: 1,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FbColors.textPrimary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: onFollow,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: FbColors.primaryBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  S.of(context).attention,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
