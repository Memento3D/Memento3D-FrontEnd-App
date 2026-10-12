enum ReconstructionJobStatus { queued, running, done, failed, cancelled }

enum ReconstructionStage {
  downloading,
  preprocessing,
  shapeGeneration,
  texturing,
  validating,
  exporting,
  uploading,
}

enum ReconstructionExecutionMode { real, mock }

/// Wire response. Timestamp format/nullability and progress units are unspecified;
/// timestamps are retained verbatim and progress is never treated as a percent.
class ReconstructionJobResponse {
  ReconstructionJobResponse.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected reconstruction job object');
    }
    String string(String key) {
      final field = value[key];
      if (field is! String) throw FormatException('Invalid $key');
      return field;
    }

    String uuid(String key) {
      final field = string(key);
      if (!RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(field)) {
        throw FormatException('Invalid $key');
      }
      return field;
    }

    int integer(String key) {
      final field = value[key];
      if (field is! int) throw FormatException('Invalid $key');
      return field;
    }

    String? nullableString(String key) {
      if (!value.containsKey(key)) throw FormatException('Missing $key');
      final field = value[key];
      if (field != null && field is! String) {
        throw FormatException('Invalid $key');
      }
      return field as String?;
    }

    T parse<T>(String key, Map<String, T> values) {
      final result = values[string(key)];
      if (result == null) throw FormatException('Unknown $key');
      return result;
    }

    status = parse('status', {
      for (final v in ReconstructionJobStatus.values) v.name: v,
    });
    stage = parse('stage', {
      'downloading': ReconstructionStage.downloading,
      'preprocessing': ReconstructionStage.preprocessing,
      'shape_generation': ReconstructionStage.shapeGeneration,
      'texturing': ReconstructionStage.texturing,
      'validating': ReconstructionStage.validating,
      'exporting': ReconstructionStage.exporting,
      'uploading': ReconstructionStage.uploading,
    });
    executionMode = parse('execution_mode', {
      for (final v in ReconstructionExecutionMode.values) v.name: v,
    });
    progress = integer('progress');
    retryCount = integer('retry_count');
    profile = string('profile');
    jobId = uuid('job_id');
    scanId = uuid('scan_id');
    inputImageId = uuid('input_image_id');
    errorCode = nullableString('error_code');
    errorMessage = nullableString('error_message');
    timestamps = Map.unmodifiable({
      for (final key in [
        'queued_at',
        'started_at',
        'completed_at',
        'created_at',
        'updated_at',
      ])
        key: _timestamp(value, key),
    });
  }

  static Object? _timestamp(Map<String, dynamic> json, String key) {
    if (!json.containsKey(key)) throw FormatException('Missing $key');
    return json[key];
  }

  late final ReconstructionJobStatus status;
  late final ReconstructionStage stage;
  late final ReconstructionExecutionMode executionMode;
  late final int progress;
  late final int retryCount;
  late final String profile;
  late final String jobId;
  late final String scanId;
  late final String inputImageId;
  late final String? errorCode;
  late final String? errorMessage;
  late final Map<String, Object?> timestamps;
}
