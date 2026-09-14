import 'package:flutter/foundation.dart';

class PlaybackQueueController extends ChangeNotifier {
  final items = <String>[];
  int currentIndex = -1;

  String? get current => currentIndex >= 0 && currentIndex < items.length
      ? items[currentIndex]
      : null;

  void add(String path) {
    final normalized = path.trim();
    if (normalized.isEmpty || items.contains(normalized)) return;
    items.add(normalized);
    currentIndex = currentIndex < 0 ? 0 : currentIndex;
    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= items.length) return;
    items.removeAt(index);
    if (items.isEmpty) {
      currentIndex = -1;
    } else if (currentIndex >= items.length) {
      currentIndex = items.length - 1;
    }
    notifyListeners();
  }

  String? next() {
    if (currentIndex + 1 >= items.length) return null;
    currentIndex += 1;
    notifyListeners();
    return current;
  }
}