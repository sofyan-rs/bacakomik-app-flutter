import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/network/doh.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:yoru/features/settings/presentation/bloc/settings_cubit.dart';

/// The DNS over HTTPS setting as shown in More: "Off", a preset's name, or
/// a custom server's host.
String dnsSettingLabel(String setting) =>
    DohServer.fromSetting(setting)?.shortName ?? AppText.dnsOff;

/// Picks the DNS over HTTPS server: off, a preset, or a custom URL.
Future<void> showDnsSheet(BuildContext context) =>
    showDotSheet<void>(context: context, builder: (_) => const _DnsSheet());

class _DnsSheet extends StatefulWidget {
  const _DnsSheet();

  @override
  State<_DnsSheet> createState() => _DnsSheetState();
}

class _DnsSheetState extends State<_DnsSheet> {
  late final TextEditingController _url;
  String? _error;

  /// The Custom row is picked: its address field shows. Saved only once
  /// the address is used, so picking it alone keeps the current server.
  late bool _custom;

  bool _isPreset(String setting) =>
      setting.isEmpty || dohPresets.any((p) => p.id == setting);

  @override
  void initState() {
    super.initState();
    final setting = context.read<SettingsCubit>().state.dnsOverHttps;
    _custom = !_isPreset(setting);
    _url = TextEditingController(text: _custom ? setting : '');
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _pick(String setting) {
    context.read<SettingsCubit>().update(
      (s) => s.copyWith(dnsOverHttps: setting),
    );
    Navigator.of(context).pop();
  }

  void _useCustom() {
    final url = DohServer.normalizeCustomUrl(_url.text);
    if (url == null) {
      setState(() => _error = AppText.dnsCustomInvalid);
      return;
    }
    _url.text = url;
    _pick(url);
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final current = context.select((SettingsCubit s) => s.state.dnsOverHttps);
    Widget? check(bool on) =>
        on ? Icon(LucideIcons300.check, color: c.ink) : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ActionSheetHeader(
          icon: LucideIcons300.globeLock,
          title: AppText.dnsOverHttps,
        ),
        const SizedBox(height: DotSpace.s4),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListGroup(
                  background: c.bg,
                  children: [
                    ListRow(
                      icon: LucideIcons300.globe,
                      title: AppText.dnsOff,
                      subtitle: AppText.dnsOffDescription,
                      showChevron: false,
                      trailing: check(!_custom && current.isEmpty),
                      onTap: () => _pick(''),
                    ),
                    for (final preset in dohPresets)
                      ListRow(
                        icon: LucideIcons300.server,
                        title: preset.name,
                        subtitle: Uri.parse(preset.url).host,
                        showChevron: false,
                        trailing: check(!_custom && current == preset.id),
                        onTap: () => _pick(preset.id),
                      ),
                    ListRow(
                      icon: LucideIcons300.pencil,
                      title: AppText.dnsCustom,
                      subtitle: !_isPreset(current)
                          ? Uri.parse(current).host
                          : AppText.dnsCustomDescription,
                      showChevron: false,
                      trailing: check(_custom),
                      onTap: () => setState(() => _custom = true),
                    ),
                  ],
                ),
                if (_custom) ...[
                  const SizedBox(height: DotSpace.s4),
                  TextField(
                    controller: _url,
                    autofocus: _url.text.isEmpty,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    style: DotlineText.body.copyWith(color: c.ink),
                    decoration: InputDecoration(
                      hintText: AppText.dnsCustomHint,
                      errorText: _error,
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    onSubmitted: (_) => _useCustom(),
                  ),
                  const SizedBox(height: DotSpace.s3),
                  DotButton(
                    label: AppText.dnsUseCustom,
                    leading: LucideIcons300.check,
                    onTap: _useCustom,
                  ),
                ],
                const SizedBox(height: DotSpace.s4),
                Text(
                  Platform.isAndroid
                      ? '${AppText.dnsCoverageAndroid} ${AppText.dnsPrivateDnsHint}'
                      : AppText.dnsCoverageDesktop,
                  style: DotlineText.bodyS.copyWith(color: c.inkFaint),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
