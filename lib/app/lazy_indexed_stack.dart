import 'package:flutter/widgets.dart';

/// An [IndexedStack] that builds a child the first time [index] selects
/// it, then keeps it (and its state) like [IndexedStack] does. Children
/// never shown cost nothing.
class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int index;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  final _built = <int>{};

  @override
  Widget build(BuildContext context) {
    _built.add(widget.index);
    return IndexedStack(
      index: widget.index,
      children: [
        for (var i = 0; i < widget.itemCount; i++)
          _built.contains(i)
              ? KeyedSubtree(
                  key: ValueKey(i),
                  child: widget.itemBuilder(context, i),
                )
              : const SizedBox.shrink(),
      ],
    );
  }
}
