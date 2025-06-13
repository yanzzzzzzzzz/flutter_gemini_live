// lib/google_genai.dart
import 'dart:io'; // Dart 런타임 버전 확인을 위해 import

import 'package:http/http.dart' as http;

import 'client/api_client.dart';
import 'live_service.dart';

export 'live_service.dart'
    show LiveCallbacks, LiveConnectParameters, LiveSession;
export 'model/models.dart';

class GoogleGenAI {
  final String apiKey;
  final http.Client? httpClient;

  late final ApiClient _apiClient;

  late final LiveService live;

  GoogleGenAI({required this.apiKey, this.httpClient}) {
    _apiClient = ApiClient(apiKey: apiKey, httpClient: httpClient);
    live = LiveService(apiKey: apiKey);
  }

  void close() {
    _apiClient.close();
  }
}
