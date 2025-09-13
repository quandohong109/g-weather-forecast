// lib/presentations/weather/weather_cubit.dart
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:g_weather_forecast/objects/weather_data.dart';
import 'package:g_weather_forecast/presentations/weather/weather_state.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../objects/location.dart';

class WeatherCubit extends Cubit<WeatherState> {
  WeatherCubit() : super(const WeatherState()) {
    _loadInitialWeather();
  }

  final Dio _dio = Dio();

  Future<void> _loadInitialWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCityId = prefs.getString('last_city_id');
    final lastFetchDateStr = prefs.getString('last_fetch_date');

    if (lastCityId != null && lastFetchDateStr != null) {
      final lastFetchDate = DateTime.parse(lastFetchDateStr);
      final now = DateTime.now();

      if (lastFetchDate.year == now.year &&
          lastFetchDate.month == now.month &&
          lastFetchDate.day == now.day) {
        emit(state.copyWith(cityID: lastCityId, updateTextField: true));
        await getWeather();
      }
    }
  }

  void setQ(String q) {
    emit(state.copyWith(q: q));
  }

  void setCityID(String cityID) {
    emit(state.copyWith(cityID: cityID, updateTextField: false));
  }

  Future<void> getWeatherForCurrentLocation() async {
    emit(state.copyWith(isLoading: true, error: null, clearError: true, updateTextField: true));
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(state.copyWith(
              isLoading: false, error: 'Location permissions are denied'));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        emit(state.copyWith(
            isLoading: false,
            error:
            'Location permissions are permanently denied, we cannot request permissions.'));
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final List<Location> locations =
      await searchCities('${position.latitude},${position.longitude}');

      if (locations.isNotEmpty) {
        final location = locations.first;
        if (location.id != null) {
          emit(state.copyWith(cityID: location.id.toString()));
          await getWeather();
        } else {
          throw Exception('Could not find a city ID for the current location.');
        }
      } else {
        throw Exception('Could not find a city for the current location.');
      }
    } catch (e) {
      emit(state.copyWith(
          isLoading: false, error: 'Failed to get current location: $e'));
    }
  }

  Future<void> getWeather() async {
    if (state.cityID.isEmpty) return;

    if (!state.isLoading) {
      emit(state.copyWith(isLoading: true, error: null, clearError: true));
    }

    final String apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      emit(state.copyWith(isLoading: false, error: 'API Key not found.'));
      return;
    }

    try {
      final response = await _dio.get(
        "https://api.weatherapi.com/v1/forecast.json",
        queryParameters: {
          'key': apiKey,
          'q': 'id:${state.cityID}',
          'days': 14,
        },
      );

      if (response.data != null) {
        final location = response.data['location'];
        final current = response.data['current'];
        final forecastDays = response.data['forecast']['forecastday'] as List;

        final currentWeatherData = WeatherData(
          cityName: location['name'],
          date: DateTime.parse(current['last_updated']),
          temperature: current['temp_c'],
          windSpeed: current['wind_kph'] / 3.6,
          humidity: current['humidity'],
          condition: current['condition']['text'],
          iconUrl: 'https:${current['condition']['icon']}',
        );

        final forecastData = forecastDays.skip(1).map((day) {
          final dayData = day['day'];
          return WeatherData(
            cityName: location['name'],
            date: DateTime.parse(day['date']),
            temperature: dayData['avgtemp_c'],
            windSpeed: dayData['maxwind_kph'] / 3.6,
            humidity: dayData['avghumidity'].toInt(),
            condition: dayData['condition']['text'],
            iconUrl: 'https:${dayData['condition']['icon']}',
          );
        }).toList();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_city_id', state.cityID);
        await prefs.setString('last_fetch_date', DateTime.now().toIso8601String());

        emit(state.copyWith(
          isLoading: false,
          currentWeather: currentWeatherData,
          forecast: forecastData,
        ));
      } else {
        throw Exception('No data received from API');
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          isLoading: false, error: 'Failed to fetch data: ${e.message}'));
    } catch (e) {
      emit(state.copyWith(
          isLoading: false, error: 'An unexpected error occurred: $e'));
    }
  }

  Future<List<Location>> searchCities(String query) async {
    final String apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      throw Exception('API Key not found. Please check your .env file.');
    }

    try {
      final response = await _dio.get(
        "https://api.weatherapi.com/v1/search.json",
        queryParameters: {
          'key': apiKey,
          'q': query,
        },
      );

      if (response.data != null) {
        List<dynamic> jsonList = response.data;
        return jsonList.map((json) => Location.fromMap(json)).toList();
      } else {
        throw Exception('No data received from API');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch data: ${e.message}');
    }
  }
}
