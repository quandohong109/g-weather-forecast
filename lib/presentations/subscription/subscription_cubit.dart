// lib/presentations/subscription/subscription_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:g_weather_forecast/objects/location.dart';
import 'package:g_weather_forecast/presentations/subscription/subscription_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit() : super(const SubscriptionState()) {
    _loadLastUsedCity();
  }

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final Dio _dio = Dio();

  void changeEmail(String email) {
    emit(state.copyWith(email: email));
  }

  void setCity(Location location) {
    emit(state.copyWith(selectedLocation: location));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  void clearSuccessMessage() {
    emit(state.copyWith(clearSuccess: true));
  }

  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegExp.hasMatch(email);
  }

  Future<Map<String, dynamic>?> _checkExistingSubscription(String email) async {
    try {
      final callable = _functions.httpsCallable('checkSubscription');
      final response = await callable.call<Map<String, dynamic>>({
        'email': email,
      });
      return response.data;
    } catch (e) {
      print('Error checking subscription: $e');
      return null;
    }
  }

  Future<void> subscribe() async {
    // Clear previous messages
    emit(state.copyWith(clearError: true, clearSuccess: true));

    // Validate email and city first
    if (state.email.isEmpty || state.selectedLocation == null) {
      emit(state.copyWith(error: "Email and city must be selected.", clearError: false));
      return;
    }

    // Validate email format before proceeding
    if (!_isValidEmail(state.email)) {
      emit(state.copyWith(error: "Please enter a valid email address.", clearError: false));
      return;
    }

    emit(state.copyWith(isLoading: true));

    try {
      // Check if subscription exists
      final existingSubData = await _checkExistingSubscription(state.email);

      if (existingSubData != null && existingSubData['exists'] == true) {
        final existingCityId = existingSubData['cityId'].toString();
        final newCityId = state.selectedLocation!.id.toString();

        emit(state.copyWith(isLoading: false));

        // If same city, show message
        if (existingCityId == newCityId) {
          emit(state.copyWith(successMessage: "You're already subscribed to this city's weather updates."));
          return;
        }

        // If different city, show confirmation dialog
        emit(state.copyWith(
          pendingCityChange: true,
          existingCityName: existingSubData['cityName'] ?? "another city",
        ));
        return;
      }

      // New subscription process
      final callable = _functions.httpsCallable('requestSubscription');
      final response = await callable.call<Map<String, dynamic>>({
        'email': state.email.trim().toLowerCase(),
        'cityId': state.selectedLocation!.id.toString(),
        'cityName': state.selectedLocation!.name,
      });

      final message = response.data['message'] as String;
      emit(state.copyWith(isLoading: false, successMessage: message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: "Request failed: $e"));
    }
  }

  Future<void> confirmCityChange() async {
    emit(state.copyWith(isLoading: true, pendingCityChange: false, clearError: true, clearSuccess: true));

    try {
      final callable = _functions.httpsCallable('requestSubscription');
      final response = await callable.call<Map<String, dynamic>>({
        'email': state.email.trim().toLowerCase(),
        'cityId': state.selectedLocation!.id.toString(),
        'cityName': state.selectedLocation!.name, // Add city name
        'isChangeRequest': true,
      });

      final message = response.data['message'] as String;
      emit(state.copyWith(isLoading: false, successMessage: message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: "Request failed: $e"));
    }
  }

  Future<void> _loadLastUsedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCityId = prefs.getString('last_city_id');
    if (lastCityId == null) return;

    final String apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
    if (apiKey.isEmpty) return;

    try {
      final response = await _dio.get(
        "https://api.weatherapi.com/v1/forecast.json",
        queryParameters: {'key': apiKey, 'q': 'id:$lastCityId', 'days': 1},
      );
      if (response.data != null) {
        final locationData = response.data['location'];
        final location = Location(
          id: int.tryParse(lastCityId),
          name: locationData['name'],
          region: locationData['region'],
          country: locationData['country'],
        );
        emit(state.copyWith(lastUsedLocation: location, selectedLocation: location));
      }
    } catch (e) {
      // Ignore error
    }
  }

  Future<List<Location>> searchCities(String query) async {
    if (query.isEmpty) {
      return [
        Location(id: 2717933, name: "Ha Noi", region: "", country: "Vietnam"),
        Location(id: 2718413, name: "Ho Chi Minh City", region: "", country: "Vietnam"),
      ];
    }
    final String apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('API Key not found.');
    }
    try {
      final response = await _dio.get(
        "https://api.weatherapi.com/v1/search.json",
        queryParameters: {'key': apiKey, 'q': query},
      );
      if (response.data != null) {
        return (response.data as List).map((json) => Location.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> unsubscribe() async {
    // Clear previous messages
    emit(state.copyWith(clearError: true, clearSuccess: true));

    // First, check if email is provided
    if (state.email.isEmpty) {
      emit(state.copyWith(error: "Email cannot be empty.", clearError: false));
      return;
    }

    // Next, validate email format before doing anything else
    if (!_isValidEmail(state.email)) {
      emit(state.copyWith(error: "Please enter a valid email address.", clearError: false));
      return;
    }

    // Only proceed with API call if email is valid
    emit(state.copyWith(isLoading: true));

    try {
      // Check if subscription exists first before attempting to unsubscribe
      final existingSubData = await _checkExistingSubscription(state.email);

      // If no subscription exists, return early with friendly message
      if (existingSubData == null || existingSubData['exists'] == false) {
        emit(state.copyWith(
            isLoading: false,
            successMessage: "This email is not currently subscribed to any weather updates."
        ));
        return;
      }

      // If subscription exists, proceed with unsubscription
      final callable = _functions.httpsCallable('requestUnsubscription');
      final response = await callable.call<Map<String, dynamic>>({
        'email': state.email,
      });

      final message = response.data['message'] as String;
      emit(state.copyWith(isLoading: false, successMessage: message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: "Request failed: $e"));
    }
  }
}
