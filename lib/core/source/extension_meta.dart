import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:bacakomik_app/core/utils/version.dart';

/// Extension lib versions the Mihon host runs (`AndroidLoader.libs`).
const supportedMihonLibs = {'1.4', '1.5', '1.6'};

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
    this.languages = const [],
    this.urlPatterns = const [],
    this.parentId,
    this.icon,
    this.pkg,
    this.signer,
    this.versionCode = 0,
    this.mihonSources = const [],
  });

  factory ExtensionMeta.fromJson(
    Map<String, dynamic> json, {
    String? repoUrl,
  }) => ExtensionMeta(
    id: json['id'] as String,
    name: json['name'] as String,
    lang: json['lang'] as String? ?? 'all',
    version: _version(json['version']),
    apiVersion: (json['apiVersion'] as num?)?.toInt() ?? 1,
    baseUrl: json['baseUrl'] as String? ?? '',
    file: json['file'] as String,
    sha256: json['sha256'] as String,
    nsfw: json['nsfw'] as bool? ?? false,
    repoUrl: repoUrl ?? json['repoUrl'] as String?,
    languages: (json['languages'] as List?)?.cast<String>() ?? const [],
    urlPatterns:
        (json['urlPatterns'] as List?)?.whereType<String>().toList() ??
        const [],
    icon: json['icon'] as String?,
    pkg: json['pkg'] as String?,
    signer: json['signer'] as String?,
    versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
    mihonSources: [
      for (final s in (json['mihonSources'] as List?) ?? const [])
        if (s is Map) MihonSourceRef.fromJson(s.cast<String, dynamic>()),
    ],
  );

  /// Prefix of Mihon ids: extensions `mihon-<package>`, sources
  /// `mihon-<Mihon source id>`. Never `:`, which [ComicKey] splits on.
  static const mihonPrefix = 'mihon-';

  /// The slug of a Mihon series: its URL as base64url without padding
  /// (`Slugs.kt`), ASCII and slash-free for keys and folders. Past
  /// [mihonSlugMax] characters it is `~` + the URL's SHA-1, which Kotlin
  /// reads back only once told the URL ([isHashedMihonSlug]).
  static String mihonSlug(String url) {
    final slug = base64Url.encode(utf8.encode(url)).replaceAll('=', '');
    if (slug.length <= mihonSlugMax) return slug;
    return '~${sha1.convert(utf8.encode(url))}';
  }

  /// `Slugs.MAX` in Kotlin.
  static const mihonSlugMax = 200;

  static bool isHashedMihonSlug(String slug) => slug.startsWith('~');

  /// Id of the Mihon extension [pkg]: `eu.kanade.tachiyomi.extension.en.foo`
  /// → `mihon-en_foo`.
  static String mihonExtensionId(String pkg) =>
      mihonPrefix +
      pkg
          .replaceFirst('eu.kanade.tachiyomi.extension.', '')
          .toLowerCase()
          .replaceAll(RegExp('[^a-z0-9]+'), '_');

  final String id;
  final String name;

  /// ISO 639-1 code, or `all` for multi-language sources.
  final String lang;

  /// `major.minor.patch`; compare with [isNewerThan].
  final String version;
  final int apiVersion;
  final String baseUrl;

  /// Script file, relative to the repo's `index.json`.
  final String file;
  final String sha256;
  final bool nsfw;

  /// `index.json` the extension came from; null for bundled ones.
  final String? repoUrl;

  /// Language codes of a multi-language extension (e.g. MangaDex). Each
  /// enabled one is its own source ([forLanguage]); empty for an extension
  /// that is a single source.
  final List<String> languages;

  /// Regexes that find the slug in a series URL path (their one capture
  /// group), e.g. `^/manga/([^/?#]+)`. Lets the app read links, such as a
  /// Mihon backup's, without running the script; see [slugFromUrl].
  final List<String> urlPatterns;

  /// For a source made by [forLanguage] or [forMihonSource]: the
  /// extension's id.
  final String? parentId;

  /// Icon URL, absolute or relative to the repo's index; null shows the
  /// name's first letter.
  final String? icon;

  /// Android package of a Mihon extension; null for a JS one.
  final String? pkg;

  /// SHA-256 of the certificate a Mihon extension must be signed with (the
  /// repo's `signingKeyFingerprint`).
  final String? signer;

  /// A Mihon extension's version code; updates compare it.
  final int versionCode;

  /// The sources a Mihon extension holds.
  final List<MihonSourceRef> mihonSources;

  bool get isMihon => pkg != null;

  /// Whether a source of this Mihon extension has settings.
  bool get hasSettings => mihonSources.any((s) => s.configurable);

  /// [icon] as a full URL.
  String? get iconUrl {
    final icon = this.icon;
    if (icon == null || icon.isEmpty) return null;
    final repo = repoUrl;
    if (Uri.tryParse(icon)?.hasScheme ?? false) return icon;
    return repo == null ? null : Uri.parse(repo).resolve(icon).toString();
  }

  /// Id of the installed extension (script file, updates, uninstall).
  String get extensionId => parentId ?? id;

  /// Name without the language a [forLanguage] source adds.
  String get baseName => parentId == null
      ? name
      : name.replaceFirst(' (${lang.toUpperCase()})', '');

  /// The source [sourceId] of this extension: itself, or one of its
  /// [languages] (`<id>-<lang>`). Null when it is neither.
  ExtensionMeta? sourceFor(String sourceId) {
    if (isMihon) {
      final source = mihonSources
          .where((s) => '$mihonPrefix${s.id}' == sourceId)
          .firstOrNull;
      return source == null ? null : forMihonSource(source);
    }
    if (sourceId == id) return this;
    if (!sourceId.startsWith('$id-')) return null;
    final language = sourceId.substring(id.length + 1);
    return languages.contains(language) ? forLanguage(language) : null;
  }

  /// The source of one of [languages]: id `<id>-<lang>`, so its comics,
  /// bookmarks and history are its own.
  ExtensionMeta forLanguage(String language) => ExtensionMeta(
    id: '$id-$language',
    name: '$name (${language.toUpperCase()})',
    lang: language,
    version: version,
    apiVersion: apiVersion,
    baseUrl: baseUrl,
    file: file,
    sha256: sha256,
    nsfw: nsfw,
    repoUrl: repoUrl,
    urlPatterns: urlPatterns,
    parentId: id,
    icon: icon,
  );

  /// The sources of a Mihon extension to read from: those in [languages]
  /// (all when the extension has one language).
  List<ExtensionMeta> mihonSourcesIn(Iterable<String> languages) => [
    for (final s in mihonSources)
      if (this.languages.isEmpty || languages.contains(s.lang))
        forMihonSource(s),
  ];

  /// One source of a Mihon extension: id `mihon-<Mihon id>`, so its keys
  /// survive updates and match Mihon backups.
  ExtensionMeta forMihonSource(MihonSourceRef source) => ExtensionMeta(
    id: '$mihonPrefix${source.id}',
    name: languages.isEmpty
        ? source.name
        : '${source.name} (${source.lang.toUpperCase()})',
    lang: source.lang,
    version: version,
    apiVersion: apiVersion,
    baseUrl: source.baseUrl.isEmpty ? baseUrl : source.baseUrl,
    file: file,
    sha256: sha256,
    nsfw: nsfw,
    repoUrl: repoUrl,
    parentId: id,
    icon: icon,
    pkg: pkg,
    signer: signer,
    versionCode: versionCode,
  );

  /// The slug in [url], a full URL or a path like `/manga/<slug>/`, by the
  /// first of [urlPatterns] that matches. Null when none does.
  String? slugFromUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    var path = url.trim();
    if (uri != null && uri.hasScheme) {
      path = uri.path;
      if (uri.hasQuery) path += '?${uri.query}';
      if (uri.hasFragment) path += '#${uri.fragment}';
    }
    for (final pattern in urlPatterns) {
      try {
        final match = RegExp(pattern).firstMatch(path);
        final slug = match != null && match.groupCount > 0
            ? match.group(1)
            : null;
        if (slug != null && slug.isNotEmpty) return slug;
      } on FormatException {
        // A pattern Dart cannot parse matches nothing.
      }
    }
    return null;
  }

  bool get supported => isMihon
      ? supportedMihonLibs.contains(_mihonLib)
      : apiVersion <= supportedExtensionApi;

  /// `1.4.12` → `1.4`.
  String get _mihonLib => version.split('.').take(2).join('.');

  bool isNewerThan(ExtensionMeta other) => isMihon && other.isMihon
      ? versionCode > other.versionCode
      : isNewerVersion(version, other.version);

  /// Builds before semver stored a plain integer; `1` reads as `1.0.0`.
  static String _version(Object? raw) =>
      raw is num ? '${raw.toInt()}.0.0' : raw as String;

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
    if (languages.isNotEmpty) 'languages': languages,
    if (urlPatterns.isNotEmpty) 'urlPatterns': urlPatterns,
    if (icon != null) 'icon': icon,
    if (pkg != null) 'pkg': pkg,
    if (signer != null) 'signer': signer,
    if (versionCode != 0) 'versionCode': versionCode,
    if (mihonSources.isNotEmpty)
      'mihonSources': [for (final s in mihonSources) s.toJson()],
  };
}

