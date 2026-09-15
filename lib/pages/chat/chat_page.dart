import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:dudu/api/status_api.dart';
import 'package:dudu/constant/api.dart';
import 'package:dudu/constant/fb_colors.dart';
import 'package:dudu/l10n/l10n.dart';
import 'package:dudu/models/json_serializable/article_item.dart';
import 'package:dudu/models/json_serializable/owner_account.dart';
import 'package:dudu/models/logined_user.dart';
import 'package:dudu/public.dart';
import 'package:dudu/utils/cache_manager.dart';
import 'package:dudu/utils/date_until.dart';
import 'package:dudu/widget/other/avatar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart' as picker;

/// Tela de chat individual (estilo Messenger) de uma conversa (DM) do
/// Mastodon.
///
/// O Mastodon não tem endpoint de "thread de chat": uma conversa é uma
/// sequência de status com visibility=direct, encadeados por
/// in_reply_to_id. Por isso o histórico é reconstruído com
/// GET /api/v1/statuses/:id/context (ancestors + o próprio status +
/// descendants) a partir do último status da conversa, e cada mensagem
/// nova é enviada como POST /api/v1/statuses com visibility=direct,
/// mencionando os outros participantes e respondendo (in_reply_to_id) à
/// última mensagem do fio, pra continuar na mesma conversa.
class ChatPage extends StatefulWidget {
  final String conversationId;
  final List<OwnerAccount> participants;
  final StatusItemData lastStatus;

  const ChatPage({
    Key key,
    this.conversationId,
    this.participants,
    this.lastStatus,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<StatusItemData> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _uploadingMedia = false;
  File _attachedFile;

  OwnerAccount get _otherAccount =>
      (widget.participants != null && widget.participants.isNotEmpty)
          ? widget.participants.first
          : null;

  String get _chatTitle {
    if (widget.participants == null || widget.participants.isEmpty) return '';
    return widget.participants
        .map((a) => StringUtil.displayName(a))
        .join(', ');
  }

  @override
  void initState() {
    super.initState();
    _loadThread();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadThread() async {
    setState(() => _loading = true);
    List<StatusItemData> thread = [];
    try {
      var result = await StatusApi.getContext(data: widget.lastStatus);
      if (result != null) {
        (result['ancestors'] as List ?? [])
            .forEach((e) => thread.add(StatusItemData.fromJson(e)));
        thread.add(widget.lastStatus);
        (result['descendants'] as List ?? [])
            .forEach((e) => thread.add(StatusItemData.fromJson(e)));
      } else {
        thread.add(widget.lastStatus);
      }
      thread.sort((a, b) =>
          DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)));
    } catch (e) {
      thread = [widget.lastStatus];
    }
    if (!mounted) return;
    setState(() {
      _messages = thread;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  Future<void> _pickAttachment() async {
    final assets = await picker.AssetPicker.pickAssets(
      context,
      maxAssets: 1,
      themeColor: FbColors.primaryBlue,
      requestType: picker.RequestType.image,
    );
    if (assets == null || assets.isEmpty) return;
    File file = await assets.first.file;
    if (!mounted) return;
    setState(() => _attachedFile = file);
  }

  void _removeAttachment() {
    setState(() => _attachedFile = null);
  }

  Future<String> _uploadAttachment() async {
    if (_attachedFile == null) return null;
    setState(() => _uploadingMedia = true);
    try {
      String fileName = _attachedFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file':
            await MultipartFile.fromFile(_attachedFile.path, filename: fileName),
      });
      var response =
          await Request.requestDio(url: Api.attachMedia, params: formData);
      return response['id'] as String;
    } catch (e) {
      Fluttertoast.showToast(msg: S.of(context).file_upload_failed);
      return null;
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
    }
  }

  Future<void> _send() async {
    String text = _textController.text.trim();
    if (text.isEmpty && _attachedFile == null) return;
    if (widget.participants == null || widget.participants.isEmpty) return;

    setState(() => _sending = true);

    List<String> mediaIds = [];
    if (_attachedFile != null) {
      String mediaId = await _uploadAttachment();
      if (mediaId == null) {
        if (mounted) setState(() => _sending = false);
        return;
      }
      mediaIds.add(mediaId);
    }

    // O Mastodon não notifica ninguém numa mensagem "direct" a menos que a
    // pessoa seja mencionada no próprio texto -- por isso cada envio
    // precisa repetir o(s) @handle(s) dos participantes.
    String mentions = widget.participants.map((a) => '@${a.acct}').join(' ');
    String status = text.isNotEmpty ? '$mentions $text' : mentions;

    String lastId =
        _messages.isNotEmpty ? _messages.last.id : widget.lastStatus.id;

    Map<String, dynamic> params = {
      'status': status,
      'visibility': 'direct',
      'in_reply_to_id': lastId,
      'media_ids': mediaIds,
    };

    try {
      var data =
          await Request.post(url: Api.status, params: params, showDialog: false);
      if (data != null && data['id'] != null) {
        if (!mounted) return;
        setState(() {
          _messages.add(StatusItemData.fromJson(data));
          _textController.clear();
          _attachedFile = null;
          _sending = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      } else {
        throw Exception('empty response');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      Fluttertoast.showToast(msg: S.of(context).failed_to_send_toot);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FbColors.background,
      appBar: AppBar(
        backgroundColor: FbColors.cardBackground,
        elevation: 0.6,
        iconTheme: IconThemeData(color: FbColors.textPrimary),
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(
              account: _otherAccount,
              width: 34,
              height: 34,
              navigateToDetail: false,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                _chatTitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: FbColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_attachedFile != null) _buildAttachmentPreview(),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(FbColors.primaryBlue)));
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(S.of(context).no_conversations_yet,
            style: TextStyle(color: FbColors.textSecondary)),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        StatusItemData message = _messages[index];
        bool isMe = message.account?.id == LoginedUser().account?.id;
        return _MessageBubble(message: message, isMe: isMe);
      },
    );
  }

  Widget _buildAttachmentPreview() {
    return Container(
      color: FbColors.cardBackground,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      alignment: Alignment.centerLeft,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child:
                Image.file(_attachedFile, width: 72, height: 72, fit: BoxFit.cover),
          ),
          Positioned(
            right: -8,
            top: -8,
            child: InkWell(
              onTap: _removeAttachment,
              child: Container(
                width: 22,
                height: 22,
                decoration:
                    BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        color: FbColors.cardBackground,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.add_photo_alternate_outlined,
                  color: FbColors.primaryBlue),
              onPressed: _uploadingMedia ? null : _pickAttachment,
            ),
            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: 40, maxHeight: 120),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: FbColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: FbColors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    hintText: S.of(context).type_a_message,
                    hintStyle: TextStyle(color: FbColors.textSecondary),
                  ),
                ),
              ),
            ),
            SizedBox(width: 6),
            (_sending || _uploadingMedia)
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: Icon(Icons.send, color: FbColors.primaryBlue),
                    onPressed: _send,
                  ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final StatusItemData message;
  final bool isMe;

