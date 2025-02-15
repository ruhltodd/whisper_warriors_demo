import 'package:flutter/material.dart';

class GamePageTransition<T> extends PageRoute<T> {
  GamePageTransition({
    required this.builder,
    this.duration = const Duration(milliseconds: 300),
    this.transitionType = TransitionType.fade,
  });

  final WidgetBuilder builder;
  final Duration duration;
  final TransitionType transitionType;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    switch (transitionType) {
      case TransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: builder(context),
        );
      case TransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: builder(context),
          ),
        );
    }
  }
}

enum TransitionType {
  fade,
  slideUp,
}
