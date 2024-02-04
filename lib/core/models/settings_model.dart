import 'dart:convert';

class SettingsModel {
  final String darkMode;
  SettingsModel({
    required this.darkMode,
  });

  SettingsModel copyWith({
    String? darkMode,
  }) {
    return SettingsModel(
      darkMode: darkMode ?? this.darkMode,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'darkMode': darkMode,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      darkMode: map['darkMode'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory SettingsModel.fromJson(String source) =>
      SettingsModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'SettingsModel(darkMode: $darkMode)';

  @override
  bool operator ==(covariant SettingsModel other) {
    if (identical(this, other)) return true;

    return other.darkMode == darkMode;
  }

  @override
  int get hashCode => darkMode.hashCode;
}
