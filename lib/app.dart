import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/app_theme.dart';
import 'blocs/rov_cubit.dart';
import 'screens/connection_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';

class RovCommanderApp extends StatelessWidget {
  const RovCommanderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RovCubit()..bootstrap(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ROV Commander',
        theme: AppTheme.darkTheme,
        home: const AppRouter(),
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RovCubit, RovState>(
      builder: (context, state) {
        return switch (state.startupDestination) {
          StartupDestination.loading => const SplashScreen(),
          StartupDestination.setup => const ConnectionScreen(),
          StartupDestination.dashboard => const DashboardScreen(),
        };
      },
    );
  }
}
