import 'package:flutter/material.dart';

/// A drop-in replacement for IndexedStack that lazily builds its children.
/// Children are only injected into the widget tree when they are first navigated to.
/// Once built, they remain in the tree to preserve their state.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final StackFit sizing;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.sizing = StackFit.loose,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late List<bool> _activatedList;

  @override
  void initState() {
    super.initState();
    _activatedList = List<bool>.filled(widget.children.length, false);
    _activatedList[widget.index] = true;
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      _activatedList = List<bool>.filled(widget.children.length, false);
    }
    _activatedList[widget.index] = true;
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      alignment: widget.alignment,
      textDirection: widget.textDirection,
      sizing: widget.sizing,
      children: List<Widget>.generate(widget.children.length, (i) {
        if (_activatedList[i]) {
          return widget.children[i];
        } else {
          return const SizedBox.shrink();
        }
      }),
    );
  }
}
