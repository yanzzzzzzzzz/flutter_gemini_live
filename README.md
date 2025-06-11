
# Flutter Gemini Live 

[![pub version](https://img.shields.io/pub/v/gemini_live.svg)](https://pub.dev/packages/[gemini_live])
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue)

---

## ✨ Features

*   Gemini Live API (Experimental) for Flutter 

## 🏁 Getting Started

### Prerequisites

You need a Google Gemini API key to use this package. You can get your key from [Google AI Studio](https://aistudio.google.com/app/apikey).

### Installation

Add the package to your `pubspec.yaml` file:

```yaml
dependencies:
  gemini_live: ^0.0.1 # Use the latest version
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

### 1. Initialize Gemini

Initialize the Gemini service with your API key, preferably when your app starts (e.g., in your `main` function).

**Security Note**: Do not hardcode your API key directly in your source code. It is highly recommended to use a `.env` file with a package like `flutter_dotenv` to keep your credentials secure.


## 🤝 Contributing

Contributions of all kinds are welcome, including bug reports, feature requests, and pull requests! Please feel free to open an issue on the issue tracker.

1.  Fork this repository.
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

## 📜 License

See the `LICENSE` file for more details.