enum TransferStatus { idle, downloading, verifying, failed, completed }

class TransferSnapshot {
  const TransferSnapshot({
    required this.status,
    required this.bytesReceived,
    required this.totalBytes,
    this.errorMessage,
    this.temporaryPath,
  });

  final TransferStatus status;
  final int bytesReceived;
  final int totalBytes;
  final String? errorMessage;
  final String? temporaryPath;

  double get progress =>
      totalBytes <= 0 ? 0 : (bytesReceived / totalBytes).clamp(0.0, 1.0);
}