  const _MessageBubble({Key key, this.message, this.isMe}) : super(key: key);

  // Remove o(s) @handle(s) do início da mensagem: eles são obrigatórios
  // pra API notificar os participantes, mas não fazem sentido aparecer
  // repetidos em todo balão de um chat 1:1 (já sabemos quem está na
  // conversa pelo cabeçalho da tela).
  String _displayText() {
    String text = (StringUtil.removeAllHtmlTags(message.content ?? '') ?? '')
        .trim();
    List mentions = message.mentions ?? [];
    if (mentions.isEmpty) return text;
    String pattern = mentions
        .map((m) => RegExp.escape('@${m['acct']}'))
        .join('|');
    RegExp leading = RegExp('^(?:(?:$pattern)\\s*)+', caseSensitive: false);
    return text.replaceFirst(leading, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    String text = _displayText();
    List mediaAttachments = message.mediaAttachments ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Avatar(
              account: message.account,
              width: 26,
              height: 26,
              navigateToDetail: false,
            ),
            SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (mediaAttachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: mediaAttachments.first['preview_url'] ?? '',
                        cacheManager: CustomCacheManager(),
                        width: 180,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => SizedBox(),
                      ),
                    ),
                  ),
                if (text.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.72),
                    decoration: BoxDecoration(
                      color:
                          isMe ? FbColors.primaryBlue : FbColors.iconChipBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Colors.white : FbColors.textPrimary,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(
                    DateUntil.absoluteTime(message.createdAt),
                    style: TextStyle(fontSize: 11, color: FbColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
