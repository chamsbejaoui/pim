import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../user_management/api/user_management_api.dart';
import '../../user_management/models/user_management_models.dart';
import '../communication_theme.dart';
import '../models/communication_models.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.api,
    required this.session,
    required this.conversationId,
    required this.title,
  });

  final UserManagementApi api;
  final SessionModel session;
  final String conversationId;
  final String title;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessageModel> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  StreamSubscription<Map<String, dynamic>>? _chatSub;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final messages = await widget.api.getMessages(
        widget.session.token,
        widget.conversationId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = messages;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _subscribeRealtime() {
    _chatSub?.cancel();
    _chatSub = widget.api
        .subscribeSse(token: widget.session.token, path: '/chat/stream')
        .listen((event) {
          final eventType = (event['eventType'] ?? '').toString();
          if (eventType == 'heartbeat') {
            return;
          }

          final payload = event['payload'];
          if (payload is! Map<String, dynamic>) {
            return;
          }

          final conversationId = (payload['conversationId'] ?? '').toString();
          if (conversationId == widget.conversationId) {
            _loadMessages();
          }
        });
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }

    setState(() => _sending = true);
    try {
      await widget.api.sendChatMessage(
        token: widget.session.token,
        conversationId: widget.conversationId,
        text: text,
      );
      _textController.clear();
      await _loadMessages();
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _sendAttachment() async {
    if (_sending) {
      return;
    }

    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file == null) {
        return;
      }

      setState(() => _sending = true);
      final bytes = await file.readAsBytes();
      final uploaded = await widget.api.uploadDocument(
        token: widget.session.token,
        bytes: bytes,
        filename: file.name,
      );

      await widget.api.sendChatMessage(
        token: widget.session.token,
        conversationId: widget.conversationId,
        file: uploaded,
      );

      await _loadMessages();
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _openDeleteOptions(ChatMessageModel message) async {
    final canDeleteEveryone =
        message.senderId == widget.session.userId ||
        widget.session.role == 'CLUB_RESPONSABLE';

    final scope = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: CommunicationPalette.card(context),
      builder: (context) {
        final textColor = CommunicationPalette.textPrimary(context);

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(
                  'Delete for me',
                  style: TextStyle(color: textColor),
                ),
                onTap: () => Navigator.pop(context, 'me'),
              ),
              if (canDeleteEveryone)
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined),
                  title: Text(
                    'Delete for everyone',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () => Navigator.pop(context, 'everyone'),
                ),
            ],
          ),
        );
      },
    );

    if (scope == null) {
      return;
    }

    try {
      await widget.api.deleteChatMessage(
        token: widget.session.token,
        messageId: message.id,
        scope: scope,
      );
      await _loadMessages();
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _showError(String raw) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(raw.replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fg = CommunicationPalette.textPrimary(context);
    final muted = CommunicationPalette.textMuted(context);
    final card = CommunicationPalette.card(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            Text(
              'Club internal chat',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Container(
        decoration: CommunicationPalette.backgroundDecoration(),
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? _MessagesSkeleton(card: card)
                  : _error != null
                  ? Center(
                      child: Text(_error!, style: TextStyle(color: muted)),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMessages,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final mine =
                              message.senderId == widget.session.userId;

                          return GestureDetector(
                            onLongPress: () => _openDeleteOptions(message),
                            child: Align(
                              alignment: mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                constraints: const BoxConstraints(
                                  maxWidth: 290,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? CommunicationPalette.primary
                                      : card,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (message.file != null) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.attach_file_rounded,
                                            size: 18,
                                            color: mine
                                                ? Colors.white
                                                : CommunicationPalette
                                                      .secondary,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              message.file!.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: mine ? Colors.white : fg,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                    if ((message.text ?? '').isNotEmpty)
                                      Text(
                                        message.text!,
                                        style: TextStyle(
                                          color: mine ? Colors.white : fg,
                                        ),
                                      ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _timeLabel(message.createdAt),
                                      style: TextStyle(
                                        color: mine
                                            ? Colors.white.withValues(
                                                alpha: 0.84,
                                              )
                                            : muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                color: card,
                border: Border(
                  top: BorderSide(color: muted.withValues(alpha: 0.2)),
                ),
              ),
              padding: EdgeInsets.only(
                left: 8,
                right: 8,
                top: 10,
                bottom: MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom
                    : 12,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sending ? null : _sendAttachment,
                    icon: const Icon(Icons.attach_file_rounded),
                    color: CommunicationPalette.secondary,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      style: TextStyle(color: fg),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: muted),
                        filled: true,
                        fillColor: CommunicationPalette.scaffold(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _sendText,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    color: CommunicationPalette.secondary,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.mic_none_rounded),
                    color: muted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime dateTime) {
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _MessagesSkeleton extends StatelessWidget {
  const _MessagesSkeleton({required this.card});

  final Color card;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      padding: const EdgeInsets.all(14),
      itemBuilder: (context, index) {
        final mine = index.isEven;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 220,
            height: 52,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: card.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
    );
  }
}
