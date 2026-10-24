/// Bridge and contract version this app implements. Extensions built for a
/// newer one are listed but cannot be installed.
const supportedExtensionApi = 1;

/// One entry of a repo's `index.json`, also stored for installed extensions.
class ExtensionMeta {
  const ExtensionMeta({
    required this.id,
    required this.name,
    required this.lang,
    required this.version,
    required this.apiVersion,
    required this.baseUrl,
    required this.file,
    required this.sha256,
    this.nsfw = false,
    this.repoUrl,
  });

  factory ExtensionMeta.fromJson(
    Map<String, dynamic> json, {
    String? repoUrl,
  }) => ExtensionMeta(
    id: json['id'] as String,
    name: json['name'] as String,
    lang: json['lang'] as String? ?? 'all',
    version: (json['version'] as num).toInt(),
    apiVersion: (json['apiVersion'] as num?)?.toInt() ?? 1,
    baseUrl: json['baseUrl'] as String? ?? '',
    file: json['file'] as String,
    sha256: json['sha256'] as String,
    nsfw: json['nsfw'] as bool? ?? false,
    repoUrl: repoUrl ?? json['repoUrl'] as String?,
  );

  final String id;
  final String name;

  /// ISO 639-1 code, or `all` for multi-language sources.
  final String lang;
  final int version;
  final int apiVersion;
  final String baseUrl;

  /// Script file, relative to the repo's `index.json`.
  final String file;
  final String sha256;
  final bool nsfw;

  /// `index.json` the extension came from; null for bundled ones.
  final String? repoUrl;

  bool get supported => apiVersion <= supportedExtensionApi;

  /// Host shown under the source name, e.g. `voratoon.co`.
  String get domain => Uri.tryParse(baseUrl)?.host ?? baseUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lang': lang,
    'version': version,
    'apiVersion': apiVersion,
    'baseUrl': baseUrl,
    'file': file,
    'sha256': sha256,
    'nsfw': nsfw,
    if (repoUrl != null) 'repoUrl': repoUrl,
  };
}

/// A filter value offered by a source, e.g. `{value: 'ongoing', label: 'Ongoing'}`.
class SourceOption {
  const SourceOption(this.value, this.label);

  final String value;
  final String label;
}

/// One group of a source's filter sheet. A select group always has one
/// value (an "All" option has the value `''`); a multi group any number.
class FilterGroup {
  const FilterGroup({
    required this.key,
    required this.label,
    required this.multi,
    required this.options,
    this.defaultValue,
    this.quick = false,
  });

  /// Null when [json] is not a usable group.
  static FilterGroup? tryParse(Object? json) {
    if (json is! Map) return null;
    final options = [
      for (final o in (json['options'] as List?) ?? const [])
        if (o is Map) SourceOption('${o['value']}', '${o['label']}'),
    ];
    final key = json['key'];
    final multi = json['type'] == 'multi';
    if (key is! String || (!multi && options.isEmpty)) return null;
    return FilterGroup(
      key: key,
      label: '${json['label'] ?? key}',
      multi: multi,
      options: options,
      defaultValue: json['default'] as String?,
      quick: json['quick'] == true,
    );
  }

  /// Key of the multi group holding the ids of a series' genres.
  static const genreKey = 'genre';

  final String key;
  final String label;
  final bool multi;
  final List<SourceOption> options;
  final String? defaultValue;

  /// Shown as a quick picker above the Explore grid.
  final bool quick;

  /// Values when nothing is picked.
  List<String> get defaults =>
      multi ? const [] : [defaultValue ?? options.first.value];

  String labelOf(String value) =>
      options.where((o) => o.value == value).firstOrNull?.label ?? value;
}

/// Filter values per group key, as sent to a source's `browse`.
typedef FilterValues = Map<String, List<String>>;

/// What a source offers besides its methods: filter groups and the filters
/// of Home's two sections.
class SourceFeatures {
  const SourceFeatures({
    this.groups = const [],
    this.featured = const {},
    this.latest = const {},
  });

  /// [home] is the extension's `home` object, [groups] its `filters()`.
  factory SourceFeatures.fromJson({Object? home, Object? groups}) {
    FilterValues values(Object? json) => {
      if (json is Map)
        for (final MapEntry(:key, :value) in json.entries)
          '$key': [
            for (final v in value is List ? value : [value]) '$v',
          ],
    };
    final homeMap = home is Map ? home : const {};
    return SourceFeatures(
      groups: [
        for (final g in groups is List ? groups : const [])
          ?FilterGroup.tryParse(g),
      ],
      featured: values(homeMap['featured']),
      latest: values(homeMap['latest']),
    );
  }

  final List<FilterGroup> groups;

  /// Filters of Home's slider and of its latest-updates list.
  final FilterValues featured;
  final FilterValues latest;

  FilterGroup? group(String key) =>
      groups.where((g) => g.key == key).firstOrNull;

  FilterGroup? get quick => groups.where((g) => g.quick).firstOrNull;

  /// Values of [key] in [values], else the group's default.
  List<String> valueOf(FilterValues values, String key) =>
      values[key] ?? group(key)?.defaults ?? const [];
}
