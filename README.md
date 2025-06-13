# Flutter Gemini Live

[![pub version](https://img.shields.io/pub/v/gemini_live.svg)](https://pub.dev/packages/gemini_live)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue)

---

A Flutter package for using the experimental Gemini Live API, enabling real-time, multimodal conversations with Google's Gemini models.

## ✨ Features

*   **Real-time Communication**: Establishes a WebSocket connection for low-latency, two-way interaction.
*   **Multimodal Input**: Send text, images, and audio in a single conversational turn.
*   **Streaming Responses**: Receive text responses from the model as they are being generated.
*   **Easy-to-use Callbacks**: Simple event-based handlers for `onOpen`, `onMessage`, `onError`, and `onClose`.

## 🏁 Getting Started

### Prerequisites

You need a Google Gemini API key to use this package. You can get your key from [Google AI Studio](https://aistudio.google.com/app/apikey).

### Installation

Add the package to your `pubspec.yaml` file:

```yaml
dependencies:
  gemini_live: ^0.0.3 # Use the latest version
```

or run this command:

```bash
flutter pub add gemini_live
```

Install the package from your terminal:

```bash
flutter pub get
```

Now, import the package in your Dart code:

```dart
import 'package:gemini_live/gemini_live.dart';
```

## 🚀 Usage

Here is a basic example of how to use the `gemini_live` package to start a session and send a message.

**Security Note**: Do not hardcode your API key. It is highly recommended to use a `.env` file with a package like `flutter_dotenv` to keep your credentials secure.

```dart
import 'package:gemini_live/gemini_live.dart';

// 1. Initialize Gemini with your API key
final genAI = GoogleGenAI(apiKey: 'YOUR_API_KEY_HERE');
LiveSession? session;

// 2. Connect to the Live API
Future<void> connect() async {
  try {
    session = await genAI.live.connect(
      model: 'gemini-2.0-flash-live-001',
      callbacks: LiveCallbacks(
        onOpen: () => print('✅ Connection opened'),
        onMessage: (LiveServerMessage message) {
          // 3. Handle incoming messages from the model
          if (message.text != null) {
            print('Received chunk: ${message.text}');
          }
          if (message.serverContent?.turnComplete ?? false) {
            print('✅ Turn complete!');
          }
        },
        onError: (e, s) => print('🚨 Error: $e'),
        onClose: (code, reason) => print('🚪 Connection closed'),
      ),
    );
  } catch (e) {
    print('Connection failed: $e');
  }
}

// 4. Send a message to the model
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

## 💬 Live Chat Demo

This repository includes a comprehensive example application demonstrating the features of the `gemini_live` package.

### Running the Demo App

1.  **Get an API Key**: Make sure you have a Gemini API key from [Google AI Studio](https://aistudio.google.com/app/apikey).

2.  **Set Up the Project**:
    *   Clone this repository.
    *   Open the `example/lib/main.dart` file and insert your API key:
        ```dart
        // example/lib/main.dart
        const String geminiApiKey = 'YOUR_API_KEY_HERE';
        ```
    *   Configure platform permissions for microphone and photo library access as needed.
    *   Run `flutter pub get` in the `example` directory.

3.  **Run the App**:
    ```bash
    cd example
    flutter run
    ```

### How to Use the App

1.  **Connect**: The app will attempt to connect to the Gemini API automatically. If the connection fails, tap the **"Reconnect"** button.

2.  **Send a Text Message**:
    -   Type your message in the text field at the bottom.
    -   Tap the send (**▶️**) icon.

3.  **Send a Message with an Image**:
    -   Tap the image (**🖼️**) icon to open your gallery.
    -   Select an image. A preview will appear.
    -   (Optional) Type a question about the image.
    -   Tap the send (**▶️**) icon.

4.  **Send a Voice Message**:
    -   Tap the microphone (**🎤**) icon. Recording will start, and the icon will change to a red stop (**⏹️**) icon.
    -   Speak your message.
    -   Tap the stop (**⏹️**) icon again to finish. The audio will be sent automatically.

## 🤝 Contributing

Contributions of all kinds are welcome, including bug reports, feature requests, and pull requests! Please feel free to open an issue on the issue tracker.

1.  Fork this repository.
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

## 📜 License

See the `LICENSE` file for more details.