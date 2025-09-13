import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:g_weather_forecast/objects/location.dart';
import 'package:g_weather_forecast/presentations/subscription/subscription_cubit.dart';
import 'package:g_weather_forecast/presentations/subscription/subscription_state.dart';
import 'package:g_weather_forecast/widgets/city_search_card.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  static Widget newInstance() => BlocProvider(
    create: (context) => SubscriptionCubit(),
    child: const SubscriptionPage(),
  );

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _typeAheadController = TextEditingController();

  SubscriptionCubit get subCubit => context.read<SubscriptionCubit>();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      subCubit.changeEmail(_emailController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _typeAheadController.dispose();
    super.dispose();
  }

  void _showSuccessDialog({required String title, required String message}) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.secondary,
        title: Text(title, style: TextStyle(color: colorScheme.onSecondary)),
        content: Text(message, style: TextStyle(color: colorScheme.onSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              subCubit.clearSuccessMessage(); // Clear success state
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog({required String message}) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.secondary,
        title: Text('Error', style: TextStyle(color: colorScheme.onSecondary)),
        content: Text(message, style: TextStyle(color: colorScheme.onSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              subCubit.clearError(); // Clear error state
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog({required String title, required String content, required VoidCallback onConfirm}) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.secondary,
        title: Text(title, style: TextStyle(color: colorScheme.onSecondary)),
        content: Text(content, style: TextStyle(color: colorScheme.onSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: colorScheme.onSecondary),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<SubscriptionCubit, SubscriptionState>(
        listener: (context, state) {
          if (state.error != null) {
            _showErrorDialog(message: state.error!);
          }
          if (state.successMessage != null) {
            _showSuccessDialog(
              title: 'Success',
              message: state.successMessage!,
            );
          }
          if (state.selectedLocation != null && _typeAheadController.text != state.selectedLocation!.name) {
            _typeAheadController.text = state.selectedLocation!.name ?? '';
          }

          if (state.pendingCityChange) {
            _showConfirmationDialog(
              title: 'Change Subscription',
              content: 'You are already subscribed to ${state.existingCityName}. Would you like to change your subscription to ${state.selectedLocation!.name}?',
              onConfirm: () => subCubit.confirmCityChange(),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Subscribe for Daily Weather Updates', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                    hintText: 'Enter your email address',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSecondary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 24),
                CitySearchCard(
                  suggestionsCallback: subCubit.searchCities,
                  typeAheadController: _typeAheadController,
                  onCitySelected: (Location location) {
                    subCubit.setCity(location);
                  },
                ),
                const SizedBox(height: 24),
                if (state.isLoading) const Center(child: CircularProgressIndicator()),
                if (!state.isLoading) ...[
                  ElevatedButton(
                    onPressed: state.email.isEmpty || state.selectedLocation == null
                        ? null
                        : () => _showConfirmationDialog(
                      title: 'Confirm Subscription',
                      content: 'Subscribe ${state.email} to updates for ${state.selectedLocation!.name}?',
                      onConfirm: () => subCubit.subscribe(),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Subscribe'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: state.email.isEmpty
                        ? null
                        : () => _showConfirmationDialog(
                      title: 'Confirm Unsubscription',
                      content: 'Unsubscribe ${state.email} from all updates?',
                      onConfirm: () => subCubit.unsubscribe(),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Unsubscribe'),
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}
