import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/logging/app_logger.dart';
import '../models/audio.dart';
import '../models/transfer_state.dart';
import '../services/transfer/audio_transfer_service.dart';
import '../services/transfer/checksum_service.dart';

class TransferController extends ChangeNotifier {
  TransferController({
    AudioTransferService? transferService,
    ChecksumService? checksumService,
  }) : _transferService = transferService ?? LocalAudioTransferService(),
       _checksumService = checksumService ?? Sha256ChecksumService() {
    _progressSubscription = _transferService.progressStream.listen((progress) {
      snapshot = TransferSnapshot(
        status: TransferStatus.downloading,
        bytesReceived: progress.bytesReceived,
        totalBytes: progress.totalBytes,
        temporaryPath: snapshot.temporaryPath,
      );
      notifyListeners();
    });
  }

  final AudioTransferService _transferService;
  final ChecksumService _checksumService;
  late final StreamSubscription<AudioTransferProgress> _progressSubscription;
  TransferSnapshot snapshot = const TransferSnapshot(
    status: TransferStatus.idle,
    bytesReceived: 0,
    totalBytes: 0,
  );

  Future<void> download(Uri source, AudioMetadata metadata) async {
    snapshot = TransferSnapshot(
      status: TransferStatus.downloading,
      bytesReceived: 0,
      totalBytes: metadata.size,
    );
    notifyListeners();
    try {
      final temporaryPath = await _transferService.download(source, metadata);
      snapshot = TransferSnapshot(
        status: TransferStatus.verifying,
        bytesReceived: metadata.size,
        totalBytes: metadata.size,
        temporaryPath: temporaryPath,
      );
      notifyListeners();
      final verification = await _checksumService.verify(
        File(temporaryPath),
        metadata,
      );
      if (!verification.isValid) {
        await _deleteTemporaryFile(temporaryPath);
        throw const FormatException('Downloaded audio failed verification.');
      }
      snapshot = TransferSnapshot(
        status: TransferStatus.completed,
        bytesReceived: metadata.size,
        totalBytes: metadata.size,
        temporaryPath: temporaryPath,
      );
    } catch (error, stackTrace) {
      AppLogger.error('Audio download failed', error, stackTrace);
      snapshot = TransferSnapshot(
        status: TransferStatus.failed,
        bytesReceived: 0,
        totalBytes: metadata.size,
        errorMessage:
            'Audio download failed. Retry when the connection is ready.',
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _progressSubscription.cancel();
    _transferService.dispose();
    super.dispose();
  }

  Future<void> _deleteTemporaryFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.parent.delete(recursive: true);
    } on FileSystemException catch (error, stackTrace) {
      AppLogger.error('Failed to remove invalid audio temporary file', error, stackTrace);
    }
  }
}
