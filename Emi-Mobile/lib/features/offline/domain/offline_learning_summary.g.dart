// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_learning_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OfflineLearningSummaryImpl _$$OfflineLearningSummaryImplFromJson(
  Map<String, dynamic> json,
) => _$OfflineLearningSummaryImpl(
  moduleCount: (json['moduleCount'] as num?)?.toInt() ?? 0,
  categoryCount: (json['categoryCount'] as num?)?.toInt() ?? 0,
  entryCount: (json['entryCount'] as num?)?.toInt() ?? 0,
  pendingActivities: (json['pendingActivities'] as num?)?.toInt() ?? 0,
  failedActivities: (json['failedActivities'] as num?)?.toInt() ?? 0,
  authBlockedActivities: (json['authBlockedActivities'] as num?)?.toInt() ?? 0,
  dbSizeBytes: (json['dbSizeBytes'] as num?)?.toInt() ?? 0,
  mediaSizeBytes: (json['mediaSizeBytes'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$OfflineLearningSummaryImplToJson(
  _$OfflineLearningSummaryImpl instance,
) => <String, dynamic>{
  'moduleCount': instance.moduleCount,
  'categoryCount': instance.categoryCount,
  'entryCount': instance.entryCount,
  'pendingActivities': instance.pendingActivities,
  'failedActivities': instance.failedActivities,
  'authBlockedActivities': instance.authBlockedActivities,
  'dbSizeBytes': instance.dbSizeBytes,
  'mediaSizeBytes': instance.mediaSizeBytes,
};
