import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:permission_handler/permission_handler.dart';

import 'bubble.dart';
import 'main.dart';
import 'message.dart';
import 'package:record/record.dart';

enum ConnectionStatus { connecting, connected, disconnected }

enum ResponseMode { text, audio }

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatPage> {
  late final GoogleGenAI _genAI;
  LiveSession? _session;
  final TextEditingController _textController = TextEditingController();

  // 상태 관리 변수
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  bool _isReplying = false;
  final List<ChatMessage> _messages = [];
  ChatMessage? _streamingMessage; // 스트리밍 중인 메시지를 별도로 관리
  String _statusText = "연결을 초기화합니다...";

  // 이미지 및 오디오 관련 변수
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  StreamSubscription<RecordState>? _recordSub;
  bool _isRecording = false;

  // --- 오디오 및 모드 관리 ---
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<List<int>>? _audioStreamSubscription;
  ResponseMode _responseMode = ResponseMode.text; // 기본 응답 모드
  final StringBuffer _audioBuffer = StringBuffer();

  Future<void> _initialize() async {
    await _connectToLiveAPI();
  }

  @override
  void initState() {
    super.initState();
    _genAI = GoogleGenAI(apiKey: geminiApiKey);
    _initialize();
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      if (mounted) {
        setState(() => _isRecording = recordState == RecordState.record);
      }
    });
  }

  @override
  void dispose() {
    _session?.close();
    _audioStreamSubscription?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _updateStatus(String text) {
    if (mounted) setState(() => _statusText = text);
  }

  // --- 연결 관리 ---
  Future<void> _connectToLiveAPI() async {
    if (_connectionStatus == ConnectionStatus.connecting) return;

    // 이전 세션이 있다면 안전하게 종료
    await _session?.close();
    setState(() {
      _session = null;
      _connectionStatus = ConnectionStatus.connecting;
      _messages.clear();
      _addMessage(
        ChatMessage(
          text: "Gemini Live API에 연결 중 (${_responseMode.name} 모드)...",
          author: Role.model,
        ),
      );
      _updateStatus("Gemini Live API에 연결 중...");
    });

    try {
      final session = await _genAI.live.connect(
        LiveConnectParameters(
          model: 'gemini-2.0-flash-live-001',
          config: GenerationConfig(
            responseModalities: _responseMode == ResponseMode.audio
                ? [Modality.AUDIO]
                : [Modality.TEXT],
          ),
          systemInstruction: Content(
            parts: [
              Part(
                text: "You are a helpful AI assistant. "
                    "Your goal is to provide comprehensive, detailed, and well-structured answers. Always explain the background, key concepts, and provide illustrative examples. Do not give short or brief answers."
                    "**You must respond in the same language that the user uses for their question.** For example, if the user asks a question in Korean, you must reply in Korean. "
                    "If they ask in Japanese, reply in Japanese.",
              ),
            ],
          ),
          callbacks: LiveCallbacks(
            // onOpen: () => print('✅ WebSocket 연결 성공'),
            onOpen: () => _updateStatus("연결 성공! 마이크와 비디오를 켜보세요."),
            onMessage: _handleLiveAPIResponse,
            onError: (error, stack) {
              print('🚨 에러 발생: $error');
              if (mounted) {
                setState(
                  () => _connectionStatus = ConnectionStatus.disconnected,
                );
              }
            },
            onClose: (code, reason) {
              print('🚪 연결 종료: $code, $reason');
              if (mounted) {
                setState(
                  () => _connectionStatus = ConnectionStatus.disconnected,
                );
              }
            },
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _session = session;
          _connectionStatus = ConnectionStatus.connected;
          _messages.removeLast(); // "연결 중..." 메시지 제거
          _addMessage(
            ChatMessage(text: "안녕하세요! 마이크 버튼을 눌러 말씀해보세요.", author: Role.model),
          );
        });
      }
    } catch (e) {
      print("연결 실패: $e");
      if (mounted) {
        setState(() => _connectionStatus = ConnectionStatus.disconnected);
      }
    }
  }

  // --- 메시지 처리 ---
  void _handleLiveAPIResponse(LiveServerMessage message) {
    if (!mounted) return;

    final textChunk = message.text;
    print('📥 Received message textchunk: ${textChunk}');
    if (textChunk != null) {
      setState(() {
        if (_streamingMessage == null) {
          _streamingMessage = ChatMessage(text: textChunk, author: Role.model);
        } else {
          _streamingMessage = ChatMessage(
            text: _streamingMessage!.text + textChunk,
            author: Role.model,
          );
        }
      });
    }

    if (message.serverContent?.turnComplete ?? false) {
      setState(() {
        if (_streamingMessage != null) {
          _messages.add(_streamingMessage!);
          _streamingMessage = null;
        }
        _isReplying = false;
      });
    }
  }

  void _addMessage(ChatMessage message) {
    if (!mounted) return;
    setState(() {
      _messages.add(message);
    });
  }

  // --- 멀티모달 입력 및 전송 ---
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  // *** _toggleRecording 함수 수정 ***
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // --- 녹음 중지 로직 ---
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false); // UI 즉시 업데이트

      if (path != null) {
        print("녹음 중지. 파일 경로: $path");

        // 1. 녹음된 파일을 바이트로 읽기
        final file = File(path);
        final audioBytes = await file.readAsBytes();

        // 2. 오디오 파일을 UI에 메시지로 표시
        // 텍스트는 비워두고, 이미지 표시 로직처럼 오디오 아이콘을 표시할 수 있습니다.
        // 여기서는 간단하게 텍스트로 표현합니다.
        _addMessage(ChatMessage(text: "[사용자 음성 전송됨]", author: Role.user));

        // 3. 서버로 오디오 데이터 전송
        if (_session != null) {
          setState(() => _isReplying = true);

          _session!.sendMessage(
            LiveClientMessage(
              clientContent: LiveClientContent(
                turns: [
                  Content(
                    role: "user",
                    parts: [
                      Part(
                        inlineData: Blob(
                          // Gemini API는 다양한 오디오 포맷을 지원합니다.
                          // record 패키지의 기본 인코더에 맞춰 MIME 타입을 설정합니다.
                          // 예: aacLc, pcm16bits, flac, opus, amrNb, amrWb
                          mimeType: 'audio/wav', // RecordConfig에 따라 변경 필요
                          data: base64Encode(audioBytes),
                        ),
                      ),
                    ],
                  ),
                ],
                turnComplete: true,
              ),
            ),
          );
        }

        // 4. 임시 파일 삭제
        await file.delete();
      }
    } else {
      // --- 녹음 시작 로직 ---
      if (await Permission.microphone.request().isGranted) {
        final tempDir = await getTemporaryDirectory();
        final filePath =
            '${tempDir.path}/temp_audio.m4a'; // 확장자를 .m4a (AAC) 등으로 변경

        // MIME 타입과 일치하는 인코더 사용 (예: AAC)
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );
      } else {
        print("마이크 권한이 거부되었습니다.");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("마이크 권한이 필요합니다.")));
        }
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text;
    if ((text.isEmpty && _pickedImage == null) ||
        _isReplying ||
        _session == null)
      return;

    // 사용자 메시지를 UI에 먼저 추가
    _addMessage(
      ChatMessage(text: text, author: Role.user, image: _pickedImage),
    );

    setState(() => _isReplying = true);

    final List<Part> parts = [];
    if (text.isNotEmpty) {
      parts.add(Part(text: text));
    }
    if (_pickedImage != null) {
      final imageBytes = await _pickedImage!.readAsBytes();
      parts.add(
        Part(
          inlineData: Blob(
            mimeType: 'image/jpeg',
            data: base64Encode(imageBytes),
          ),
        ),
      );
    }

    _session!.sendMessage(
      LiveClientMessage(
        clientContent: LiveClientContent(
          turns: [Content(role: "user", parts: parts)],
          turnComplete: true,
        ),
      ),
    );

    _textController.clear();
    setState(() => _pickedImage = null);
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          if (_pickedImage != null)
            Container(
              height: 100,
              padding: const EdgeInsets.only(bottom: 8),
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_pickedImage!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.white70,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                        onPressed: () => setState(() => _pickedImage = null),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image_outlined),
                onPressed: _pickImage,
              ),
              IconButton(
                icon: Icon(
                  _isRecording
                      ? Icons.stop_circle_outlined
                      : Icons.mic_none_outlined,
                ),
                color: _isRecording
                    ? Colors.red
                    : Theme.of(context).iconTheme.color,
                onPressed: _toggleRecording,
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration.collapsed(
                    hintText: '메시지 또는 이미지 설명 입력',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: _toggleRecording,
            backgroundColor: _isRecording
                ? Colors.red.shade400
                : Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: _isRecording
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSecondaryContainer,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // --- UI 위젯 빌더 ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Live API'),
        actions: [
          // *** 추가: 응답 모드 선택 메뉴 ***
          PopupMenuButton<ResponseMode>(
            onSelected: (ResponseMode mode) {
              if (mode != _responseMode) {
                setState(() => _responseMode = mode);
                // 모드가 변경되면 재연결
                _connectToLiveAPI();
              }
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<ResponseMode>>[
                  const PopupMenuItem<ResponseMode>(
                    value: ResponseMode.text,
                    child: Text('텍스트 응답'),
                  ),
                ],
            icon: Icon(
              _responseMode == ResponseMode.text
                  ? Icons.text_fields
                  : Icons.graphic_eq,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.circle,
              color: _connectionStatus == ConnectionStatus.connected
                  ? Colors.green
                  : _connectionStatus == ConnectionStatus.connecting
                  ? Colors.orange
                  : Colors.red,
              size: 16,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                reverse: true,
                itemCount:
                    _messages.length + (_streamingMessage == null ? 0 : 1),
                itemBuilder: (context, index) {
                  if (_streamingMessage != null && index == 0) {
                    return Bubble(message: _streamingMessage!);
                  }
                  final messageIndex =
                      index - (_streamingMessage == null ? 0 : 1);
                  final message = _messages.reversed.toList()[messageIndex];
                  return Bubble(message: message);
                },
              ),
            ),
            if (_isReplying) const LinearProgressIndicator(),
            const Divider(height: 1.0),
            if (_connectionStatus == ConnectionStatus.disconnected)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("연결 재시도"),
                  onPressed: _connectToLiveAPI,
                ),
              ),
            if (_connectionStatus == ConnectionStatus.connected)
              _buildTextComposer(),
          ],
        ),
      ),
    );
  }
}
