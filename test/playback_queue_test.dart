import 'package:flutter_test/flutter_test.dart';
import 'package:multi_phone_sync/state/playback_queue_controller.dart';

void main() {
  test('adds unique tracks and advances in order', () {
    final queue = PlaybackQueueController();

    queue.add('/music/one.mp3');
    queue.add('/music/one.mp3');
    queue.add('/music/two.mp3');

    expect(queue.items, ['/music/one.mp3', '/music/two.mp3']);
    expect(queue.current, '/music/one.mp3');
    expect(queue.next(), '/music/two.mp3');
    expect(queue.next(), isNull);
  });

  test('removing the active track keeps the index valid', () {
    final queue = PlaybackQueueController();
    queue.add('/music/one.mp3');
    queue.add('/music/two.mp3');
    queue.next();

    queue.removeAt(1);

    expect(queue.currentIndex, 0);
    expect(queue.current, '/music/one.mp3');
  });
}
