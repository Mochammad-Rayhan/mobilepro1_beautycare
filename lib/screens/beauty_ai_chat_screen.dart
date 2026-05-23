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

  const BeautyAIChatScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<BeautyAIChatScreen> createState() => _BeautyAIChatScreenState();
}

class _BeautyAIChatScreenState extends State<BeautyAIChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  List<ChatSession> _sessions = [];
  int? _currentSessionId;

  bool _isLoading = false;
  File? _selectedImage;

  late final GenerativeModel _model;
  late ai.ChatSession _chatSessionAI; // To hold generative AI session

  @override
  void initState() {
    super.initState();
    _initAI();
    _loadSessions();
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
    _chatSessionAI = _model.startChat();
  }

  Future<void> _loadSessions() async {
    final dbHelper = DBHelper();
    final sessionsMap = await dbHelper.getChatSessions(widget.user.id!);

    setState(() {
      _sessions = sessionsMap.map((map) => ChatSession.fromMap(map)).toList();
    });

    if (_sessions.isNotEmpty && _currentSessionId == null) {
      // Auto load the most recent session if none selected
      _loadSessionChats(_sessions.first.id!);
    } else if (_sessions.isEmpty) {
      _createNewSession();
    }
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

        // Rebuild AI chat history
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

  Future<void> _deleteSession(int sessionId) async {
    final dbHelper = DBHelper();
    await dbHelper.deleteChatSession(sessionId);
    if (_currentSessionId == sessionId) {
      _createNewSession();
    }
    _loadSessions();
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
      _loadSessions(); // Refresh sidebar
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'BeautyAI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        centerTitle: true,
      ),
      drawer: _buildSidebar(),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && !_isLoading
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      top: 20,
                      bottom: 20,
                      left: 16,
                      right: 16,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),
          if (_isLoading) _buildTypingIndicator(),
          if (_selectedImage != null) _buildImagePreview(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFFE27F99)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              widget.user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(widget.user.email),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppColors.primary, size: 40),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close drawer
                _createNewSession();
              },
              icon: const Icon(Icons.add),
              label: const Text('Konsultasi Baru'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Riwayat Konsultasi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: _sessions.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada riwayat',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      final isSelected = session.id == _currentSessionId;
                      return ListTile(
                        leading: Icon(
                          Icons.chat_bubble_outline,
                          color: isSelected ? AppColors.primary : Colors.grey,
                        ),
                        title: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('dd MMM, HH:mm').format(session.timestamp),
                          style: const TextStyle(fontSize: 10),
                        ),
                        selected: isSelected,
                        selectedTileColor: AppColors.primary.withOpacity(0.05),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteSession(session.id!),
                        ),
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          if (!isSelected) {
                            _loadSessionChats(session.id!);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Halo, saya BeautyAI! 👋',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Ceritakan masalah kulitmu atau unggah foto untuk mendapatkan rekomendasi penanganan terbaik.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'AI sedang mengetik...',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
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
          alignment: Alignment.topRight,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
                image: DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImage = null;
                });
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
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
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [AppColors.primary, Color(0xFFE27F99)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : Colors.white,
                boxShadow: isMe
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.imagePath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
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
                              height: 1.3,
                            ),
                          )
                        : MarkdownBody(
                            data: msg.message,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                height: 1.5,
                              ),
                              listBullet: const TextStyle(
                                color: AppColors.primary,
                              ),
                              strong: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(msg.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe)
            const SizedBox(width: 24), // Offset to not touch the very edge
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.primary,
                ),
                onPressed: _isLoading ? null : _pickImage,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _textController,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Tanya masalah kulit...',
                    hintStyle: TextStyle(color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  maxLines: 5,
                  minLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFE27F99)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
