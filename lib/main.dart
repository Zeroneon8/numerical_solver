import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const double _mobileViewportWidth = 412;
  static const double _mobileViewportHeight = 915;
  static const Size _mobileViewportSize = Size(
    _mobileViewportWidth,
    _mobileViewportHeight,
  );
  static const double _mobileAspectRatio =
      _mobileViewportWidth / _mobileViewportHeight;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      builder: (context, child) {
        final Widget routedChild = child ?? const SizedBox.shrink();
        return _ViewportAdapter(child: routedChild);
      },
    );
  }
}

class _ViewportAdapter extends StatelessWidget {
  const _ViewportAdapter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final Size availableSize = mediaQuery.size;

    if (availableSize.shortestSide < 600) {
      return child;
    }

    final Size viewportSize = _resolveMobileViewport(availableSize);
    final MediaQueryData viewportMediaQuery = mediaQuery.copyWith(
      size: viewportSize,
    );

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: SizedBox(
          width: viewportSize.width,
          height: viewportSize.height,
          child: MediaQuery(data: viewportMediaQuery, child: child),
        ),
      ),
    );
  }

  Size _resolveMobileViewport(Size availableSize) {
    final double widthLimitedByScreen = math.min(
      availableSize.width,
      MyApp._mobileViewportSize.width,
    );
    final double heightAtWidthLimit =
        widthLimitedByScreen / MyApp._mobileAspectRatio;

    if (heightAtWidthLimit <= availableSize.height) {
      return Size(widthLimitedByScreen, heightAtWidthLimit);
    }

    final double heightLimitedByScreen = math.min(
      availableSize.height,
      MyApp._mobileViewportSize.height,
    );
    final double widthAtHeightLimit =
        heightLimitedByScreen * MyApp._mobileAspectRatio;

    return Size(widthAtHeightLimit, heightLimitedByScreen);
  }
}
