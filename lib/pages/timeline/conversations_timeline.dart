import 'package:dudu/api/timeline_api.dart';
import 'package:dudu/constant/api.dart';
import 'package:dudu/constant/fb_colors.dart';
import 'package:dudu/l10n/l10n.dart';
import 'package:dudu/models/json_serializable/article_item.dart';
import 'package:dudu/models/json_serializable/owner_account.dart';
import 'package:dudu/models/logined_user.dart';
import 'package:dudu/models/provider/result_list_provider.dart';
import 'package:dudu/pages/chat/chat_page.dart';
import 'package:dudu/public.dart';
import 'package:dudu/widget/other/avatar.dart';
import 'package:dudu/widget/timeline/timeline_content.dart';
import 'package:flutter/material.dart';

/// Inbox de Mensagens Diretas (DMs) no estilo Messenger: fundo cinza-gelo,
/// cards de conversa com avatar, nome, prévia da última mensagem e o tempo
/// decorrido. Cada item vem de GET /api/v1/conversations; ao tocar, abre o
/// chat individual (ChatPage) daquela conversa.
class ConversationTimeline extends StatelessWidget {
  // true quando embutida como aba dentro do HomePage (sem Scaffold/AppBar
  // próprios -- a barra de abas do HomePage já cumpre esse papel, e ter
  // dois "cabeçalhos" empilhados foi o bug que já corrigimos no feed).
  // false (padrão) quando aberta como página independente, com back button
  // -- caso do atalho "mensagens privadas" dentro de Notificações.
  final bool embedded;

  const ConversationTimeline({Key key, this.embedded = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = TimelineContent(
      url: TimelineApi.conversations,
      tag: 'conversations',
      prefixId: false,
      rowBuilder: _buildRow,
      emptyView: _buildEmptyView(context),
    );

    if (embedded) {
      return Container(
        color: FbColors.background,
        child: Column(
          children: [
            Container(
              height: 48,
              width: double.infinity,
              color: FbColors.cardBackground,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                S.of(context).chat,
                style: TextStyle(
                    color: FbColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20),
              ),
            ),
            Container(color: FbColors.background, height: 1),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: FbColors.background,
      appBar: AppBar(
        backgroundColor: FbColors.cardBackground,
        elevation: 0.6,
        iconTheme: IconThemeData(color: FbColors.textPrimary),
        title: Text(
          S.of(context).chat,
          style: TextStyle(
              color: FbColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20),
        ),
      ),
      body: content,
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: FbColors.textSecondary),
            SizedBox(height: 16),
            Text(
              S.of(context).no_conversations_yet,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: FbColors.textPrimary),
            ),
            SizedBox(height: 6),
            Text(
              S.of(context).start_chatting_hint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: FbColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(int index, List data, ResultListProvider provider) {
    Map conversation = data[index] as Map;
    return _ConversationTile(conversation: conversation);
  }
}

class _ConversationTile extends StatelessWidget {
  final Map conversation;

  const _ConversationTile({Key key, this.conversation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List accountsJson = (conversation['accounts'] as List) ?? [];
    List<OwnerAccount> participants =
        accountsJson.map((e) => OwnerAccount.fromJson(e)).toList();
    Map lastStatusJson = conversation['last_status'] as Map;
    StatusItemData lastStatus =
        lastStatusJson != null ? StatusItemData.fromJson(lastStatusJson) : null;
    bool unread = conversation['unread'] == true;

    OwnerAccount avatarAccount =
        participants.isNotEmpty ? participants.first : null;
    String title = participants.isEmpty
        ? ''
        : participants.map((a) => StringUtil.displayName(a)).join(', ');

    String preview = '';
    if (lastStatus != null) {
      preview = (StringUtil.removeAllHtmlTags(lastStatus.content ?? '') ?? '')
          .trim();
      if (preview.isEmpty &&
          (lastStatus.mediaAttachments ?? []).isNotEmpty) {
        preview = S.of(context).media;
      }
      bool sentByMe = lastStatus.account?.id == LoginedUser().account?.id;
      if (sentByMe) {
        preview = '${S.of(context).you}: $preview';
      }
    }

    return InkWell(
      onTap: () {
        if (lastStatus == null || participants.isEmpty) return;
        if (unread) {
          Request.post(
              url: Api.conversationRead(conversation['id']),
              showDialog: false);
        }
        AppNavigate.push(ChatPage(
          conversationId: conversation['id'],
          participants: participants,
          lastStatus: lastStatus,
        ));
      },
      child: Container(
        color: FbColors.cardBackground,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Avatar(
              account: avatarAccount,
              width: 54,
              height: 54,
              navigateToDetail: false,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            unread ? FontWeight.w800 : FontWeight.w600,
                        color: FbColors.textPrimary),
                  ),
                  SizedBox(height: 3),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            unread ? FontWeight.w600 : FontWeight.normal,
                        color: unread
                            ? FbColors.textPrimary
                            : FbColors.textSecondary),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lastStatus != null
                      ? DateUntil.dateTime(lastStatus.createdAt, context)
                      : '',
                  style: TextStyle(fontSize: 12, color: FbColors.textSecondary),
                ),
                if (unread) ...[
                  SizedBox(height: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: FbColors.primaryBlue, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
