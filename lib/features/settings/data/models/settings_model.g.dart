// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingsModel _$SettingsModelFromJson(Map<String, dynamic> json) =>
    SettingsModel(
      darkMode: json['darkMode'] as String,
      readingDirection:
          $enumDecodeNullable(
            _$ReadingDirectionEnumMap,
            json['readingDirection'],
            unknownValue: ReadingDirection.vertical,
          ) ??
          ReadingDirection.vertical,
      pageFit:
          $enumDecodeNullable(
            _$PageFitEnumMap,
            json['pageFit'],
            unknownValue: PageFit.width,
          ) ??
          PageFit.width,
      keepScreenOn: json['keepScreenOn'] as bool? ?? true,
      pageGap: json['pageGap'] as bool? ?? false,
    );

Map<String, dynamic> _$SettingsModelToJson(SettingsModel instance) =>
    <String, dynamic>{
      'darkMode': instance.darkMode,
      'readingDirection': _$ReadingDirectionEnumMap[instance.readingDirection]!,
      'pageFit': _$PageFitEnumMap[instance.pageFit]!,
      'keepScreenOn': instance.keepScreenOn,
      'pageGap': instance.pageGap,
    };

const _$ReadingDirectionEnumMap = {
  ReadingDirection.vertical: 'vertical',
  ReadingDirection.rightToLeft: 'rightToLeft',
  ReadingDirection.leftToRight: 'leftToRight',
};

const _$PageFitEnumMap = {PageFit.width: 'width', PageFit.height: 'height'};
