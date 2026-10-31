import 'dart:math' as math;

import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// Horizontal inset that centres a [maxWidth] column inside [width], zero
/// when [width] is narrower. Used as a scroll view's padding so the view
/// itself stays full width and the wheel works over the margins too.
EdgeInsets contentInset(
  double width, [
  double maxWidth = DotSize.contentMaxWidth,
]) => EdgeInsets.symmetric(horizontal: math.max(0, (width - maxWidth) / 2));

/// Centres [child] in a column at most [maxWidth] wide, e.g. a
/// [ScreenHeader] above a scroll view wrapped in [SliverCenteredContent].
class CenteredContent extends StatelessWidget {
  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth = DotSize.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    // As tall as [child], so it can go where height is loose, e.g. a
    // Scaffold's bottomNavigationBar.
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// [slivers] in a column at most [maxWidth] wide, centred in the scroll view.
class SliverCenteredContent extends StatelessWidget {
  const SliverCenteredContent({
    super.key,
    required this.slivers,
    this.maxWidth = DotSize.contentMaxWidth,
  });

  final List<Widget> slivers;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverPadding(
        padding: contentInset(constraints.crossAxisExtent, maxWidth),
        sliver: SliverMainAxisGroup(slivers: slivers),
      ),
    );
  }
}
