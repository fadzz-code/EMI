import 'package:freezed_annotation/freezed_annotation.dart';

part 'offline_learning_summary.freezed.dart';
part 'offline_learning_summary.g.dart';

@freezed
class OfflineLearningSummary with _$OfflineLearningSummary {
  const factory OfflineLearningSummary({
    @Default(0) int moduleCount,
    @Default(0) int categoryCount,
    @Default(0) int entryCount,
    @Default(0) int pendingActivities,
    @Default(0) int failedActivities,
    @Default(0) int authBlockedActivities,
    @Default(0) int dbSizeBytes,
    @Default(0) int mediaSizeBytes,
  }) = _OfflineLearningSummary;

  factory OfflineLearningSummary.fromJson(Map<String, dynamic> json) =>
      _$OfflineLearningSummaryFromJson(json);
}

extension OfflineLearningSummaryX on OfflineLearningSummary {
  int get totalSizeBytes => dbSizeBytes + mediaSizeBytes;

  String get formattedTotalSize {
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