/// One source inside a Mihon extension.
class MihonSourceRef {
  const MihonSourceRef({
    required this.id,
    required this.name,
    required this.lang,
    this.baseUrl = '',
    this.configurable = false,
  });

  factory MihonSourceRef.fromJson(Map<String, dynamic> json) => MihonSourceRef(
    id: '${json['id']}',
    name: json['name'] as String? ?? '${json['id']}',
    lang: json['lang'] as String? ?? 'all',
    baseUrl: json['baseUrl'] as String? ?? '',
    configurable: json['configurable'] == true,
  );

  /// Mihon's source id, a 63-bit number as text.
  final String id;
  final String name;
  final String lang;
  final String baseUrl;

  /// Has settings (`ConfigurableSource`); known once installed.
  final bool configurable;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lang': lang,
    if (baseUrl.isNotEmpty) 'baseUrl': baseUrl,
    if (configurable) 'configurable': true,
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
    this.sort = false,
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
      sort: json['type'] == 'sort',
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

  /// A select whose values are `<field>:a` / `<field>:d` (Mihon's sort):
  /// one chip per field, the direction an arrow.
  final bool sort;

  /// Values when nothing is picked.
  List<String> get defaults =>
      multi ? const [] : [defaultValue ?? options.first.value];

  String labelOf(String value) {
    final label =
        options.where((o) => o.value == value).firstOrNull?.label ?? value;
    if (!sort || !value.contains(':')) return label;
    return '$label ${value.endsWith(':a') ? '↑' : '↓'}';
  }
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
    this.showFeatured = true,
    this.featuredLabel,
    this.latestLabel,
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
      // `featured: null` (Mihon, nothing new to offer): no first section.
      showFeatured:
          !(homeMap.containsKey('featured') && homeMap['featured'] == null),
      featuredLabel: homeMap['featuredLabel'] as String?,
      latestLabel: homeMap['latestLabel'] as String?,
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

