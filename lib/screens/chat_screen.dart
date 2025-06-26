// File: screens/chat_screen.dart

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/gpt_service.dart';
import '../services/upload_service.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool isSubscriber = false;
  int userTokens = 0;
  bool isSidebarOpen = true;

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _renameController = TextEditingController();
  String userId = '';
  String? activeSessionId;
  Map<String, String> sessionNames = {};
  List<PlatformFile> pendingUploads = [];

  @override
  void initState() {
    super.initState();
    userId = AuthService.getCurrentUserId();
    _checkSubscription();
  }

  void _checkSubscription() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final data = doc.data() ?? {};
    final role = data['role'] ?? 'free';
    final tokens = data.containsKey('tokens') ? data['tokens'] : 999;
    if (!data.containsKey('tokens')) {
      await doc.reference.update({'tokens': tokens});
    }
    setState(() {
      isSubscriber = role == 'subscriber';
      userTokens = tokens;
    });
  }

  String _formatReadableTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final nowDate = DateTime(now.year, now.month, now.day);
    final isToday = date == nowDate;
    final isYesterday = date == nowDate.subtract(Duration(days: 1));
    final timeString = TimeOfDay.fromDateTime(timestamp).format(context);
    if (isToday) return 'Today at $timeString';
    if (isYesterday) return 'Yesterday at $timeString';
    return '${timestamp.month}/${timestamp.day}/${timestamp.year} at $timeString';
  }

  void _startNewSession() async {
    final sessionId = await FirestoreService.createNewSession(userId);
    setState(() => activeSessionId = sessionId);
    _controller.addListener(() async {
      final firstPrompt = _controller.text.trim();
      if (firstPrompt.isNotEmpty && activeSessionId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('sessions')
            .doc(activeSessionId)
            .get();
        final hasName = (doc.data()?['name'] ?? '').toString().isNotEmpty;
        if (!hasName) {
          await doc.reference.update({
            'name': firstPrompt.substring(
              0,
              firstPrompt.length > 30 ? 30 : firstPrompt.length,
            ),
          });
        }
        _controller.removeListener(() {});
      }
    });
  }

  void _renameSession(String sessionId, String newName) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .doc(sessionId)
        .update({'name': newName});
    setState(() => sessionNames[sessionId] = newName);
  }

  void _deleteSession(String sessionId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .doc(sessionId)
        .delete();
    if (activeSessionId == sessionId) setState(() => activeSessionId = null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Session deleted')));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() => pendingUploads.addAll(result.files));
    }
  }

  void _sendMessage() async {
    final prompt = _controller.text.trim();
    if ((prompt.isEmpty && pendingUploads.isEmpty) || activeSessionId == null)
      return;

    if (!isSubscriber && userTokens <= 0) {
      _showTokenDialog();
      return;
    }

    List<String> attachmentUrls = [];
    for (final file in pendingUploads) {
      final url = await UploadService.uploadFile(file: file, userId: userId);
      if (url != null) attachmentUrls.add(url);
    }

    _controller.clear();
    setState(() => pendingUploads.clear());

    await GPTService.sendToLancasterMode(
      prompt +
          (attachmentUrls.isNotEmpty
              ? '\n\nAttachments:\n${attachmentUrls.join('\n')}'
              : ''),
      userId,
      activeSessionId!,
    );

    if (!isSubscriber) {
      setState(() => userTokens -= 1);
      FirebaseFirestore.instance.collection('users').doc(userId).update({
        'tokens': userTokens,
      });
    }
  }

  void _showTokenDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Out of Tokens'),
        content: Text('Subscribe to continue using Lancaster Mode.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: isSidebarOpen ? 300 : 70,
      color: Colors.grey[900],
      child: Column(
        children: [
          if (isSidebarOpen)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text("Sessions", style: TextStyle(fontSize: 18)),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.arrow_left),
                    onPressed: () => setState(() => isSidebarOpen = false),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  tooltip: 'Expand',
                  onPressed: () => setState(() => isSidebarOpen = true),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  tooltip: 'New Chat',
                  onPressed: _startNewSession,
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  tooltip: 'Search',
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.folder),
                  tooltip: 'Library',
                  onPressed: () {},
                ),
              ],
            ),
          if (isSidebarOpen)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirestoreService.getSessions(userId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Container();
                  final sessions = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (_, i) {
                      final session = sessions[i];
                      final sid = session.id;
                      final name =
                          session['name'] ?? 'Session ${sid.substring(0, 6)}';
                      final timestamp = session['created_at'] != null
                          ? _formatReadableTimestamp(
                              (session['created_at'] as Timestamp).toDate(),
                            )
                          : '';
                      return ListTile(
                        title: Text(
                          name,
                          style: TextStyle(color: Colors.white70),
                        ),
                        subtitle: timestamp.isNotEmpty
                            ? Text(
                                timestamp,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              )
                            : null,
                        selected: sid == activeSessionId,
                        onTap: () => setState(() => activeSessionId = sid),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 18),
                          onSelected: (value) {
                            if (value == 'rename') {
                              _renameController.text = name;
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text('Rename Session'),
                                  content: TextField(
                                    controller: _renameController,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        final newName = _renameController.text
                                            .trim();
                                        if (newName.isNotEmpty)
                                          _renameSession(sid, newName);
                                        Navigator.pop(context);
                                      },
                                      child: Text('Rename'),
                                    ),
                                  ],
                                ),
                              );
                            } else if (value == 'delete') {
                              _deleteSession(sid);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'rename',
                              child: Text('Rename'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Column(
      children: [
        Expanded(
          child: activeSessionId == null
              ? Center(child: Text("Select or start a session"))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirestoreService.getMessageStream(
                    userId,
                    activeSessionId!,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    return ListView(
                      reverse: true,
                      children: docs.map((doc) {
                        return ChatBubble(
                          userText: doc['prompt'],
                          gptText: doc['response'],
                          userId: userId,
                        );
                      }).toList(),
                    );
                  },
                ),
        ),
        if (pendingUploads.isNotEmpty)
          Container(
            height: 80,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: pendingUploads.length,
              itemBuilder: (_, i) {
                final file = pendingUploads[i];
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      margin: EdgeInsets.all(6),
                      padding: EdgeInsets.all(8),
                      width: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.insert_drive_file, size: 24),
                          Text(
                            file.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => pendingUploads.removeAt(i)),
                      child: Icon(Icons.close, size: 16),
                    ),
                  ],
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(icon: Icon(Icons.attach_file), onPressed: _pickFile),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(hintText: 'Enter your message'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: (isSubscriber || userTokens > 0)
                    ? _sendMessage
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lancaster Mode Chat'),
        actions: [
          if (!isSidebarOpen)
            IconButton(
              icon: Icon(Icons.arrow_right),
              tooltip: 'Expand Menu',
              onPressed: () => setState(() => isSidebarOpen = true),
            ),
          if (!isSubscriber)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('Tokens: $userTokens')),
            ),
        ],
      ),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildChatArea()),
        ],
      ),
    );
  }
}
