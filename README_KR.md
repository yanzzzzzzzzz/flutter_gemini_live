# Flutter Gemini Live

[![pub version](https://img.shields.io/pub/v/gemini_live.svg)](https://pub.dev/packages/gemini_live)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue)

---

- Google의 Gemini 모델과 실시간, 멀티모달 대화를 가능하게 해주는 [실험적인 Gemini Live API](https://ai.google.dev/gemini-api/docs/live)를 사용하기 위한 Flutter 패키지입니다.
- 이 패키지는 Firebase / Firebase AI Logic 사용 없이 활용가능 합니다.
- 그리고 `gemini-2.0-flash-live-001` 모델을 지원합니다.

https://github.com/user-attachments/assets/7d826f37-196e-4ddd-8828-df66db252e8e

## ✨ 주요 기능

*   **실시간 통신**: WebSocket 연결을 통해 지연 시간이 짧은(low-latency) 양방향(two-way) 상호작용을 구축합니다.
*   **멀티모달 입력**: 하나의 대화 턴(turn)에서 텍스트, 이미지, 오디오를 함께 전송할 수 있습니다.
*   **스트리밍 응답**: 모델이 생성하는 텍스트 응답을 실시간 스트리밍으로 수신합니다.
*   **사용하기 쉬운 콜백**: `onOpen`, `onMessage`, `onError`, `onClose` 등 간단한 이벤트 기반 핸들러를 제공합니다.

| 데모 1: 치와와 vs 머핀 | 데모 2: 래브라두들 vs 프라이드 치킨 |
| :---: | :---: |
| <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222333.png?raw=true" alt="실시간 대화 데모" width="400"/> | <img src="https://github.com/JAICHANGPARK/flutter_gemini_live/blob/main/imgs/Screenshot_20250613_222355.png?raw=true" alt="멀티모달 입력 데모" width="400"/> |
| *치와와 vs 머핀* | *래브라두들 vs 프라이드 치킨* |

## 🏁 시작하기

### 사전 준비

이 패키지를 사용하려면 Google Gemini API 키가 필요합니다. [Google AI Studio](https://aistudio.google.com/app/apikey)에서 API 키를 발급받을 수 있습니다.

### 설치

`pubspec.yaml` 파일에 패키지를 추가하세요:

```yaml
dependencies:
  gemini_live: ^0.0.5 # 최신 버전을 사용하세요
```

또는 아래 명령어를 실행하세요(추천):

```bash
flutter pub add gemini_live
```

터미널에서 패키지를 설치하세요:

```bash
flutter pub get
```

이제 Dart 코드에서 패키지를 import 하세요:

```dart
import 'package:gemini_live/gemini_live.dart';
```

## 🚀 사용법

다음은 `gemini_live` 패키지를 사용하여 세션을 시작하고 메시지를 보내는 기본적인 예제입니다.

**보안 참고**: API 키를 코드에 직접 하드코딩하지 마세요. `flutter_dotenv`와 같은 패키지를 사용하여 `.env` 파일에 자격 증명을 안전하게 보관하는 것을 강력히 권장합니다.

```dart
import 'package:gemini_live/gemini_live.dart';

// 1. API 키로 Gemini 초기화
final genAI = GoogleGenAI(apiKey: 'YOUR_API_KEY_HERE');
LiveSession? session;

// 2. Live API에 연결
Future<void> connect() async {
  try {
    session = await genAI.live.connect(
      model: 'gemini-2.0-flash-live-001',
      callbacks: LiveCallbacks(
        onOpen: () => print('✅ 연결 성공'),
        onMessage: (LiveServerMessage message) {
          // 3. 모델로부터 수신되는 메시지 처리
          if (message.text != null) {
            print('수신된 청크: ${message.text}');
          }
          if (message.serverContent?.turnComplete ?? false) {
            print('✅ 턴(Turn) 완료!');
          }
        },
        onError: (e, s) => print('🚨 오류 발생: $e'),
        onClose: (code, reason) => print('🚪 연결 종료'),
      ),
    );
  } catch (e) {
    print('연결 실패: $e');
  }
}

// 4. 모델에 메시지 전송
void sendMessage(String text) {
  session?.sendMessage(
    LiveClientMessage(
      clientContent: LiveClientContent(
        turns: [
          Content(
            role: "user",
            parts: [Part(text: text)],
          ),
        ],
        turnComplete: true,
      ),
    ),
  );
}
```

## 💬 라이브 채팅 데모

이 저장소(repository)에는 `gemini_live` 패키지의 기능을 보여주는 종합적인 예제 앱이 포함되어 있습니다.

### 데모 앱 실행하기

1.  **API 키 발급받기**: [Google AI Studio](https://aistudio.google.com/app/apikey)에서 Gemini API 키를 준비하세요.

2.  **프로젝트 설정**:
    *   이 저장소를 클론(clone)하세요.
    *   `example/lib/main.dart` 파일을 열고 API 키를 입력하세요:
        ```dart
        // example/lib/main.dart
        const String geminiApiKey = 'YOUR_API_KEY_HERE';
        ```
    *   필요에 따라 마이크 및 사진 라이브러리 접근을 위한 플랫폼별 권한을 설정하세요.
    *   `example` 디렉토리에서 `flutter pub get`을 실행하세요.

3.  **앱 실행하기**:
    ```bash
    cd example
    flutter run
    ```

### 앱 사용 방법

1.  **연결**: 앱이 자동으로 Gemini API에 연결을 시도합니다. 연결에 실패하면 **"재연결"** 버튼을 탭하세요.

2.  **텍스트 메시지 보내기**:
    -   하단의 텍스트 입력 필드에 메시지를 입력하세요.
    -   전송(**▶️**) 아이콘을 탭하세요.

3.  **이미지와 함께 메시지 보내기**:
    -   이미지(**🖼️**) 아이콘을 탭하여 갤러리를 여세요.
    -   이미지를 선택하면 미리보기가 나타납니다.
    -   (선택 사항) 이미지에 대해 질문할 내용을 입력하세요.
    -   전송(**▶️**) 아이콘을 탭하세요.

4.  **음성 메시지 보내기**:
    -   마이크(**🎤**) 아이콘을 탭하면 녹음이 시작되고 아이콘이 빨간색 정지(**⏹️**) 아이콘으로 바뀝니다.
    -   메시지를 말하세요.
    -   정지(**⏹️**) 아이콘을 다시 탭하면 녹음이 종료되고 오디오가 자동으로 전송됩니다.

## 🤝 기여하기

버그 리포트, 기능 제안, 풀 리퀘스트(Pull Request) 등 모든 종류의 기여를 환영합니다! 이슈 트래커에 언제든지 이슈를 등록해주세요.

1.  이 저장소를 포크(Fork)하세요.
2.  기능 브랜치를 생성하세요 (`git checkout -b feature/AmazingFeature`).
3.  변경 사항을 커밋하세요 (`git commit -m 'Add some AmazingFeature'`).
4.  브랜치에 푸시하세요 (`git push origin feature/AmazingFeature`).
5.  풀 리퀘스트(Pull Request)를 열어주세요.

## 📜 라이선스

자세한 내용은 `LICENSE` 파일을 참고하세요.
