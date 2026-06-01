import 'package:flutter/material.dart';

/// IndexedStack yang hanya membuild tab yang pernah dikunjungi user.
/// Tab yang belum pernah dibuka akan tetap berupa placeholder kosong
/// sehingga mengurangi beban build saat cold start (dari 5 screen → 1 screen).
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  final Set<int> _activatedIndexes = {};

  @override
  void initState() {
    super.initState();
    _activatedIndexes.add(widget.index);
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _activatedIndexes.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: List.generate(widget.children.length, (i) {
        if (_activatedIndexes.contains(i)) {
          return widget.children[i];
        }
        return const SizedBox.shrink();
      }),
    );
  }
}
