class AudioMetadata {
  const AudioMetadata({
    required this.audioId,
    required this.fileName,
    required this.format,
    required this.size,
    required this.checksum,
    this.localPath = '',
    this.duration,
  });

  final String audioId;
  final String fileName;
  final String format;
  final int size;
  final String checksum;
  final String localPath;
  final Duration? duration;

  Map<String, dynamic> toJson() {
    return {
      'audioId': audioId,
      'fileName': fileName,
      'format': format,
      'size': size,
      'duration': duration?.inMilliseconds,
      'checksum': checksum,
    };
  }
}