  /// Whether Home shows the slider at all.
  final bool showFeatured;

  /// Titles of Home's two sections when the source fills them with
  /// something else (Mihon's popular list); null: "New series" and
  /// "Latest updates".
  final String? featuredLabel;
  final String? latestLabel;

  FilterGroup? group(String key) =>
      groups.where((g) => g.key == key).firstOrNull;

  FilterGroup? get quick => groups.where((g) => g.quick).firstOrNull;

  /// The filter that shows a series' genre ([id], [name]): the `genre`
  /// group's option [id], else any option labelled [name] (Mihon sources
  /// name their groups `f<n>`). Null when the source has no such filter.
  ({String key, String value})? genreFilter(String id, String name) {
    final genre = group(FilterGroup.genreKey);
    if (genre != null && genre.options.any((o) => o.value == id)) {
      return (key: genre.key, value: id);
    }
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final wanted = norm(name);
    if (wanted.isEmpty) return null;
    for (final g in groups) {
      for (final o in g.options) {
        if (o.value.isNotEmpty && norm(o.label) == wanted) {
          return (key: g.key, value: o.value);
        }
      }
    }
    return null;
  }

  /// Values of [key] in [values], else the group's default.
  List<String> valueOf(FilterValues values, String key) =>
      values[key] ?? group(key)?.defaults ?? const [];
}
