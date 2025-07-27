import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final messages = <Map<String, dynamic>>[];
  String? attachedImageBase64;
  bool isLoading = false;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void showFullImage(String imageProvider, {bool isBase64 = false}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: Container(
          color: Colors.black,
          child: PhotoView(
            imageProvider: isBase64
                ? MemoryImage(base64Decode(imageProvider))
                : NetworkImage(imageProvider) as ImageProvider,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI ChatBot"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: messages.length,
              itemBuilder: (_, index) {
                final msg = messages[index];
                final isUser = msg['role'] == 'user';
                final hasImage = msg.containsKey('image');
                final hasImageUrl = msg.containsKey('imageUrl');

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isUser)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          child: Text("🤖", style: TextStyle(fontSize: 22)),
                        ),
                      ),
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: const BoxConstraints(maxWidth: 260),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Colors.blue[100]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft:
                            Radius.circular(isUser ? 16 : 4),
                            bottomRight:
                            Radius.circular(isUser ? 4 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasImage || hasImageUrl) ...[
                              GestureDetector(
                                onTap: () => showFullImage(
                                  hasImage
                                      ? msg['image']
                                      : msg['imageUrl'],
                                  isBase64: hasImage,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: hasImage
                                      ? Image.memory(
                                    base64Decode(msg['image']),
                                    width: 220,
                                    fit: BoxFit.cover,
                                  )
                                      : Image.network(
                                    msg['imageUrl'],
                                    width: 220,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(
                              msg['content'] ?? "",
                              style: const TextStyle(
                                  fontSize: 15, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isUser)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          child: Text("👤", style: TextStyle(fontSize: 22)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(30),
              child: Row(
                children: [
                  if (attachedImageBase64 != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              base64Decode(attachedImageBase64!),
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => attachedImageBase64 = null),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black54,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: TextFormField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: "Ask anything...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                          source: ImageSource.gallery);
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setState(
                                () => attachedImageBase64 = base64Encode(bytes));
                      }
                    },
                  ),
                  isLoading
                      ? const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                      : IconButton(
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).primaryColor,
                    onPressed: () async {
                      // --- ORIGINAL LOGIC UNCHANGED ---
                      final question = messageController.text.trim();
                      if (question.isEmpty &&
                          attachedImageBase64 == null) return;

                      final openAiKey = dotenv.env['OPENAI_API_KEY'];
                      final headers = {
                        "Content-Type": "application/json",
                        "Authorization": "Bearer $openAiKey"
                      };

                      setState(() => isLoading = true);

                      final lower = question.toLowerCase();
                      final isImagePrompt = lower.startsWith("generate") ||
                          lower.startsWith("create") ||
                          lower.contains("generate an image") ||
                          lower.contains("create an image");

                      if (isImagePrompt) {
                        messages.add({
                          "role": "user",
                          "content": question
                        });
                        try {
                          final resp = await http.post(
                            Uri.parse(
                                "https://api.openai.com/v1/images/generations"),
                            headers: headers,
                            body: jsonEncode({
                              "prompt": question,
                              "n": 1,
                              "size": "512x512"
                            }),
                          );
                          final imageUrl =
                          jsonDecode(resp.body)['data'][0]['url'];
                          setState(() {
                            messages.add({
                              "role": "assistant",
                              "content": "Here is the image you requested:",
                              "imageUrl": imageUrl
                            });
                          });
                        } catch (e) {
                          debugPrint("DALL·E Error: $e");
                        }
                      } else if (attachedImageBase64 != null) {
                        messages.add({
                          "role": "user",
                          "content": question.isEmpty ? "[Image]" : question,
                          "image": attachedImageBase64
                        });

                        final body = jsonEncode({
                          "model": "gpt-4o",
                          "messages": [
                            {
                              "role": "user",
                              "content": [
                                {
                                  "type": "text",
                                  "text": question.isEmpty
                                      ? "Describe this image"
                                      : question
                                },
                                {
                                  "type": "image_url",
                                  "image_url": {
                                    "url":
                                    "data:image/jpeg;base64,$attachedImageBase64"
                                  }
                                }
                              ]
                            }
                          ]
                        });

                        try {
                          final resp = await http.post(
                            Uri.parse(
                                "https://api.openai.com/v1/chat/completions"),
                            headers: headers,
                            body: body,
                          );
                          final answer = jsonDecode(resp.body)['choices'][0]
                          ['message']['content'];
                          setState(() {
                            messages.add({
                              "role": "assistant",
                              "content": answer
                            });
                            attachedImageBase64 = null;
                          });
                        } catch (err) {
                          debugPrint("Image+Text error: $err");
                        }
                      } else {
                        messages.add(
                            {"role": "user", "content": question});

                        final body = jsonEncode({
                          "model": "gpt-4o",
                          "messages": messages
                              .map((msg) => {
                            "role": msg['role'],
                            "content": msg['content']
                          })
                              .toList()
                        });

                        try {
                          final resp = await http.post(
                            Uri.parse(
                                "https://api.openai.com/v1/chat/completions"),
                            headers: headers,
                            body: body,
                          );
                          final answer = jsonDecode(resp.body)['choices'][0]
                          ['message']['content'];
                          setState(() {
                            messages.add({
                              "role": "assistant",
                              "content": answer
                            });
                          });
                        } catch (err) {
                          debugPrint("Text error: $err");
                        }
                      }

                      messageController.clear();
                      setState(() => isLoading = false);
                      scrollToBottom();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}