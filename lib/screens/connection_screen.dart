import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/rov_cubit.dart';
import '../core/constants.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final saved = context.read<RovCubit>().state.lastSavedBaseUrl ?? '';
    _addressController = TextEditingController(text: saved);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    FocusScope.of(context).unfocus();
    await context.read<RovCubit>().connect(_addressController.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RovCubit, RovState>(
      builder: (context, state) {
        final saved = state.lastSavedBaseUrl;
        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.background, AppColors.backgroundDeep],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.card.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Container(
                                width: 68,
                                height: 68,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.settings_input_antenna,
                                  size: 38,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Connect to ROV',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Enter the Raspberry Pi IP address. Your phone and Raspberry Pi must be connected to the same Wi-Fi network.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 28),
                            TextField(
                              controller: _addressController,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _connect(),
                              decoration: const InputDecoration(
                                labelText: 'Raspberry Pi address',
                                hintText: '192.168.1.193',
                                prefixIcon: Icon(Icons.router),
                              ),
                            ),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: state.isConnecting ? null : _connect,
                              icon: state.isConnecting
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.wifi_tethering),
                              label: Text(
                                state.isConnecting
                                    ? 'Connecting...'
                                    : 'Connect to Dashboard',
                              ),
                            ),
                            if (state.setupError != null) ...[
                              const SizedBox(height: 14),
                              _MessagePanel(
                                icon: Icons.error_outline,
                                text: state.setupError!,
                              ),
                            ],
                            if (saved != null && saved.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Card(
                                child: ListTile(
                                  leading: const Icon(Icons.history),
                                  title: const Text('Previously saved server'),
                                  subtitle: Text(saved),
                                  trailing: IconButton(
                                    tooltip: 'Use saved server',
                                    icon: const Icon(Icons.north_west),
                                    onPressed: () =>
                                        _addressController.text = saved,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
