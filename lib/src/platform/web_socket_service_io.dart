// platform/web_socket_service_io.dart

import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// 웹소켓 연결을 생성하는 함수
// 헤더를 포함할 수 있도록 수정합니다.
Future<WebSocketChannel> connect(Uri uri, Map<String, dynamic> headers) async {
  // dart:io의 WebSocket을 사용하여 직접 헤더와 함께 연결합니다.
  final webSocket = await WebSocket.connect(
    uri.toString(),
    headers: headers,
  );

  // IOWebSocketChannel로 래핑하여 반환합니다.
  return IOWebSocketChannel(webSocket);
}