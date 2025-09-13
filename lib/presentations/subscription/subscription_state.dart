import '../../objects/location.dart';

class SubscriptionState {
  final String email;
  final Location? selectedLocation;
  final Location? lastUsedLocation;
  final String? error;
  final String? successMessage;
  final bool isLoading;
  final bool pendingCityChange;
  final String? existingCityName;

  const SubscriptionState({
    this.email = '',
    this.selectedLocation,
    this.lastUsedLocation,
    this.error,
    this.successMessage,
    this.isLoading = false,
    this.pendingCityChange = false,
    this.existingCityName,
  });

  SubscriptionState copyWith({
    String? email,
    Location? selectedLocation,
    Location? lastUsedLocation,
    String? error,
    String? successMessage,
    bool? isLoading,
    bool? pendingCityChange,
    String? existingCityName,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SubscriptionState(
      email: email ?? this.email,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      lastUsedLocation: lastUsedLocation ?? this.lastUsedLocation,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      isLoading: isLoading ?? this.isLoading,
      pendingCityChange: pendingCityChange ?? this.pendingCityChange,
      existingCityName: existingCityName ?? this.existingCityName,
    );
  }
}
