import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/rov_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RovCubit, RovState>(
      builder: (context, state) {
        final controller = context.read<RovCubit>();
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.router),
                  title: const Text('Raspberry Pi server'),
                  subtitle: Text(state.baseUrl ?? 'No server configured'),
                  trailing: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      controller.changeServer();
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Change'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Status polling'),
                  subtitle: Text(
                    'Every ${RovCubit.pollInterval.inMilliseconds} ms',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
