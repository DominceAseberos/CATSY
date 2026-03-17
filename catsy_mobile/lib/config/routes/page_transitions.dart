import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A custom GoRouter transition that slides in from the right and fades in.
class SlidePageTransition<T> extends CustomTransitionPage<T> {
  SlidePageTransition({required super.child, super.key})
    : super(
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideAnimation =
              Tween<Offset>(
                begin: const Offset(1.0, 0.0), // Start from the right
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                ),
              );

          final fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(opacity: fadeAnimation, child: child),
          );
        },
      );
}
