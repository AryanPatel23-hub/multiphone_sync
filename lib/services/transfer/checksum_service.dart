import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../models/audio.dart';

class ChecksumVerificationResult {
  const ChecksumVerificationResult({
    required this.sizeMatches,
    required this.checksumMatches,
    required this.actualSize,
    required this.actualChecksum,
  });

  final bool sizeMatches;
  final bool checksumMatches;
  final int actualSize;
  final String actualChecksum;

  bool get isValid => sizeMatches && checksumMatches;
}

abstract interface class ChecksumService {
  Future<ChecksumVerificationResult> verify(
    File file,
    AudioMetadata metadata,
  );
}

class Sha256ChecksumService implements ChecksumService {
  @override
  Future<ChecksumVerificationResult> verify(
    File file,
    AudioMetadata metadata,
  ) async {
    if (metadata.checksum.isEmpty) {
      throw const FormatException('Audio checksum metadata is required.');
    }
    final actualSize = await file.length();
    final actualChecksum = (await sha256.bind(file.openRead()).first).toString();
    return ChecksumVerificationResult(
      sizeMatches: actualSize == metadata.size,
      checksumMatches: actualChecksum.toLowerCase() ==
          metadata.checksum.toLowerCase(),
      actualSize: actualSize,
      actualChecksum: actualChecksum,
    );
  }
}