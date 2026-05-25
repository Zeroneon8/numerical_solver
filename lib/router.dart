import 'package:go_router/go_router.dart';

import 'presentation/screens/home_screen.dart';
import 'presentation/screens/input_screen.dart';
import 'presentation/screens/result_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: <GoRoute>[
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/input',
      builder: (context, state) => const InputScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) => const ResultScreen(),
    ),
  ],
);
