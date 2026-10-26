import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/extensions_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

Future<void> showReposSheet(BuildContext context, ExtensionsCubit cubit) =>
    showDotSheet(
      context: context,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const ReposSheet()),
    );

/// Repo URLs the extension list comes from, with a field to add one.
class ReposSheet extends StatefulWidget {
  const ReposSheet({super.key});

  @override
  State<ReposSheet> createState() => _ReposSheetState();
}

class _ReposSheetState extends State<ReposSheet> {
  final _url = TextEditingController();
  var _adding = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final url = _url.text.trim();
    if (Uri.tryParse(url)?.hasScheme != true) {
      setState(() => _error = AppText.repoInvalid);
      return;
    }
    setState(() {
      _adding = true;
      _error = null;
    });
    final error = await context.read<ExtensionsCubit>().addRepo(url);
    if (!mounted) return;
    setState(() {
      _adding = false;
      _error = error == null ? null : AppText.repoInvalid;
    });
    if (error == null) _url.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final repos = context.watch<ExtensionsCubit>().state.repos;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ActionSheetHeader(
          icon: LucideIcons300.gitBranch,
          title: AppText.manageRepos,
          subtitle: AppText.reposDescription,
        ),
        const SizedBox(height: DotSpace.s4),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListGroup(
                background: c.bg,
                children: [
                  for (final repo in repos)
                    ListRow(
                      title:
                          repo.name ?? Uri.tryParse(repo.url)?.host ?? repo.url,
                      subtitle: repo.error == null
                          ? repo.url
                          : '${AppText.repoFailed} · ${repo.url}',
                      trailing: RoundIconButton(
                        icon: LucideIcons300.trash2,
                        semanticLabel: AppText.delete,
                        iconSize: DotSize.iconSmall,
                        background: Colors.transparent,
                        onTap: () => context.read<ExtensionsCubit>().removeRepo(
                          repo.url,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: DotSpace.s4),
        TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          autocorrect: false,
          style: DotlineText.body.copyWith(color: c.ink),
          decoration: InputDecoration(
            hintText: 'https://…/index.json · index.min.json',
            errorText: _error,
          ),
          onSubmitted: (_) => _add(),
        ),
        const SizedBox(height: DotSpace.s3),
        Text(
          AppText.repoWarning,
          style: DotlineText.bodyS.copyWith(color: c.inkFaint),
        ),
        const SizedBox(height: DotSpace.s4),
        DotButton(
          label: _adding ? AppText.repoAdding : AppText.addRepo,
          leading: LucideIcons300.plus,
          onTap: _adding ? null : _add,
        ),
      ],
    );
  }
}
