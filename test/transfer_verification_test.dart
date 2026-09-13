import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:multi_phone_sync/models/audio.dart';
import 'package:multi_phone_sync/models/transfer_state.dart';
import 'package:multi_phone_sync/services/transfer/audio_transfer_service.dart';
import 'package:multi_phone_sync/services/transfer/checksum_service.dart';
import 'package:multi_phone_sync/state/transfer_controller.dart';

void main() {
  test('checksum failure removes the temporary file and stays non-ready', () async {
    final directory = await Directory.systemTemp.createTemp('verification_test');
    final file = File('${directory.path}${Platform.pathSeparator}audio.mp3');
    await file.writeAsBytes(List<int>.filled(16, 3));
    final transfer = FakeTransferService(file.path);
    final controller = TransferController(
      transferService: transfer,
      checksumService: Sha256ChecksumService(),
    );

    await controller.download(
      Uri.parse('http://localhost/audio/audio-1'),
      const AudioMetadata(
        audioId: 'audio-1',
        fileName: 'audio.mp3',
        format: 'mp3',
        size: 16,
        checksum: 'wrong-checksum',
      ),
    );

    expect(controller.snapshot.status, TransferStatus.failed);
    expect(await file.exists(), isFalse);
    expect(controller.snapshot.temporaryPath, isNull);

    controller.dispose();
    if (await directory.exists()) await directory.delete(recursive: true);
  });
}

class FakeTransferService implements AudioTransferService {
  FakeTransferService(this.path);

  final String path;
  final progressController = StreamController<AudioTransferProgress>.broadcast();

  @override
  Stream<AudioTransferProgress> get progressStream => progressController.stream;

  @override
  Future<String> download(Uri source, AudioMetadata metadata, {int maxAttempts = 3}) async {
    return path;
  }

  @override
  Future<void> dispose() async {
    await progressController.close();
  }
}
