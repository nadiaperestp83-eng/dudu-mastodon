import 'package:dudu/l10n/l10n.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dudu/models/json_serializable/media_attachment.dart';
import 'package:dudu/utils/dialog_util.dart';
import 'package:dudu/utils/media_util.dart';
import 'package:dudu/utils/url_util.dart';
import 'package:dudu/widget/common/media_detail.dart';
import 'package:flutter/material.dart';

class VideoPlay extends StatefulWidget {
  final MediaAttachment media;
  VideoPlay(this.media);

  @override
  _VideoPlayState createState() => _VideoPlayState();
}

class _VideoPlayState extends State<VideoPlay> {
  Future<void> _openExternally() async {
    try {
      await UrlUtil.openUrl(widget.media.url);
    } catch (e) {
      DialogUtils.toastErrorInfo(S.of(context).something_went_wrong);
    }
  }

  @override
  void initState() {
    super.initState();
    // Abre direto no player externo (navegador/player do sistema),
    // já que o player interno (cached_video_player) foi desativado.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openExternally());
  }

  @override
  Widget build(BuildContext context) {
    return MediaDetail(
      child: GestureDetector(
        onTap: _openExternally,
        child: Container(
          color: Colors.black,
          child: Hero(
            tag: widget.media.id,
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: <Widget>[
                if (widget.media.previewUrl != null)
                  CachedNetworkImage(
                    imageUrl: widget.media.previewUrl,
                    fit: BoxFit.contain,
                  ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black45,
                  ),
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 44),
                ),
              ],
            ),
          ),
        ),
      ),
      title: "1/1",
      onDownloadClick: () async => await MediaUtil.downloadMedia(widget.media),
      onShareClick: () async {
        await MediaUtil.shareMedia(widget.media);
      },
    );
  }
}
