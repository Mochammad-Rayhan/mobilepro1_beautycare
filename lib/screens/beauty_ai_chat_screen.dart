import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart'
    hide ChatSession;
import 'package:google_generative_ai/google_generative_ai.dart'
    as ai
    show ChatSession;
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../database/db_helper.dart';
import '../utils/env.dart';
import '../theme/app_colors.dart';

class BeautyAIChatScreen extends StatefulWidget {
  final User user;
  final String? initialMessage;
  final int? sessionId;

  const BeautyAIChatScreen({
    Key? key,
    required this.user,
    this.initialMessage,
    this.sessionId,
  }) : super(key: key);

  @override
  State<BeautyAIChatScreen> createState() => _BeautyAIChatScreenState();
}

class _BeautyAIChatScreenState extends State<BeautyAIChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  int? _currentSessionId;

  bool _isLoading = false;
  File? _selectedImage;

  late final GenerativeModel _model;
  late ai.ChatSession _chatSessionAI;

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _initAI();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _textController.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.sessionId != null) {
      _loadSessionChats(widget.sessionId!);
    } else {
      _createNewSession();
      if (widget.initialMessage != null) {
        _textController.text = widget.initialMessage!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _sendMessage();
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _initAI() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: Env.geminiApiKey,
      systemInstruction: Content.system(
        "Kamu adalah Pakar Kecantikan dan Dokter Kulit Profesional bernama BeautyAI. "
        "Gunakan bahasa yang ramah, empati, dan profesional. "
        "Berikan solusi, saran produk, atau penanganan medis dasar terkait permasalahan kulit, rambut, dan tubuh.",
      ),
    );
  }

  Future<void> _loadSessionChats(int sessionId) async {
    final dbHelper = DBHelper();
    final chatsMap = await dbHelper.getChatsBySession(sessionId);

    List<Content> historyContents = [];

    setState(() {
      _currentSessionId = sessionId;
      _messages.clear();
      for (var chatMap in chatsMap) {
        final chat = ChatMessage.fromMap(chatMap);
        _messages.add(chat);

        if (chat.isUser) {
          historyContents.add(Content.text(chat.message));
        } else {
          historyContents.add(Content.model([TextPart(chat.message)]));
        }
      }
    });

    _chatSessionAI = _model.startChat(history: historyContents);
    _scrollToBottom();
  }

  void _createNewSession() {
    setState(() {
      _currentSessionId = null;
      _messages.clear();
      _chatSessionAI = _model.startChat();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    final imageToSend = _selectedImage;
    _textController.clear();
    setState(() {
      _selectedImage = null;
      _isLoading = true;
    });

    final dbHelper = DBHelper();

    // Create session if it doesn't exist
    if (_currentSessionId == null) {
      String title = text.isNotEmpty
          ? (text.length > 20 ? '${text.substring(0, 20)}...' : text)
          : 'Konsultasi Foto';

      final newSession = ChatSession(
        userId: widget.user.id!,
        title: title,
        timestamp: DateTime.now(),
      );
      _currentSessionId = await dbHelper.createChatSession(newSession.toMap());
    }

    // Save User Message
    final userMessage = ChatMessage(
      sessionId: _currentSessionId!,
      userId: widget.user.id!,
      message: text,
      isUser: true,
      imagePath: imageToSend?.path,
      timestamp: DateTime.now(),
    );

    final insertedId = await dbHelper.insertChat(userMessage.toMap());
    final savedUserMessage = ChatMessage(
      id: insertedId,
      sessionId: userMessage.sessionId,
      userId: userMessage.userId,
      message: userMessage.message,
      isUser: userMessage.isUser,
      imagePath: userMessage.imagePath,
      timestamp: userMessage.timestamp,
    );

    setState(() {
      _messages.add(savedUserMessage);
    });
    _scrollToBottom();

    try {
      GenerateContentResponse response;

      if (imageToSend != null) {
        final imageBytes = await imageToSend.readAsBytes();
        final prompt = TextPart(
          text.isEmpty ? "Tolong analisis kulit saya pada foto ini." : text,
        );
        final imagePart = DataPart('image/jpeg', imageBytes);

        response = await _chatSessionAI.sendMessage(
          Content.multi([prompt, imagePart]),
        );
      } else {
        response = await _chatSessionAI.sendMessage(Content.text(text));
      }

      final aiText =
          response.text ??
          "Maaf, saya tidak bisa memproses permintaan tersebut saat ini.";

      // Save AI Message
      final aiMessage = ChatMessage(
        sessionId: _currentSessionId!,
        userId: widget.user.id!,
        message: aiText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      final aiInsertedId = await dbHelper.insertChat(aiMessage.toMap());
      final savedAiMessage = ChatMessage(
        id: aiInsertedId,
        sessionId: aiMessage.sessionId,
        userId: aiMessage.userId,
        message: aiMessage.message,
        isUser: aiMessage.isUser,
        timestamp: aiMessage.timestamp,
      );

      setState(() {
        _messages.add(savedAiMessage);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inputFill,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : _buildMessageList(),
            ),
            if (_isLoading) _buildTypingIndicator(),
            if (_selectedImage != null) _buildImagePreview(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'BeautyAI',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        // Animate messages in
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _buildMessageBubble(msg),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.12),
                    AppColors.primary.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Mulai Konsultasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ceritakan masalah kulitmu atau unggah foto untuk mendapatkan rekomendasi terbaik.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12, right: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, const Color(0xFFE27F99)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Sedang mengetik...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, right: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
                image: DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: () => setState(() => _selectedImage = null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFE27F99)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [AppColors.primary, Color(0xFFE27F99)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : AppColors.surface,
                border: isMe
                    ? null
                    : Border.all(color: AppColors.border.withOpacity(0.5)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.black.withOpacity(0.03),
                    blurRadius: isMe ? 12 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.imagePath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(msg.imagePath!),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (msg.message.isNotEmpty)
                    isMe
                        ? Text(
                            msg.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          )
                        : MarkdownBody(
                            data: msg.message,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                height: 1.5,
                              ),
                              listBullet: const TextStyle(
                                color: AppColors.primary,
                              ),
                              strong: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      DateFormat('HH:mm').format(msg.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white.withOpacity(0.7)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final isFocused = _focusNode.hasFocus;
    final hasText = _textController.text.trim().isNotEmpty;
    final hasImage = _selectedImage != null;
    final canSend = (hasText || hasImage) && !_isLoading;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused
                  ? AppColors.primary.withOpacity(0.5)
                  : AppColors.border.withOpacity(0.4),
              width: isFocused ? 1.5 : 1.0,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Photo button
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: IconButton(
                  icon: const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  onPressed: _isLoading ? null : _pickImage,
                  splashRadius: 20,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),

              // Text field
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (canSend) _sendMessage();
                  },
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tanya BeautyAI...',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                  ),
                  maxLines: 5,
                  minLines: 1,
                ),
              ),

              // Send button
              Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    gradient: canSend
                        ? const LinearGradient(
                            colors: [AppColors.primary, Color(0xFFE27F99)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: canSend ? null : AppColors.border.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: canSend
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: canSend ? _sendMessage : null,
                      child: Center(
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: canSend
                              ? Colors.white
                              : AppColors.textSecondary.withOpacity(0.5),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
