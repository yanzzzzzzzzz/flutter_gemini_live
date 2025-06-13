import 'package:image_picker/image_picker.dart';

import 'bubble.dart';

class ChatMessage {
  final String text;
  final Role author;
  final XFile? image;

  ChatMessage({required this.text, required this.author, this.image,});
}
