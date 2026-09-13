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

  AudioMetadata copyWith({String? localPath}) {
    return AudioMetadata(
      audioId: audioId,
      fileName: fileName,
      format: format,
      size: size,
      checksum: checksum,
      localPath: localPath ?? this.localPath,
      duration: duration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audioId': audioId,
      'fileName': fileName,
      'format': format,
      'size': size,
      'duration': duration?.inMilliseconds,
      'checksum': checksum,
      'localPath': localPath,
    };
  }

  factory AudioMetadata.fromJson(Map<String, dynamic> json) {
    return AudioMetadata(
      audioId: json['audioId'] as String,
      fileName: json['fileName'] as String,
      format: json['format'] as String,
      size: json['size'] as int,
      checksum: json['checksum'] as String,
      localPath: json['localPath'] as String? ?? '',
      duration: (json['duration'] as int?) == null
          ? null
          : Duration(milliseconds: json['duration'] as int),
    );
  }
}
