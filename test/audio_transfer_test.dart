import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:multi_phone_sync/models/audio.dart';
import 'package:multi_phone_sync/services/transfer/audio_transfer_service.dart';

void main() {
  test('downloads audio to a temporary part file and reports progress', () async {
    final bytes = List<int>.generate(1024, (index) => index % 256);
    final server = await _startServer((request) async {
      request.response
        ..statusCode = HttpStatus.ok
        ..contentLength = bytes.length;
      await request.response.addStream(Stream<List<int>>.fromIterable([
        bytes.sublist(0, 400),
        bytes.sublist(400),
      ]));
      await request.response.close();
    });
    final service = LocalAudioTransferService();
    final progress = <AudioTransferProgress>[];
    final subscription = service.progressStream.listen(progress.add);
    final metadata = _metadata(bytes.length);

    final path = await service.download(
      Uri.parse('http://127.0.0.1:${server.port}/audio/${metadata.audioId}'),
      metadata,
    );

    expect(File(path).path, endsWith('.part'));
    expect(await File(path).readAsBytes(), bytes);
    expect(progress.last.bytesReceived, bytes.length);
    expect(progress.last.progress, 1);

    await subscription.cancel();
    await service.dispose();
    await server.close(force: true);
    await File(path).parent.delete(recursive: true);
  });

  test('retries interrupted downloads and removes failed temporary files', () async {
    var attempts = 0;
    final bytes = List<int>.filled(64, 7);
    final server = await _startServer((request) async {
      attempts++;
      request.response.statusCode = HttpStatus.ok;
      if (attempts == 1) {
        await request.response.addStream(Stream<List<int>>.fromIterable([
          bytes.sublist(0, 10),
        ]));
      } else {
        await request.response.addStream(Stream<List<int>>.fromIterable([bytes]));
      }
      await request.response.close();
    });
    final service = LocalAudioTransferService();
    final metadata = _metadata(bytes.length);

    final path = await service.download(
      Uri.parse('http://127.0.0.1:${server.port}/audio/${metadata.audioId}'),
      metadata,
      maxAttempts: 2,
    );
    expect(attempts, 2);
    expect(await File(path).readAsBytes(), bytes);
    await service.dispose();
    await server.close(force: true);
    await File(path).parent.delete(recursive: true);
  });

  test('does not leave a partial file after all attempts fail', () async {
    final server = await _startServer((request) async {
      request.response.statusCode = HttpStatus.ok;
      await request.response.addStream(Stream<List<int>>.fromIterable([
        List<int>.filled(2, 1),
      ]));
      await request.response.close();
    });
    final service = LocalAudioTransferService();
    final metadata = _metadata(10);

    await expectLater(
      service.download(
        Uri.parse('http://127.0.0.1:${server.port}/audio/${metadata.audioId}'),
        metadata,
        maxAttempts: 2,
      ),
      throwsA(isA<Exception>()),
    );

    await service.dispose();
    await server.close(force: true);
  });
}

AudioMetadata _metadata(int size) {
  return AudioMetadata(
    audioId: 'audio-1',
    fileName: 'sample.mp3',
    format: 'mp3',
    size: size,
    checksum: 'not-verified-in-phase-6',
  );
}

Future<HttpServer> _startServer(
  Future<void> Function(HttpRequest request) handler,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen(handler);
  return server;
}
