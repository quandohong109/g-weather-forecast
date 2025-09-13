// lib/presentations/weather/weather_state.dart
import 'package:equatable/equatable.dart';
import 'package:g_weather_forecast/objects/weather_data.dart';

class WeatherState extends Equatable {
  final String q;
  final String cityID;
  final WeatherData? currentWeather;
  final List<WeatherData>? forecast;
  final bool isLoading;
  final String? error;
  final bool updateTextField; // Changed from autoLoaded

  const WeatherState({
    this.q = '',
    this.cityID = '',
    this.currentWeather,
    this.forecast,
    this.isLoading = false,
    this.error,
    this.updateTextField = false, // Changed from autoLoaded
  });

  WeatherState copyWith({
    String? q,
    String? cityID,
    WeatherData? currentWeather,
    List<WeatherData>? forecast,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? updateTextField, // Changed from autoLoaded
  }) {
    return WeatherState(
      q: q ?? this.q,
      cityID: cityID ?? this.cityID,
      currentWeather: currentWeather ?? this.currentWeather,
      forecast: forecast ?? this.forecast,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      updateTextField: updateTextField ?? this.updateTextField, // Changed from autoLoaded
    );
  }

  @override
  List<Object?> get props => [q, cityID, currentWeather, forecast, isLoading, error, updateTextField]; // Changed from autoLoaded
}
