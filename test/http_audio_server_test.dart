import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_phone_sync/services/http/audio_http_server.dart';

void main() {
  test('registers MP3 metadata and serves only its authorized audio id', () async {
    final server = AudioHttpServer();
    final directory = await Directory.systemTemp.createTemp('multi_phone_sync');
    final file = File('${directory.path}${Platform.pathSeparator}sample.mp3');
    final bytes = List<int>.generate(128, (index) => index);
    await file.writeAsBytes(bytes);

    try {
      await server.start();
      final metadata = await server.registerFile(file.path);
      final expectedChecksum = sha256.convert(bytes).toString();

      expect(metadata.audioId, expectedChecksum);
      expect(metadata.checksum, expectedChecksum);
      expect(metadata.fileName, 'sample.mp3');
      expect(metadata.size, bytes.length);

      final client = HttpClient();
      final response = await (await client.getUrl(Uri.parse(
        'http://127.0.0.1:${server.boundPort}/audio/${metadata.audioId}',
      ))).close();
      final responseBytes = await response.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      expect(response.statusCode, HttpStatus.ok);
      expect(responseBytes, bytes);

      final unauthorized = await (await client.getUrl(Uri.parse(
        'http://127.0.0.1:${server.boundPort}/audio/${'../sample.mp3'}',
      ))).close();
      expect(unauthorized.statusCode, HttpStatus.notFound);
      client.close(force: true);
    } finally {
      await server.dispose();
      await directory.delete(recursive: true);
    }
  });

  test('rejects unsupported audio formats', () async {
    final server = AudioHttpServer();
    final directory = await Directory.systemTemp.createTemp('multi_phone_sync');
    final file = File('${directory.path}${Platform.pathSeparator}sample.wav');
    await file.writeAsString('not an mp3');

    try {
      await server.start();
      expect(() => server.registerFile(file.path), throwsFormatException);
    } finally {
      await server.dispose();
      await directory.delete(recursive: true);
    }
  });
}
